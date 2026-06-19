-- ============================================================================
-- Bora — Plans (propose a get-together to a chosen subset of friends)
-- ============================================================================

create table if not exists public.plans (
    id         uuid primary key default gen_random_uuid(),
    creator_id uuid not null references auth.users (id) on delete cascade,
    title      text not null default 'Get together',
    starts_at  timestamptz not null,
    ends_at    timestamptz not null,
    created_at timestamptz not null default now(),
    check (ends_at > starts_at)
);

create table if not exists public.plan_participants (
    plan_id uuid not null references public.plans (id) on delete cascade,
    user_id uuid not null references auth.users (id) on delete cascade,
    status  text not null default 'invited' check (status in ('invited', 'accepted', 'declined')),
    primary key (plan_id, user_id)
);

create index if not exists plan_participants_user_idx
    on public.plan_participants (user_id);

-- Helpers (security definer to avoid RLS recursion between the two tables).
create or replace function public.is_plan_creator(pid uuid)
returns boolean language sql stable security definer set search_path = public as $$
    select exists (select 1 from public.plans p where p.id = pid and p.creator_id = auth.uid());
$$;

create or replace function public.can_see_plan(pid uuid)
returns boolean language sql stable security definer set search_path = public as $$
    select exists (select 1 from public.plans p where p.id = pid and p.creator_id = auth.uid())
        or exists (select 1 from public.plan_participants pp
                   where pp.plan_id = pid and pp.user_id = auth.uid());
$$;

-- RLS
alter table public.plans              enable row level security;
alter table public.plan_participants  enable row level security;

create policy "plans_select_visible" on public.plans
    for select using (public.can_see_plan(id));
create policy "plans_insert_own" on public.plans
    for insert with check (creator_id = auth.uid());
create policy "plans_update_creator" on public.plans
    for update using (creator_id = auth.uid()) with check (creator_id = auth.uid());
create policy "plans_delete_creator" on public.plans
    for delete using (creator_id = auth.uid());

-- The creator manages the guest list; participants can read it and update
-- their own RSVP status.
create policy "pp_select_visible" on public.plan_participants
    for select using (public.can_see_plan(plan_id));
create policy "pp_insert_by_creator" on public.plan_participants
    for insert with check (public.is_plan_creator(plan_id));
create policy "pp_update_self_or_creator" on public.plan_participants
    for update using (user_id = auth.uid() or public.is_plan_creator(plan_id))
    with check (user_id = auth.uid() or public.is_plan_creator(plan_id));
create policy "pp_delete_by_creator" on public.plan_participants
    for delete using (public.is_plan_creator(plan_id));
