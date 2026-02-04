-- Blocked users: blocker does not see lesson requests from blocked_user_id.

create table if not exists public.blocked_users (
  user_id uuid not null references auth.users(id) on delete cascade,
  blocked_user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, blocked_user_id)
);

create index if not exists idx_blocked_users_user_id on public.blocked_users(user_id);

alter table public.blocked_users enable row level security;

create policy "Users can read own blocked list"
  on public.blocked_users for select to authenticated using (auth.uid() = user_id);

create policy "Users can insert own blocked list"
  on public.blocked_users for insert to authenticated with check (auth.uid() = user_id);

create policy "Users can delete own blocked list"
  on public.blocked_users for delete to authenticated using (auth.uid() = user_id);

comment on table public.blocked_users is 'Blocked users: lesson requests from blocked_user_id are hidden from user_id.';
