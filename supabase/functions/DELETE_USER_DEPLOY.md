# Delete User Edge Function – 배포 방법

설정의 "Delete my account"가 동작하려면 Supabase Edge Function `delete-user`를 배포해야 합니다.

## 1. Supabase CLI 설치

- https://supabase.com/docs/guides/cli

## 2. 로그인 및 프로젝트 연결

```bash
supabase login
supabase link --project-ref oibboowecbxvjmookwtd
```

(프로젝트 ref는 Supabase 대시보드 URL에서 확인 가능)

## 3. Edge Function 배포

```bash
supabase functions deploy delete-user
```

배포 시 `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`는 자동으로 주입됩니다.

## 4. 동작 방식

- 앱에서 "Delete my account" → Yes 선택 시, 현재 세션의 JWT로 `delete-user` 함수를 호출합니다.
- 함수는 JWT로 사용자를 검증한 뒤, **service role**로 Supabase Auth에서 해당 사용자를 삭제합니다.
- 이메일·Google 등 모든 로그인 방식에 동일하게 적용됩니다.
