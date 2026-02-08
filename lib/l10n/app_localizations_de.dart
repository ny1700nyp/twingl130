// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get hello => 'Hallo Welt';

  @override
  String get notSignedIn => 'Nicht angemeldet';

  @override
  String accountDeletionFailed(int statusCode) {
    return 'Kontolöschung fehlgeschlagen ($statusCode)';
  }

  @override
  String get noAuthenticatedUserFound => 'Kein angemeldeter Benutzer gefunden';

  @override
  String get noRowsDeletedCheckMatchesRls =>
      'Keine Zeilen gelöscht. RLS-DELETE-Richtlinie für Matches prüfen.';

  @override
  String get userNotAuthenticated => 'Benutzer nicht angemeldet';

  @override
  String requestMessage(String skill, String method) {
    return 'Anfrage: $skill ($method)';
  }

  @override
  String get schedulePromptMessage =>
      'Bitte besprecht Verfügbarkeit, Ort und Konditionen, um loszulegen.';

  @override
  String get unknownName => 'Unbekannt';

  @override
  String get systemDefault => 'Systemstandard';

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
  String get verification => 'Verifizierung';

  @override
  String get language => 'Sprache';

  @override
  String get help => 'Hilfe';

  @override
  String get terms => 'AGB';

  @override
  String get invalidProfileLink => 'Ungültiger Profillink';

  @override
  String anonymousLoginFailed(String error) {
    return 'Anonymer Login fehlgeschlagen: $error';
  }

  @override
  String get signInWithSocialLogin => 'Mit Social Login anmelden';

  @override
  String get signInWithGoogle => 'Mit Google anmelden';

  @override
  String get leaveTwingl => 'Twingl verlassen';

  @override
  String get leaveTwinglDialogMessage =>
      'Deine Favoritenliste, Blockierliste und der Chatverlauf werden gelöscht, dein Profil wird entfernt. Dein Konto bleibt bestehen.';

  @override
  String get no => 'Nein';

  @override
  String get yes => 'Ja';

  @override
  String failedToLeaveTwingl(String error) {
    return 'Twingl verlassen fehlgeschlagen: $error';
  }

  @override
  String get generalSettings => 'Allgemeine Einstellungen';

  @override
  String get clearLikedBlockedChatHistory =>
      'Favoriten, Blockierliste und Chatverlauf löschen';

  @override
  String get requestDeclinedMessage =>
      'Deine Anfrage wurde abgelehnt. Du kannst jederzeit eine neue Anfrage senden.';

  @override
  String get considerAnotherTutor =>
      'Du kannst auch einen anderen Tutor oder eine andere Tutorin suchen.';

  @override
  String get paymentIntro =>
      'Twingl verbindet dich mit Menschen in deiner Nähe – wir bearbeiten keine Zahlungen. So bleibt unser Service kostenlos und 100 % der Gebühr geht an deinen Tutor bzw. deine Tutorin!';

  @override
  String get paymentAgreeMethod =>
      'Einigt euch auf eine passende Zahlungsart, z. B.:';

  @override
  String get paymentVenmoZellePaypal => 'Venmo / Zelle / PayPal';

  @override
  String get paymentCash => 'Bargeld';

  @override
  String get paymentCoffeeOrMeal => 'Kaffee oder Essen (bei lockeren Treffen)';

  @override
  String get paymentNoteSafety =>
      'Hinweis: Aus Sicherheitsgründen empfehlen wir die Zahlung nach dem persönlichen Treffen.';

  @override
  String get paymentTipOnline =>
      'Tipp: Bei Online-Stunden PayPal für Käuferschutz nutzen oder die 50/50-Methode.';

  @override
  String get unread => 'Ungelesen';

  @override
  String get howDoIPayForLessons => 'Wie bezahle ich den Unterricht?';

  @override
  String get chatOnlyAfterAccept =>
      'Der Chat ist erst verfügbar, wenn deine erste Unterrichtsanfrage angenommen wurde. Bitte warte.';

  @override
  String get declineReason => 'Ablehnungsgrund';

  @override
  String get whyDecliningHint => 'Warum lehnst du ab?';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String get block => 'Blockieren';

  @override
  String get removeFromFavoriteTitle => 'Aus Favoriten entfernen';

  @override
  String get removeFromFavoriteConfirmMessage =>
      'Diese Person aus deiner Favoritenliste entfernen?';

  @override
  String get blockUserConfirmMessage =>
      'Diesen Nutzer blockieren? Du erhältst keine Unterrichtsanfragen mehr von dieser Person.';

  @override
  String get send => 'Senden';

  @override
  String get declined => 'Abgelehnt';

  @override
  String failedToDecline(String error) {
    return 'Ablehnen fehlgeschlagen: $error';
  }

  @override
  String get decline => 'Ablehnen';

  @override
  String get accept => 'Annehmen';

  @override
  String get request => 'Anfrage';

  @override
  String failedToLoadProfile(String error) {
    return 'Profil konnte nicht geladen werden: $error';
  }

  @override
  String get profileNotFound => 'Profil nicht gefunden';

  @override
  String get addedToLiked => 'Zu Favoriten hinzugefügt';

  @override
  String get waitingForAccept => 'Warte auf Annahme';

  @override
  String get declinedStatus => 'Abgelehnt';

  @override
  String get messageHint => 'Nachricht …';

  @override
  String get scheduling => 'Terminplanung';

  @override
  String get locationLabel => 'Ort';

  @override
  String get sendProposal => 'Vorschlag senden';

  @override
  String get acceptedChatNow => 'Angenommen. Ihr könnt jetzt chatten.';

  @override
  String failedToAccept(String error) {
    return 'Annehmen fehlgeschlagen: $error';
  }

  @override
  String failedToSendProposal(String error) {
    return 'Vorschlag senden fehlgeschlagen: $error';
  }

  @override
  String failedToSend(String error) {
    return 'Senden fehlgeschlagen: $error';
  }

  @override
  String get gotIt => 'Verstanden';

  @override
  String get more => 'Mehr';

  @override
  String get aboutUs => 'Über uns';

  @override
  String get paymentGuide => 'Zahlungshinweise';

  @override
  String get offer => 'Angebot';

  @override
  String get usefulLinks => 'Nützliche Links';

  @override
  String get lessonSpaceFinder => 'Raum für Unterricht finden';

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get account => 'Konto';

  @override
  String get whatIsTwingl => 'Was ist Twingl?';

  @override
  String get letterFromTwingl => 'Ein Brief von Twingl';

  @override
  String get leaveTwinglConfirm => 'Möchtest du Twingl wirklich verlassen?';

  @override
  String get leaveTwinglDialogContentFull =>
      'Dein Konto bleibt bestehen, aber:\n\n• Deine Favoriten- und Blockierliste werden gelöscht.\n• Dein Chatverlauf wird gelöscht.\n• Dein Profil wird entfernt.\n\nMöchtest du Twingl wirklich verlassen?';

  @override
  String leaveTwinglError(String error) {
    return 'Twingl verlassen: $error';
  }

  @override
  String get editMyProfile => 'Profil bearbeiten';

  @override
  String get editProfile => 'Profil bearbeiten';

  @override
  String get onboardingTitle => 'Onboarding';

  @override
  String get addingMoreInfo => 'Weitere Infos hinzufügen';

  @override
  String get deleteUser => 'Nutzer entfernen';

  @override
  String get removeFromLikedList =>
      'Nutzer aus deiner Favoritenliste entfernen';

  @override
  String get blockUser => 'Nutzer blockieren';

  @override
  String get blockUserDescription =>
      'Blockierte Nutzer können dir keine Nachrichten senden';

  @override
  String get unblockUser => 'Nutzer entsperren';

  @override
  String get unblockUserDescription =>
      'Entsperrte Nutzer können dir wieder schreiben';

  @override
  String get logOut => 'Abmelden';

  @override
  String get chatMessages => 'Chat-Nachrichten';

  @override
  String get chat => 'Chat';

  @override
  String get notificationsOnOff => 'Benachrichtigung bei neuen Nachrichten';

  @override
  String get notificationsOff => 'Benachrichtigungen aus';

  @override
  String get couldNotOpenLink => 'Link konnte nicht geöffnet werden.';

  @override
  String get publicLibraries => 'Öffentliche Bibliotheken';

  @override
  String get schoolFacilities => 'Schulräume';

  @override
  String get creativeStudios => 'Kreativstudios';

  @override
  String get meetingRooms => 'Meetingräume';

  @override
  String get theLearner => 'Der Lernende';

  @override
  String get theLearnerDescription =>
      'Fokussiere dich auf dein Wachstum. Definiere deine Ziele und finde passende Mentoren in deiner Nähe oder weltweit.';

  @override
  String get theGuide => 'Der Guide';

  @override
  String get theGuideDescription =>
      'Teile dein Wissen. Hilf anderen, ihre Ziele zu erreichen, und schaffe so Mehrwert aus deinen Talenten.';

  @override
  String get theConnector => 'Der Connector';

  @override
  String get theConnectorDescription =>
      'Das volle Twingl-Erlebnis: Du gibst weiter, was du kannst, und lernst, was du liebst. Du bist das Herz unserer Community.';

  @override
  String get becomeStudentToo => 'Auch Lernender werden';

  @override
  String get becomeTutorToo => 'Auch Tutor werden';

  @override
  String get becomeStudentTooSubtext =>
      'Gute Lehrer hören nie auf zu lernen. Erweitere deinen Blickwinkel durch neue Ziele.';

  @override
  String get becomeTutorTooSubtext =>
      'Lehren ist der beste Weg, deine Fähigkeiten zu meistern. Teile dein Talent mit Nachbarn.';

  @override
  String get unlockStudentMode => 'Lernenden-Modus freischalten';

  @override
  String get unlockTutorMode => 'Tutor-Modus freischalten';

  @override
  String get twinerBadgeMessage => 'Du erhältst das Twiner-Abzeichen.';

  @override
  String get starting => 'Wird gestartet …';

  @override
  String get meetTutorsInArea => 'Tutoren in deiner Nähe finden';

  @override
  String get perfectTutorsAnywhere => 'Die passenden Tutoren – überall';

  @override
  String get fellowTutorsInArea => 'Tutoren in deiner Nähe';

  @override
  String get studentCandidatesInArea => 'Lernende in deiner Nähe';

  @override
  String get noTutorsYet =>
      'Noch keine Tutoren. Finde welche unter Tutoren in deiner Nähe oder Die passenden Tutoren – überall.';

  @override
  String get noStudentsYet =>
      'Noch keine Lernenden. Finde welche unter Lernende in deiner Nähe oder im Chat.';

  @override
  String get noFellowsYet =>
      'Noch keine Fellow-Tutoren. Finde welche unter Tutoren in deiner Nähe.';

  @override
  String get noMatchingTalentsFound => 'Keine passenden Talente gefunden.';

  @override
  String get learnShareConnect => 'Lernen, teilen, verbinden.';

  @override
  String get student => 'Lernender';

  @override
  String get tutor => 'Tutor';

  @override
  String get twiner => 'Twiner';

  @override
  String get twinglIdentity => 'Twingl-Identität';

  @override
  String get leaveTwinglSubtitle =>
      'Favoriten, Blockierliste und Chatverlauf löschen';

  @override
  String failedToStartConversion(String error) {
    return 'Umstellung fehlgeschlagen: $error';
  }

  @override
  String get man => 'Mann';

  @override
  String get woman => 'Frau';

  @override
  String get nonBinary => 'Nicht-binär';

  @override
  String get preferNotToSay => 'Keine Angabe';

  @override
  String get share => 'Teilen';

  @override
  String get copyLink => 'Link kopieren';

  @override
  String get iCanTeach => 'Das kann ich unterrichten';

  @override
  String get iWantToLearn => 'Das möchte ich lernen';

  @override
  String get tutoringRate => 'Stundensatz';

  @override
  String get superClose => 'Ganz in der Nähe';

  @override
  String kmAway(int km) {
    return '$km km entfernt';
  }

  @override
  String get onlineOnsite => 'Online, Vor Ort';

  @override
  String get online => 'Online';

  @override
  String get onsite => 'Vor Ort';

  @override
  String get noMoreMatches => 'Keine weiteren Treffer';

  @override
  String get noMoreNearbyResults => 'Keine weiteren Ergebnisse in der Nähe';

  @override
  String get noNearbyTalentFound => 'In der Nähe wurde kein Talent gefunden.';

  @override
  String get tapRefreshToFindMore =>
      'Tippe auf Aktualisieren, um weitere Talente zu finden.';

  @override
  String get tapRefreshToSearchAgain =>
      'Tippe auf Aktualisieren, um erneut zu suchen.';

  @override
  String get refresh => 'Aktualisieren';

  @override
  String failedToSave(String error) {
    return 'Speichern fehlgeschlagen: $error';
  }

  @override
  String get profileDetails => 'Profil';

  @override
  String get aboutMe => 'Über mich';

  @override
  String get aboutTheLesson => 'Über die Stunde';

  @override
  String get lessonLocation => 'Unterrichtsort';

  @override
  String lessonFeePerHour(String amount) {
    return 'Stundensatz: $amount/Std.';
  }

  @override
  String get parentParticipationWelcomed => 'Elternbeteiligung willkommen';

  @override
  String get parentParticipationNotSpecified =>
      'Elternbeteiligung nicht angegeben';

  @override
  String get unableToGenerateProfileLink =>
      'Profillink konnte nicht erstellt werden.';

  @override
  String get profileLinkCopiedToClipboard =>
      'Profillink in die Zwischenablage kopiert!';

  @override
  String failedToShare(String error) {
    return 'Teilen fehlgeschlagen: $error';
  }

  @override
  String get unableToSendRequest => 'Anfrage konnte nicht gesendet werden.';

  @override
  String get sent => 'Gesendet';

  @override
  String failedToSendRequest(String error) {
    return 'Anfrage senden fehlgeschlagen: $error';
  }

  @override
  String get sendRequest => 'Anfrage senden';

  @override
  String declinedWithReason(String reason) {
    return 'Abgelehnt: $reason';
  }

  @override
  String get addToCalendar => 'In Kalender ';

  @override
  String get invalidDateInProposal => 'Ungültiges Datum in diesem Vorschlag';

  @override
  String get addedToCalendar => 'Zum Kalender hinzugefügt';

  @override
  String failedToAddToCalendar(String error) {
    return 'Kalender hinzufügen fehlgeschlagen: $error';
  }

  @override
  String get locationHint => 'z. B. Stadtbibliothek, Zoom';

  @override
  String get tabTutors => 'Tutoren';

  @override
  String get tabStudents => 'Lernende';

  @override
  String get tabFellows => 'Tutoren in der Nähe';

  @override
  String get likedSectionTitle => 'Favoriten';

  @override
  String get myDetails => 'Meine Angaben';

  @override
  String get myActivityStats => 'Meine Aktivitätsstatistik';

  @override
  String get statsViews => 'Aufrufe';

  @override
  String get statsLiked => 'Favoriten';

  @override
  String get statsRequests => 'Anfragen';

  @override
  String get statsRequesteds => 'Angefragt';

  @override
  String get requestTraining => 'Training anfragen';

  @override
  String get chatHistory => 'Chat-Verlauf';

  @override
  String get selectSkillAndMethod =>
      'Wähle die Fähigkeit und Methode, die du lernen möchtest';

  @override
  String get whatToLearn => 'Was möchtest du lernen';

  @override
  String chatHistoryWith(String name) {
    return 'Chat-Verlauf mit $name';
  }

  @override
  String get noChatHistoryYet => 'Noch kein Chat-Verlauf';

  @override
  String get noLikedUsers => 'Keine Favoriten.';

  @override
  String get noUsersToBlockFromLikedList =>
      'Keine Nutzer zum Blockieren in deiner Favoritenliste.';

  @override
  String get noBlockedUsers => 'Keine blockierten Nutzer.';

  @override
  String get removeFromLiked => 'Aus Favoriten entfernen';

  @override
  String get blockSelected => 'Ausgewählte blockieren';

  @override
  String get unblockSelected => 'Ausgewählte entsperren';

  @override
  String get selectAtLeastOneUser => 'Wähle mindestens einen Nutzer';

  @override
  String removeUsersFromLikedConfirm(int count) {
    return '$count Nutzer aus deiner Favoritenliste entfernen?';
  }

  @override
  String blockUsersConfirm(int count) {
    return '$count Nutzer blockieren? Sie können dir keine Nachrichten mehr senden.';
  }

  @override
  String unblockUsersConfirm(int count) {
    return '$count Nutzer entsperren? Sie können dir wieder schreiben.';
  }

  @override
  String get confirm => 'Bestätigen';

  @override
  String get someActionsFailed =>
      'Einige Aktionen sind fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String usersUpdated(int count) {
    return '$count Nutzer aktualisiert';
  }

  @override
  String get roleAndBasicInfo => 'Rolle & Grundangaben';

  @override
  String get demoModeRandomData =>
      'Demo-Modus: Zufallsdaten werden ausgefüllt (Fotos übersprungen).';

  @override
  String get regenerate => 'Erneut generieren';

  @override
  String get name => 'Name';

  @override
  String get gender => 'Geschlecht';

  @override
  String get birthdate => 'Geburtsdatum';

  @override
  String ageLabel(String age) {
    return 'Alter: $age';
  }

  @override
  String get aboutMeOptional => 'Über mich (optional)';

  @override
  String get tellOthersAboutYou => 'Erzähle anderen von dir…';

  @override
  String get whatDoYouWantToLearn => 'Was möchtest du lernen?';

  @override
  String get whatCanYouTeach => 'Was kannst du unterrichten?';

  @override
  String get selectTopicsHint => 'Wähle 1–6.';

  @override
  String get lessonInfo => 'Unterrichtsinfo';

  @override
  String get aboutTheLessonOptional => 'Über die Unterrichtsstunde (optional)';

  @override
  String get shareLessonDetails => 'Details, Erwartungen, Ziele teilen…';

  @override
  String get lessonLocationRequired => 'Unterrichtsort (Pflicht)';

  @override
  String get tutoringRatePerHourRequired => 'Stundensatz (Pflicht)';

  @override
  String get parentParticipationOptional =>
      'Elternteilnahme willkommen (optional)';

  @override
  String get profilePhoto => 'Profilfoto';

  @override
  String get profilePhotoRequired => 'Profilfoto (Pflicht)';

  @override
  String get addPhoto => 'Foto hinzufügen';

  @override
  String get waivers => 'Einverständniserklärungen';

  @override
  String get waiversRequiredBeforeFinishing =>
      'Vor dem Abschluss erforderlich.';

  @override
  String get back => 'Zurück';

  @override
  String get next => 'Weiter';

  @override
  String get save => 'Speichern';

  @override
  String get finish => 'Fertig';

  @override
  String get selectBirthdate => 'Geburtsdatum wählen';

  @override
  String get nameRequired => 'Name ist erforderlich.';

  @override
  String get birthdateRequired => 'Geburtsdatum ist erforderlich.';

  @override
  String get selectAtLeastOneTopic => 'Bitte wähle mindestens 1 Thema.';

  @override
  String get selectLessonLocation =>
      'Bitte wähle mindestens einen Unterrichtsort (Online/Vor Ort).';

  @override
  String get tutoringRateRequired => 'Stundensatz ist erforderlich.';

  @override
  String get tutoringRateMustBeNumber => 'Stundensatz muss eine Zahl sein.';

  @override
  String get selectAtLeastOneTopicToLearn =>
      'Bitte wähle mindestens 1 Thema zum Lernen.';

  @override
  String get selectOneProfilePhoto => 'Bitte wähle 1 Profilfoto (Pflicht).';

  @override
  String get pleaseAgreeToTutorWaiver =>
      'Bitte stimme der Tutor-Vereinbarung zu.';

  @override
  String get pleaseAgreeToStudentWaiver =>
      'Bitte stimme der Schüler-Einverständniserklärung zu.';

  @override
  String get parentalConsentRequiredForMinors =>
      'Einverständnis der Erziehungsberechtigten für Minderjährige erforderlich.';

  @override
  String get notLoggedIn => 'Du bist nicht angemeldet.';

  @override
  String failedToSaveProfile(String error) {
    return 'Profil konnte nicht gespeichert werden: $error';
  }

  @override
  String failedToPickPhoto(String error) {
    return 'Foto konnte nicht ausgewählt werden: $error';
  }

  @override
  String get tutorWaiverTitle => 'Tutor-Vereinbarung & Haftungsverzicht';

  @override
  String get tutorWaiverText =>
      'Berufliches Verhalten: Ich bestätige, dass die Angaben in meinem Profil zu meinen Fähigkeiten und Qualifikationen wahrheitsgemäß sind. Ich verpflichte mich, alle Sitzungen professionell und respektvoll durchzuführen.\n\nUnabhängiger Status: Ich verstehe, dass Twingl eine Vermittlungsplattform ist und ich kein Angestellter, Vertreter oder Auftragnehmer von Twingl bin. Ich bin allein verantwortlich für mein Handeln und den Inhalt meiner Sitzungen.\n\nSicherheit & Null Toleranz: Ich verpflichte mich, die strengen Sicherheitsrichtlinien von Twingl einzuhalten. Ich verstehe, dass Belästigung, Diskriminierung oder unangemessenes Verhalten zur sofortigen Kündigung meines Kontos und möglichen rechtlichen Schritten führen.\n\nHaftungsverzicht: Ich entbinde Twingl, seine Inhaber und verbundenen Unternehmen von jeglicher Haftung, Ansprüchen oder Forderungen, die aus meiner Teilnahme als Tutor entstehen.';

  @override
  String get studentWaiverTitle => 'Schüler-Risikoübernahme & Verzicht';

  @override
  String get studentWaiverText =>
      'Freiwillige Teilnahme: Ich nehme freiwillig an Aktivitäten (Laufen, Lernsitzungen usw.) teil, die über Twingl vermittelt werden.\n\nRisikoübernahme: Ich verstehe, dass bestimmte Aktivitäten, insbesondere körperliche wie Laufen oder Wandern, inhärente Verletzungsrisiken bergen. Ich übernehme bewusst alle solche Risiken, bekannte und unbekannte.\n\nEigenverantwortung: Ich bestätige, dass Twingl nicht bei jedem Nutzer Hintergrundprüfungen durchführt, und ich bin für notwendige Sicherheitsvorkehrungen beim Treffen mit anderen verantwortlich.\n\nVerzicht auf Ansprüche: Ich verzichte auf das Recht, Twingl oder verbundene Unternehmen wegen Verletzung, Verlust oder Schaden im Zusammenhang mit meiner Teilnahme zu verklagen.';

  @override
  String get parentalConsentTitle =>
      'Einwilligung der Erziehungsberechtigten & Entlastung';

  @override
  String get parentalConsentText =>
      'Vertretungsberechtigung: Ich erkläre, dass ich der Elternteil oder gesetzliche Vormund des minderjährigen Nutzers von Twingl bin.\n\nEinwilligung zur Teilnahme: Ich erteile hiermit die Erlaubnis, dass mein Kind an Aktivitäten auf Twingl teilnimmt und sich mit anderen Nutzern verbindet.\n\nAufsicht & Verantwortung: Ich verstehe, dass Twingl eine offene Community-Plattform ist. Ich verpflichte mich, die Nutzung der App durch mein Kind zu überwachen und übernehme die volle Verantwortung für deren Sicherheit und Handlungen.\n\nNotfallmedizinische Behandlung: Im Notfall während einer Twingl-Aktivität ermächtige ich die erforderliche medizinische Behandlung für mein Kind, wenn ich nicht erreichbar bin.';

  @override
  String get agreeToTutorWaiverCheckbox =>
      'Ich habe die Tutor-Vereinbarung & den Haftungsverzicht gelesen und stimme zu';

  @override
  String get agreeToStudentWaiverCheckbox =>
      'Ich habe die Schüler-Risikoübernahme & den Verzicht gelesen und stimme zu';

  @override
  String get agreeToParentalConsentCheckbox =>
      'Ich habe die Einwilligung der Erziehungsberechtigten & Entlastung gelesen und stimme zu';

  @override
  String get parentalConsentOnlyForMinors =>
      'Einwilligung der Erziehungsberechtigten ist nur für Minderjährige (unter 18) erforderlich.';
}
