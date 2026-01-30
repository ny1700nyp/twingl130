-- Calendar Events 테이블 생성
-- Chat에서 추가한 캘린더 이벤트를 저장하는 테이블

CREATE TABLE IF NOT EXISTS public.calendar_events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    conversation_id UUID REFERENCES public.conversations(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT valid_time_range CHECK (end_time > start_time)
);

-- 인덱스 생성 (조회 성능 향상)
CREATE INDEX IF NOT EXISTS idx_calendar_events_user_id ON public.calendar_events(user_id);
CREATE INDEX IF NOT EXISTS idx_calendar_events_start_time ON public.calendar_events(start_time);
CREATE INDEX IF NOT EXISTS idx_calendar_events_user_start ON public.calendar_events(user_id, start_time);

-- RLS (Row Level Security) 활성화
ALTER TABLE public.calendar_events ENABLE ROW LEVEL SECURITY;

-- RLS 정책: 사용자는 자신의 이벤트만 조회 가능
CREATE POLICY "Users can view their own calendar events"
    ON public.calendar_events
    FOR SELECT
    USING (auth.uid() = user_id);

-- RLS 정책: 사용자는 자신의 이벤트만 생성 가능
CREATE POLICY "Users can insert their own calendar events"
    ON public.calendar_events
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- RLS 정책: 사용자는 자신의 이벤트만 수정 가능
CREATE POLICY "Users can update their own calendar events"
    ON public.calendar_events
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- RLS 정책: 사용자는 자신의 이벤트만 삭제 가능
CREATE POLICY "Users can delete their own calendar events"
    ON public.calendar_events
    FOR DELETE
    USING (auth.uid() = user_id);

-- updated_at 자동 업데이트 트리거 함수
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- updated_at 트리거 생성
CREATE TRIGGER update_calendar_events_updated_at
    BEFORE UPDATE ON public.calendar_events
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
