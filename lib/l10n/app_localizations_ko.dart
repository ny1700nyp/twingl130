// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get hello => '안녕하세요 세계';

  @override
  String get notSignedIn => '로그인되어 있지 않습니다';

  @override
  String accountDeletionFailed(int statusCode) {
    return '계정 삭제에 실패했습니다($statusCode)';
  }

  @override
  String get noAuthenticatedUserFound => '인증된 사용자를 찾을 수 없습니다';

  @override
  String get noRowsDeletedCheckMatchesRls =>
      '삭제된 행이 없습니다. 매칭 RLS DELETE 정책을 확인하세요.';

  @override
  String get userNotAuthenticated => '사용자가 인증되지 않았습니다';

  @override
  String requestMessage(String skill, String method) {
    return '요청: $skill($method)';
  }

  @override
  String get schedulePromptMessage => '일정, 장소, 비용을 이야기하고 시작해 보세요.';

  @override
  String get unknownName => '알 수 없음';

  @override
  String get systemDefault => '시스템 기본값';

  @override
  String get languageChinese => '中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageSpanish => 'Español';

  @override
  String get support => '지원';

  @override
  String get verification => '인증';

  @override
  String get language => '언어';

  @override
  String get help => '도움말';

  @override
  String get terms => '약관';

  @override
  String get invalidProfileLink => '유효하지 않은 프로필 링크입니다';

  @override
  String anonymousLoginFailed(String error) {
    return '익명 로그인에 실패했습니다: $error';
  }

  @override
  String get signInWithSocialLogin => '소셜 로그인으로 시작하기';

  @override
  String get signInWithGoogle => 'Google로 로그인';

  @override
  String get leaveTwingl => 'Twingl 탈퇴하기';

  @override
  String get leaveTwinglDialogMessage =>
      '좋아요 목록, 차단 목록, 채팅 기록이 삭제되고 프로필이 제거됩니다. 계정은 유지됩니다.';

  @override
  String get no => '아니오';

  @override
  String get yes => '예';

  @override
  String failedToLeaveTwingl(String error) {
    return 'Twingl 탈퇴에 실패했습니다: $error';
  }

  @override
  String get generalSettings => '일반 설정';

  @override
  String get clearLikedBlockedChatHistory => '좋아요, 차단, 채팅 기록 삭제';

  @override
  String get requestDeclinedMessage => '요청이 거절되었습니다. 원하실 때 새 요청을 보내 주세요.';

  @override
  String get considerAnotherTutor => '다른 튜터를 찾아 보시는 것도 좋습니다.';

  @override
  String get paymentIntro =>
      'Twingl은 주변 사람과 연결해 드립니다. 결제는 직접 하시며, 서비스는 무료이고 수수료 100%가 튜터에게 갑니다.';

  @override
  String get paymentAgreeMethod => '서로 편한 결제 방법을 정해 보세요. 예:';

  @override
  String get paymentVenmoZellePaypal => 'Venmo / Zelle / PayPal';

  @override
  String get paymentCash => '현금';

  @override
  String get paymentCoffeeOrMeal => '커피 또는 식사(가벼운 수업용)';

  @override
  String get paymentNoteSafety => '안전을 위해 대면 만남 후 결제를 권장합니다.';

  @override
  String get paymentTipOnline => '온라인 수업은 PayPal 구매자 보호나 50/50 결제도 고려해 보세요.';

  @override
  String get unread => '읽지 않음';

  @override
  String get howDoIPayForLessons => '수업료는 어떻게 결제하나요?';

  @override
  String get chatOnlyAfterAccept =>
      '채팅은 상대가 첫 수업 요청을 수락한 후에 이용할 수 있습니다. 잠시만 기다려 주세요.';

  @override
  String get declineReason => '거절 사유';

  @override
  String get whyDecliningHint => '왜 거절하시나요?';

  @override
  String get cancel => '취소';

  @override
  String get delete => '삭제';

  @override
  String get block => '차단';

  @override
  String get removeFromFavoriteTitle => '좋아요에서 제거';

  @override
  String get removeFromFavoriteConfirmMessage => '이 사용자를 좋아요 목록에서 제거할까요?';

  @override
  String get blockUserConfirmMessage => '이 사용자를 차단할까요? 레슨 요청을 더 이상 받지 않습니다.';

  @override
  String get send => '보내기';

  @override
  String get declined => '거절됨';

  @override
  String failedToDecline(String error) {
    return '거절 전송에 실패했습니다: $error';
  }

  @override
  String get decline => '거절';

  @override
  String get accept => '수락';

  @override
  String get request => '요청';

  @override
  String failedToLoadProfile(String error) {
    return '프로필을 불러오지 못했습니다: $error';
  }

  @override
  String get profileNotFound => '프로필을 찾을 수 없습니다';

  @override
  String get addedToLiked => '좋아요에 추가됨';

  @override
  String get waitingForAccept => '수락 대기 중';

  @override
  String get declinedStatus => '거절됨';

  @override
  String get messageHint => '메시지…';

  @override
  String get scheduling => '일정 잡기';

  @override
  String get locationLabel => '장소';

  @override
  String get sendProposal => '제안 보내기';

  @override
  String get acceptedChatNow => '수락되었습니다. 이제 채팅할 수 있어요.';

  @override
  String failedToAccept(String error) {
    return '수락에 실패했습니다: $error';
  }

  @override
  String failedToSendProposal(String error) {
    return '제안 보내기에 실패했습니다: $error';
  }

  @override
  String failedToSend(String error) {
    return '보내기에 실패했습니다: $error';
  }

  @override
  String get gotIt => '알겠어요';

  @override
  String get more => '더보기';

  @override
  String get aboutUs => '소개';

  @override
  String get paymentGuide => '결제 안내';

  @override
  String get offer => '제안';

  @override
  String get usefulLinks => '유용한 링크';

  @override
  String get lessonSpaceFinder => '수업 공간 찾기';

  @override
  String get notifications => '알림';

  @override
  String get account => '계정';

  @override
  String get whatIsTwingl => 'Twingl이란?';

  @override
  String get letterFromTwingl => 'Twingl의 메시지';

  @override
  String get leaveTwinglConfirm => 'Twingl을 탈퇴하시겠어요?';

  @override
  String get leaveTwinglDialogContentFull =>
      '계정은 유지되지만:\n\n• 좋아요·차단 목록이 삭제됩니다.\n• 채팅 기록이 삭제됩니다.\n• 프로필이 삭제됩니다.\n\nTwingl을 탈퇴하시겠어요?';

  @override
  String leaveTwinglError(String error) {
    return 'Twingl 탈퇴: $error';
  }

  @override
  String get editMyProfile => '내 프로필 수정';

  @override
  String get editProfile => '프로필 수정';

  @override
  String get onboardingTitle => '온보딩';

  @override
  String get addingMoreInfo => '정보 추가하기';

  @override
  String get deleteUser => '사용자 삭제';

  @override
  String get removeFromLikedList => '좋아요 목록에서 사용자 제거';

  @override
  String get blockUser => '사용자 차단';

  @override
  String get blockUserDescription => '차단한 사용자는 메시지를 보낼 수 없습니다';

  @override
  String get unblockUser => '차단 해제';

  @override
  String get unblockUserDescription => '차단을 해제하면 다시 메시지를 보낼 수 있습니다';

  @override
  String get logOut => '로그아웃';

  @override
  String get chatMessages => '채팅 메시지';

  @override
  String get chat => '채팅';

  @override
  String get notificationsOnOff => '새 메시지 알림 받기';

  @override
  String get notificationsOff => '알림 끔';

  @override
  String get couldNotOpenLink => '링크를 열 수 없습니다.';

  @override
  String get publicLibraries => '공공 도서관';

  @override
  String get schoolFacilities => '학교 시설';

  @override
  String get creativeStudios => '크리에이티브 스튜디오';

  @override
  String get meetingRooms => '회의실';

  @override
  String get theLearner => '학습자';

  @override
  String get theLearnerDescription =>
      '성장에 집중하세요. 목표를 정하고 가까운 곳이나 어디서든 맞는 멘토를 찾아 보세요.';

  @override
  String get theGuide => '가이드';

  @override
  String get theGuideDescription =>
      '당신의 전문성을 나누세요. 다른 사람의 목표를 돕고 당신의 재능을 가치로 만드세요.';

  @override
  String get theConnector => '커넥터';

  @override
  String get theConnectorDescription =>
      'Twingl의 모든 것: 아는 것을 가르치고 좋아하는 것을 배우세요. 커뮤니티의 중심이에요.';

  @override
  String get becomeStudentToo => '학습자도 되기';

  @override
  String get becomeTutorToo => '튜터도 되기';

  @override
  String get becomeStudentTooSubtext =>
      '좋은 선생님은 배움을 멈추지 않아요. 새로운 목표를 이루며 시야를 넓혀 보세요.';

  @override
  String get becomeTutorTooSubtext =>
      '가르치는 것이 실력을 키우는 가장 좋은 방법이에요. 이웃과 재능을 나눠 보세요.';

  @override
  String get unlockStudentMode => '학습자 모드 사용하기';

  @override
  String get unlockTutorMode => '튜터 모드 사용하기';

  @override
  String get twinerBadgeMessage => 'Twiner 배지를 받게 됩니다.';

  @override
  String get starting => '시작 중…';

  @override
  String get meetTutorsInArea => '내 주변 튜터 만나기';

  @override
  String get perfectTutorsAnywhere => '어디서나 맞는 튜터';

  @override
  String get fellowTutorsInArea => '내 주변 튜터';

  @override
  String get studentCandidatesInArea => '내 주변 학습자';

  @override
  String get noTutorsYet =>
      '아직 튜터가 없어요. 내 주변 튜터 만나기나 어디서나 맞는 튜터에서 좋아요를 눌러 보세요.';

  @override
  String get noStudentsYet => '아직 학습자가 없어요. 내 주변 학습자나 채팅에서 좋아요를 눌러 보세요.';

  @override
  String get noFellowsYet => '아직 내 주변 튜터가 없어요. 내 주변 튜터에서 좋아요를 눌러 보세요.';

  @override
  String get noMatchingTalentsFound => '매칭되는 인재가 없습니다.';

  @override
  String get learnShareConnect => '배우고, 나누고, 연결하세요.';

  @override
  String get student => '학습자';

  @override
  String get tutor => '튜터';

  @override
  String get twiner => 'Twiner';

  @override
  String get twinglIdentity => 'Twingl 정체성';

  @override
  String get leaveTwinglSubtitle => '좋아요, 차단, 채팅 기록 삭제';

  @override
  String failedToStartConversion(String error) {
    return '전환을 시작하지 못했습니다: $error';
  }

  @override
  String get man => '남성';

  @override
  String get woman => '여성';

  @override
  String get nonBinary => '논바이너리';

  @override
  String get preferNotToSay => '말하지 않기';

  @override
  String get share => '공유';

  @override
  String get copyLink => '링크 복사';

  @override
  String get iCanTeach => '가르칠 수 있어요';

  @override
  String get iWantToLearn => '배우고 싶어요';

  @override
  String get tutoringRate => '수업료';

  @override
  String get superClose => '아주 가까움';

  @override
  String kmAway(int km) {
    return '$km km';
  }

  @override
  String get onlineOnsite => '온라인·대면';

  @override
  String get online => '온라인';

  @override
  String get onsite => '대면';

  @override
  String get noMoreMatches => '더 이상 매칭이 없어요';

  @override
  String get noMoreNearbyResults => '근처에 더 이상 결과가 없어요';

  @override
  String get noNearbyTalentFound => '근처에서 인재를 찾지 못했어요.';

  @override
  String get tapRefreshToFindMore => '새로고침해서 더 많은 인재를 찾아 보세요.';

  @override
  String get tapRefreshToSearchAgain => '새로고침해서 다시 검색하세요.';

  @override
  String get refresh => '새로고침';

  @override
  String failedToSave(String error) {
    return '저장에 실패했습니다: $error';
  }

  @override
  String get profileDetails => '프로필';

  @override
  String get aboutMe => '소개';

  @override
  String get aboutTheLesson => '수업 소개';

  @override
  String get lessonLocation => '수업 장소';

  @override
  String lessonFeePerHour(String amount) {
    return '수업료: $amount/시간';
  }

  @override
  String get parentParticipationWelcomed => '보호자 동석 환영';

  @override
  String get parentParticipationNotSpecified => '보호자 동석 미정';

  @override
  String get unableToGenerateProfileLink => '프로필 링크를 만들 수 없습니다.';

  @override
  String get profileLinkCopiedToClipboard => '링크가 클립보드에 복사되었습니다!';

  @override
  String failedToShare(String error) {
    return '공유에 실패했습니다: $error';
  }

  @override
  String get unableToSendRequest => '요청을 보낼 수 없습니다.';

  @override
  String get sent => '전송됨';

  @override
  String failedToSendRequest(String error) {
    return '요청 전송에 실패했습니다: $error';
  }

  @override
  String get sendRequest => '요청 보내기';

  @override
  String declinedWithReason(String reason) {
    return '거절됨: $reason';
  }

  @override
  String get addToCalendar => '캘린더에 추가 ';

  @override
  String get invalidDateInProposal => '이 제안의 날짜가 잘못되었습니다';

  @override
  String get addedToCalendar => '캘린더에 추가됨';

  @override
  String failedToAddToCalendar(String error) {
    return '캘린더에 추가하지 못했습니다: $error';
  }

  @override
  String get locationHint => '예: Santa Teresa Library, Zoom';

  @override
  String get tabTutors => '튜터';

  @override
  String get tabStudents => '학습자';

  @override
  String get tabFellows => '주변 튜터';

  @override
  String get likedSectionTitle => '좋아요';

  @override
  String get myDetails => '내 정보';

  @override
  String get myActivityStats => '내 활동 통계';

  @override
  String get statsViews => '조회';

  @override
  String get statsLiked => '좋아요';

  @override
  String get statsRequests => '요청';

  @override
  String get statsRequesteds => '요청함';

  @override
  String get requestTraining => '수업 요청';

  @override
  String get chatHistory => '채팅 기록';

  @override
  String get selectSkillAndMethod => '배우고 싶은 스킬과 수업 방식을 선택하세요';

  @override
  String get whatToLearn => '배우고 싶은 것';

  @override
  String chatHistoryWith(String name) {
    return '$name님과의 채팅 기록';
  }

  @override
  String get noChatHistoryYet => '아직 채팅 기록이 없어요';

  @override
  String get noLikedUsers => '좋아요한 사용자가 없어요.';

  @override
  String get noUsersToBlockFromLikedList => '좋아요 목록에서 차단할 사용자가 없어요.';

  @override
  String get noBlockedUsers => '차단한 사용자가 없어요.';

  @override
  String get removeFromLiked => '좋아요에서 제거';

  @override
  String get blockSelected => '선택 차단';

  @override
  String get unblockSelected => '선택 차단 해제';

  @override
  String get selectAtLeastOneUser => '최소 한 명 이상 선택하세요';

  @override
  String removeUsersFromLikedConfirm(int count) {
    return '좋아요 목록에서 $count명을 제거할까요?';
  }

  @override
  String blockUsersConfirm(int count) {
    return '$count명을 차단할까요? 메시지를 보낼 수 없게 됩니다.';
  }

  @override
  String unblockUsersConfirm(int count) {
    return '$count명 차단을 해제할까요? 다시 메시지를 보낼 수 있게 됩니다.';
  }

  @override
  String get confirm => '확인';

  @override
  String get someActionsFailed => '일부 작업에 실패했습니다. 다시 시도해 주세요.';

  @override
  String usersUpdated(int count) {
    return '$count명이 업데이트되었습니다';
  }

  @override
  String get roleAndBasicInfo => '역할 및 기본 정보';

  @override
  String get demoModeRandomData => '데모 모드: 랜덤 데이터가 입력됩니다(사진 제외).';

  @override
  String get regenerate => '다시 생성';

  @override
  String get name => '이름';

  @override
  String get gender => '성별';

  @override
  String get birthdate => '생년월일';

  @override
  String ageLabel(String age) {
    return '나이: $age';
  }

  @override
  String get aboutMeOptional => '자기소개 (선택)';

  @override
  String get tellOthersAboutYou => '자기소개를 적어 주세요…';

  @override
  String get whatDoYouWantToLearn => '무엇을 배우고 싶으신가요?';

  @override
  String get whatCanYouTeach => '무엇을 가르칠 수 있나요?';

  @override
  String get selectTopicsHint => '1–6개 선택.';

  @override
  String get lessonInfo => '레슨 정보';

  @override
  String get aboutTheLessonOptional => '레슨 소개 (선택)';

  @override
  String get shareLessonDetails => '레슨 세부사항, 기대, 목표를 공유해 주세요…';

  @override
  String get lessonLocationRequired => '레슨 장소 (필수)';

  @override
  String get tutoringRatePerHourRequired => '시간당 레슨비 (필수)';

  @override
  String get parentParticipationOptional => '보호자 동석 환영 (선택)';

  @override
  String get profilePhoto => '프로필 사진';

  @override
  String get profilePhotoRequired => '프로필 사진 (필수)';

  @override
  String get addPhoto => '사진 추가';

  @override
  String get waivers => '동의서';

  @override
  String get waiversRequiredBeforeFinishing => '완료 전 필수입니다.';

  @override
  String get back => '뒤로';

  @override
  String get next => '다음';

  @override
  String get save => '저장';

  @override
  String get finish => '완료';

  @override
  String get selectBirthdate => '생년월일 선택';

  @override
  String get nameRequired => '이름을 입력해 주세요.';

  @override
  String get birthdateRequired => '생년월일을 선택해 주세요.';

  @override
  String get selectAtLeastOneTopic => '최소 1개 주제를 선택해 주세요.';

  @override
  String get selectLessonLocation => '레슨 장소(온라인/대면)를 최소 1곳 선택해 주세요.';

  @override
  String get tutoringRateRequired => '시간당 레슨비를 입력해 주세요.';

  @override
  String get tutoringRateMustBeNumber => '레슨비는 숫자로 입력해 주세요.';

  @override
  String get selectAtLeastOneTopicToLearn => '배우고 싶은 주제를 최소 1개 선택해 주세요.';

  @override
  String get selectOneProfilePhoto => '프로필 사진 1장을 선택해 주세요 (필수).';

  @override
  String get pleaseAgreeToTutorWaiver => '튜터 동의서에 동의해 주세요.';

  @override
  String get pleaseAgreeToStudentWaiver => '학생 위험 인수·동의서에 동의해 주세요.';

  @override
  String get parentalConsentRequiredForMinors => '미성년자의 경우 보호자 동의가 필요합니다.';

  @override
  String get notLoggedIn => '로그인되어 있지 않습니다.';

  @override
  String failedToSaveProfile(String error) {
    return '프로필 저장 실패: $error';
  }

  @override
  String failedToPickPhoto(String error) {
    return '사진 선택 실패: $error';
  }

  @override
  String get tutorWaiverTitle => '튜터 계약 및 면책 동의';

  @override
  String get tutorWaiverText =>
      '전문적 행동: 프로필에 기재한 기술 및 자격 정보가 정확하고 진실함을 인증합니다. 모든 세션을 전문성과 존중으로 진행하는 데 동의합니다.\n\n독립적 지위: Twingl은 매칭 플랫폼이며 저는 Twingl의 직원·대리인·계약자가 아님을 이해합니다. 제 행동과 세션 내용에 대해 전적으로 책임을 집니다.\n\n안전 및 제로 톨러런스: Twingl의 엄격한 안전 가이드라인을 준수하는 데 동의합니다. 괴롭힘, 차별, 부적절한 행위는 계정 즉시 해지 및 법적 조치로 이어질 수 있음을 이해합니다.\n\n면책: 튜터로서의 참여로 인한 모든 책임·청구·요구로부터 Twingl, 소유자 및 제휴사를 면제합니다.';

  @override
  String get studentWaiverTitle => '학생 위험 인수 및 동의서';

  @override
  String get studentWaiverText =>
      '자발적 참여: Twingl을 통해 연결된 활동(러닝, 학습 세션 등)에 자발적으로 참여합니다.\n\n위험 인수: 러닝이나 하이킹 같은 신체 활동에는 부상 위험이 따름을 이해합니다. 알려진·알 수 없는 모든 해당 위험을 인지하고 인수합니다.\n\n개인 책임: Twingl이 모든 이용자에 대한 신원 조회를 하지 않으며, 타인과 만날 때 필요한 안전 조치에 대해 제가 책임짐을 인정합니다.\n\n청구 포기: 참여와 관련된 부상·손실·손해에 대해 Twingl 또는 제휴사를 소송할 권리를 포기합니다.';

  @override
  String get parentalConsentTitle => '보호자 동의 및 감독자 면제';

  @override
  String get parentalConsentText =>
      '감독 권한: Twingl에 등록하는 미성년자의 부모 또는 법적 보호자임을 진술합니다.\n\n참여 동의: 자녀가 Twingl 활동에 참여하고 다른 이용자와 연결하는 것을 허락합니다.\n\n감독 및 책임: Twingl이 오픈 커뮤니티 플랫폼임을 이해합니다. 자녀의 앱 이용을 감독하고 그들의 안전과 행동에 대한 전적인 책임을 집니다.\n\n응급 의료: Twingl 관련 활동 중 응급 상황 시 연락이 되지 않으면 자녀에 대한 필요한 의료 처치를 허가합니다.';

  @override
  String get agreeToTutorWaiverCheckbox => '튜터 계약 및 면책 동의를 읽었으며 동의합니다';

  @override
  String get agreeToStudentWaiverCheckbox => '학생 위험 인수·동의서를 읽었으며 동의합니다';

  @override
  String get agreeToParentalConsentCheckbox => '보호자 동의 및 감독자 면제를 읽었으며 동의합니다';

  @override
  String get parentalConsentOnlyForMinors => '보호자 동의는 미성년자(18세 미만)에게만 필요합니다.';
}
