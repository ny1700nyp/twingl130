// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get hello => 'こんにちは世界';

  @override
  String get notSignedIn => 'サインインしていません';

  @override
  String accountDeletionFailed(int statusCode) {
    return 'アカウントの削除に失敗しました（$statusCode）';
  }

  @override
  String get noAuthenticatedUserFound => '認証されたユーザーが見つかりません';

  @override
  String get noRowsDeletedCheckMatchesRls =>
      '行が削除されませんでした。マッチのRLS DELETEポリシーを確認してください。';

  @override
  String get userNotAuthenticated => 'ユーザーが認証されていません';

  @override
  String requestMessage(String skill, String method) {
    return 'リクエスト：$skill（$method）';
  }

  @override
  String get schedulePromptMessage => '日程・場所・料金について話し合って、始めましょう。';

  @override
  String get unknownName => '不明';

  @override
  String get systemDefault => 'システムデフォルト';

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
  String get support => 'サポート';

  @override
  String get verification => '認証';

  @override
  String get language => '言語';

  @override
  String get help => 'ヘルプ';

  @override
  String get terms => '利用規約';

  @override
  String get invalidProfileLink => 'プロフィールリンクが無効です';

  @override
  String anonymousLoginFailed(String error) {
    return '匿名ログインに失敗しました：$error';
  }

  @override
  String get signInWithSocialLogin => 'ソーシャルログインでサインイン';

  @override
  String get signInWithGoogle => 'Googleでサインイン';

  @override
  String get leaveTwingl => 'Twinglを退会する';

  @override
  String get leaveTwinglDialogMessage =>
      'お気に入り・ブロックリスト・チャット履歴は削除され、プロフィールは削除されます。アカウントは残ります。';

  @override
  String get no => 'いいえ';

  @override
  String get yes => 'はい';

  @override
  String failedToLeaveTwingl(String error) {
    return 'Twinglの退会に失敗しました：$error';
  }

  @override
  String get generalSettings => '一般設定';

  @override
  String get clearLikedBlockedChatHistory => 'お気に入り・ブロック・チャット履歴を削除';

  @override
  String get requestDeclinedMessage => 'リクエストはお断りされました。また新しいリクエストを送れます。';

  @override
  String get considerAnotherTutor => '他のチューターを探すのもおすすめです。';

  @override
  String get paymentIntro =>
      'Twinglは近くの誰かとつなぎます。支払いは直接やり取りしません。サービスは無料で、料金は100％チューターに渡ります。';

  @override
  String get paymentAgreeMethod => '双方で合意できる支払い方法を決めてください。例：';

  @override
  String get paymentVenmoZellePaypal => 'Venmo / Zelle / PayPal';

  @override
  String get paymentCash => '現金';

  @override
  String get paymentCoffeeOrMeal => 'コーヒーや食事（カジュアルなレッスン向け）';

  @override
  String get paymentNoteSafety => '安全のため、対面で会った後に支払うことをおすすめします。';

  @override
  String get paymentTipOnline => 'オンラインレッスンでは、PayPalの購入者保護や50/50支払いも検討してください。';

  @override
  String get unread => '未読';

  @override
  String get howDoIPayForLessons => 'レッスン料の支払い方法は？';

  @override
  String get chatOnlyAfterAccept =>
      'チャットは相手が最初のレッスンリクエストを受け取った後に利用できます。少々お待ちください。';

  @override
  String get declineReason => 'お断りする理由';

  @override
  String get whyDecliningHint => 'なぜお断りしますか？';

  @override
  String get cancel => 'キャンセル';

  @override
  String get delete => '削除';

  @override
  String get block => 'ブロック';

  @override
  String get removeFromFavoriteTitle => 'お気に入りから削除';

  @override
  String get removeFromFavoriteConfirmMessage => 'この人をお気に入りリストから削除しますか？';

  @override
  String get blockUserConfirmMessage => 'このユーザーをブロックしますか？レッスンリクエストが届かなくなります。';

  @override
  String get send => '送信';

  @override
  String get declined => 'お断りされました';

  @override
  String failedToDecline(String error) {
    return 'お断りの送信に失敗しました：$error';
  }

  @override
  String get decline => 'お断りする';

  @override
  String get accept => '受け入れる';

  @override
  String get request => 'リクエスト';

  @override
  String failedToLoadProfile(String error) {
    return 'プロフィールの読み込みに失敗しました：$error';
  }

  @override
  String get profileNotFound => 'プロフィールが見つかりません';

  @override
  String get addedToLiked => 'お気に入りに追加しました';

  @override
  String get waitingForAccept => '承認待ち';

  @override
  String get declinedStatus => 'お断りされました';

  @override
  String get messageHint => 'メッセージ…';

  @override
  String get scheduling => '日程調整';

  @override
  String get locationLabel => '場所';

  @override
  String get sendProposal => '提案を送る';

  @override
  String get acceptedChatNow => '承諾されました。チャットできます。';

  @override
  String failedToAccept(String error) {
    return '受け入れに失敗しました：$error';
  }

  @override
  String failedToSendProposal(String error) {
    return '提案の送信に失敗しました：$error';
  }

  @override
  String failedToSend(String error) {
    return '送信に失敗しました：$error';
  }

  @override
  String get gotIt => '了解';

  @override
  String get more => 'その他';

  @override
  String get aboutUs => '私たちについて';

  @override
  String get paymentGuide => '支払いガイド';

  @override
  String get offer => 'オファー';

  @override
  String get usefulLinks => '便利なリンク';

  @override
  String get lessonSpaceFinder => 'レッスン場所を探す';

  @override
  String get notifications => '通知';

  @override
  String get account => 'アカウント';

  @override
  String get whatIsTwingl => 'Twinglとは？';

  @override
  String get letterFromTwingl => 'Twinglからのメッセージ';

  @override
  String get leaveTwinglConfirm => 'Twinglを退会してもよろしいですか？';

  @override
  String get leaveTwinglDialogContentFull =>
      'アカウントは残りますが：\n\n• お気に入り・ブロックリストは削除されます。\n• チャット履歴は削除されます。\n• プロフィールは削除されます。\n\nTwinglを退会してもよろしいですか？';

  @override
  String leaveTwinglError(String error) {
    return 'Twingl退会：$error';
  }

  @override
  String get editMyProfile => 'プロフィールを編集';

  @override
  String get editProfile => 'プロフィールを編集';

  @override
  String get onboardingTitle => 'オンボーディング';

  @override
  String get addingMoreInfo => '情報を追加';

  @override
  String get deleteUser => 'ユーザーを削除';

  @override
  String get removeFromLikedList => 'お気に入りリストからユーザーを削除';

  @override
  String get blockUser => 'ユーザーをブロック';

  @override
  String get blockUserDescription => 'ブロックしたユーザーはメッセージを送れません';

  @override
  String get unblockUser => 'ブロックを解除';

  @override
  String get unblockUserDescription => 'ブロック解除すると、またメッセージを送れるようになります';

  @override
  String get logOut => 'ログアウト';

  @override
  String get chatMessages => 'チャットメッセージ';

  @override
  String get chat => 'チャット';

  @override
  String get notificationsOnOff => '新しいメッセージを通知する';

  @override
  String get notificationsOff => '通知オフ';

  @override
  String get couldNotOpenLink => 'リンクを開けませんでした。';

  @override
  String get publicLibraries => '公共図書館';

  @override
  String get schoolFacilities => '学校施設';

  @override
  String get creativeStudios => 'クリエイティブスタジオ';

  @override
  String get meetingRooms => '会議室';

  @override
  String get theLearner => '学習者';

  @override
  String get theLearnerDescription => '成長に集中。目標を決めて、近くや世界中の理想のメンターを見つけましょう。';

  @override
  String get theGuide => 'ガイド';

  @override
  String get theGuideDescription => '得意を活かす。他の人の目標達成を手伝い、自分の才能を価値に変えましょう。';

  @override
  String get theConnector => 'コネクター';

  @override
  String get theConnectorDescription =>
      'Twinglのすべて：知っていることを教え、好きなことを学ぶ。コミュニティの中心です。';

  @override
  String get becomeStudentToo => '学習者にもなる';

  @override
  String get becomeTutorToo => 'チューターにもなる';

  @override
  String get becomeStudentTooSubtext => '良い先生は学びをやめません。新しい目標に挑戦して視野を広げましょう。';

  @override
  String get becomeTutorTooSubtext =>
      '教えることはスキルを極める最高の方法です。近くの人とあなたの才能を共有しましょう。';

  @override
  String get unlockStudentMode => '学習者モードを解除';

  @override
  String get unlockTutorMode => 'チューターモードを解除';

  @override
  String get twinerBadgeMessage => 'Twinerバッジを取得できます。';

  @override
  String get starting => '開始中…';

  @override
  String get meetTutorsInArea => 'お近くのチューターと出会う';

  @override
  String get perfectTutorsAnywhere => 'どこでも理想のチューター';

  @override
  String get fellowTutorsInArea => 'お近くのチューター';

  @override
  String get studentCandidatesInArea => 'お近くの学習者';

  @override
  String get noTutorsYet => 'まだチューターがいません。お近くのチューターや理想のチューターでいいねしてみてください。';

  @override
  String get noStudentsYet => 'まだ学習者がいません。お近くの学習者やチャットでいいねしてみてください。';

  @override
  String get noFellowsYet => 'まだお近くのチューターがいません。お近くのチューターでいいねしてみてください。';

  @override
  String get noMatchingTalentsFound => 'マッチするタレントがいませんでした。';

  @override
  String get learnShareConnect => '学ぶ・共有する・つながる。';

  @override
  String get student => '学習者';

  @override
  String get tutor => 'チューター';

  @override
  String get twiner => 'Twiner';

  @override
  String get twinglIdentity => 'Twinglアイデンティティ';

  @override
  String get leaveTwinglSubtitle => 'お気に入り・ブロック・チャット履歴を削除';

  @override
  String failedToStartConversion(String error) {
    return '切り替えに失敗しました：$error';
  }

  @override
  String get man => '男性';

  @override
  String get woman => '女性';

  @override
  String get nonBinary => 'ノンバイナリー';

  @override
  String get preferNotToSay => '答えたくない';

  @override
  String get share => '共有';

  @override
  String get copyLink => 'リンクをコピー';

  @override
  String get iCanTeach => '教えられること';

  @override
  String get iWantToLearn => '学びたいこと';

  @override
  String get tutoringRate => '料金';

  @override
  String get superClose => 'すぐ近く';

  @override
  String kmAway(int km) {
    return '$km km';
  }

  @override
  String get onlineOnsite => 'オンライン・対面';

  @override
  String get online => 'オンライン';

  @override
  String get onsite => '対面';

  @override
  String get noMoreMatches => 'これ以上マッチなし';

  @override
  String get noMoreNearbyResults => '近くにこれ以上結果はありません';

  @override
  String get noNearbyTalentFound => '近くにタレントが見つかりませんでした。';

  @override
  String get tapRefreshToFindMore => '更新してもっとタレントを探す。';

  @override
  String get tapRefreshToSearchAgain => '更新してもう一度検索。';

  @override
  String get refresh => '更新';

  @override
  String failedToSave(String error) {
    return '保存に失敗しました: $error';
  }

  @override
  String get profileDetails => 'プロフィール';

  @override
  String get aboutMe => '自己紹介';

  @override
  String get aboutTheLesson => 'レッスンについて';

  @override
  String get lessonLocation => 'レッスン場所';

  @override
  String lessonFeePerHour(String amount) {
    return '料金: $amount/時間';
  }

  @override
  String get parentParticipationWelcomed => '保護者の同席歓迎';

  @override
  String get parentParticipationNotSpecified => '保護者の同席は未指定';

  @override
  String get unableToGenerateProfileLink => 'プロフィールリンクを生成できませんでした。';

  @override
  String get profileLinkCopiedToClipboard => 'リンクをコピーしました！';

  @override
  String failedToShare(String error) {
    return '共有に失敗しました: $error';
  }

  @override
  String get unableToSendRequest => 'リクエストを送信できませんでした。';

  @override
  String get sent => '送信済み';

  @override
  String failedToSendRequest(String error) {
    return 'リクエスト送信に失敗しました: $error';
  }

  @override
  String get sendRequest => 'リクエストを送る';

  @override
  String declinedWithReason(String reason) {
    return '辞退: $reason';
  }

  @override
  String get addToCalendar => 'カレンダーに追加 ';

  @override
  String get invalidDateInProposal => 'この提案の日付が無効です';

  @override
  String get addedToCalendar => 'カレンダーに追加しました';

  @override
  String failedToAddToCalendar(String error) {
    return 'カレンダーに追加できませんでした: $error';
  }

  @override
  String get locationHint => '例: Santa Teresa Library, Zoom';

  @override
  String get tabTutors => 'チューター';

  @override
  String get tabStudents => '学習者';

  @override
  String get tabFellows => '近くのチューター';

  @override
  String get likedSectionTitle => 'お気に入り';

  @override
  String get myDetails => '自己情報';

  @override
  String get myActivityStats => 'アクティビティ';

  @override
  String get statsViews => '閲覧数';

  @override
  String get statsLiked => 'いいね';

  @override
  String get statsRequests => 'リクエスト';

  @override
  String get statsRequesteds => 'リクエスト済';

  @override
  String get requestTraining => 'レッスンリクエスト';

  @override
  String get chatHistory => 'チャット履歴';

  @override
  String get selectSkillAndMethod => '学びたいスキルと方法を選んでください';

  @override
  String get whatToLearn => '学びたいこと';

  @override
  String chatHistoryWith(String name) {
    return '$name とのチャット履歴';
  }

  @override
  String get noChatHistoryYet => 'まだチャット履歴がありません';

  @override
  String get noLikedUsers => 'お気に入りはいません。';

  @override
  String get noUsersToBlockFromLikedList => 'ブロックするユーザーがいません。';

  @override
  String get noBlockedUsers => 'ブロック中のユーザーはいません。';

  @override
  String get removeFromLiked => 'お気に入りから削除';

  @override
  String get blockSelected => '選択をブロック';

  @override
  String get unblockSelected => '選択のブロック解除';

  @override
  String get selectAtLeastOneUser => '1人以上選択してください';

  @override
  String removeUsersFromLikedConfirm(int count) {
    return 'お気に入りから$count人を削除しますか？';
  }

  @override
  String blockUsersConfirm(int count) {
    return '$count人をブロックしますか？メッセージを送れなくなります。';
  }

  @override
  String unblockUsersConfirm(int count) {
    return '$count人のブロックを解除しますか？再度メッセージを送れるようになります。';
  }

  @override
  String get confirm => '確認';

  @override
  String get someActionsFailed => '一部失敗しました。もう一度お試しください。';

  @override
  String usersUpdated(int count) {
    return '$count人を更新しました';
  }

  @override
  String get roleAndBasicInfo => '役割と基本情報';

  @override
  String get demoModeRandomData => 'デモモード：ランダムデータが入力されます（写真はスキップ）。';

  @override
  String get regenerate => '再生成';

  @override
  String get name => '名前';

  @override
  String get gender => '性別';

  @override
  String get birthdate => '生年月日';

  @override
  String ageLabel(String age) {
    return '年齢: $age';
  }

  @override
  String get aboutMeOptional => '自己紹介（任意）';

  @override
  String get tellOthersAboutYou => '自己紹介を書いてください…';

  @override
  String get whatDoYouWantToLearn => '何を学びたいですか？';

  @override
  String get whatCanYouTeach => '何を教えられますか？';

  @override
  String get selectTopicsHint => '1〜6個選択してください。';

  @override
  String get lessonInfo => 'レッスン情報';

  @override
  String get aboutTheLessonOptional => 'レッスンについて（任意）';

  @override
  String get shareLessonDetails => 'レッスンの詳細・期待・目標を共有…';

  @override
  String get lessonLocationRequired => 'レッスン場所（必須）';

  @override
  String get tutoringRatePerHourRequired => '時給（必須）';

  @override
  String get parentParticipationOptional => '保護者の同席歓迎（任意）';

  @override
  String get profilePhoto => 'プロフィール写真';

  @override
  String get profilePhotoRequired => 'プロフィール写真（必須）';

  @override
  String get addPhoto => '写真を追加';

  @override
  String get waivers => '同意書';

  @override
  String get waiversRequiredBeforeFinishing => '完了前に必須です。';

  @override
  String get back => '戻る';

  @override
  String get next => '次へ';

  @override
  String get save => '保存';

  @override
  String get finish => '完了';

  @override
  String get selectBirthdate => '生年月日を選択';

  @override
  String get nameRequired => '名前は必須です。';

  @override
  String get birthdateRequired => '生年月日は必須です。';

  @override
  String get selectAtLeastOneTopic => '少なくとも1つのトピックを選択してください。';

  @override
  String get selectLessonLocation => 'レッスン場所（オンライン/対面）を1つ以上選択してください。';

  @override
  String get tutoringRateRequired => '時給は必須です。';

  @override
  String get tutoringRateMustBeNumber => '時給は数字で入力してください。';

  @override
  String get selectAtLeastOneTopicToLearn => '学びたいトピックを1つ以上選択してください。';

  @override
  String get selectOneProfilePhoto => 'プロフィール写真を1枚選択してください（必須）。';

  @override
  String get pleaseAgreeToTutorWaiver => 'チューター同意書に同意してください。';

  @override
  String get pleaseAgreeToStudentWaiver => '生徒リスク承知・同意書に同意してください。';

  @override
  String get parentalConsentRequiredForMinors => '未成年の場合は保護者の同意が必要です。';

  @override
  String get notLoggedIn => 'ログインしていません。';

  @override
  String failedToSaveProfile(String error) {
    return 'プロフィールの保存に失敗しました: $error';
  }

  @override
  String failedToPickPhoto(String error) {
    return '写真の選択に失敗しました: $error';
  }

  @override
  String get tutorWaiverTitle => 'チューター契約・免責事項';

  @override
  String get tutorWaiverText =>
      '職業上の行為：プロフィールに記載したスキル・資格に関する情報が正確かつ真実であることを証明します。すべてのセッションをプロフェッショナルかつ敬意をもって行うことに同意します。\n\n独立した立場：Twinglはマッチングプラットフォームであり、私はTwinglの従業員・代理人・請負業者ではないことを理解しています。自分の行動とセッション内容について単独で責任を負います。\n\n安全とゼロトレランス：Twinglの厳格な安全ガイドラインに従うことに同意します。ハラスメント、差別、不適切な行為はアカウント即時終了および法的措置につながることを理解しています。\n\n免責：チューターとしての参加に起因する一切の責任・請求・要求から、Twingl、そのオーナーおよび関連団体を免責することをここに表明します。';

  @override
  String get studentWaiverTitle => '生徒のリスク承知・同意書';

  @override
  String get studentWaiverText =>
      '自発的参加：Twinglを通じてつながった活動（ランニング、学習セッション等）に自発的に参加します。\n\nリスク承知：ランニングやハイキングなどの身体的活動には怪我のリスクが伴うことを理解しています。既知・未知のすべてのそのようなリスクを承知のうえで負います。\n\n自己責任：Twinglが全ユーザーの身元調査を行うわけではないことを認め、他のユーザーと会う際の必要な安全対策について自分で責任を負います。\n\n請求権の放棄：参加に伴う怪我・損失・損害について、Twinglまたはその関連団体を訴える権利を放棄します。';

  @override
  String get parentalConsentTitle => '保護者同意・監督者免責';

  @override
  String get parentalConsentText =>
      '監督権限：Twinglに登録する未成年の親権者または法定後見人であることを表明します。\n\n参加同意：子がTwinglの活動に参加し、他のユーザーとつながることを許可します。\n\n監督と責任：Twinglはオープンなコミュニティプラットフォームであることを理解しています。子のアプリ利用を監督し、その安全と行動について全面的に責任を負うことに同意します。\n\n緊急時の医療：Twingl関連活動中の緊急時、連絡が取れない場合、子に必要な医療処置を許可します。';

  @override
  String get agreeToTutorWaiverCheckbox => 'チューター契約・免責事項を読み、同意します';

  @override
  String get agreeToStudentWaiverCheckbox => '生徒のリスク承知・同意書を読み、同意します';

  @override
  String get agreeToParentalConsentCheckbox => '保護者同意・監督者免責を読み、同意します';

  @override
  String get parentalConsentOnlyForMinors => '保護者の同意は未成年（18歳未満）のみ必要です。';
}
