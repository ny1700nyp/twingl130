-- ============================================
-- matches 테이블 재생성 SQL
-- ============================================
-- 주의: 이 스크립트는 기존 matches 테이블과 모든 데이터를 삭제합니다.
-- Supabase Dashboard > SQL Editor에서 실행하세요.
-- ============================================

-- 1. 기존 RLS 정책 삭제 (있는 경우)
DROP POLICY IF EXISTS "Users can read own matches" ON matches;
DROP POLICY IF EXISTS "Users can insert own matches" ON matches;
DROP POLICY IF EXISTS "Users can update own matches" ON matches;
DROP POLICY IF EXISTS "Users can delete own matches" ON matches;

-- 2. 기존 인덱스 삭제 (있는 경우)
DROP INDEX IF EXISTS idx_matches_user_id;
DROP INDEX IF EXISTS idx_matches_swiped_user_id;

-- 3. 기존 테이블 삭제 (CASCADE로 외래키 제약조건도 함께 삭제)
DROP TABLE IF EXISTS matches CASCADE;

-- 4. matches 테이블 재생성
CREATE TABLE matches (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  swiped_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  is_match BOOLEAN NOT NULL, -- true: 좋아요, false: 싫어요
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, swiped_user_id)
);

-- 5. 인덱스 생성
CREATE INDEX idx_matches_user_id ON matches(user_id);
CREATE INDEX idx_matches_swiped_user_id ON matches(swiped_user_id);

-- 6. RLS 활성화
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;

-- 7. RLS 정책 생성
-- 사용자는 자신의 매치 기록을 읽을 수 있음
CREATE POLICY "Users can read own matches"
  ON matches FOR SELECT
  USING (auth.uid() = user_id);

-- 사용자는 자신의 매치를 생성할 수 있음
CREATE POLICY "Users can insert own matches"
  ON matches FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- 사용자는 자신의 매치를 업데이트할 수 있음 (upsert를 위해 필요)
CREATE POLICY "Users can update own matches"
  ON matches FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 사용자는 자신의 매치를 삭제할 수 있음 (즐겨찾기 제거)
CREATE POLICY "Users can delete own matches"
  ON matches FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================
-- 완료!
-- ============================================
-- 이제 앱에서 다시 좋아요를 보내면 정상적으로 저장됩니다.
-- ============================================
