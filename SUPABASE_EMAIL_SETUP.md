# Supabase 이메일 인증 설정 가이드

## 문제점

현재 이메일로 **Magic Link**가 전송되고 있습니다. 이것은 Supabase의 기본 설정 때문입니다.

## 해결 방법

### 방법 1: Supabase Dashboard에서 이메일 템플릿 수정 (권장)

1. **Supabase Dashboard 접속**
   - https://supabase.com/dashboard
   - 프로젝트 선택

2. **Authentication > Email Templates 이동**
   - 좌측 메뉴에서 Authentication 클릭
   - Email Templates 탭 선택

3. **Magic Link 템플릿을 OTP 템플릿으로 변경**

   **"Confirm signup" 템플릿 수정:**
   ```
   <h2>Confirm your signup</h2>
   <p>Your verification code is: <strong>{{ .Token }}</strong></p>
   <p>Enter this code in the app to complete your signup.</p>
   ```

   또는 더 간단하게:
   ```
   <h2>인증 코드</h2>
   <p>인증 코드: <strong>{{ .Token }}</strong></p>
   <p>이 코드를 앱에 입력하세요.</p>
   ```

4. **"Magic Link" 템플릿 비활성화**
   - Magic Link 템플릿을 사용하지 않도록 설정
   - 또는 Magic Link 템플릿을 OTP 형식으로 변경

### 방법 2: Supabase Auth 설정 확인

1. **Authentication > Settings 이동**
   - "Enable email confirmations" 확인
   - "Enable email change confirmations" 확인

2. **Email Auth Provider 설정**
   - "Confirm email" 옵션이 활성화되어 있는지 확인
   - "Secure email change" 설정 확인

### 방법 3: 코드에서 명시적으로 OTP 요청

코드가 이미 OTP 방식을 사용하도록 수정되어 있습니다. 하지만 Supabase 설정이 Magic Link로 되어 있으면 여전히 링크가 올 수 있습니다.

**확인 사항:**
- Supabase Dashboard > Authentication > Email Templates
- "Confirm signup" 템플릿이 `{{ .Token }}`을 사용하는지 확인
- Magic Link 템플릿이 비활성화되어 있는지 확인

## 이메일 템플릿 예시

### OTP 방식 (현재 코드에 맞춤)

**Subject:** `Confirm your signup`

**Body (HTML):**
```html
<h2>인증 코드</h2>
<p>안녕하세요,</p>
<p>GuruTown 가입을 위한 인증 코드입니다:</p>
<p style="font-size: 24px; font-weight: bold; color: #007bff;">{{ .Token }}</p>
<p>이 코드를 앱에 입력하여 가입을 완료하세요.</p>
<p>이 코드는 1시간 동안 유효합니다.</p>
```

**Body (Plain Text):**
```
인증 코드

안녕하세요,

GuruTown 가입을 위한 인증 코드입니다:

{{ .Token }}

이 코드를 앱에 입력하여 가입을 완료하세요.
이 코드는 1시간 동안 유효합니다.
```

## 테스트 방법

1. Supabase Dashboard에서 이메일 템플릿 수정
2. 앱에서 이메일 입력 후 "인증 코드 받기" 클릭
3. 이메일 확인 - 6자리 숫자 코드가 와야 함
4. 코드를 앱에 입력하여 인증 완료

## 참고

- `{{ .Token }}`: 6자리 인증 코드
- `{{ .ConfirmationURL }}`: Magic Link URL (OTP 방식에서는 사용하지 않음)
- `{{ .Email }}`: 사용자 이메일 주소
- `{{ .SiteURL }}`: 사이트 URL

## 추가 설정

**Rate Limiting:**
- Authentication > Settings > Rate Limits
- 이메일 전송 제한 설정 가능

**SMTP 설정 (선택사항):**
- Authentication > Settings > SMTP Settings
- 커스텀 SMTP 서버 사용 가능 (기본적으로 Supabase SMTP 사용)
