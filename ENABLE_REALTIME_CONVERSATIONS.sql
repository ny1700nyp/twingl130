-- 대시보드에서 실시간으로 마지막 메시지가 반영되도록
-- conversations 테이블을 Realtime publication에 추가합니다.
-- Supabase 대시보드: Database > Publications > supabase_realtime 에서
-- conversations 테이블을 켜도 되고, 아래 SQL을 SQL Editor에서 실행해도 됩니다.

ALTER PUBLICATION supabase_realtime ADD TABLE public.conversations;
