-- Favorite tab assignments: which tab (Tutor / Student) a chat-added favorite belongs to.
-- Syncs across devices. Used when user taps "like" in chat profile.

create table if not exists public.favorite_tab_assignments (
  user_id uuid not null references auth.users(id) on delete cascade,
  other_user_id uuid not null references auth.users(id) on delete cascade,
  tab text not null check (tab in ('tutor', 'student')),
  created_at timestamptz not null default now(),
  primary key (user_id, other_user_id)
);

create index if not exists idx_favorite_tab_assignments_user_id
  on public.favorite_tab_assignments(user_id);

alter table public.favorite_tab_assignments enable row level security;

create policy "Users can read own favorite tab assignments"
  on public.favorite_tab_assignments for select
  to authenticated
  using (auth.uid() = user_id);

create policy "Users can insert own favorite tab assignments"
  on public.favorite_tab_assignments for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "Users can update own favorite tab assignments"
  on public.favorite_tab_assignments for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can delete own favorite tab assignments"
  on public.favorite_tab_assignments for delete
  to authenticated
  using (auth.uid() = user_id);

comment on table public.favorite_tab_assignments is
  'Stores which Favorite tab (tutor | student) a user added from chat. Syncs across devices.';
