-- 실시간 채팅을 위해 messages 테이블을 Realtime publication에 추가합니다.
-- Supabase 대시보드: Database > Publications > supabase_realtime 에서
-- messages 테이블을 켜도 되고, 아래 SQL을 SQL Editor에서 실행해도 됩니다.

ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
