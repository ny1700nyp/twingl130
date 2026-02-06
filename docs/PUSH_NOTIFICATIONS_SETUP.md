# 백그라운드 푸시 알림 설정 가이드

앱이 백그라운드 또는 종료 상태일 때도 채팅 메시지 알림을 받으려면 아래 순서대로 설정하세요.

---

## Step 1: Firebase 프로젝트 생성

1. [Firebase Console](https://console.firebase.google.com/) 접속
2. **프로젝트 추가** → 프로젝트 이름 입력 (예: Twingl)
3. Google Analytics 사용 여부 선택 (선택 사항)
4. 프로젝트 생성 완료

---

## Step 2: Android 앱 등록

1. Firebase 프로젝트 → **프로젝트 설정** (톱니바퀴)
2. **앱 추가** → Android 선택
3. **Android 패키지 이름** 입력: `com.example.flutter_application_1` (또는 `android/app/build.gradle`의 `applicationId` 확인)
4. 앱 닉네임, SHA-1 (선택) 입력 후 **앱 등록**
5. **google-services.json** 다운로드
6. `google-services.json`을 `android/app/` 폴더에 복사

### android/build.gradle 수정

`android/build.gradle` (프로젝트 레벨)에 다음이 있는지 확인:

```gradle
buildscript {
  dependencies {
    classpath 'com.google.gms:google-services:4.4.0'
  }
}
```

`android/app/build.gradle` (앱 레벨) 맨 아래에 추가:

```gradle
apply plugin: 'com.google.gms.google-services'
```

---

## Step 3: iOS 앱 등록

1. Firebase 프로젝트 → **프로젝트 설정** → **앱 추가** → iOS 선택
2. **번들 ID** 입력: `com.example.flutterApplication1` (또는 `ios/Runner/Info.plist` / Xcode에서 확인)
3. **앱 등록**
4. **GoogleService-Info.plist** 다운로드
5. `GoogleService-Info.plist`를 `ios/Runner/` 폴더에 복사
6. Xcode에서 `ios/Runner.xcworkspace` 열기 → Runner 프로젝트에 `GoogleService-Info.plist` 추가 (파일 드래그)

### iOS 푸시 권한

`ios/Runner/AppDelegate.swift` (또는 AppDelegate.m)에서 푸시 권한 요청 코드가 있는지 확인. `firebase_messaging` 플러그인이 자동으로 처리합니다.

---

## Step 4: Firebase 서비스 계정 키 발급

1. Firebase Console → **프로젝트 설정** → **서비스 계정** 탭
2. **새 비공개 키 생성** 클릭 → JSON 파일 다운로드
3. JSON 파일을 열어 다음 값 확인:
   - `project_id`
   - `client_email`
   - `private_key` (전체 문자열, `\n` 포함)

---

## Step 5: Supabase 설정

### 5-1. 마이그레이션 실행

```bash
supabase db push
# 또는 Supabase Dashboard → SQL Editor에서
# supabase/migrations/20250204120000_user_fcm_tokens.sql 내용 실행
```

### 5-2. Edge Function 배포 및 시크릿 설정

```bash
cd c:\coding\flutter\test\flutter_application_1

# 프로젝트 링크 (최초 1회)
supabase link --project-ref oibboowecbxvjmookwtd

# FCM 시크릿 설정 (.env.local 또는 직접 입력)
# .env.local 예시:
# FCM_PROJECT_ID=your-firebase-project-id
# FCM_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com
# FCM_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIE...\n-----END PRIVATE KEY-----\n"

supabase secrets set FCM_PROJECT_ID=your-project-id
supabase secrets set FCM_CLIENT_EMAIL=your-client-email
supabase secrets set FCM_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"

# Edge Function 배포
supabase functions deploy send-push-on-message
```

### 5-3. Database Webhook 생성

1. [Supabase Dashboard](https://supabase.com/dashboard) → 프로젝트 선택
2. **Database** → **Webhooks** → **Create a new hook**
3. 설정:
   - **Name**: `send-push-on-message`
   - **Table**: `messages`
   - **Events**: `Insert` 체크
   - **Type**: Supabase Edge Functions
   - **Function**: `send-push-on-message`
   - **HTTP Headers**: "Add auth header with service key" 체크
4. **Create webhook** 클릭

---

## Step 6: Flutter 패키지 설치

```bash
flutter pub get
```

---

## Step 7: 동작 확인

1. 앱 실행 → 로그인
2. More → Notifications → Chat messages ON 확인
3. 앱을 **백그라운드로 보내거나 종료**
4. 다른 계정으로 채팅 메시지 전송
5. 푸시 알림 수신 확인

---

## 트러블슈팅

| 증상 | 확인 사항 |
|------|-----------|
| 앱 실행 시 Firebase init 에러 | `google-services.json`, `GoogleService-Info.plist` 위치 및 내용 확인 |
| 토큰이 DB에 저장되지 않음 | `user_fcm_tokens` 테이블 RLS 정책, 로그인 여부 확인 |
| 푸시가 오지 않음 | Database Webhook 생성 여부, Edge Function 로그, FCM 시크릿 설정 확인 |
| iOS에서 알림 안 옴 | APNs 인증서/키 설정 (Firebase Console → 프로젝트 설정 → Cloud Messaging) |

### Edge Function 로그 확인

```bash
supabase functions logs send-push-on-message
```
