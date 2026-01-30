# Supabase 전화번호 인증 (SMS) 설정 가이드

## 문제점

Supabase의 전화번호 인증은 기본적으로 **SMS 제공업체 설정이 필요**합니다. 무료 플랜에서는 제한적이거나 추가 설정이 필요할 수 있습니다.

## 해결 방법

### 방법 1: Supabase Dashboard에서 SMS 제공업체 설정

1. **Supabase Dashboard 접속**
   - https://supabase.com/dashboard 접속
   - 프로젝트 선택

2. **Authentication > Providers 이동**
   - 좌측 메뉴에서 Authentication 클릭
   - Providers 탭 선택

3. **Phone Provider 활성화**
   - Phone 제공업체를 찾아 활성화
   - SMS 제공업체 선택 (Twilio 권장)

4. **Twilio 설정** (권장)
   - Twilio 계정 생성: https://www.twilio.com/
   - Twilio에서 Phone Number 구매 또는 Trial 번호 사용
   - Supabase Dashboard에 Twilio 계정 정보 입력:
     - Account SID
     - Auth Token
     - Phone Number (발신 번호)

### 방법 2: 개발/테스트용 이메일 인증 사용

프로덕션 전 단계에서는 이메일 인증을 사용하는 것이 더 간단합니다.

#### 이메일 인증으로 변경하는 방법:

1. **Supabase Dashboard에서 이메일 인증 활성화**
   - Authentication > Providers > Email 활성화

2. **코드 수정**
   - `lib/screens/login_screen.dart`를 이메일 인증으로 변경
   - 또는 이메일/전화번호 선택 옵션 추가

### 방법 3: 개발 환경에서 테스트 코드 사용

개발 중에는 실제 SMS 없이 테스트할 수 있는 방법:

1. **Supabase Dashboard > Authentication > Settings**
   - "Enable phone confirmations" 활성화
   - 개발 모드에서는 테스트 전화번호 사용 가능

2. **테스트 전화번호**
   - Supabase는 특정 테스트 번호에서 자동으로 인증 코드를 반환합니다
   - 예: `+15005550006` (Twilio 테스트 번호)

## 전화번호 형식

### 올바른 형식:
- 미국: `+1XXXXXXXXXX` (예: +12125551234)
- 한국: `+82XXXXXXXXXX` (예: +821012345678)
- 국제 형식: `+[국가코드][전화번호]` (공백, 하이픈 제거)

### 잘못된 형식:
- `010-1234-5678` (국가코드 없음)
- `12125551234` (+ 없음)
- `(212) 555-1234` (특수문자 포함)

## 현재 코드의 개선 사항

코드에 다음이 추가되었습니다:

1. **전화번호 자동 포맷팅**
   - 10자리 미국 번호 → `+1` 자동 추가
   - 11자리 (1로 시작) → `+` 자동 추가

2. **에러 메시지 개선**
   - SMS 설정 오류 감지
   - 전화번호 형식 오류 감지
   - Rate limit 오류 감지

3. **입력 검증 강화**
   - 전화번호 형식 검증
   - 도움말 텍스트 추가

## 즉시 테스트하는 방법

1. **Twilio Trial 계정 사용** (무료)
   - https://www.twilio.com/try-twilio
   - Trial 번호로 제한적이지만 테스트 가능

2. **Supabase의 테스트 번호 사용**
   - 개발 환경에서만 작동
   - `+15005550006` 같은 Twilio 테스트 번호 사용

3. **이메일 인증으로 전환** (가장 빠름)
   - Supabase Dashboard에서 이메일 인증 활성화
   - 코드를 이메일 인증으로 변경

## 참고 링크

- Supabase Phone Auth 문서: https://supabase.com/docs/guides/auth/phone-login
- Twilio 설정 가이드: https://supabase.com/docs/guides/auth/phone-login/twilio
- Supabase Auth 설정: https://supabase.com/dashboard/project/_/auth/providers
