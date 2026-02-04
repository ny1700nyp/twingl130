-- get_user_stats: single RPC for My Activity Stats (profile views, fans, incoming/outgoing requests)
-- A방식: 한 번의 RPC로 모든 통계 반환. profile_views 및 matches RLS 포함.

-- 1) profile_views 테이블 (Views 카운트용)
create table if not exists public.profile_views (
  id uuid primary key default gen_random_uuid(),
  viewer_id uuid not null references auth.users(id) on delete cascade,
  viewed_user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(viewer_id, viewed_user_id)
);
create index if not exists idx_profile_views_viewed_user_id on public.profile_views(viewed_user_id);
alter table public.profile_views enable row level security;
drop policy if exists "Users can insert own profile view" on public.profile_views;
create policy "Users can insert own profile view"
  on public.profile_views for insert to authenticated with check (auth.uid() = viewer_id);
drop policy if exists "Users can read views on own profile" on public.profile_views;
create policy "Users can read views on own profile"
  on public.profile_views for select to authenticated using (auth.uid() = viewed_user_id);

-- 2) matches RLS – Fans(나를 좋아요한 수) 조회 허용 (swiped_user_id uuid)
drop policy if exists "Users can read matches where they are swiped_user (fans count)" on public.matches;
create policy "Users can read matches where they are swiped_user (fans count)"
  on public.matches for select to authenticated using (auth.uid() = swiped_user_id);

create or replace function public.get_user_stats(p_user_id uuid)
returns jsonb
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_profile_view_count int;
  v_favorite_count int;
  v_in_total int;
  v_in_accepted int;
  v_out_total int;
  v_out_accepted int;
begin
  -- Only allow requesting own stats
  if auth.uid() is null or auth.uid() != p_user_id then
    return jsonb_build_object(
      'profileViewCount', 0,
      'favoriteCount', 0,
      'incomingRequests', jsonb_build_object('total', 0, 'accepted', 0),
      'outgoingRequests', jsonb_build_object('total', 0, 'accepted', 0)
    );
  end if;

  -- Profile views count
  select count(*)::int into v_profile_view_count
  from public.profile_views
  where viewed_user_id = p_user_id;

  -- Fans: matches where swiped_user_id = me and is_match = true (uuid)
  select count(*)::int into v_favorite_count
  from public.matches
  where swiped_user_id = p_user_id and is_match = true;

  -- Incoming requests: I am trainer_id (uuid)
  select count(*)::int into v_in_total
  from public.conversations
  where trainer_id = p_user_id;

  select count(*)::int into v_in_accepted
  from public.conversations
  where trainer_id = p_user_id and lower(trim(coalesce(status, ''))) = 'accepted';

  -- Outgoing requests: I am trainee_id (uuid)
  select count(*)::int into v_out_total
  from public.conversations
  where trainee_id = p_user_id;

  select count(*)::int into v_out_accepted
  from public.conversations
  where trainee_id = p_user_id and lower(trim(coalesce(status, ''))) = 'accepted';

  return jsonb_build_object(
    'profileViewCount', coalesce(v_profile_view_count, 0),
    'favoriteCount', coalesce(v_favorite_count, 0),
    'incomingRequests', jsonb_build_object('total', coalesce(v_in_total, 0), 'accepted', coalesce(v_in_accepted, 0)),
    'outgoingRequests', jsonb_build_object('total', coalesce(v_out_total, 0), 'accepted', coalesce(v_out_accepted, 0))
  );
end;
$$;

comment on function public.get_user_stats(uuid) is 'Returns activity stats for the current user: profileViewCount, favoriteCount, incomingRequests, outgoingRequests. Caller must pass own user id.';

grant execute on function public.get_user_stats(uuid) to authenticated;
