# Supabase 소셜 로그인 설정 가이드

## 구현 완료

이메일 인증을 제거하고 다음 소셜 로그인을 구현했습니다:
- Google
- 카카오 (Kakao)
- Facebook
- Apple

## Supabase Dashboard 설정 필요

각 소셜 로그인 제공업체를 Supabase Dashboard에서 설정해야 합니다.

### 1. Supabase Dashboard 접속
- https://supabase.com/dashboard
- 프로젝트 선택

### 2. Authentication > Providers 이동
- 좌측 메뉴에서 **Authentication** 클릭
- **Providers** 탭 선택

### 3. 각 제공업체별 설정

#### Google 설정

1. **Google Provider 활성화**
   - Google 토글을 ON으로 설정

2. **Google Cloud Console 설정**
   - https://console.cloud.google.com/ 접속
   - 새 프로젝트 생성 또는 기존 프로젝트 선택
   - **APIs & Services > Credentials** 이동
   - **Create Credentials > OAuth client ID** 선택
   - Application type: **Web application**
   - Authorized redirect URIs에 추가:
     ```
     https://oibboowecbxvjmookwtd.supabase.co/auth/v1/callback
     ```
   - Client ID와 Client Secret 복사

3. **Supabase에 입력**
   - Client ID (Client Secret) 입력
   - Save 클릭

#### 카카오 설정

1. **카카오 Developer 설정**
   - https://developers.kakao.com/ 접속
   - 내 애플리케이션 생성
   - 플랫폼 설정:
     - Web 플랫폼 추가
     - 사이트 도메인 등록
   - Redirect URI 등록:
     ```
     https://oibboowecbxvjmookwtd.supabase.co/auth/v1/callback
     ```
   - REST API 키 확인

2. **Supabase에 입력**
   - Kakao Provider 활성화
   - Client ID (REST API 키) 입력
   - Client Secret 입력 (카카오 개발자 콘솔에서 발급)
   - Save 클릭

#### Facebook 설정

1. **Facebook Developer 설정**
   - https://developers.facebook.com/ 접속
   - 앱 생성
   - Facebook Login 제품 추가
   - Settings > Basic에서:
     - App ID 확인
     - App Secret 확인
   - Valid OAuth Redirect URIs에 추가:
     ```
     https://oibboowecbxvjmookwtd.supabase.co/auth/v1/callback
     ```

2. **Supabase에 입력**
   - Facebook Provider 활성화
   - Client ID (App ID) 입력
   - Client Secret (App Secret) 입력
   - Save 클릭

#### Apple 설정

1. **Apple Developer 설정**
   - https://developer.apple.com/ 접속
   - Certificates, Identifiers & Profiles 이동
   - Services ID 생성
   - Sign in with Apple 활성화
   - Return URLs 등록:
     ```
     https://oibboowecbxvjmookwtd.supabase.co/auth/v1/callback
     ```
   - Key 생성 (Sign in with Apple용)

2. **Supabase에 입력**
   - Apple Provider 활성화
   - Services ID 입력
   - Key ID 입력
   - Private Key 입력
   - Team ID 입력
   - Save 클릭

## Redirect URL 설정

모든 제공업체에서 다음 Redirect URL을 등록해야 합니다:

```
https://oibboowecbxvjmookwtd.supabase.co/auth/v1/callback
```

## 앱 설정 (Deep Link)

### Android 설정

`android/app/src/main/AndroidManifest.xml`에 추가:

```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    android:launchMode="singleTop"
    android:theme="@style/LaunchTheme">
    <!-- ... existing code ... -->
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data
            android:scheme="io.supabase.gurutown"
            android:host="login-callback" />
    </intent-filter>
</activity>
```

### iOS 설정

`ios/Runner/Info.plist`에 추가:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>io.supabase.gurutown</string>
        </array>
    </dict>
</array>
```

## 테스트 방법

1. Supabase Dashboard에서 각 제공업체 설정 완료
2. 앱 실행
3. 소셜 로그인 버튼 클릭
4. 브라우저에서 로그인 진행
5. 앱으로 자동 리다이렉트되어 로그인 완료

## 참고 링크

- Supabase OAuth 가이드: https://supabase.com/docs/guides/auth/social-login
- Google OAuth 설정: https://supabase.com/docs/guides/auth/social-login/auth-google
- 카카오 OAuth 설정: https://supabase.com/docs/guides/auth/social-login/auth-kakao
- Facebook OAuth 설정: https://supabase.com/docs/guides/auth/social-login/auth-facebook
- Apple OAuth 설정: https://supabase.com/docs/guides/auth/social-login/auth-apple
