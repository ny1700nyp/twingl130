// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get hello => 'Hello World';

  @override
  String get notSignedIn => 'Not signed in';

  @override
  String accountDeletionFailed(int statusCode) {
    return 'Account deletion failed ($statusCode)';
  }

  @override
  String get noAuthenticatedUserFound => 'No authenticated user found';

  @override
  String get noRowsDeletedCheckMatchesRls =>
      'No rows deleted. Check matches RLS DELETE policy.';

  @override
  String get userNotAuthenticated => 'User not authenticated';

  @override
  String requestMessage(String skill, String method) {
    return 'Request: $skill ($method)';
  }

  @override
  String get schedulePromptMessage =>
      'Please discuss your availability, preferred location, and rates to kick things off.';

  @override
  String get unknownName => 'Unknown';

  @override
  String get systemDefault => 'System Default';

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
  String get support => 'Support';

  @override
  String get verification => 'Verification';

  @override
  String get language => 'Language';

  @override
  String get help => 'Help';

  @override
  String get terms => 'Terms';

  @override
  String get invalidProfileLink => 'Invalid profile link';

  @override
  String anonymousLoginFailed(String error) {
    return 'Anonymous login failed: $error';
  }

  @override
  String get signInWithSocialLogin => 'Sign in with social login';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get leaveTwingl => 'Leave Twingl';

  @override
  String get leaveTwinglDialogMessage =>
      'Your liked list, blocked list, and chat history will be cleared, and your profile will be removed. Your account will remain.';

  @override
  String get no => 'No';

  @override
  String get yes => 'Yes';

  @override
  String failedToLeaveTwingl(String error) {
    return 'Failed to leave Twingl: $error';
  }

  @override
  String get generalSettings => 'General Settings';

  @override
  String get clearLikedBlockedChatHistory =>
      'Clear liked, blocked, chat history';

  @override
  String get requestDeclinedMessage =>
      'Your request was declined. Please feel free to send a new request when you\'re ready.';

  @override
  String get considerAnotherTutor =>
      'You might also consider finding another tutor.';

  @override
  String get paymentIntro =>
      'Twingl connects you with neighbors, but we don\'t handle payments directly. This keeps our service free and puts 100% of the fee in your tutor\'s pocket!';

  @override
  String get paymentAgreeMethod =>
      'Please agree on a method that works for both of you, such as:';

  @override
  String get paymentVenmoZellePaypal => 'Venmo / Zelle / PayPal';

  @override
  String get paymentCash => 'Cash';

  @override
  String get paymentCoffeeOrMeal => 'Coffee or Meal (for casual sessions)';

  @override
  String get paymentNoteSafety =>
      'Note: For safety, we recommend paying after meeting in person.';

  @override
  String get paymentTipOnline =>
      'Tip: For online lessons, consider paying via PayPal for buyer protection, or use the 50/50 payment method.';

  @override
  String get unread => 'Unread';

  @override
  String get howDoIPayForLessons => 'How do I pay for lessons?';

  @override
  String get chatOnlyAfterAccept =>
      'Chat is only available after the other person accepts your first class request. Please wait.';

  @override
  String get declineReason => 'Decline reason';

  @override
  String get whyDecliningHint => 'Why are you declining?';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get block => 'Block';

  @override
  String get removeFromFavoriteTitle => 'Remove from Favorite';

  @override
  String get removeFromFavoriteConfirmMessage =>
      'Remove this person from your Liked list?';

  @override
  String get blockUserConfirmMessage =>
      'Block this user? You will not see lesson requests from them.';

  @override
  String get send => 'Send';

  @override
  String get declined => 'Declined';

  @override
  String failedToDecline(String error) {
    return 'Failed to decline: $error';
  }

  @override
  String get decline => 'Decline';

  @override
  String get accept => 'Accept';

  @override
  String get request => 'Request';

  @override
  String failedToLoadProfile(String error) {
    return 'Failed to load profile: $error';
  }

  @override
  String get profileNotFound => 'Profile not found';

  @override
  String get addedToLiked => 'Added to Liked';

  @override
  String get waitingForAccept => 'Waiting for Accept';

  @override
  String get declinedStatus => 'Declined';

  @override
  String get messageHint => 'Message...';

  @override
  String get scheduling => 'Scheduling';

  @override
  String get locationLabel => 'Location';

  @override
  String get sendProposal => 'Send Proposal';

  @override
  String get acceptedChatNow => 'Accepted. You can chat now.';

  @override
  String failedToAccept(String error) {
    return 'Failed to accept: $error';
  }

  @override
  String failedToSendProposal(String error) {
    return 'Failed to send proposal: $error';
  }

  @override
  String failedToSend(String error) {
    return 'Failed to send: $error';
  }

  @override
  String get gotIt => 'Got it';

  @override
  String get more => 'More';

  @override
  String get aboutUs => 'About US';

  @override
  String get paymentGuide => 'Payment guide';

  @override
  String get offer => 'Offer';

  @override
  String get usefulLinks => 'Useful links';

  @override
  String get lessonSpaceFinder => 'Lesson Space Finder';

  @override
  String get notifications => 'Notifications';

  @override
  String get account => 'Account';

  @override
  String get whatIsTwingl => 'What is Twingl?';

  @override
  String get letterFromTwingl => 'Letter from Twingl';

  @override
  String get leaveTwinglConfirm => 'Are you sure you want to leave Twingl?';

  @override
  String get leaveTwinglDialogContentFull =>
      'Your account will stay, but:\n\n• Your liked list and blocked list will be cleared.\n• Your chat history will be deleted.\n• Your profile will be removed.\n\nAre you sure you want to leave Twingl?';

  @override
  String leaveTwinglError(String error) {
    return 'Leave Twingl: $error';
  }

  @override
  String get editMyProfile => 'Edit My Profile';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get onboardingTitle => 'Onboarding';

  @override
  String get addingMoreInfo => 'Adding more info';

  @override
  String get deleteUser => 'Delete User';

  @override
  String get removeFromLikedList => 'Remove users from your Liked list';

  @override
  String get blockUser => 'Block User';

  @override
  String get blockUserDescription =>
      'Block users so they cannot send you messages';

  @override
  String get unblockUser => 'Unblock User';

  @override
  String get unblockUserDescription =>
      'Unblock users so they can message you again';

  @override
  String get logOut => 'Log out';

  @override
  String get chatMessages => 'Chat messages';

  @override
  String get chat => 'Chat';

  @override
  String get notificationsOnOff => 'Get notified when you receive new messages';

  @override
  String get notificationsOff => 'Notifications off';

  @override
  String get couldNotOpenLink => 'Could not open link.';

  @override
  String get publicLibraries => 'Public Libraries';

  @override
  String get schoolFacilities => 'School Facilities';

  @override
  String get creativeStudios => 'Creative Studios';

  @override
  String get meetingRooms => 'Meeting Rooms';

  @override
  String get theLearner => 'The Learner';

  @override
  String get theLearnerDescription =>
      'Focus on your growth. Define your goals and find the perfect mentors nearby or globally.';

  @override
  String get theGuide => 'The Guide';

  @override
  String get theGuideDescription =>
      'Share your expertise. Turn your talents into value by helping others achieve their dreams.';

  @override
  String get theConnector => 'The Connector';

  @override
  String get theConnectorDescription =>
      'The ultimate Twingl experience. You teach what you know and learn what you love. You are the heart of our community.';

  @override
  String get becomeStudentToo => 'Become a Student too';

  @override
  String get becomeTutorToo => 'Become a Tutor too';

  @override
  String get becomeStudentTooSubtext =>
      'Great teachers never stop learning. Expand your perspective by achieving new goals.';

  @override
  String get becomeTutorTooSubtext =>
      'Teaching is the best way to master your skills. Share your talent with neighbors.';

  @override
  String get unlockStudentMode => 'Unlock Student Mode';

  @override
  String get unlockTutorMode => 'Unlock Tutor Mode';

  @override
  String get twinerBadgeMessage => 'You will get the Twiner badge.';

  @override
  String get starting => 'Starting…';

  @override
  String get meetTutorsInArea => 'Meet Tutors in your area';

  @override
  String get perfectTutorsAnywhere => 'The Perfect Tutors, Anywhere';

  @override
  String get fellowTutorsInArea => 'Fellow tutors in the area';

  @override
  String get studentCandidatesInArea => 'Student Candidates in the area';

  @override
  String get noTutorsYet =>
      'No tutors yet. Like from Meet Tutors or Perfect Tutors.';

  @override
  String get noStudentsYet =>
      'No students yet. Like from Student Candidates or chat.';

  @override
  String get noFellowsYet =>
      'No fellows yet. Like from Fellow tutors in the area.';

  @override
  String get noMatchingTalentsFound => 'No matching talents found.';

  @override
  String get learnShareConnect => 'Learn, Share, and Connect.';

  @override
  String get student => 'Student';

  @override
  String get tutor => 'Tutor';

  @override
  String get twiner => 'Twiner';

  @override
  String get twinglIdentity => 'Twingl Identity';

  @override
  String get leaveTwinglSubtitle => 'Clear liked, blocked, chat history';

  @override
  String failedToStartConversion(String error) {
    return 'Failed to start conversion: $error';
  }

  @override
  String get man => 'Man';

  @override
  String get woman => 'Woman';

  @override
  String get nonBinary => 'Non-binary';

  @override
  String get preferNotToSay => 'Prefer not to say';

  @override
  String get share => 'Share';

  @override
  String get copyLink => 'Copy Link';

  @override
  String get iCanTeach => 'I can teach';

  @override
  String get iWantToLearn => 'I want to learn';

  @override
  String get tutoringRate => 'Tutoring rate';

  @override
  String get superClose => 'Super close';

  @override
  String kmAway(int km) {
    return '$km km away';
  }

  @override
  String get onlineOnsite => 'Online, Onsite';

  @override
  String get online => 'Online';

  @override
  String get onsite => 'Onsite';

  @override
  String get noMoreMatches => 'No more matches';

  @override
  String get noMoreNearbyResults => 'No more nearby results';

  @override
  String get noNearbyTalentFound => 'No nearby talent found.';

  @override
  String get tapRefreshToFindMore => 'Tap refresh to find more talent matches.';

  @override
  String get tapRefreshToSearchAgain => 'Tap refresh to search again.';

  @override
  String get refresh => 'Refresh';

  @override
  String failedToSave(String error) {
    return 'Failed to save: $error';
  }

  @override
  String get profileDetails => 'Profile Details';

  @override
  String get aboutMe => 'About me';

  @override
  String get aboutTheLesson => 'About the lesson';

  @override
  String get lessonLocation => 'Lesson location';

  @override
  String lessonFeePerHour(String amount) {
    return 'Lesson Fee: $amount/hour';
  }

  @override
  String get parentParticipationWelcomed => 'Parent participation welcomed';

  @override
  String get parentParticipationNotSpecified =>
      'Parent participation not specified';

  @override
  String get unableToGenerateProfileLink => 'Unable to generate profile link.';

  @override
  String get profileLinkCopiedToClipboard =>
      'Profile link copied to clipboard!';

  @override
  String failedToShare(String error) {
    return 'Failed to share: $error';
  }

  @override
  String get unableToSendRequest => 'Unable to send request.';

  @override
  String get sent => 'Sent';

  @override
  String failedToSendRequest(String error) {
    return 'Failed to send request: $error';
  }

  @override
  String get sendRequest => 'Send Request';

  @override
  String declinedWithReason(String reason) {
    return 'Declined: $reason';
  }

  @override
  String get addToCalendar => 'Add to ';

  @override
  String get invalidDateInProposal => 'Invalid date in this proposal';

  @override
  String get addedToCalendar => 'Added to calendar';

  @override
  String failedToAddToCalendar(String error) {
    return 'Failed to add to calendar: $error';
  }

  @override
  String get locationHint => 'e.g. Santa Teresa Library, Zoom';

  @override
  String get tabTutors => 'Tutors';

  @override
  String get tabStudents => 'Students';

  @override
  String get tabFellows => 'Fellows';

  @override
  String get likedSectionTitle => 'Liked';

  @override
  String get myDetails => 'My Details';

  @override
  String get myActivityStats => 'My Activity Stats';

  @override
  String get statsViews => 'Views';

  @override
  String get statsLiked => 'Liked';

  @override
  String get statsRequests => 'Requests';

  @override
  String get statsRequesteds => 'Requesteds';

  @override
  String get requestTraining => 'Request Training';

  @override
  String get chatHistory => 'Chat history';

  @override
  String get selectSkillAndMethod =>
      'Select the skill and method you want to learn';

  @override
  String get whatToLearn => 'What to learn';

  @override
  String chatHistoryWith(String name) {
    return 'Chat history with $name';
  }

  @override
  String get noChatHistoryYet => 'No chat history yet';

  @override
  String get noLikedUsers => 'No liked users.';

  @override
  String get noUsersToBlockFromLikedList =>
      'No users to block from your liked list.';

  @override
  String get noBlockedUsers => 'No blocked users.';

  @override
  String get removeFromLiked => 'Remove from Liked';

  @override
  String get blockSelected => 'Block selected';

  @override
  String get unblockSelected => 'Unblock selected';

  @override
  String get selectAtLeastOneUser => 'Select at least one user';

  @override
  String removeUsersFromLikedConfirm(int count) {
    return 'Remove $count user(s) from your Liked list?';
  }

  @override
  String blockUsersConfirm(int count) {
    return 'Block $count user(s)? They will not be able to send you messages.';
  }

  @override
  String unblockUsersConfirm(int count) {
    return 'Unblock $count user(s)? They will be able to message you again.';
  }

  @override
  String get confirm => 'Confirm';

  @override
  String get someActionsFailed => 'Some actions failed. Please try again.';

  @override
  String usersUpdated(int count) {
    return '$count user(s) updated';
  }

  @override
  String get roleAndBasicInfo => 'Role & Basic info';

  @override
  String get demoModeRandomData =>
      'Demo mode: random data is filled (photos skipped).';

  @override
  String get regenerate => 'Regenerate';

  @override
  String get name => 'Name';

  @override
  String get gender => 'Gender';

  @override
  String get birthdate => 'Birthdate';

  @override
  String ageLabel(String age) {
    return 'Age: $age';
  }

  @override
  String get aboutMeOptional => 'About me (optional)';

  @override
  String get tellOthersAboutYou => 'Tell others about you…';

  @override
  String get whatDoYouWantToLearn => 'What do you want to learn?';

  @override
  String get whatCanYouTeach => 'What can you teach?';

  @override
  String get selectTopicsHint => 'Select 1–6.';

  @override
  String get lessonInfo => 'Lesson info';

  @override
  String get aboutTheLessonOptional => 'About the lesson (optional)';

  @override
  String get shareLessonDetails => 'Share lesson details, expectations, goals…';

  @override
  String get lessonLocationRequired => 'Lesson Location (required)';

  @override
  String get tutoringRatePerHourRequired => 'Tutoring Rate per Hour (required)';

  @override
  String get parentParticipationOptional =>
      'Parent participation welcomed (optional)';

  @override
  String get profilePhoto => 'Profile photo';

  @override
  String get profilePhotoRequired => 'Profile photo (required)';

  @override
  String get addPhoto => 'Add photo';

  @override
  String get waivers => 'Waivers';

  @override
  String get waiversRequiredBeforeFinishing => 'Required before finishing.';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get save => 'Save';

  @override
  String get finish => 'Finish';

  @override
  String get selectBirthdate => 'Select birthdate';

  @override
  String get nameRequired => 'Name is required.';

  @override
  String get birthdateRequired => 'Birthdate is required.';

  @override
  String get selectAtLeastOneTopic => 'Please select at least 1 topic.';

  @override
  String get selectLessonLocation =>
      'Please select at least one lesson location (Online/Onsite).';

  @override
  String get tutoringRateRequired => 'Tutoring rate per hour is required.';

  @override
  String get tutoringRateMustBeNumber => 'Tutoring rate must be a number.';

  @override
  String get selectAtLeastOneTopicToLearn =>
      'Please select at least 1 topic for what you want to learn.';

  @override
  String get selectOneProfilePhoto =>
      'Please select 1 profile photo (required).';

  @override
  String get pleaseAgreeToTutorWaiver => 'Please agree to the Tutor waiver.';

  @override
  String get pleaseAgreeToStudentWaiver =>
      'Please agree to the Student waiver.';

  @override
  String get parentalConsentRequiredForMinors =>
      'Parental consent is required for minors.';

  @override
  String get notLoggedIn => 'You are not logged in.';

  @override
  String failedToSaveProfile(String error) {
    return 'Failed to save profile: $error';
  }

  @override
  String failedToPickPhoto(String error) {
    return 'Failed to pick photo: $error';
  }

  @override
  String get tutorWaiverTitle => 'Tutor Agreement & Liability Waiver';

  @override
  String get tutorWaiverText =>
      'Professional Conduct: I certify that the information provided in my profile regarding my skills and qualifications is accurate and truthful. I agree to conduct all sessions with professionalism and respect.\n\nIndependent Status: I understand that Twingl is a matching platform and I am not an employee, agent, or contractor of Twingl. I am solely responsible for my actions and the content of my sessions.\n\nSafety & Zero Tolerance: I agree to adhere to Twingl\'s strict safety guidelines. I understand that any form of harassment, discrimination, or inappropriate behavior will result in immediate termination of my account and potential legal action.\n\nRelease of Liability: I hereby release and hold harmless Twingl, its owners, and affiliates from any and all liability, claims, or demands arising out of my participation as a tutor.';

  @override
  String get studentWaiverTitle => 'Student Assumption of Risk & Waiver';

  @override
  String get studentWaiverText =>
      'Voluntary Participation: I am voluntarily participating in activities (running, learning sessions, etc.) connected through Twingl.\n\nAssumption of Risk: I understand that certain activities, particularly physical ones like running or hiking, carry inherent risks of injury. I knowingly assume all such risks, both known and unknown.\n\nPersonal Responsibility: I acknowledge that Twingl does not conduct background checks on every user and I am responsible for taking necessary safety precautions when meeting others.\n\nWaiver of Claims: I waive any right to sue Twingl or its affiliates for any injury, loss, or damage associated with my participation.';

  @override
  String get parentalConsentTitle => 'Parental Consent & Guardian Release';

  @override
  String get parentalConsentText =>
      'Guardian Authority: I represent that I am the parent or legal guardian of the minor registering for Twingl.\n\nConsent to Participate: I hereby give permission for my child to participate in activities and connect with other users on Twingl.\n\nSupervision & Responsibility: I understand that Twingl is an open community platform. I agree to supervise my child\'s use of the app and assume full responsibility for their safety and actions.\n\nEmergency Medical Treatment: In the event of an emergency during a Twingl-related activity, I authorize necessary medical treatment for my child if I cannot be reached.';

  @override
  String get agreeToTutorWaiverCheckbox =>
      'I have read and agree to the Tutor Agreement & Liability Waiver';

  @override
  String get agreeToStudentWaiverCheckbox =>
      'I have read and agree to the Student Assumption of Risk & Waiver';

  @override
  String get agreeToParentalConsentCheckbox =>
      'I have read and agree to the Parental Consent & Guardian Release';

  @override
  String get parentalConsentOnlyForMinors =>
      'Parental consent is only required for minors (under 18).';
}
