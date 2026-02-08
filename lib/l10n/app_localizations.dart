import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
  ];

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello World'**
  String get hello;

  /// No description provided for @notSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get notSignedIn;

  /// No description provided for @accountDeletionFailed.
  ///
  /// In en, this message translates to:
  /// **'Account deletion failed ({statusCode})'**
  String accountDeletionFailed(int statusCode);

  /// No description provided for @noAuthenticatedUserFound.
  ///
  /// In en, this message translates to:
  /// **'No authenticated user found'**
  String get noAuthenticatedUserFound;

  /// No description provided for @noRowsDeletedCheckMatchesRls.
  ///
  /// In en, this message translates to:
  /// **'No rows deleted. Check matches RLS DELETE policy.'**
  String get noRowsDeletedCheckMatchesRls;

  /// No description provided for @userNotAuthenticated.
  ///
  /// In en, this message translates to:
  /// **'User not authenticated'**
  String get userNotAuthenticated;

  /// No description provided for @requestMessage.
  ///
  /// In en, this message translates to:
  /// **'Request: {skill} ({method})'**
  String requestMessage(String skill, String method);

  /// No description provided for @schedulePromptMessage.
  ///
  /// In en, this message translates to:
  /// **'Please discuss your availability, preferred location, and rates to kick things off.'**
  String get schedulePromptMessage;

  /// No description provided for @unknownName.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownName;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @languageChinese.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get languageChinese;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageFrench.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @languageGerman.
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get languageGerman;

  /// No description provided for @languageJapanese.
  ///
  /// In en, this message translates to:
  /// **'日本語'**
  String get languageJapanese;

  /// No description provided for @languageKorean.
  ///
  /// In en, this message translates to:
  /// **'한국어'**
  String get languageKorean;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @verification.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get verification;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get terms;

  /// No description provided for @invalidProfileLink.
  ///
  /// In en, this message translates to:
  /// **'Invalid profile link'**
  String get invalidProfileLink;

  /// No description provided for @anonymousLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Anonymous login failed: {error}'**
  String anonymousLoginFailed(String error);

  /// No description provided for @signInWithSocialLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign in with social login'**
  String get signInWithSocialLogin;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @leaveTwingl.
  ///
  /// In en, this message translates to:
  /// **'Leave Twingl'**
  String get leaveTwingl;

  /// No description provided for @leaveTwinglDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Your liked list, blocked list, and chat history will be cleared, and your profile will be removed. Your account will remain.'**
  String get leaveTwinglDialogMessage;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @failedToLeaveTwingl.
  ///
  /// In en, this message translates to:
  /// **'Failed to leave Twingl: {error}'**
  String failedToLeaveTwingl(String error);

  /// No description provided for @generalSettings.
  ///
  /// In en, this message translates to:
  /// **'General Settings'**
  String get generalSettings;

  /// No description provided for @clearLikedBlockedChatHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear liked, blocked, chat history'**
  String get clearLikedBlockedChatHistory;

  /// No description provided for @requestDeclinedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your request was declined. Please feel free to send a new request when you\'re ready.'**
  String get requestDeclinedMessage;

  /// No description provided for @considerAnotherTutor.
  ///
  /// In en, this message translates to:
  /// **'You might also consider finding another tutor.'**
  String get considerAnotherTutor;

  /// No description provided for @paymentIntro.
  ///
  /// In en, this message translates to:
  /// **'Twingl connects you with neighbors, but we don\'t handle payments directly. This keeps our service free and puts 100% of the fee in your tutor\'s pocket!'**
  String get paymentIntro;

  /// No description provided for @paymentAgreeMethod.
  ///
  /// In en, this message translates to:
  /// **'Please agree on a method that works for both of you, such as:'**
  String get paymentAgreeMethod;

  /// No description provided for @paymentVenmoZellePaypal.
  ///
  /// In en, this message translates to:
  /// **'Venmo / Zelle / PayPal'**
  String get paymentVenmoZellePaypal;

  /// No description provided for @paymentCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get paymentCash;

  /// No description provided for @paymentCoffeeOrMeal.
  ///
  /// In en, this message translates to:
  /// **'Coffee or Meal (for casual sessions)'**
  String get paymentCoffeeOrMeal;

  /// No description provided for @paymentNoteSafety.
  ///
  /// In en, this message translates to:
  /// **'Note: For safety, we recommend paying after meeting in person.'**
  String get paymentNoteSafety;

  /// No description provided for @paymentTipOnline.
  ///
  /// In en, this message translates to:
  /// **'Tip: For online lessons, consider paying via PayPal for buyer protection, or use the 50/50 payment method.'**
  String get paymentTipOnline;

  /// No description provided for @unread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get unread;

  /// No description provided for @howDoIPayForLessons.
  ///
  /// In en, this message translates to:
  /// **'How do I pay for lessons?'**
  String get howDoIPayForLessons;

  /// No description provided for @chatOnlyAfterAccept.
  ///
  /// In en, this message translates to:
  /// **'Chat is only available after the other person accepts your first class request. Please wait.'**
  String get chatOnlyAfterAccept;

  /// No description provided for @declineReason.
  ///
  /// In en, this message translates to:
  /// **'Decline reason'**
  String get declineReason;

  /// No description provided for @whyDecliningHint.
  ///
  /// In en, this message translates to:
  /// **'Why are you declining?'**
  String get whyDecliningHint;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// No description provided for @removeFromFavoriteTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove from Favorite'**
  String get removeFromFavoriteTitle;

  /// No description provided for @removeFromFavoriteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove this person from your Liked list?'**
  String get removeFromFavoriteConfirmMessage;

  /// No description provided for @blockUserConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Block this user? You will not see lesson requests from them.'**
  String get blockUserConfirmMessage;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @declined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get declined;

  /// No description provided for @failedToDecline.
  ///
  /// In en, this message translates to:
  /// **'Failed to decline: {error}'**
  String failedToDecline(String error);

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @request.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get request;

  /// No description provided for @failedToLoadProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to load profile: {error}'**
  String failedToLoadProfile(String error);

  /// No description provided for @profileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Profile not found'**
  String get profileNotFound;

  /// No description provided for @addedToLiked.
  ///
  /// In en, this message translates to:
  /// **'Added to Liked'**
  String get addedToLiked;

  /// No description provided for @waitingForAccept.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Accept'**
  String get waitingForAccept;

  /// No description provided for @declinedStatus.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get declinedStatus;

  /// No description provided for @messageHint.
  ///
  /// In en, this message translates to:
  /// **'Message...'**
  String get messageHint;

  /// No description provided for @scheduling.
  ///
  /// In en, this message translates to:
  /// **'Scheduling'**
  String get scheduling;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel;

  /// No description provided for @sendProposal.
  ///
  /// In en, this message translates to:
  /// **'Send Proposal'**
  String get sendProposal;

  /// No description provided for @acceptedChatNow.
  ///
  /// In en, this message translates to:
  /// **'Accepted. You can chat now.'**
  String get acceptedChatNow;

  /// No description provided for @failedToAccept.
  ///
  /// In en, this message translates to:
  /// **'Failed to accept: {error}'**
  String failedToAccept(String error);

  /// No description provided for @failedToSendProposal.
  ///
  /// In en, this message translates to:
  /// **'Failed to send proposal: {error}'**
  String failedToSendProposal(String error);

  /// No description provided for @failedToSend.
  ///
  /// In en, this message translates to:
  /// **'Failed to send: {error}'**
  String failedToSend(String error);

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About US'**
  String get aboutUs;

  /// No description provided for @paymentGuide.
  ///
  /// In en, this message translates to:
  /// **'Payment guide'**
  String get paymentGuide;

  /// No description provided for @offer.
  ///
  /// In en, this message translates to:
  /// **'Offer'**
  String get offer;

  /// No description provided for @usefulLinks.
  ///
  /// In en, this message translates to:
  /// **'Useful links'**
  String get usefulLinks;

  /// No description provided for @lessonSpaceFinder.
  ///
  /// In en, this message translates to:
  /// **'Lesson Space Finder'**
  String get lessonSpaceFinder;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @whatIsTwingl.
  ///
  /// In en, this message translates to:
  /// **'What is Twingl?'**
  String get whatIsTwingl;

  /// No description provided for @letterFromTwingl.
  ///
  /// In en, this message translates to:
  /// **'Letter from Twingl'**
  String get letterFromTwingl;

  /// No description provided for @leaveTwinglConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave Twingl?'**
  String get leaveTwinglConfirm;

  /// No description provided for @leaveTwinglDialogContentFull.
  ///
  /// In en, this message translates to:
  /// **'Your account will stay, but:\n\n• Your liked list and blocked list will be cleared.\n• Your chat history will be deleted.\n• Your profile will be removed.\n\nAre you sure you want to leave Twingl?'**
  String get leaveTwinglDialogContentFull;

  /// No description provided for @leaveTwinglError.
  ///
  /// In en, this message translates to:
  /// **'Leave Twingl: {error}'**
  String leaveTwinglError(String error);

  /// No description provided for @editMyProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit My Profile'**
  String get editMyProfile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Onboarding'**
  String get onboardingTitle;

  /// No description provided for @addingMoreInfo.
  ///
  /// In en, this message translates to:
  /// **'Adding more info'**
  String get addingMoreInfo;

  /// No description provided for @deleteUser.
  ///
  /// In en, this message translates to:
  /// **'Delete User'**
  String get deleteUser;

  /// No description provided for @removeFromLikedList.
  ///
  /// In en, this message translates to:
  /// **'Remove users from your Liked list'**
  String get removeFromLikedList;

  /// No description provided for @blockUser.
  ///
  /// In en, this message translates to:
  /// **'Block User'**
  String get blockUser;

  /// No description provided for @blockUserDescription.
  ///
  /// In en, this message translates to:
  /// **'Block users so they cannot send you messages'**
  String get blockUserDescription;

  /// No description provided for @unblockUser.
  ///
  /// In en, this message translates to:
  /// **'Unblock User'**
  String get unblockUser;

  /// No description provided for @unblockUserDescription.
  ///
  /// In en, this message translates to:
  /// **'Unblock users so they can message you again'**
  String get unblockUserDescription;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @chatMessages.
  ///
  /// In en, this message translates to:
  /// **'Chat messages'**
  String get chatMessages;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @notificationsOnOff.
  ///
  /// In en, this message translates to:
  /// **'Get notified when you receive new messages'**
  String get notificationsOnOff;

  /// No description provided for @notificationsOff.
  ///
  /// In en, this message translates to:
  /// **'Notifications off'**
  String get notificationsOff;

  /// No description provided for @couldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open link.'**
  String get couldNotOpenLink;

  /// No description provided for @publicLibraries.
  ///
  /// In en, this message translates to:
  /// **'Public Libraries'**
  String get publicLibraries;

  /// No description provided for @schoolFacilities.
  ///
  /// In en, this message translates to:
  /// **'School Facilities'**
  String get schoolFacilities;

  /// No description provided for @creativeStudios.
  ///
  /// In en, this message translates to:
  /// **'Creative Studios'**
  String get creativeStudios;

  /// No description provided for @meetingRooms.
  ///
  /// In en, this message translates to:
  /// **'Meeting Rooms'**
  String get meetingRooms;

  /// No description provided for @theLearner.
  ///
  /// In en, this message translates to:
  /// **'The Learner'**
  String get theLearner;

  /// No description provided for @theLearnerDescription.
  ///
  /// In en, this message translates to:
  /// **'Focus on your growth. Define your goals and find the perfect mentors nearby or globally.'**
  String get theLearnerDescription;

  /// No description provided for @theGuide.
  ///
  /// In en, this message translates to:
  /// **'The Guide'**
  String get theGuide;

  /// No description provided for @theGuideDescription.
  ///
  /// In en, this message translates to:
  /// **'Share your expertise. Turn your talents into value by helping others achieve their dreams.'**
  String get theGuideDescription;

  /// No description provided for @theConnector.
  ///
  /// In en, this message translates to:
  /// **'The Connector'**
  String get theConnector;

  /// No description provided for @theConnectorDescription.
  ///
  /// In en, this message translates to:
  /// **'The ultimate Twingl experience. You teach what you know and learn what you love. You are the heart of our community.'**
  String get theConnectorDescription;

  /// No description provided for @becomeStudentToo.
  ///
  /// In en, this message translates to:
  /// **'Become a Student too'**
  String get becomeStudentToo;

  /// No description provided for @becomeTutorToo.
  ///
  /// In en, this message translates to:
  /// **'Become a Tutor too'**
  String get becomeTutorToo;

  /// No description provided for @becomeStudentTooSubtext.
  ///
  /// In en, this message translates to:
  /// **'Great teachers never stop learning. Expand your perspective by achieving new goals.'**
  String get becomeStudentTooSubtext;

  /// No description provided for @becomeTutorTooSubtext.
  ///
  /// In en, this message translates to:
  /// **'Teaching is the best way to master your skills. Share your talent with neighbors.'**
  String get becomeTutorTooSubtext;

  /// No description provided for @unlockStudentMode.
  ///
  /// In en, this message translates to:
  /// **'Unlock Student Mode'**
  String get unlockStudentMode;

  /// No description provided for @unlockTutorMode.
  ///
  /// In en, this message translates to:
  /// **'Unlock Tutor Mode'**
  String get unlockTutorMode;

  /// No description provided for @twinerBadgeMessage.
  ///
  /// In en, this message translates to:
  /// **'You will get the Twiner badge.'**
  String get twinerBadgeMessage;

  /// No description provided for @starting.
  ///
  /// In en, this message translates to:
  /// **'Starting…'**
  String get starting;

  /// No description provided for @meetTutorsInArea.
  ///
  /// In en, this message translates to:
  /// **'Meet Tutors in your area'**
  String get meetTutorsInArea;

  /// No description provided for @perfectTutorsAnywhere.
  ///
  /// In en, this message translates to:
  /// **'The Perfect Tutors, Anywhere'**
  String get perfectTutorsAnywhere;

  /// No description provided for @fellowTutorsInArea.
  ///
  /// In en, this message translates to:
  /// **'Fellow tutors in the area'**
  String get fellowTutorsInArea;

  /// No description provided for @studentCandidatesInArea.
  ///
  /// In en, this message translates to:
  /// **'Student Candidates in the area'**
  String get studentCandidatesInArea;

  /// No description provided for @noTutorsYet.
  ///
  /// In en, this message translates to:
  /// **'No tutors yet. Like from Meet Tutors or Perfect Tutors.'**
  String get noTutorsYet;

  /// No description provided for @noStudentsYet.
  ///
  /// In en, this message translates to:
  /// **'No students yet. Like from Student Candidates or chat.'**
  String get noStudentsYet;

  /// No description provided for @noFellowsYet.
  ///
  /// In en, this message translates to:
  /// **'No fellows yet. Like from Fellow tutors in the area.'**
  String get noFellowsYet;

  /// No description provided for @noMatchingTalentsFound.
  ///
  /// In en, this message translates to:
  /// **'No matching talents found.'**
  String get noMatchingTalentsFound;

  /// No description provided for @learnShareConnect.
  ///
  /// In en, this message translates to:
  /// **'Learn, Share, and Connect.'**
  String get learnShareConnect;

  /// No description provided for @student.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get student;

  /// No description provided for @tutor.
  ///
  /// In en, this message translates to:
  /// **'Tutor'**
  String get tutor;

  /// No description provided for @twiner.
  ///
  /// In en, this message translates to:
  /// **'Twiner'**
  String get twiner;

  /// No description provided for @twinglIdentity.
  ///
  /// In en, this message translates to:
  /// **'Twingl Identity'**
  String get twinglIdentity;

  /// No description provided for @leaveTwinglSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clear liked, blocked, chat history'**
  String get leaveTwinglSubtitle;

  /// No description provided for @failedToStartConversion.
  ///
  /// In en, this message translates to:
  /// **'Failed to start conversion: {error}'**
  String failedToStartConversion(String error);

  /// No description provided for @man.
  ///
  /// In en, this message translates to:
  /// **'Man'**
  String get man;

  /// No description provided for @woman.
  ///
  /// In en, this message translates to:
  /// **'Woman'**
  String get woman;

  /// No description provided for @nonBinary.
  ///
  /// In en, this message translates to:
  /// **'Non-binary'**
  String get nonBinary;

  /// No description provided for @preferNotToSay.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get preferNotToSay;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get copyLink;

  /// No description provided for @iCanTeach.
  ///
  /// In en, this message translates to:
  /// **'I can teach'**
  String get iCanTeach;

  /// No description provided for @iWantToLearn.
  ///
  /// In en, this message translates to:
  /// **'I want to learn'**
  String get iWantToLearn;

  /// No description provided for @tutoringRate.
  ///
  /// In en, this message translates to:
  /// **'Tutoring rate'**
  String get tutoringRate;

  /// No description provided for @superClose.
  ///
  /// In en, this message translates to:
  /// **'Super close'**
  String get superClose;

  /// No description provided for @kmAway.
  ///
  /// In en, this message translates to:
  /// **'{km} km away'**
  String kmAway(int km);

  /// No description provided for @onlineOnsite.
  ///
  /// In en, this message translates to:
  /// **'Online, Onsite'**
  String get onlineOnsite;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @onsite.
  ///
  /// In en, this message translates to:
  /// **'Onsite'**
  String get onsite;

  /// No description provided for @noMoreMatches.
  ///
  /// In en, this message translates to:
  /// **'No more matches'**
  String get noMoreMatches;

  /// No description provided for @noMoreNearbyResults.
  ///
  /// In en, this message translates to:
  /// **'No more nearby results'**
  String get noMoreNearbyResults;

  /// No description provided for @noNearbyTalentFound.
  ///
  /// In en, this message translates to:
  /// **'No nearby talent found.'**
  String get noNearbyTalentFound;

  /// No description provided for @tapRefreshToFindMore.
  ///
  /// In en, this message translates to:
  /// **'Tap refresh to find more talent matches.'**
  String get tapRefreshToFindMore;

  /// No description provided for @tapRefreshToSearchAgain.
  ///
  /// In en, this message translates to:
  /// **'Tap refresh to search again.'**
  String get tapRefreshToSearchAgain;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @failedToSave.
  ///
  /// In en, this message translates to:
  /// **'Failed to save: {error}'**
  String failedToSave(String error);

  /// No description provided for @profileDetails.
  ///
  /// In en, this message translates to:
  /// **'Profile Details'**
  String get profileDetails;

  /// No description provided for @aboutMe.
  ///
  /// In en, this message translates to:
  /// **'About me'**
  String get aboutMe;

  /// No description provided for @aboutTheLesson.
  ///
  /// In en, this message translates to:
  /// **'About the lesson'**
  String get aboutTheLesson;

  /// No description provided for @lessonLocation.
  ///
  /// In en, this message translates to:
  /// **'Lesson location'**
  String get lessonLocation;

  /// No description provided for @lessonFeePerHour.
  ///
  /// In en, this message translates to:
  /// **'Lesson Fee: {amount}/hour'**
  String lessonFeePerHour(String amount);

  /// No description provided for @parentParticipationWelcomed.
  ///
  /// In en, this message translates to:
  /// **'Parent participation welcomed'**
  String get parentParticipationWelcomed;

  /// No description provided for @parentParticipationNotSpecified.
  ///
  /// In en, this message translates to:
  /// **'Parent participation not specified'**
  String get parentParticipationNotSpecified;

  /// No description provided for @unableToGenerateProfileLink.
  ///
  /// In en, this message translates to:
  /// **'Unable to generate profile link.'**
  String get unableToGenerateProfileLink;

  /// No description provided for @profileLinkCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Profile link copied to clipboard!'**
  String get profileLinkCopiedToClipboard;

  /// No description provided for @failedToShare.
  ///
  /// In en, this message translates to:
  /// **'Failed to share: {error}'**
  String failedToShare(String error);

  /// No description provided for @unableToSendRequest.
  ///
  /// In en, this message translates to:
  /// **'Unable to send request.'**
  String get unableToSendRequest;

  /// No description provided for @sent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get sent;

  /// No description provided for @failedToSendRequest.
  ///
  /// In en, this message translates to:
  /// **'Failed to send request: {error}'**
  String failedToSendRequest(String error);

  /// No description provided for @sendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send Request'**
  String get sendRequest;

  /// No description provided for @declinedWithReason.
  ///
  /// In en, this message translates to:
  /// **'Declined: {reason}'**
  String declinedWithReason(String reason);

  /// No description provided for @addToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Add to '**
  String get addToCalendar;

  /// No description provided for @invalidDateInProposal.
  ///
  /// In en, this message translates to:
  /// **'Invalid date in this proposal'**
  String get invalidDateInProposal;

  /// No description provided for @addedToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Added to calendar'**
  String get addedToCalendar;

  /// No description provided for @failedToAddToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Failed to add to calendar: {error}'**
  String failedToAddToCalendar(String error);

  /// No description provided for @locationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Santa Teresa Library, Zoom'**
  String get locationHint;

  /// No description provided for @tabTutors.
  ///
  /// In en, this message translates to:
  /// **'Tutors'**
  String get tabTutors;

  /// No description provided for @tabStudents.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get tabStudents;

  /// No description provided for @tabFellows.
  ///
  /// In en, this message translates to:
  /// **'Fellows'**
  String get tabFellows;

  /// No description provided for @likedSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Liked'**
  String get likedSectionTitle;

  /// No description provided for @myDetails.
  ///
  /// In en, this message translates to:
  /// **'My Details'**
  String get myDetails;

  /// No description provided for @myActivityStats.
  ///
  /// In en, this message translates to:
  /// **'My Activity Stats'**
  String get myActivityStats;

  /// No description provided for @statsViews.
  ///
  /// In en, this message translates to:
  /// **'Views'**
  String get statsViews;

  /// No description provided for @statsLiked.
  ///
  /// In en, this message translates to:
  /// **'Liked'**
  String get statsLiked;

  /// No description provided for @statsRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get statsRequests;

  /// No description provided for @statsRequesteds.
  ///
  /// In en, this message translates to:
  /// **'Requesteds'**
  String get statsRequesteds;

  /// No description provided for @requestTraining.
  ///
  /// In en, this message translates to:
  /// **'Request Training'**
  String get requestTraining;

  /// No description provided for @chatHistory.
  ///
  /// In en, this message translates to:
  /// **'Chat history'**
  String get chatHistory;

  /// No description provided for @selectSkillAndMethod.
  ///
  /// In en, this message translates to:
  /// **'Select the skill and method you want to learn'**
  String get selectSkillAndMethod;

  /// No description provided for @whatToLearn.
  ///
  /// In en, this message translates to:
  /// **'What to learn'**
  String get whatToLearn;

  /// No description provided for @chatHistoryWith.
  ///
  /// In en, this message translates to:
  /// **'Chat history with {name}'**
  String chatHistoryWith(String name);

  /// No description provided for @noChatHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No chat history yet'**
  String get noChatHistoryYet;

  /// No description provided for @noLikedUsers.
  ///
  /// In en, this message translates to:
  /// **'No liked users.'**
  String get noLikedUsers;

  /// No description provided for @noUsersToBlockFromLikedList.
  ///
  /// In en, this message translates to:
  /// **'No users to block from your liked list.'**
  String get noUsersToBlockFromLikedList;

  /// No description provided for @noBlockedUsers.
  ///
  /// In en, this message translates to:
  /// **'No blocked users.'**
  String get noBlockedUsers;

  /// No description provided for @removeFromLiked.
  ///
  /// In en, this message translates to:
  /// **'Remove from Liked'**
  String get removeFromLiked;

  /// No description provided for @blockSelected.
  ///
  /// In en, this message translates to:
  /// **'Block selected'**
  String get blockSelected;

  /// No description provided for @unblockSelected.
  ///
  /// In en, this message translates to:
  /// **'Unblock selected'**
  String get unblockSelected;

  /// No description provided for @selectAtLeastOneUser.
  ///
  /// In en, this message translates to:
  /// **'Select at least one user'**
  String get selectAtLeastOneUser;

  /// No description provided for @removeUsersFromLikedConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {count} user(s) from your Liked list?'**
  String removeUsersFromLikedConfirm(int count);

  /// No description provided for @blockUsersConfirm.
  ///
  /// In en, this message translates to:
  /// **'Block {count} user(s)? They will not be able to send you messages.'**
  String blockUsersConfirm(int count);

  /// No description provided for @unblockUsersConfirm.
  ///
  /// In en, this message translates to:
  /// **'Unblock {count} user(s)? They will be able to message you again.'**
  String unblockUsersConfirm(int count);

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @someActionsFailed.
  ///
  /// In en, this message translates to:
  /// **'Some actions failed. Please try again.'**
  String get someActionsFailed;

  /// No description provided for @usersUpdated.
  ///
  /// In en, this message translates to:
  /// **'{count} user(s) updated'**
  String usersUpdated(int count);

  /// No description provided for @roleAndBasicInfo.
  ///
  /// In en, this message translates to:
  /// **'Role & Basic info'**
  String get roleAndBasicInfo;

  /// No description provided for @demoModeRandomData.
  ///
  /// In en, this message translates to:
  /// **'Demo mode: random data is filled (photos skipped).'**
  String get demoModeRandomData;

  /// No description provided for @regenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get regenerate;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @birthdate.
  ///
  /// In en, this message translates to:
  /// **'Birthdate'**
  String get birthdate;

  /// No description provided for @ageLabel.
  ///
  /// In en, this message translates to:
  /// **'Age: {age}'**
  String ageLabel(String age);

  /// No description provided for @aboutMeOptional.
  ///
  /// In en, this message translates to:
  /// **'About me (optional)'**
  String get aboutMeOptional;

  /// No description provided for @tellOthersAboutYou.
  ///
  /// In en, this message translates to:
  /// **'Tell others about you…'**
  String get tellOthersAboutYou;

  /// No description provided for @whatDoYouWantToLearn.
  ///
  /// In en, this message translates to:
  /// **'What do you want to learn?'**
  String get whatDoYouWantToLearn;

  /// No description provided for @whatCanYouTeach.
  ///
  /// In en, this message translates to:
  /// **'What can you teach?'**
  String get whatCanYouTeach;

  /// No description provided for @selectTopicsHint.
  ///
  /// In en, this message translates to:
  /// **'Select 1–6.'**
  String get selectTopicsHint;

  /// No description provided for @lessonInfo.
  ///
  /// In en, this message translates to:
  /// **'Lesson info'**
  String get lessonInfo;

  /// No description provided for @aboutTheLessonOptional.
  ///
  /// In en, this message translates to:
  /// **'About the lesson (optional)'**
  String get aboutTheLessonOptional;

  /// No description provided for @shareLessonDetails.
  ///
  /// In en, this message translates to:
  /// **'Share lesson details, expectations, goals…'**
  String get shareLessonDetails;

  /// No description provided for @lessonLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Lesson Location (required)'**
  String get lessonLocationRequired;

  /// No description provided for @tutoringRatePerHourRequired.
  ///
  /// In en, this message translates to:
  /// **'Tutoring Rate per Hour (required)'**
  String get tutoringRatePerHourRequired;

  /// No description provided for @parentParticipationOptional.
  ///
  /// In en, this message translates to:
  /// **'Parent participation welcomed (optional)'**
  String get parentParticipationOptional;

  /// No description provided for @profilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get profilePhoto;

  /// No description provided for @profilePhotoRequired.
  ///
  /// In en, this message translates to:
  /// **'Profile photo (required)'**
  String get profilePhotoRequired;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addPhoto;

  /// No description provided for @waivers.
  ///
  /// In en, this message translates to:
  /// **'Waivers'**
  String get waivers;

  /// No description provided for @waiversRequiredBeforeFinishing.
  ///
  /// In en, this message translates to:
  /// **'Required before finishing.'**
  String get waiversRequiredBeforeFinishing;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @selectBirthdate.
  ///
  /// In en, this message translates to:
  /// **'Select birthdate'**
  String get selectBirthdate;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required.'**
  String get nameRequired;

  /// No description provided for @birthdateRequired.
  ///
  /// In en, this message translates to:
  /// **'Birthdate is required.'**
  String get birthdateRequired;

  /// No description provided for @selectAtLeastOneTopic.
  ///
  /// In en, this message translates to:
  /// **'Please select at least 1 topic.'**
  String get selectAtLeastOneTopic;

  /// No description provided for @selectLessonLocation.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one lesson location (Online/Onsite).'**
  String get selectLessonLocation;

  /// No description provided for @tutoringRateRequired.
  ///
  /// In en, this message translates to:
  /// **'Tutoring rate per hour is required.'**
  String get tutoringRateRequired;

  /// No description provided for @tutoringRateMustBeNumber.
  ///
  /// In en, this message translates to:
  /// **'Tutoring rate must be a number.'**
  String get tutoringRateMustBeNumber;

  /// No description provided for @selectAtLeastOneTopicToLearn.
  ///
  /// In en, this message translates to:
  /// **'Please select at least 1 topic for what you want to learn.'**
  String get selectAtLeastOneTopicToLearn;

  /// No description provided for @selectOneProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Please select 1 profile photo (required).'**
  String get selectOneProfilePhoto;

  /// No description provided for @pleaseAgreeToTutorWaiver.
  ///
  /// In en, this message translates to:
  /// **'Please agree to the Tutor waiver.'**
  String get pleaseAgreeToTutorWaiver;

  /// No description provided for @pleaseAgreeToStudentWaiver.
  ///
  /// In en, this message translates to:
  /// **'Please agree to the Student waiver.'**
  String get pleaseAgreeToStudentWaiver;

  /// No description provided for @parentalConsentRequiredForMinors.
  ///
  /// In en, this message translates to:
  /// **'Parental consent is required for minors.'**
  String get parentalConsentRequiredForMinors;

  /// No description provided for @notLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'You are not logged in.'**
  String get notLoggedIn;

  /// No description provided for @failedToSaveProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to save profile: {error}'**
  String failedToSaveProfile(String error);

  /// No description provided for @failedToPickPhoto.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick photo: {error}'**
  String failedToPickPhoto(String error);

  /// No description provided for @tutorWaiverTitle.
  ///
  /// In en, this message translates to:
  /// **'Tutor Agreement & Liability Waiver'**
  String get tutorWaiverTitle;

  /// No description provided for @tutorWaiverText.
  ///
  /// In en, this message translates to:
  /// **'Professional Conduct: I certify that the information provided in my profile regarding my skills and qualifications is accurate and truthful. I agree to conduct all sessions with professionalism and respect.\n\nIndependent Status: I understand that Twingl is a matching platform and I am not an employee, agent, or contractor of Twingl. I am solely responsible for my actions and the content of my sessions.\n\nSafety & Zero Tolerance: I agree to adhere to Twingl\'s strict safety guidelines. I understand that any form of harassment, discrimination, or inappropriate behavior will result in immediate termination of my account and potential legal action.\n\nRelease of Liability: I hereby release and hold harmless Twingl, its owners, and affiliates from any and all liability, claims, or demands arising out of my participation as a tutor.'**
  String get tutorWaiverText;

  /// No description provided for @studentWaiverTitle.
  ///
  /// In en, this message translates to:
  /// **'Student Assumption of Risk & Waiver'**
  String get studentWaiverTitle;

  /// No description provided for @studentWaiverText.
  ///
  /// In en, this message translates to:
  /// **'Voluntary Participation: I am voluntarily participating in activities (running, learning sessions, etc.) connected through Twingl.\n\nAssumption of Risk: I understand that certain activities, particularly physical ones like running or hiking, carry inherent risks of injury. I knowingly assume all such risks, both known and unknown.\n\nPersonal Responsibility: I acknowledge that Twingl does not conduct background checks on every user and I am responsible for taking necessary safety precautions when meeting others.\n\nWaiver of Claims: I waive any right to sue Twingl or its affiliates for any injury, loss, or damage associated with my participation.'**
  String get studentWaiverText;

  /// No description provided for @parentalConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Parental Consent & Guardian Release'**
  String get parentalConsentTitle;

  /// No description provided for @parentalConsentText.
  ///
  /// In en, this message translates to:
  /// **'Guardian Authority: I represent that I am the parent or legal guardian of the minor registering for Twingl.\n\nConsent to Participate: I hereby give permission for my child to participate in activities and connect with other users on Twingl.\n\nSupervision & Responsibility: I understand that Twingl is an open community platform. I agree to supervise my child\'s use of the app and assume full responsibility for their safety and actions.\n\nEmergency Medical Treatment: In the event of an emergency during a Twingl-related activity, I authorize necessary medical treatment for my child if I cannot be reached.'**
  String get parentalConsentText;

  /// No description provided for @agreeToTutorWaiverCheckbox.
  ///
  /// In en, this message translates to:
  /// **'I have read and agree to the Tutor Agreement & Liability Waiver'**
  String get agreeToTutorWaiverCheckbox;

  /// No description provided for @agreeToStudentWaiverCheckbox.
  ///
  /// In en, this message translates to:
  /// **'I have read and agree to the Student Assumption of Risk & Waiver'**
  String get agreeToStudentWaiverCheckbox;

  /// No description provided for @agreeToParentalConsentCheckbox.
  ///
  /// In en, this message translates to:
  /// **'I have read and agree to the Parental Consent & Guardian Release'**
  String get agreeToParentalConsentCheckbox;

  /// No description provided for @parentalConsentOnlyForMinors.
  ///
  /// In en, this message translates to:
  /// **'Parental consent is only required for minors (under 18).'**
  String get parentalConsentOnlyForMinors;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'ja',
    'ko',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
