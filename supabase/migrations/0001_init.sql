-- ============================================================================
-- Bora — Phase 2 backend schema (sharing layer)
--
-- Privacy-first: we store ONLY busy/free intervals, never event titles,
-- locations, or guests. Row-Level Security guarantees you can read a person's
-- availability only if you are accepted friends.
--
-- Run this in the Supabase SQL editor (or via `supabase db push`).
-- ============================================================================

create extension if not exists pgcrypto with schema extensions;

-- ----------------------------------------------------------------------------
-- profiles — one row per auth user (auto-created on signup)
-- ----------------------------------------------------------------------------
create table if not exists public.profiles (
    id           uuid primary key references auth.users (id) on delete cascade,
    handle       text unique,                       -- optional @username for adding friends
    display_name text not null default 'Friend',
    color_index  smallint not null default 0,       -- avatar tint (matches the app palette)
    time_zone    text not null default 'Europe/Amsterdam',
    created_at   timestamptz not null default now()
);

-- Create a profile automatically whenever a new auth user is created.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
    insert into public.profiles (id, display_name)
    values (
        new.id,
        coalesce(new.raw_user_meta_data ->> 'full_name', 'Friend')
    )
    on conflict (id) do nothing;
    return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
    after insert on auth.users
    for each row execute function public.handle_new_user();

-- ----------------------------------------------------------------------------
-- friendships — one canonical row per pair, with user_a < user_b
-- ----------------------------------------------------------------------------
create table if not exists public.friendships (
    user_a       uuid not null references auth.users (id) on delete cascade,
    user_b       uuid not null references auth.users (id) on delete cascade,
    status       text not null default 'accepted' check (status in ('pending', 'accepted')),
    requested_by uuid not null references auth.users (id) on delete cascade,
    created_at   timestamptz not null default now(),
    primary key (user_a, user_b),
    check (user_a < user_b)
);

-- Are two users accepted friends? Used inside RLS policies.
create or replace function public.are_friends(a uuid, b uuid)
returns boolean
language sql
stable
security definer set search_path = public
as $$
    select exists (
        select 1 from public.friendships f
        where f.status = 'accepted'
          and f.user_a = least(a, b)
          and f.user_b = greatest(a, b)
    );
$$;

-- ----------------------------------------------------------------------------
-- invites — share-link tokens ("bora.app/i/<token>")
-- ----------------------------------------------------------------------------
create table if not exists public.invites (
    token      text primary key
                 default replace(replace(encode(extensions.gen_random_bytes(9), 'base64'), '+', '-'), '/', '_'),
    inviter_id uuid not null references auth.users (id) on delete cascade,
    created_at timestamptz not null default now(),
    expires_at timestamptz not null default (now() + interval '14 days')
);

-- Redeem an invite: creates an accepted friendship between inviter and caller.
-- SECURITY DEFINER so it can look up the token (which the caller can't read via RLS).
create or replace function public.redeem_invite(invite_token text)
returns uuid                                   -- returns the inviter's id
language plpgsql
security definer set search_path = public
as $$
declare
    v_inviter uuid;
    v_me      uuid := auth.uid();
begin
    if v_me is null then
        raise exception 'not authenticated';
    end if;

    select inviter_id into v_inviter
    from public.invites
    where token = invite_token and expires_at > now();

    if v_inviter is null then
        raise exception 'invalid or expired invite';
    end if;
    if v_inviter = v_me then
        raise exception 'cannot redeem your own invite';
    end if;

    insert into public.friendships (user_a, user_b, status, requested_by)
    values (least(v_inviter, v_me), greatest(v_inviter, v_me), 'accepted', v_inviter)
    on conflict (user_a, user_b) do update set status = 'accepted';

    return v_inviter;
end;
$$;

-- ----------------------------------------------------------------------------
-- busy_blocks — the synced availability (busy intervals only)
-- The app replaces its own rows for the sync window on each sync.
-- ----------------------------------------------------------------------------
create table if not exists public.busy_blocks (
    id         uuid primary key default gen_random_uuid(),
    user_id    uuid not null references auth.users (id) on delete cascade,
    starts_at  timestamptz not null,
    ends_at    timestamptz not null,
    updated_at timestamptz not null default now(),
    check (ends_at > starts_at)
);

create index if not exists busy_blocks_user_time_idx
    on public.busy_blocks (user_id, starts_at);

-- ============================================================================
-- Row-Level Security
-- ============================================================================
alter table public.profiles    enable row level security;
alter table public.friendships enable row level security;
alter table public.invites     enable row level security;
alter table public.busy_blocks enable row level security;

-- profiles: readable by self and accepted friends; writable only by self.
create policy "profiles_select_self_or_friends" on public.profiles
    for select using (id = auth.uid() or public.are_friends(auth.uid(), id));
create policy "profiles_insert_own" on public.profiles
    for insert with check (id = auth.uid());
create policy "profiles_update_own" on public.profiles
    for update using (id = auth.uid()) with check (id = auth.uid());

-- friendships: visible to the two members. Writes happen through redeem_invite().
create policy "friendships_select_members" on public.friendships
    for select using (auth.uid() in (user_a, user_b));

-- invites: an inviter manages their own links.
create policy "invites_select_own" on public.invites
    for select using (inviter_id = auth.uid());
create policy "invites_insert_own" on public.invites
    for insert with check (inviter_id = auth.uid());
create policy "invites_delete_own" on public.invites
    for delete using (inviter_id = auth.uid());

-- busy_blocks: readable by self and accepted friends; writable only by self.
create policy "busy_select_self_or_friends" on public.busy_blocks
    for select using (user_id = auth.uid() or public.are_friends(auth.uid(), user_id));
create policy "busy_write_own" on public.busy_blocks
    for all using (user_id = auth.uid()) with check (user_id = auth.uid());
