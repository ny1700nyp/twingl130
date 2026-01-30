# Android & iOS 빌드 가이드

이 문서는 GuruTown 앱을 Android와 iOS로 빌드하는 방법을 설명합니다.

## 사전 요구사항

### 공통
- Flutter SDK 설치 (최신 안정 버전 권장)
- Git 설치

### Android 빌드
- Android Studio 설치
- Android SDK 설치 (API 21 이상)
- Java JDK 17 설치
- Android 기기 또는 에뮬레이터

### iOS 빌드 (macOS만 가능)
- macOS 운영체제
- Xcode 설치 (최신 버전 권장)
- CocoaPods 설치: `sudo gem install cocoapods`
- Apple Developer 계정 (실제 기기 테스트용)
- iOS 기기 또는 시뮬레이터

## 1. 프로젝트 설정 확인

### 의존성 설치
```bash
flutter pub get
```

### Flutter Doctor 확인
```bash
flutter doctor
```
모든 항목이 체크되어 있는지 확인하세요.

## 2. Android 빌드

### 2.1 권한 확인
`android/app/src/main/AndroidManifest.xml`에 다음 권한이 추가되어 있는지 확인:
- 위치 권한 (ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION)
- 인터넷 권한 (INTERNET)
- 카메라 권한 (CAMERA)
- 갤러리 권한 (READ_MEDIA_IMAGES, READ_EXTERNAL_STORAGE)

### 2.2 앱 아이콘 및 스플래시 생성
```bash
# 앱 아이콘 생성
dart run flutter_launcher_icons

# 스플래시 스크린 생성
dart run flutter_native_splash:create
```

### 2.3 디버그 빌드
```bash
# APK 파일 생성
flutter build apk --debug

# 또는 기기에 직접 설치
flutter run
```

### 2.4 릴리즈 빌드
```bash
# APK 파일 생성
flutter build apk --release

# 또는 App Bundle 생성 (Google Play Store용)
flutter build appbundle --release
```

빌드된 파일 위치:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- App Bundle: `build/app/outputs/bundle/release/app-release.aab`

### 2.5 서명 설정 (릴리즈 빌드)
릴리즈 빌드를 위해 서명 키를 생성해야 합니다:

```bash
# 키스토어 생성 (최초 1회만)
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# key.properties 파일 생성
# android/key.properties 파일을 생성하고 다음 내용 추가:
# storePassword=<위에서 입력한 비밀번호>
# keyPassword=<위에서 입력한 비밀번호>
# keyAlias=upload
# storeFile=<키스토어 파일 경로>
```

`android/app/build.gradle.kts`에 서명 설정 추가 필요 (필요시).

## 3. iOS 빌드

### 3.1 CocoaPods 의존성 설치
```bash
cd ios
pod install
cd ..
```

### 3.2 권한 확인
`ios/Runner/Info.plist`에 다음 권한 설명이 추가되어 있는지 확인:
- NSLocationWhenInUseUsageDescription
- NSCameraUsageDescription
- NSPhotoLibraryUsageDescription

### 3.3 Xcode에서 프로젝트 열기
```bash
open ios/Runner.xcworkspace
```

또는:
```bash
open ios/Runner.xcodeproj
```

### 3.4 Xcode 설정
1. **Signing & Capabilities** 설정:
   - Team 선택 (Apple Developer 계정)
   - Bundle Identifier 확인 (고유한 값으로 변경 권장)

2. **Deployment Target** 확인:
   - 최소 iOS 버전 확인 (일반적으로 iOS 12.0 이상)

### 3.5 디버그 빌드
```bash
# 시뮬레이터에서 실행
flutter run

# 또는 특정 시뮬레이터 지정
flutter run -d "iPhone 15 Pro"
```

### 3.6 릴리즈 빌드
```bash
# IPA 파일 생성 (실제 기기용)
flutter build ios --release

# 또는 Xcode에서 직접 빌드:
# Product > Archive
```

### 3.7 실제 기기에 설치
1. Xcode에서 기기 선택
2. Product > Run (또는 Cmd+R)
3. 기기에서 "신뢰" 설정 필요 (설정 > 일반 > VPN 및 기기 관리)

## 4. 테스트 체크리스트

### 필수 기능 테스트
- [ ] 로그인/회원가입
- [ ] 위치 권한 요청 및 GPS 기능
- [ ] 프로필 사진 업로드 (카메라/갤러리)
- [ ] 카드 스와이프 기능
- [ ] 좋아요/싫어요 기능
- [ ] 프로필 상세 보기
- [ ] 좋아요 목록 보기
- [ ] 다크모드/라이트모드 전환

### 권한 테스트
- [ ] 위치 권한 거부 시 동작
- [ ] 카메라 권한 거부 시 동작
- [ ] 갤러리 권한 거부 시 동작

## 5. 문제 해결

### Android
- **빌드 오류**: `flutter clean` 후 다시 빌드
- **권한 오류**: AndroidManifest.xml 확인
- **Gradle 오류**: `cd android && ./gradlew clean`

### iOS
- **Pod 설치 오류**: `cd ios && pod deintegrate && pod install`
- **서명 오류**: Xcode에서 Signing & Capabilities 확인
- **빌드 오류**: `flutter clean` 후 다시 빌드

## 6. 추가 리소스

- [Flutter 공식 문서](https://flutter.dev/docs)
- [Android 빌드 가이드](https://flutter.dev/docs/deployment/android)
- [iOS 빌드 가이드](https://flutter.dev/docs/deployment/ios)
