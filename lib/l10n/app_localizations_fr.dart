// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get hello => 'Bonjour le monde';

  @override
  String get notSignedIn => 'Non connecté';

  @override
  String accountDeletionFailed(int statusCode) {
    return 'Échec de la suppression du compte ($statusCode)';
  }

  @override
  String get noAuthenticatedUserFound => 'Aucun utilisateur connecté';

  @override
  String get noRowsDeletedCheckMatchesRls =>
      'Aucune ligne supprimée. Vérifier la politique RLS DELETE des correspondances.';

  @override
  String get userNotAuthenticated => 'Utilisateur non connecté';

  @override
  String requestMessage(String skill, String method) {
    return 'Demande : $skill ($method)';
  }

  @override
  String get schedulePromptMessage =>
      'Discutez de vos disponibilités, du lieu et des tarifs pour commencer.';

  @override
  String get unknownName => 'Inconnu';

  @override
  String get systemDefault => 'Par défaut (système)';

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
  String get support => 'Assistance';

  @override
  String get verification => 'Vérification';

  @override
  String get language => 'Langue';

  @override
  String get help => 'Aide';

  @override
  String get terms => 'Conditions';

  @override
  String get invalidProfileLink => 'Lien de profil invalide';

  @override
  String anonymousLoginFailed(String error) {
    return 'Connexion anonyme impossible : $error';
  }

  @override
  String get signInWithSocialLogin => 'Se connecter avec un réseau social';

  @override
  String get signInWithGoogle => 'Se connecter avec Google';

  @override
  String get leaveTwingl => 'Quitter Twingl';

  @override
  String get leaveTwinglDialogMessage =>
      'Tes favoris, ta liste de blocage et ton historique de chat seront effacés, et ton profil sera supprimé. Ton compte restera actif.';

  @override
  String get no => 'Non';

  @override
  String get yes => 'Oui';

  @override
  String failedToLeaveTwingl(String error) {
    return 'Impossible de quitter Twingl : $error';
  }

  @override
  String get generalSettings => 'Réglages généraux';

  @override
  String get clearLikedBlockedChatHistory =>
      'Effacer favoris, blocages et historique de chat';

  @override
  String get requestDeclinedMessage =>
      'Ta demande a été refusée. Tu peux en envoyer une nouvelle quand tu veux.';

  @override
  String get considerAnotherTutor =>
      'Tu peux aussi chercher un autre tuteur ou une autre tutrice.';

  @override
  String get paymentIntro =>
      'Twingl te met en relation avec des gens près de chez toi ; nous ne gérons pas les paiements. Le service reste gratuit et 100 % va au tuteur ou à la tutrice.';

  @override
  String get paymentAgreeMethod =>
      'Mettez-vous d’accord sur un moyen de paiement qui vous convient, par exemple :';

  @override
  String get paymentVenmoZellePaypal => 'Venmo / Zelle / PayPal';

  @override
  String get paymentCash => 'Espèces';

  @override
  String get paymentCoffeeOrMeal =>
      'Café ou repas (pour des séances informelles)';

  @override
  String get paymentNoteSafety =>
      'Pour la sécurité, nous recommandons de payer après vous être rencontrés en personne.';

  @override
  String get paymentTipOnline =>
      'Pour les cours en ligne, pensez à PayPal pour la protection acheteur ou au paiement 50/50.';

  @override
  String get unread => 'Non lus';

  @override
  String get howDoIPayForLessons => 'Comment payer les cours ?';

  @override
  String get chatOnlyAfterAccept =>
      'Le chat n’est disponible qu’après l’acceptation de ta première demande de cours. Merci d’attendre.';

  @override
  String get declineReason => 'Motif du refus';

  @override
  String get whyDecliningHint => 'Pourquoi refuses-tu ?';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get block => 'Bloquer';

  @override
  String get removeFromFavoriteTitle => 'Retirer des favoris';

  @override
  String get removeFromFavoriteConfirmMessage =>
      'Retirer cette personne de tes favoris ?';

  @override
  String get blockUserConfirmMessage =>
      'Bloquer cet utilisateur ? Tu ne recevras plus ses demandes de cours.';

  @override
  String get send => 'Envoyer';

  @override
  String get declined => 'Refusé';

  @override
  String failedToDecline(String error) {
    return 'Échec du refus : $error';
  }

  @override
  String get decline => 'Refuser';

  @override
  String get accept => 'Accepter';

  @override
  String get request => 'Demande';

  @override
  String failedToLoadProfile(String error) {
    return 'Impossible de charger le profil : $error';
  }

  @override
  String get profileNotFound => 'Profil introuvable';

  @override
  String get addedToLiked => 'Ajouté aux favoris';

  @override
  String get waitingForAccept => 'En attente d’acceptation';

  @override
  String get declinedStatus => 'Refusé';

  @override
  String get messageHint => 'Message…';

  @override
  String get scheduling => 'Planification';

  @override
  String get locationLabel => 'Lieu';

  @override
  String get sendProposal => 'Envoyer la proposition';

  @override
  String get acceptedChatNow => 'Accepté. Vous pouvez discuter maintenant.';

  @override
  String failedToAccept(String error) {
    return 'Échec de l’acceptation : $error';
  }

  @override
  String failedToSendProposal(String error) {
    return 'Échec de l’envoi de la proposition : $error';
  }

  @override
  String failedToSend(String error) {
    return 'Échec de l’envoi : $error';
  }

  @override
  String get gotIt => 'Compris';

  @override
  String get more => 'Plus';

  @override
  String get aboutUs => 'À propos';

  @override
  String get paymentGuide => 'Guide des paiements';

  @override
  String get offer => 'Offre';

  @override
  String get usefulLinks => 'Liens utiles';

  @override
  String get lessonSpaceFinder => 'Trouver un lieu pour les cours';

  @override
  String get notifications => 'Notifications';

  @override
  String get account => 'Compte';

  @override
  String get whatIsTwingl => 'Qu’est-ce que Twingl ?';

  @override
  String get letterFromTwingl => 'Une lettre de Twingl';

  @override
  String get leaveTwinglConfirm => 'Es-tu sûr de vouloir quitter Twingl ?';

  @override
  String get leaveTwinglDialogContentFull =>
      'Ton compte restera actif, mais :\n\n• Tes favoris et ta liste de blocage seront effacés.\n• Ton historique de chat sera supprimé.\n• Ton profil sera supprimé.\n\nEs-tu sûr de vouloir quitter Twingl ?';

  @override
  String leaveTwinglError(String error) {
    return 'Quitter Twingl : $error';
  }

  @override
  String get editMyProfile => 'Modifier mon profil';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String get onboardingTitle => 'Inscription';

  @override
  String get addingMoreInfo => 'Ajouter des infos';

  @override
  String get deleteUser => 'Supprimer un utilisateur';

  @override
  String get removeFromLikedList => 'Retirer des utilisateurs de tes favoris';

  @override
  String get blockUser => 'Bloquer un utilisateur';

  @override
  String get blockUserDescription =>
      'Les utilisateurs bloqués ne peuvent pas t’envoyer de messages';

  @override
  String get unblockUser => 'Débloquer un utilisateur';

  @override
  String get unblockUserDescription =>
      'Les utilisateurs débloqués pourront à nouveau t’envoyer des messages';

  @override
  String get logOut => 'Se déconnecter';

  @override
  String get chatMessages => 'Messages du chat';

  @override
  String get chat => 'Chat';

  @override
  String get notificationsOnOff => 'Être notifié des nouveaux messages';

  @override
  String get notificationsOff => 'Notifications désactivées';

  @override
  String get couldNotOpenLink => 'Impossible d’ouvrir le lien.';

  @override
  String get publicLibraries => 'Bibliothèques publiques';

  @override
  String get schoolFacilities => 'Locaux scolaires';

  @override
  String get creativeStudios => 'Studios créatifs';

  @override
  String get meetingRooms => 'Salles de réunion';

  @override
  String get theLearner => 'L’apprenant';

  @override
  String get theLearnerDescription =>
      'Concentre-toi sur ta progression. Définis tes objectifs et trouve les mentors qu’il te faut, près de chez toi ou ailleurs.';

  @override
  String get theGuide => 'Le guide';

  @override
  String get theGuideDescription =>
      'Partage ton savoir. Mets tes talents au service des autres pour les aider à réaliser leurs objectifs.';

  @override
  String get theConnector => 'Le connecteur';

  @override
  String get theConnectorDescription =>
      'L’expérience Twingl complète : tu enseignes ce que tu sais et tu apprends ce que tu aimes. Tu es au cœur de notre communauté.';

  @override
  String get becomeStudentToo => 'Devenir aussi apprenant';

  @override
  String get becomeTutorToo => 'Devenir aussi tuteur';

  @override
  String get becomeStudentTooSubtext =>
      'Les bons professeurs n\'arrêtent jamais d\'apprendre. Élargis ta perspective en atteignant de nouveaux objectifs.';

  @override
  String get becomeTutorTooSubtext =>
      'Enseigner est la meilleure façon de maîtriser tes compétences. Partage ton talent avec ton entourage.';

  @override
  String get unlockStudentMode => 'Activer le mode apprenant';

  @override
  String get unlockTutorMode => 'Activer le mode tuteur';

  @override
  String get twinerBadgeMessage => 'Tu obtiendras le badge Twiner.';

  @override
  String get starting => 'Démarrage…';

  @override
  String get meetTutorsInArea => 'Rencontrer des tuteurs près de chez toi';

  @override
  String get perfectTutorsAnywhere => 'Les tuteurs qu’il te faut, partout';

  @override
  String get fellowTutorsInArea => 'Tuteurs près de chez toi';

  @override
  String get studentCandidatesInArea => 'Apprenants près de chez toi';

  @override
  String get noTutorsYet =>
      'Pas encore de tuteurs. Ajoute des favoris via Rencontrer des tuteurs ou Les tuteurs qu\'il te faut.';

  @override
  String get noStudentsYet =>
      'Pas encore d\'apprenants. Ajoute des favoris via Apprenants près de chez toi ou le chat.';

  @override
  String get noFellowsYet =>
      'Pas encore de tuteurs près de chez toi. Ajoute des favoris via Tuteurs près de chez toi.';

  @override
  String get noMatchingTalentsFound => 'Aucun talent trouvé.';

  @override
  String get learnShareConnect => 'Apprendre, partager, connecter.';

  @override
  String get student => 'Apprenant';

  @override
  String get tutor => 'Tuteur';

  @override
  String get twiner => 'Twiner';

  @override
  String get twinglIdentity => 'Identité Twingl';

  @override
  String get leaveTwinglSubtitle =>
      'Effacer favoris, blocages et historique de chat';

  @override
  String failedToStartConversion(String error) {
    return 'Échec du changement : $error';
  }

  @override
  String get man => 'Homme';

  @override
  String get woman => 'Femme';

  @override
  String get nonBinary => 'Non binaire';

  @override
  String get preferNotToSay => 'Je ne souhaite pas répondre';

  @override
  String get share => 'Partager';

  @override
  String get copyLink => 'Copier le lien';

  @override
  String get iCanTeach => 'Je peux enseigner';

  @override
  String get iWantToLearn => 'Je veux apprendre';

  @override
  String get tutoringRate => 'Tarif';

  @override
  String get superClose => 'Tout près';

  @override
  String kmAway(int km) {
    return 'À $km km';
  }

  @override
  String get onlineOnsite => 'En ligne, En présentiel';

  @override
  String get online => 'En ligne';

  @override
  String get onsite => 'En présentiel';

  @override
  String get noMoreMatches => 'Plus de correspondances';

  @override
  String get noMoreNearbyResults => 'Plus de résultats à proximité';

  @override
  String get noNearbyTalentFound => 'Aucun talent trouvé à proximité.';

  @override
  String get tapRefreshToFindMore =>
      'Appuie sur Actualiser pour trouver d\'autres talents.';

  @override
  String get tapRefreshToSearchAgain =>
      'Appuie sur Actualiser pour rechercher à nouveau.';

  @override
  String get refresh => 'Actualiser';

  @override
  String failedToSave(String error) {
    return 'Échec de l\'enregistrement : $error';
  }

  @override
  String get profileDetails => 'Profil';

  @override
  String get aboutMe => 'À propos de moi';

  @override
  String get aboutTheLesson => 'À propos du cours';

  @override
  String get lessonLocation => 'Lieu du cours';

  @override
  String lessonFeePerHour(String amount) {
    return 'Tarif : $amount/h';
  }

  @override
  String get parentParticipationWelcomed =>
      'Participation des parents bienvenue';

  @override
  String get parentParticipationNotSpecified =>
      'Participation des parents non précisée';

  @override
  String get unableToGenerateProfileLink =>
      'Impossible de générer le lien du profil.';

  @override
  String get profileLinkCopiedToClipboard =>
      'Lien copié dans le presse-papiers !';

  @override
  String failedToShare(String error) {
    return 'Échec du partage : $error';
  }

  @override
  String get unableToSendRequest => 'Impossible d\'envoyer la demande.';

  @override
  String get sent => 'Envoyé';

  @override
  String failedToSendRequest(String error) {
    return 'Échec de l\'envoi de la demande : $error';
  }

  @override
  String get sendRequest => 'Envoyer la demande';

  @override
  String declinedWithReason(String reason) {
    return 'Refusé : $reason';
  }

  @override
  String get addToCalendar => 'Ajouter à ';

  @override
  String get invalidDateInProposal => 'Date invalide dans cette proposition';

  @override
  String get addedToCalendar => 'Ajouté au calendrier';

  @override
  String failedToAddToCalendar(String error) {
    return 'Échec de l\'ajout au calendrier : $error';
  }

  @override
  String get locationHint => 'ex. Bibliothèque Santa Teresa, Zoom';

  @override
  String get tabTutors => 'Tuteurs';

  @override
  String get tabStudents => 'Apprenants';

  @override
  String get tabFellows => 'Tuteurs à proximité';

  @override
  String get likedSectionTitle => 'Favoris';

  @override
  String get myDetails => 'Mes infos';

  @override
  String get myActivityStats => 'Mes statistiques';

  @override
  String get statsViews => 'Vues';

  @override
  String get statsLiked => 'Favoris';

  @override
  String get statsRequests => 'Demandes';

  @override
  String get statsRequesteds => 'Demandés';

  @override
  String get requestTraining => 'Demander un cours';

  @override
  String get chatHistory => 'Historique du chat';

  @override
  String get selectSkillAndMethod =>
      'Choisis la compétence et la méthode que tu veux apprendre';

  @override
  String get whatToLearn => 'Ce que tu veux apprendre';

  @override
  String chatHistoryWith(String name) {
    return 'Historique du chat avec $name';
  }

  @override
  String get noChatHistoryYet => 'Pas encore d\'historique de chat';

  @override
  String get noLikedUsers => 'Aucun favori.';

  @override
  String get noUsersToBlockFromLikedList =>
      'Aucun utilisateur à bloquer dans tes favoris.';

  @override
  String get noBlockedUsers => 'Aucun utilisateur bloqué.';

  @override
  String get removeFromLiked => 'Retirer des favoris';

  @override
  String get blockSelected => 'Bloquer la sélection';

  @override
  String get unblockSelected => 'Débloquer la sélection';

  @override
  String get selectAtLeastOneUser => 'Sélectionne au moins un utilisateur';

  @override
  String removeUsersFromLikedConfirm(int count) {
    return 'Retirer $count utilisateur(s) de tes favoris ?';
  }

  @override
  String blockUsersConfirm(int count) {
    return 'Bloquer $count utilisateur(s) ? Ils ne pourront plus t\'envoyer de messages.';
  }

  @override
  String unblockUsersConfirm(int count) {
    return 'Débloquer $count utilisateur(s) ? Ils pourront à nouveau t\'écrire.';
  }

  @override
  String get confirm => 'Confirmer';

  @override
  String get someActionsFailed => 'Certaines actions ont échoué. Réessaie.';

  @override
  String usersUpdated(int count) {
    return '$count utilisateur(s) mis à jour';
  }

  @override
  String get roleAndBasicInfo => 'Rôle et infos de base';

  @override
  String get demoModeRandomData =>
      'Mode démo : des données aléatoires sont remplies (photos ignorées).';

  @override
  String get regenerate => 'Régénérer';

  @override
  String get name => 'Nom';

  @override
  String get gender => 'Genre';

  @override
  String get birthdate => 'Date de naissance';

  @override
  String ageLabel(String age) {
    return 'Âge : $age';
  }

  @override
  String get aboutMeOptional => 'À propos de moi (optionnel)';

  @override
  String get tellOthersAboutYou => 'Parle de toi aux autres…';

  @override
  String get whatDoYouWantToLearn => 'Que veux-tu apprendre ?';

  @override
  String get whatCanYouTeach => 'Que peux-tu enseigner ?';

  @override
  String get selectTopicsHint => 'Choisis 1 à 6.';

  @override
  String get lessonInfo => 'Infos cours';

  @override
  String get aboutTheLessonOptional => 'À propos du cours (optionnel)';

  @override
  String get shareLessonDetails => 'Partage détails, attentes, objectifs…';

  @override
  String get lessonLocationRequired => 'Lieu du cours (obligatoire)';

  @override
  String get tutoringRatePerHourRequired => 'Tarif horaire (obligatoire)';

  @override
  String get parentParticipationOptional =>
      'Participation du parent bienvenue (optionnel)';

  @override
  String get profilePhoto => 'Photo de profil';

  @override
  String get profilePhotoRequired => 'Photo de profil (obligatoire)';

  @override
  String get addPhoto => 'Ajouter une photo';

  @override
  String get waivers => 'Déclarations';

  @override
  String get waiversRequiredBeforeFinishing => 'Obligatoire avant de terminer.';

  @override
  String get back => 'Retour';

  @override
  String get next => 'Suivant';

  @override
  String get save => 'Enregistrer';

  @override
  String get finish => 'Terminer';

  @override
  String get selectBirthdate => 'Choisir la date de naissance';

  @override
  String get nameRequired => 'Le nom est obligatoire.';

  @override
  String get birthdateRequired => 'La date de naissance est obligatoire.';

  @override
  String get selectAtLeastOneTopic => 'Choisis au moins 1 thème.';

  @override
  String get selectLessonLocation =>
      'Choisis au moins un lieu (En ligne/Sur place).';

  @override
  String get tutoringRateRequired => 'Le tarif horaire est obligatoire.';

  @override
  String get tutoringRateMustBeNumber => 'Le tarif doit être un nombre.';

  @override
  String get selectAtLeastOneTopicToLearn =>
      'Choisis au moins 1 thème à apprendre.';

  @override
  String get selectOneProfilePhoto =>
      'Choisis 1 photo de profil (obligatoire).';

  @override
  String get pleaseAgreeToTutorWaiver =>
      'Veuille accepter la déclaration tuteur.';

  @override
  String get pleaseAgreeToStudentWaiver =>
      'Veuille accepter la déclaration élève.';

  @override
  String get parentalConsentRequiredForMinors =>
      'Le consentement parental est requis pour les mineurs.';

  @override
  String get notLoggedIn => 'Tu n\'es pas connecté.';

  @override
  String failedToSaveProfile(String error) {
    return 'Échec de l\'enregistrement du profil : $error';
  }

  @override
  String failedToPickPhoto(String error) {
    return 'Échec du choix de la photo : $error';
  }

  @override
  String get tutorWaiverTitle =>
      'Accord tuteur et renonciation à responsabilité';

  @override
  String get tutorWaiverText =>
      'Conduite professionnelle : Je certifie que les informations de mon profil concernant mes compétences et qualifications sont exactes. Je m\'engage à mener toutes les séances avec professionnalisme et respect.\n\nStatut indépendant : Je comprends que Twingl est une plateforme de mise en relation et que je ne suis pas employé, agent ou prestataire de Twingl. Je suis seul responsable de mes actes et du contenu de mes séances.\n\nSécurité et tolérance zéro : Je m\'engage à respecter les règles de sécurité strictes de Twingl. Je comprends que tout harcèlement, discrimination ou comportement inapproprié entraînera la résiliation immédiate de mon compte et d\'éventuelles poursuites.\n\nRenonciation à responsabilité : Je dégage Twingl, ses propriétaires et affiliés de toute responsabilité, réclamation ou demande découlant de ma participation en tant que tuteur.';

  @override
  String get studentWaiverTitle =>
      'Acceptation des risques et renonciation élève';

  @override
  String get studentWaiverText =>
      'Participation volontaire : Je participe volontairement à des activités (course, séances d\'apprentissage, etc.) proposées via Twingl.\n\nAcceptation des risques : Je comprends que certaines activités, notamment physiques (course, randonnée), comportent des risques de blessure. J\'assume en connaissance de cause tous ces risques, connus et inconnus.\n\nResponsabilité personnelle : Je reconnais que Twingl ne vérifie pas les antécédents de tous les utilisateurs et que je suis responsable des précautions de sécurité lors des rencontres.\n\nRenonciation aux réclamations : Je renonce à tout droit de poursuivre Twingl ou ses affiliés pour blessure, perte ou dommage lié à ma participation.';

  @override
  String get parentalConsentTitle =>
      'Consentement parental et décharge du tuteur';

  @override
  String get parentalConsentText =>
      'Autorité du tuteur : Je déclare être le parent ou tuteur légal du mineur inscrit sur Twingl.\n\nConsentement à la participation : J\'autorise mon enfant à participer aux activités et à échanger avec d\'autres utilisateurs sur Twingl.\n\nSupervision et responsabilité : Je comprends que Twingl est une plateforme communautaire ouverte. Je m\'engage à superviser l\'utilisation de l\'application par mon enfant et assume l\'entière responsabilité de sa sécurité et de ses actes.\n\nTraitement médical d\'urgence : En cas d\'urgence lors d\'une activité Twingl, j\'autorise les soins médicaux nécessaires pour mon enfant si je ne peux pas être joint.';

  @override
  String get agreeToTutorWaiverCheckbox =>
      'J\'ai lu et j\'accepte l\'Accord tuteur et la renonciation à responsabilité';

  @override
  String get agreeToStudentWaiverCheckbox =>
      'J\'ai lu et j\'accepte l\'Acceptation des risques et la renonciation élève';

  @override
  String get agreeToParentalConsentCheckbox =>
      'J\'ai lu et j\'accepte le Consentement parental et la décharge du tuteur';

  @override
  String get parentalConsentOnlyForMinors =>
      'Le consentement parental n\'est requis que pour les mineurs (moins de 18 ans).';
}
