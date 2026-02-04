# Supabase: 프로필/자격증/추가 사진 삭제 커맨드

사진은 **Storage 버킷이 아니라** `public.profiles` 테이블 컬럼에 저장됩니다.

- `main_photo_path` (TEXT) – 대표 사진 1장
- `profile_photos` (TEXT[]) – 프로필 추가 사진 배열
- `certificate_photos` (TEXT[]) – 자격증/수료증 사진 배열

---

## 1. 특정 사용자만 지우기 (user_id 지정)

Supabase Dashboard → **SQL Editor**에서 실행하거나, 로컬에서는 `psql` / `supabase db execute` 사용.

### 1-1. 한 사용자의 사진 전부 지우기

```sql
-- YOUR_USER_ID_UUID 를 실제 user_id로 바꾸세요 (예: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890')
UPDATE public.profiles
SET
  main_photo_path = NULL,
  profile_photos = NULL,
  certificate_photos = NULL,
  updated_at = NOW()
WHERE user_id = 'YOUR_USER_ID_UUID';
```

### 1-2. 특정 사용자 – 프로필 사진만 지우기 (자격증은 유지)

```sql
UPDATE public.profiles
SET
  main_photo_path = NULL,
  profile_photos = NULL,
  updated_at = NOW()
WHERE user_id = 'YOUR_USER_ID_UUID';
```

### 1-3. 특정 사용자 – 자격증 사진만 지우기

```sql
UPDATE public.profiles
SET
  certificate_photos = NULL,
  updated_at = NOW()
WHERE user_id = 'YOUR_USER_ID_UUID';
```

---

## 2. 모든 사용자의 사진 일괄 지우기

주의: **전체 프로필의 사진을 비웁니다.**

```sql
UPDATE public.profiles
SET
  main_photo_path = NULL,
  profile_photos = NULL,
  certificate_photos = NULL,
  updated_at = NOW();
```

---

## 3. Supabase CLI로 실행 (로컬)

프로젝트 루트에서:

```bash
# 한 사용자만 지우기 (user_id를 실제 값으로 변경)
supabase db execute --sql "UPDATE public.profiles SET main_photo_path = NULL, profile_photos = NULL, certificate_photos = NULL, updated_at = NOW() WHERE user_id = 'YOUR_USER_ID_UUID';"

# 전체 사용자 사진 지우기 (주의)
supabase db execute --sql "UPDATE public.profiles SET main_photo_path = NULL, profile_photos = NULL, certificate_photos = NULL, updated_at = NOW();"
```

---

## 4. psql로 직접 접속해 실행

```bash
# 연결 문자열은 Supabase Dashboard → Project Settings → Database 에서 확인
psql "postgresql://postgres:[PASSWORD]@db.[PROJECT_REF].supabase.co:5432/postgres"

# 접속 후
UPDATE public.profiles
SET main_photo_path = NULL, profile_photos = NULL, certificate_photos = NULL, updated_at = NOW()
WHERE user_id = 'YOUR_USER_ID_UUID';
```

---

## 5. 컬럼만 비우는지 확인 (SELECT 후 UPDATE)

```sql
-- 지우기 전: 해당 user_id의 현재 값 확인
SELECT user_id, name,
       main_photo_path IS NOT NULL AS has_main,
       array_length(profile_photos, 1) AS profile_photos_count,
       array_length(certificate_photos, 1) AS cert_photos_count
FROM public.profiles
WHERE user_id = 'YOUR_USER_ID_UUID';

-- 위에서 확인한 뒤, 필요하면 1-1의 UPDATE 실행
```

요약:  
- **한 사람만:** `WHERE user_id = '...'` 넣은 `UPDATE` 사용.  
- **전체:** `WHERE` 없이 `UPDATE public.profiles SET main_photo_path = NULL, profile_photos = NULL, certificate_photos = NULL, updated_at = NOW();`  
- 실행 위치: Supabase SQL Editor / `supabase db execute` / `psql` 중 편한 것 사용하면 됩니다.
