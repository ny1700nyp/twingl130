# My Activity Stats – Supabase 반영 (Views + Fans)

앱에서 **프로필 조회 수(Views)** 와 **Fans(나를 좋아요한 수)** 가 올라가려면 아래를 Supabase SQL Editor에서 실행해야 합니다.

---

## 1. profile_views 테이블 (Views 카운트)

다른 사람이 내 프로필을 볼 때마다 기록하고, My Activity Stats의 "Views"에 반영됩니다.

```sql
-- 프로필을 "본" 기록 (누가, 누구 프로필을 봤는지)
create table if not exists public.profile_views (
  id uuid primary key default gen_random_uuid(),
  viewer_id uuid not null references auth.users(id) on delete cascade,
  viewed_user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(viewer_id, viewed_user_id)
);

create index if not exists idx_profile_views_viewed_user_id
  on public.profile_views(viewed_user_id);

alter table public.profile_views enable row level security;

-- 로그인 사용자가 "내가 본 프로필" 기록만 insert
create policy "Users can insert own profile view"
  on public.profile_views for insert
  to authenticated
  with check (auth.uid() = viewer_id);

-- 본인 프로필에 대한 조회 수만 select (viewed_user_id = 나)
create policy "Users can read views on own profile"
  on public.profile_views for select
  to authenticated
  using (auth.uid() = viewed_user_id);
```

- `unique(viewer_id, viewed_user_id)`: 같은 사람이 같은 프로필을 여러 번 봐도 1회만 카운트됩니다. 매번 +1 하려면 이 줄을 제거하면 됩니다.

---

## 2. matches RLS – Fans(나를 좋아요한 수) 조회 허용

Fans는 `matches` 테이블에서 **swiped_user_id = 내 user_id** 이고 **is_match = true** 인 행 개수입니다.  
RLS로 "내가 스와이프한 행만 SELECT"만 허용해 두면, "나를 좋아요한 행"은 조회가 막혀 Fans가 항상 0입니다. 아래 정책을 추가하세요.

```sql
-- "나를 좋아요한 사람 수"를 위해: swiped_user_id = 나 인 행은 SELECT 허용
create policy "Users can read matches where they are swiped_user (fans count)"
  on public.matches for select
  to authenticated
  using (auth.uid()::text = swiped_user_id);
```

- `matches`의 `swiped_user_id` 컬럼 타입이 `uuid`라면 `using (auth.uid() = swiped_user_id)` 로 하세요.
- 이미 비슷한 정책이 있으면 이름만 다를 수 있으니, "swiped_user_id = auth.uid()" 조건의 SELECT 정책이 하나 있으면 됩니다.

---

## 요약

| 목적 | Supabase에서 할 일 |
|------|---------------------|
| **Views 올라가게** | `profile_views` 테이블 + RLS 생성 (위 1번 SQL 실행) |
| **Fans 올라가게** | `matches` 테이블에 "swiped_user_id = 나" 인 행 SELECT 허용 정책 추가 (위 2번 SQL 실행) |

두 가지 모두 반영한 뒤 앱에서 다시 프로필 조회·좋아요를 하면 Stats에 반영됩니다.
