// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get hello => '你好世界';

  @override
  String get notSignedIn => '未登录';

  @override
  String accountDeletionFailed(int statusCode) {
    return '账户删除失败（$statusCode）';
  }

  @override
  String get noAuthenticatedUserFound => '未找到已认证用户';

  @override
  String get noRowsDeletedCheckMatchesRls => '未删除任何行。请检查匹配项的 RLS DELETE 策略。';

  @override
  String get userNotAuthenticated => '用户未认证';

  @override
  String requestMessage(String skill, String method) {
    return '请求：$skill（$method）';
  }

  @override
  String get schedulePromptMessage => '请先商量时间、地点和费用，再开始吧。';

  @override
  String get unknownName => '未知';

  @override
  String get systemDefault => '系统默认';

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
  String get support => '支持';

  @override
  String get verification => '认证';

  @override
  String get language => '语言';

  @override
  String get help => '帮助';

  @override
  String get terms => '条款';

  @override
  String get invalidProfileLink => '个人资料链接无效';

  @override
  String anonymousLoginFailed(String error) {
    return '匿名登录失败：$error';
  }

  @override
  String get signInWithSocialLogin => '使用社交账号登录';

  @override
  String get signInWithGoogle => '使用 Google 登录';

  @override
  String get leaveTwingl => '退出 Twingl';

  @override
  String get leaveTwinglDialogMessage => '你的喜欢列表、屏蔽列表和聊天记录将被清空，个人资料将被删除。账户会保留。';

  @override
  String get no => '否';

  @override
  String get yes => '是';

  @override
  String failedToLeaveTwingl(String error) {
    return '退出 Twingl 失败：$error';
  }

  @override
  String get generalSettings => '通用设置';

  @override
  String get clearLikedBlockedChatHistory => '清空喜欢、屏蔽与聊天记录';

  @override
  String get requestDeclinedMessage => '你的请求已被拒绝。随时可以重新发送请求。';

  @override
  String get considerAnotherTutor => '也可以考虑找其他导师。';

  @override
  String get paymentIntro => 'Twingl 帮你连接身边的人，我们不直接处理付款。服务免费，费用 100% 归导师。';

  @override
  String get paymentAgreeMethod => '请双方商定一种方便的付款方式，例如：';

  @override
  String get paymentVenmoZellePaypal => 'Venmo / Zelle / PayPal';

  @override
  String get paymentCash => '现金';

  @override
  String get paymentCoffeeOrMeal => '咖啡或便餐（适用于非正式课程）';

  @override
  String get paymentNoteSafety => '为安全起见，建议见面后再付款。';

  @override
  String get paymentTipOnline => '线上课程可考虑用 PayPal 买家保护或 50/50 付款方式。';

  @override
  String get unread => '未读';

  @override
  String get howDoIPayForLessons => '如何支付课程费用？';

  @override
  String get chatOnlyAfterAccept => '对方接受你的首次课程请求后即可聊天。请稍候。';

  @override
  String get declineReason => '拒绝原因';

  @override
  String get whyDecliningHint => '为什么拒绝？';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get block => '屏蔽';

  @override
  String get removeFromFavoriteTitle => '从喜欢中移除';

  @override
  String get removeFromFavoriteConfirmMessage => '将此人从喜欢列表中移除？';

  @override
  String get blockUserConfirmMessage => '屏蔽此用户？你将不再收到其课程请求。';

  @override
  String get send => '发送';

  @override
  String get declined => '已拒绝';

  @override
  String failedToDecline(String error) {
    return '拒绝发送失败：$error';
  }

  @override
  String get decline => '拒绝';

  @override
  String get accept => '接受';

  @override
  String get request => '请求';

  @override
  String failedToLoadProfile(String error) {
    return '加载个人资料失败：$error';
  }

  @override
  String get profileNotFound => '未找到个人资料';

  @override
  String get addedToLiked => '已添加到喜欢';

  @override
  String get waitingForAccept => '等待接受';

  @override
  String get declinedStatus => '已拒绝';

  @override
  String get messageHint => '消息…';

  @override
  String get scheduling => '安排时间';

  @override
  String get locationLabel => '地点';

  @override
  String get sendProposal => '发送提议';

  @override
  String get acceptedChatNow => '已接受。现在可以聊天了。';

  @override
  String failedToAccept(String error) {
    return '接受失败：$error';
  }

  @override
  String failedToSendProposal(String error) {
    return '发送提议失败：$error';
  }

  @override
  String failedToSend(String error) {
    return '发送失败：$error';
  }

  @override
  String get gotIt => '知道了';

  @override
  String get more => '更多';

  @override
  String get aboutUs => '关于我们';

  @override
  String get paymentGuide => '付款指南';

  @override
  String get offer => '提供';

  @override
  String get usefulLinks => '实用链接';

  @override
  String get lessonSpaceFinder => '查找上课场地';

  @override
  String get notifications => '通知';

  @override
  String get account => '账户';

  @override
  String get whatIsTwingl => '什么是 Twingl？';

  @override
  String get letterFromTwingl => 'Twingl 的来信';

  @override
  String get leaveTwinglConfirm => '确定要退出 Twingl 吗？';

  @override
  String get leaveTwinglDialogContentFull =>
      '你的账户会保留，但：\n\n• 喜欢列表和屏蔽列表将被清空。\n• 聊天记录将被删除。\n• 个人资料将被删除。\n\n确定要退出 Twingl 吗？';

  @override
  String leaveTwinglError(String error) {
    return '退出 Twingl：$error';
  }

  @override
  String get editMyProfile => '编辑我的资料';

  @override
  String get editProfile => '编辑资料';

  @override
  String get onboardingTitle => '入门';

  @override
  String get addingMoreInfo => '添加更多信息';

  @override
  String get deleteUser => '删除用户';

  @override
  String get removeFromLikedList => '从喜欢列表中移除用户';

  @override
  String get blockUser => '屏蔽用户';

  @override
  String get blockUserDescription => '被屏蔽的用户无法向你发送消息';

  @override
  String get unblockUser => '取消屏蔽';

  @override
  String get unblockUserDescription => '取消屏蔽后，对方可以再次向你发送消息';

  @override
  String get logOut => '退出登录';

  @override
  String get chatMessages => '聊天消息';

  @override
  String get chat => '聊天';

  @override
  String get notificationsOnOff => '收到新消息时通知';

  @override
  String get notificationsOff => '通知已关闭';

  @override
  String get couldNotOpenLink => '无法打开链接。';

  @override
  String get publicLibraries => '公共图书馆';

  @override
  String get schoolFacilities => '学校设施';

  @override
  String get creativeStudios => '创意工作室';

  @override
  String get meetingRooms => '会议室';

  @override
  String get theLearner => '学习者';

  @override
  String get theLearnerDescription => '专注成长。设定目标，在附近或全球找到合适的导师。';

  @override
  String get theGuide => '引导者';

  @override
  String get theGuideDescription => '分享你的专长。帮助他人实现目标，让你的才华创造价值。';

  @override
  String get theConnector => '连接者';

  @override
  String get theConnectorDescription => '完整的 Twingl 体验：教你所知，学你所爱。你是我们社区的核心。';

  @override
  String get becomeStudentToo => '也当学习者';

  @override
  String get becomeTutorToo => '也当导师';

  @override
  String get becomeStudentTooSubtext => '好老师从不停止学习。通过达成新目标来拓展视野。';

  @override
  String get becomeTutorTooSubtext => '教学是精进技能的最好方式。与身边的人分享你的才华。';

  @override
  String get unlockStudentMode => '开启学习者模式';

  @override
  String get unlockTutorMode => '开启导师模式';

  @override
  String get twinerBadgeMessage => '你将获得 Twiner 徽章。';

  @override
  String get starting => '正在启动…';

  @override
  String get meetTutorsInArea => '结识附近的导师';

  @override
  String get perfectTutorsAnywhere => '随时随地，找到合适导师';

  @override
  String get fellowTutorsInArea => '附近的导师';

  @override
  String get studentCandidatesInArea => '附近的学习者';

  @override
  String get noTutorsYet => '还没有导师。在结识附近的导师或随时随地找到合适导师中点喜欢吧。';

  @override
  String get noStudentsYet => '还没有学习者。在附近的学习者或聊天中点喜欢吧。';

  @override
  String get noFellowsYet => '还没有附近的导师。在附近的导师中点喜欢吧。';

  @override
  String get noMatchingTalentsFound => '未找到匹配的导师。';

  @override
  String get learnShareConnect => '学习、分享、连接。';

  @override
  String get student => '学习者';

  @override
  String get tutor => '导师';

  @override
  String get twiner => 'Twiner';

  @override
  String get twinglIdentity => 'Twingl 身份';

  @override
  String get leaveTwinglSubtitle => '清空喜欢、屏蔽与聊天记录';

  @override
  String failedToStartConversion(String error) {
    return '切换失败：$error';
  }

  @override
  String get man => '男';

  @override
  String get woman => '女';

  @override
  String get nonBinary => '非二元';

  @override
  String get preferNotToSay => '不愿透露';

  @override
  String get share => '分享';

  @override
  String get copyLink => '复制链接';

  @override
  String get iCanTeach => '我可以教';

  @override
  String get iWantToLearn => '我想学';

  @override
  String get tutoringRate => '课时费';

  @override
  String get superClose => '很近';

  @override
  String kmAway(int km) {
    return '$km 公里';
  }

  @override
  String get onlineOnsite => '线上、线下';

  @override
  String get online => '线上';

  @override
  String get onsite => '线下';

  @override
  String get noMoreMatches => '没有更多匹配';

  @override
  String get noMoreNearbyResults => '附近没有更多结果';

  @override
  String get noNearbyTalentFound => '附近未找到导师。';

  @override
  String get tapRefreshToFindMore => '点击刷新以发现更多导师。';

  @override
  String get tapRefreshToSearchAgain => '点击刷新以重新搜索。';

  @override
  String get refresh => '刷新';

  @override
  String failedToSave(String error) {
    return '保存失败：$error';
  }

  @override
  String get profileDetails => '个人资料';

  @override
  String get aboutMe => '关于我';

  @override
  String get aboutTheLesson => '关于课程';

  @override
  String get lessonLocation => '上课地点';

  @override
  String lessonFeePerHour(String amount) {
    return '课时费：$amount/小时';
  }

  @override
  String get parentParticipationWelcomed => '欢迎家长旁听';

  @override
  String get parentParticipationNotSpecified => '家长旁听未说明';

  @override
  String get unableToGenerateProfileLink => '无法生成个人资料链接。';

  @override
  String get profileLinkCopiedToClipboard => '链接已复制到剪贴板！';

  @override
  String failedToShare(String error) {
    return '分享失败：$error';
  }

  @override
  String get unableToSendRequest => '无法发送请求。';

  @override
  String get sent => '已发送';

  @override
  String failedToSendRequest(String error) {
    return '发送请求失败：$error';
  }

  @override
  String get sendRequest => '发送请求';

  @override
  String declinedWithReason(String reason) {
    return '已拒绝：$reason';
  }

  @override
  String get addToCalendar => '添加到 ';

  @override
  String get invalidDateInProposal => '此提议中的日期无效';

  @override
  String get addedToCalendar => '已添加到日历';

  @override
  String failedToAddToCalendar(String error) {
    return '添加到日历失败：$error';
  }

  @override
  String get locationHint => '例如：Santa Teresa Library、Zoom';

  @override
  String get tabTutors => '导师';

  @override
  String get tabStudents => '学员';

  @override
  String get tabFellows => '附近导师';

  @override
  String get likedSectionTitle => '喜欢';

  @override
  String get myDetails => '我的资料';

  @override
  String get myActivityStats => '我的活动统计';

  @override
  String get statsViews => '浏览';

  @override
  String get statsLiked => '喜欢';

  @override
  String get statsRequests => '请求';

  @override
  String get statsRequesteds => '已请求';

  @override
  String get requestTraining => '请求课程';

  @override
  String get chatHistory => '聊天记录';

  @override
  String get selectSkillAndMethod => '选择你想学的技能和上课方式';

  @override
  String get whatToLearn => '想学什么';

  @override
  String chatHistoryWith(String name) {
    return '与 $name 的聊天记录';
  }

  @override
  String get noChatHistoryYet => '暂无聊天记录';

  @override
  String get noLikedUsers => '暂无喜欢的人。';

  @override
  String get noUsersToBlockFromLikedList => '喜欢列表中暂无用户可屏蔽。';

  @override
  String get noBlockedUsers => '暂无已屏蔽用户。';

  @override
  String get removeFromLiked => '从喜欢中移除';

  @override
  String get blockSelected => '屏蔽所选';

  @override
  String get unblockSelected => '解除所选屏蔽';

  @override
  String get selectAtLeastOneUser => '请至少选择一位用户';

  @override
  String removeUsersFromLikedConfirm(int count) {
    return '从喜欢列表中移除 $count 位用户？';
  }

  @override
  String blockUsersConfirm(int count) {
    return '屏蔽 $count 位用户？他们将无法向你发送消息。';
  }

  @override
  String unblockUsersConfirm(int count) {
    return '解除 $count 位用户的屏蔽？他们将可以再次向你发消息。';
  }

  @override
  String get confirm => '确认';

  @override
  String get someActionsFailed => '部分操作失败，请重试。';

  @override
  String usersUpdated(int count) {
    return '已更新 $count 位用户';
  }

  @override
  String get roleAndBasicInfo => '角色与基本信息';

  @override
  String get demoModeRandomData => '演示模式：已填充随机数据（跳过照片）。';

  @override
  String get regenerate => '重新生成';

  @override
  String get name => '姓名';

  @override
  String get gender => '性别';

  @override
  String get birthdate => '出生日期';

  @override
  String ageLabel(String age) {
    return '年龄：$age';
  }

  @override
  String get aboutMeOptional => '关于我（选填）';

  @override
  String get tellOthersAboutYou => '向大家介绍一下你自己…';

  @override
  String get whatDoYouWantToLearn => '你想学什么？';

  @override
  String get whatCanYouTeach => '你能教什么？';

  @override
  String get selectTopicsHint => '请选择 1–6 项。';

  @override
  String get lessonInfo => '课程信息';

  @override
  String get aboutTheLessonOptional => '关于课程（选填）';

  @override
  String get shareLessonDetails => '分享课程详情、期望、目标…';

  @override
  String get lessonLocationRequired => '上课地点（必填）';

  @override
  String get tutoringRatePerHourRequired => '每小时辅导费（必填）';

  @override
  String get parentParticipationOptional => '欢迎家长参与（选填）';

  @override
  String get profilePhoto => '头像';

  @override
  String get profilePhotoRequired => '头像（必填）';

  @override
  String get addPhoto => '添加照片';

  @override
  String get waivers => '同意书';

  @override
  String get waiversRequiredBeforeFinishing => '完成前必须同意。';

  @override
  String get back => '返回';

  @override
  String get next => '下一步';

  @override
  String get save => '保存';

  @override
  String get finish => '完成';

  @override
  String get selectBirthdate => '选择出生日期';

  @override
  String get nameRequired => '请填写姓名。';

  @override
  String get birthdateRequired => '请选择出生日期。';

  @override
  String get selectAtLeastOneTopic => '请至少选择 1 个主题。';

  @override
  String get selectLessonLocation => '请至少选择一种上课方式（线下/线上）。';

  @override
  String get tutoringRateRequired => '请填写每小时辅导费。';

  @override
  String get tutoringRateMustBeNumber => '辅导费请输入数字。';

  @override
  String get selectAtLeastOneTopicToLearn => '请至少选择 1 个想学的主题。';

  @override
  String get selectOneProfilePhoto => '请选择 1 张头像（必填）。';

  @override
  String get pleaseAgreeToTutorWaiver => '请同意辅导者协议与免责声明。';

  @override
  String get pleaseAgreeToStudentWaiver => '请同意学员风险承担与免责声明。';

  @override
  String get parentalConsentRequiredForMinors => '未成年人须经监护人同意。';

  @override
  String get notLoggedIn => '您尚未登录。';

  @override
  String failedToSaveProfile(String error) {
    return '保存资料失败：$error';
  }

  @override
  String failedToPickPhoto(String error) {
    return '选择照片失败：$error';
  }

  @override
  String get tutorWaiverTitle => '辅导者协议与免责声明';

  @override
  String get tutorWaiverText =>
      '职业操守：本人确认资料中关于技能与资历的信息真实准确。同意以专业、尊重的态度进行所有课程。\n\n独立身份：本人知悉 Twingl 为匹配平台，本人并非 Twingl 的员工、代理或承包商，对自身行为及课程内容负全部责任。\n\n安全与零容忍：同意遵守 Twingl 严格的安全准则。知悉任何骚扰、歧视或不当行为将导致账号立即终止并可能承担法律责任。\n\n责任免除：本人免除 Twingl 及其所有者、关联方因本人以辅导者身份参与而产生的一切责任、索赔或要求。';

  @override
  String get studentWaiverTitle => '学员风险承担与免责声明';

  @override
  String get studentWaiverText =>
      '自愿参与：本人自愿参与通过 Twingl 联系的活动（跑步、学习课程等）。\n\n风险承担：本人知悉某些活动（尤其如跑步、徒步等身体活动）存在固有受伤风险，并明知且自愿承担一切已知与未知风险。\n\n个人责任：本人知悉 Twingl 不对每位用户进行背景审查，在与他人见面时由本人负责采取必要安全措施。\n\n放弃索赔：本人放弃就参与相关的人身伤害、损失或损害向 Twingl 或其关联方提起诉讼的权利。';

  @override
  String get parentalConsentTitle => '监护人同意与免责';

  @override
  String get parentalConsentText =>
      '监护权：本人系在 Twingl 注册的未成年人的父母或法定监护人。\n\n参与同意：本人允许子女参与 Twingl 活动并与其他用户联系。\n\n监督与责任：本人知悉 Twingl 为开放社区平台，同意监督子女使用本应用，并对其安全与行为承担全部责任。\n\n紧急医疗：在 Twingl 相关活动中发生紧急情况且无法联系到本人时，本人授权对子女进行必要的医疗救治。';

  @override
  String get agreeToTutorWaiverCheckbox => '我已阅读并同意辅导者协议与免责声明';

  @override
  String get agreeToStudentWaiverCheckbox => '我已阅读并同意学员风险承担与免责声明';

  @override
  String get agreeToParentalConsentCheckbox => '我已阅读并同意监护人同意与免责';

  @override
  String get parentalConsentOnlyForMinors => '仅对未成年人（未满 18 岁）需要监护人同意。';
}
