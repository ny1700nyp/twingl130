# Supabase 데이터베이스 스키마

이 문서는 GuruTown 앱에 필요한 Supabase 테이블 스키마를 설명합니다.

## 1. profiles 테이블

사용자 프로필 정보를 저장하는 테이블입니다.

### 컬럼 구조

```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  user_type TEXT NOT NULL CHECK (user_type IN ('trainer', 'trainee')),
  name TEXT NOT NULL, -- 사용자 이름 (필수)
  gender TEXT CHECK (gender IN ('man', 'woman', 'non-binary', 'Prefer not to say')),
  age INTEGER,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  talents TEXT[], -- Trainer talents OR Trainee goals (stored in talents; UI label changes by user_type)
  interests TEXT[], -- Trainer만 사용 (예: ['Sci-Fi', 'Marathon'])
  about_me TEXT, -- Trainer/Trainee 공통
  experience_description TEXT, -- Trainer만 사용 (UI label: "About the lesson")
  teaching_methods TEXT[], -- Preferred lesson location (trainer/trainee 공통, 예: ['onsite', 'online'])
  parent_participation_welcomed BOOLEAN DEFAULT false, -- Trainer만 사용 (아동 교육 시 부모 참여 환영 여부)
  tutoring_rate TEXT, -- Trainer만 사용 (시간당 수업료, 예: "50", "100")
  certificate_photos TEXT[], -- Trainer만 사용 (자격증/상장/학위 사진 base64 배열)
  trophy_count INTEGER DEFAULT 0, -- Trainer만 사용 (deprecated, certificate_photos.length로 대체 가능)
  main_photo_path TEXT, -- Trainer만 사용
  sub_photos_count INTEGER DEFAULT 0, -- Trainer만 사용
  photos_count INTEGER DEFAULT 0, -- Trainee만 사용
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 인덱스 생성
CREATE INDEX idx_profiles_user_type ON profiles(user_type);
CREATE INDEX idx_profiles_location ON profiles USING GIST (point(longitude, latitude));
```

## 2. matches 테이블

스와이프 매치 정보를 저장하는 테이블입니다.

### 컬럼 구조

```sql
CREATE TABLE matches (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  swiped_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  is_match BOOLEAN NOT NULL, -- true: 좋아요, false: 싫어요
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, swiped_user_id)
);

-- 인덱스 생성
CREATE INDEX idx_matches_user_id ON matches(user_id);
CREATE INDEX idx_matches_swiped_user_id ON matches(swiped_user_id);
```

## 3. Row Level Security (RLS) 정책

보안을 위해 RLS를 활성화하고 정책을 설정해야 합니다.

### profiles 테이블 RLS

```sql
-- RLS 활성화
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- 모든 사용자가 자신의 프로필을 읽을 수 있음
CREATE POLICY "Users can read own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = user_id);

-- 모든 사용자가 자신의 프로필을 수정할 수 있음
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = user_id);

-- 모든 사용자가 자신의 프로필을 생성할 수 있음
CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- 다른 사용자의 프로필은 읽기만 가능 (매칭을 위해)
CREATE POLICY "Users can read other profiles for matching"
  ON profiles FOR SELECT
  USING (true);

-- 공개 프로필 읽기 (로그인 없이도 접근 가능 - 공유 링크용)
CREATE POLICY "Public profiles are viewable by everyone"
  ON profiles FOR SELECT
  USING (true);
```

### matches 테이블 RLS

```sql
-- RLS 활성화
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;

-- 사용자는 자신의 매치 기록을 읽을 수 있음
CREATE POLICY "Users can read own matches"
  ON matches FOR SELECT
  USING (auth.uid() = user_id);

-- 사용자는 자신의 매치를 생성할 수 있음
CREATE POLICY "Users can insert own matches"
  ON matches FOR INSERT
  WITH CHECK (auth.uid() = user_id);
```

## 4. Storage 버킷 (선택사항)

이미지를 Supabase Storage에 저장하려면 다음 버킷을 생성하세요:

```sql
-- Storage 버킷 생성 (Supabase Dashboard에서)
-- 버킷 이름: 'user-photos'
-- Public: true
```

## 5. 초기 설정 순서

1. Supabase Dashboard에서 위의 SQL을 실행하여 테이블 생성
2. RLS 정책 적용
3. Storage 버킷 생성 (이미지 업로드 사용 시)
4. 앱에서 테스트

## 참고사항

- `profiles` 테이블의 `talents`, `interests`, `teaching_methods`는 배열 타입입니다.
- Trainee의 goals는 `profiles.talents`에 저장하고, UI에서만 'Goals'로 표기합니다.
- GPS 좌표는 `latitude`와 `longitude`로 저장됩니다.
- 이미지 경로는 현재 로컬 파일 경로로 저장되지만, 실제 운영 환경에서는 Supabase Storage URL을 사용해야 합니다.
