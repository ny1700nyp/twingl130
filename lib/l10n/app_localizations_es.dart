// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get hello => 'Hola Mundo';

  @override
  String get notSignedIn => 'No has iniciado sesión';

  @override
  String accountDeletionFailed(int statusCode) {
    return 'Error al eliminar la cuenta ($statusCode)';
  }

  @override
  String get noAuthenticatedUserFound =>
      'No se encontró ningún usuario autenticado';

  @override
  String get noRowsDeletedCheckMatchesRls =>
      'No se eliminaron filas. Revisa la política RLS DELETE de coincidencias.';

  @override
  String get userNotAuthenticated => 'Usuario no autenticado';

  @override
  String requestMessage(String skill, String method) {
    return 'Solicitud: $skill ($method)';
  }

  @override
  String get schedulePromptMessage =>
      'Hablen de disponibilidad, lugar y tarifas para empezar.';

  @override
  String get unknownName => 'Desconocido';

  @override
  String get systemDefault => 'Predeterminado del sistema';

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
  String get support => 'Ayuda';

  @override
  String get verification => 'Verificación';

  @override
  String get language => 'Idioma';

  @override
  String get help => 'Ayuda';

  @override
  String get terms => 'Términos';

  @override
  String get invalidProfileLink => 'Enlace de perfil no válido';

  @override
  String anonymousLoginFailed(String error) {
    return 'Error al iniciar sesión de forma anónima: $error';
  }

  @override
  String get signInWithSocialLogin => 'Iniciar sesión con redes sociales';

  @override
  String get signInWithGoogle => 'Iniciar sesión con Google';

  @override
  String get leaveTwingl => 'Salir de Twingl';

  @override
  String get leaveTwinglDialogMessage =>
      'Se borrarán tus favoritos, bloqueados e historial de chat, y se eliminará tu perfil. Tu cuenta se mantendrá.';

  @override
  String get no => 'No';

  @override
  String get yes => 'Sí';

  @override
  String failedToLeaveTwingl(String error) {
    return 'Error al salir de Twingl: $error';
  }

  @override
  String get generalSettings => 'Ajustes generales';

  @override
  String get clearLikedBlockedChatHistory =>
      'Borrar favoritos, bloqueados e historial de chat';

  @override
  String get requestDeclinedMessage =>
      'Tu solicitud fue rechazada. Puedes enviar una nueva cuando quieras.';

  @override
  String get considerAnotherTutor =>
      'También puedes buscar otro tutor o tutora.';

  @override
  String get paymentIntro =>
      'Twingl te conecta con gente cerca de ti; no gestionamos pagos. Así el servicio es gratis y el 100 % va al tutor o tutora.';

  @override
  String get paymentAgreeMethod =>
      'Pónganse de acuerdo en un método que les vaya bien, por ejemplo:';

  @override
  String get paymentVenmoZellePaypal => 'Venmo / Zelle / PayPal';

  @override
  String get paymentCash => 'Efectivo';

  @override
  String get paymentCoffeeOrMeal => 'Café o comida (para sesiones informales)';

  @override
  String get paymentNoteSafety =>
      'Nota: Por seguridad, recomendamos pagar después de quedar en persona.';

  @override
  String get paymentTipOnline =>
      'Consejo: Para clases online, considera PayPal por protección al comprador o el método 50/50.';

  @override
  String get unread => 'No leídos';

  @override
  String get howDoIPayForLessons => '¿Cómo pago las clases?';

  @override
  String get chatOnlyAfterAccept =>
      'El chat solo está disponible cuando acepten tu primera solicitud de clase. Espera, por favor.';

  @override
  String get declineReason => 'Motivo del rechazo';

  @override
  String get whyDecliningHint => '¿Por qué rechazas?';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get block => 'Bloquear';

  @override
  String get removeFromFavoriteTitle => 'Quitar de Favoritos';

  @override
  String get removeFromFavoriteConfirmMessage =>
      '¿Quitar a esta persona de tu lista de Favoritos?';

  @override
  String get blockUserConfirmMessage =>
      '¿Bloquear a este usuario? No verás solicitudes de clase suyas.';

  @override
  String get send => 'Enviar';

  @override
  String get declined => 'Rechazado';

  @override
  String failedToDecline(String error) {
    return 'Error al rechazar: $error';
  }

  @override
  String get decline => 'Rechazar';

  @override
  String get accept => 'Aceptar';

  @override
  String get request => 'Solicitud';

  @override
  String failedToLoadProfile(String error) {
    return 'Error al cargar el perfil: $error';
  }

  @override
  String get profileNotFound => 'Perfil no encontrado';

  @override
  String get addedToLiked => 'Añadido a Favoritos';

  @override
  String get waitingForAccept => 'Esperando aceptación';

  @override
  String get declinedStatus => 'Rechazado';

  @override
  String get messageHint => 'Mensaje…';

  @override
  String get scheduling => 'Programación';

  @override
  String get locationLabel => 'Lugar';

  @override
  String get sendProposal => 'Enviar propuesta';

  @override
  String get acceptedChatNow => 'Aceptado. Ya pueden chatear.';

  @override
  String failedToAccept(String error) {
    return 'Error al aceptar: $error';
  }

  @override
  String failedToSendProposal(String error) {
    return 'Error al enviar la propuesta: $error';
  }

  @override
  String failedToSend(String error) {
    return 'Error al enviar: $error';
  }

  @override
  String get gotIt => 'Entendido';

  @override
  String get more => 'Más';

  @override
  String get aboutUs => 'Sobre nosotros';

  @override
  String get paymentGuide => 'Guía de pagos';

  @override
  String get offer => 'Oferta';

  @override
  String get usefulLinks => 'Enlaces útiles';

  @override
  String get lessonSpaceFinder => 'Buscar espacio para clases';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get account => 'Cuenta';

  @override
  String get whatIsTwingl => '¿Qué es Twingl?';

  @override
  String get letterFromTwingl => 'Una carta de Twingl';

  @override
  String get leaveTwinglConfirm => '¿Seguro que quieres salir de Twingl?';

  @override
  String get leaveTwinglDialogContentFull =>
      'Tu cuenta se mantendrá, pero:\n\n• Se borrarán tus favoritos y tu lista de bloqueados.\n• Se eliminará tu historial de chat.\n• Se eliminará tu perfil.\n\n¿Seguro que quieres salir de Twingl?';

  @override
  String leaveTwinglError(String error) {
    return 'Salir de Twingl: $error';
  }

  @override
  String get editMyProfile => 'Editar mi perfil';

  @override
  String get editProfile => 'Editar perfil';

  @override
  String get onboardingTitle => 'Registro';

  @override
  String get addingMoreInfo => 'Añadir más información';

  @override
  String get deleteUser => 'Eliminar usuario';

  @override
  String get removeFromLikedList => 'Quitar usuarios de tu lista de favoritos';

  @override
  String get blockUser => 'Bloquear usuario';

  @override
  String get blockUserDescription =>
      'Los usuarios bloqueados no pueden enviarte mensajes';

  @override
  String get unblockUser => 'Desbloquear usuario';

  @override
  String get unblockUserDescription =>
      'Los usuarios desbloqueados podrán enviarte mensajes de nuevo';

  @override
  String get logOut => 'Cerrar sesión';

  @override
  String get chatMessages => 'Mensajes del chat';

  @override
  String get chat => 'Chat';

  @override
  String get notificationsOnOff => 'Recibir avisos de nuevos mensajes';

  @override
  String get notificationsOff => 'Notificaciones desactivadas';

  @override
  String get couldNotOpenLink => 'No se pudo abrir el enlace.';

  @override
  String get publicLibraries => 'Bibliotecas públicas';

  @override
  String get schoolFacilities => 'Instalaciones escolares';

  @override
  String get creativeStudios => 'Estudios creativos';

  @override
  String get meetingRooms => 'Salas de reuniones';

  @override
  String get theLearner => 'El aprendiz';

  @override
  String get theLearnerDescription =>
      'Enfócate en crecer. Define tus metas y encuentra mentores cerca o en cualquier lugar.';

  @override
  String get theGuide => 'El guía';

  @override
  String get theGuideDescription =>
      'Comparte lo que sabes. Convierte tu talento en valor ayudando a otros a cumplir sus metas.';

  @override
  String get theConnector => 'El conector';

  @override
  String get theConnectorDescription =>
      'La experiencia Twingl completa: enseñas lo que sabes y aprendes lo que te gusta. Eres el corazón de nuestra comunidad.';

  @override
  String get becomeStudentToo => 'Ser también aprendiz';

  @override
  String get becomeTutorToo => 'Ser también tutor';

  @override
  String get becomeStudentTooSubtext =>
      'Los buenos profesores nunca dejan de aprender. Amplía tu perspectiva alcanzando nuevos objetivos.';

  @override
  String get becomeTutorTooSubtext =>
      'Enseñar es la mejor forma de dominar tus habilidades. Comparte tu talento con los demás.';

  @override
  String get unlockStudentMode => 'Activar modo aprendiz';

  @override
  String get unlockTutorMode => 'Activar modo tutor';

  @override
  String get twinerBadgeMessage => 'Obtendrás la insignia Twiner.';

  @override
  String get starting => 'Iniciando…';

  @override
  String get meetTutorsInArea => 'Conocer tutores en tu zona';

  @override
  String get perfectTutorsAnywhere => 'Los tutores ideales, donde sea';

  @override
  String get fellowTutorsInArea => 'Tutores en tu zona';

  @override
  String get studentCandidatesInArea => 'Aprendices en tu zona';

  @override
  String get noTutorsYet =>
      'Aún no hay tutores. Dale a me gusta en Conocer tutores o Los tutores ideales.';

  @override
  String get noStudentsYet =>
      'Aún no hay aprendices. Dale a me gusta en Aprendices en tu zona o en el chat.';

  @override
  String get noFellowsYet =>
      'Aún no hay tutores cerca. Dale a me gusta en Tutores en tu zona.';

  @override
  String get noMatchingTalentsFound => 'No se encontraron talentos.';

  @override
  String get learnShareConnect => 'Aprender, compartir, conectar.';

  @override
  String get student => 'Aprendiz';

  @override
  String get tutor => 'Tutor';

  @override
  String get twiner => 'Twiner';

  @override
  String get twinglIdentity => 'Identidad Twingl';

  @override
  String get leaveTwinglSubtitle =>
      'Borrar favoritos, bloqueados e historial de chat';

  @override
  String failedToStartConversion(String error) {
    return 'Error al iniciar el cambio: $error';
  }

  @override
  String get man => 'Hombre';

  @override
  String get woman => 'Mujer';

  @override
  String get nonBinary => 'No binario';

  @override
  String get preferNotToSay => 'Prefiero no decir';

  @override
  String get share => 'Compartir';

  @override
  String get copyLink => 'Copiar enlace';

  @override
  String get iCanTeach => 'Puedo enseñar';

  @override
  String get iWantToLearn => 'Quiero aprender';

  @override
  String get tutoringRate => 'Tarifa';

  @override
  String get superClose => 'Muy cerca';

  @override
  String kmAway(int km) {
    return 'A $km km';
  }

  @override
  String get onlineOnsite => 'Online, Presencial';

  @override
  String get online => 'Online';

  @override
  String get onsite => 'Presencial';

  @override
  String get noMoreMatches => 'No hay más coincidencias';

  @override
  String get noMoreNearbyResults => 'No hay más resultados cercanos';

  @override
  String get noNearbyTalentFound => 'No se encontró talento cercano.';

  @override
  String get tapRefreshToFindMore =>
      'Toca actualizar para buscar más talentos.';

  @override
  String get tapRefreshToSearchAgain => 'Toca actualizar para buscar de nuevo.';

  @override
  String get refresh => 'Actualizar';

  @override
  String failedToSave(String error) {
    return 'Error al guardar: $error';
  }

  @override
  String get profileDetails => 'Perfil';

  @override
  String get aboutMe => 'Sobre mí';

  @override
  String get aboutTheLesson => 'Sobre la clase';

  @override
  String get lessonLocation => 'Lugar de la clase';

  @override
  String lessonFeePerHour(String amount) {
    return 'Tarifa: $amount/h';
  }

  @override
  String get parentParticipationWelcomed =>
      'Participación de padres bienvenida';

  @override
  String get parentParticipationNotSpecified =>
      'Participación de padres no indicada';

  @override
  String get unableToGenerateProfileLink =>
      'No se pudo generar el enlace del perfil.';

  @override
  String get profileLinkCopiedToClipboard => '¡Enlace copiado al portapapeles!';

  @override
  String failedToShare(String error) {
    return 'Error al compartir: $error';
  }

  @override
  String get unableToSendRequest => 'No se pudo enviar la solicitud.';

  @override
  String get sent => 'Enviado';

  @override
  String failedToSendRequest(String error) {
    return 'Error al enviar la solicitud: $error';
  }

  @override
  String get sendRequest => 'Enviar solicitud';

  @override
  String declinedWithReason(String reason) {
    return 'Rechazado: $reason';
  }

  @override
  String get addToCalendar => 'Añadir a ';

  @override
  String get invalidDateInProposal => 'Fecha no válida en esta propuesta';

  @override
  String get addedToCalendar => 'Añadido al calendario';

  @override
  String failedToAddToCalendar(String error) {
    return 'Error al añadir al calendario: $error';
  }

  @override
  String get locationHint => 'ej. Biblioteca Santa Teresa, Zoom';

  @override
  String get tabTutors => 'Tutores';

  @override
  String get tabStudents => 'Aprendices';

  @override
  String get tabFellows => 'Tutores cercanos';

  @override
  String get likedSectionTitle => 'Favoritos';

  @override
  String get myDetails => 'Mis datos';

  @override
  String get myActivityStats => 'Mis estadísticas';

  @override
  String get statsViews => 'Vistas';

  @override
  String get statsLiked => 'Favoritos';

  @override
  String get statsRequests => 'Solicitudes';

  @override
  String get statsRequesteds => 'Solicitados';

  @override
  String get requestTraining => 'Solicitar clase';

  @override
  String get chatHistory => 'Historial del chat';

  @override
  String get selectSkillAndMethod =>
      'Elige la habilidad y el método que quieres aprender';

  @override
  String get whatToLearn => 'Qué quieres aprender';

  @override
  String chatHistoryWith(String name) {
    return 'Historial del chat con $name';
  }

  @override
  String get noChatHistoryYet => 'Aún no hay historial de chat';

  @override
  String get noLikedUsers => 'No hay usuarios en favoritos.';

  @override
  String get noUsersToBlockFromLikedList =>
      'No hay usuarios para bloquear en tu lista de favoritos.';

  @override
  String get noBlockedUsers => 'No hay usuarios bloqueados.';

  @override
  String get removeFromLiked => 'Quitar de Favoritos';

  @override
  String get blockSelected => 'Bloquear seleccionados';

  @override
  String get unblockSelected => 'Desbloquear seleccionados';

  @override
  String get selectAtLeastOneUser => 'Selecciona al menos un usuario';

  @override
  String removeUsersFromLikedConfirm(int count) {
    return '¿Quitar $count usuario(s) de tu lista de Favoritos?';
  }

  @override
  String blockUsersConfirm(int count) {
    return '¿Bloquear $count usuario(s)? No podrán enviarte mensajes.';
  }

  @override
  String unblockUsersConfirm(int count) {
    return '¿Desbloquear $count usuario(s)? Podrán enviarte mensajes de nuevo.';
  }

  @override
  String get confirm => 'Confirmar';

  @override
  String get someActionsFailed =>
      'Algunas acciones fallaron. Inténtalo de nuevo.';

  @override
  String usersUpdated(int count) {
    return '$count usuario(s) actualizado(s)';
  }

  @override
  String get roleAndBasicInfo => 'Rol e información básica';

  @override
  String get demoModeRandomData =>
      'Modo demo: se rellenan datos aleatorios (fotos omitidas).';

  @override
  String get regenerate => 'Regenerar';

  @override
  String get name => 'Nombre';

  @override
  String get gender => 'Género';

  @override
  String get birthdate => 'Fecha de nacimiento';

  @override
  String ageLabel(String age) {
    return 'Edad: $age';
  }

  @override
  String get aboutMeOptional => 'Sobre mí (opcional)';

  @override
  String get tellOthersAboutYou => 'Cuéntales a los demás sobre ti…';

  @override
  String get whatDoYouWantToLearn => '¿Qué quieres aprender?';

  @override
  String get whatCanYouTeach => '¿Qué puedes enseñar?';

  @override
  String get selectTopicsHint => 'Selecciona 1–6.';

  @override
  String get lessonInfo => 'Info de la clase';

  @override
  String get aboutTheLessonOptional => 'Sobre la clase (opcional)';

  @override
  String get shareLessonDetails =>
      'Comparte detalles, expectativas, objetivos…';

  @override
  String get lessonLocationRequired => 'Ubicación de la clase (obligatorio)';

  @override
  String get tutoringRatePerHourRequired => 'Tarifa por hora (obligatorio)';

  @override
  String get parentParticipationOptional =>
      'Participación del padre bienvenida (opcional)';

  @override
  String get profilePhoto => 'Foto de perfil';

  @override
  String get profilePhotoRequired => 'Foto de perfil (obligatorio)';

  @override
  String get addPhoto => 'Añadir foto';

  @override
  String get waivers => 'Declaraciones';

  @override
  String get waiversRequiredBeforeFinishing => 'Obligatorio antes de terminar.';

  @override
  String get back => 'Atrás';

  @override
  String get next => 'Siguiente';

  @override
  String get save => 'Guardar';

  @override
  String get finish => 'Finalizar';

  @override
  String get selectBirthdate => 'Seleccionar fecha de nacimiento';

  @override
  String get nameRequired => 'El nombre es obligatorio.';

  @override
  String get birthdateRequired => 'La fecha de nacimiento es obligatoria.';

  @override
  String get selectAtLeastOneTopic => 'Selecciona al menos 1 tema.';

  @override
  String get selectLessonLocation =>
      'Selecciona al menos una ubicación (En línea/En persona).';

  @override
  String get tutoringRateRequired => 'La tarifa por hora es obligatoria.';

  @override
  String get tutoringRateMustBeNumber => 'La tarifa debe ser un número.';

  @override
  String get selectAtLeastOneTopicToLearn =>
      'Selecciona al menos 1 tema que quieras aprender.';

  @override
  String get selectOneProfilePhoto =>
      'Selecciona 1 foto de perfil (obligatorio).';

  @override
  String get pleaseAgreeToTutorWaiver =>
      'Por favor acepta la declaración del tutor.';

  @override
  String get pleaseAgreeToStudentWaiver =>
      'Por favor acepta la declaración del estudiante.';

  @override
  String get parentalConsentRequiredForMinors =>
      'Se requiere consentimiento parental para menores.';

  @override
  String get notLoggedIn => 'No has iniciado sesión.';

  @override
  String failedToSaveProfile(String error) {
    return 'Error al guardar el perfil: $error';
  }

  @override
  String failedToPickPhoto(String error) {
    return 'Error al elegir foto: $error';
  }

  @override
  String get tutorWaiverTitle =>
      'Acuerdo del tutor y renuncia de responsabilidad';

  @override
  String get tutorWaiverText =>
      'Conducta profesional: Certifico que la información de mi perfil sobre mis habilidades y cualificaciones es veraz. Me comprometo a realizar todas las sesiones con profesionalidad y respeto.\n\nEstado independiente: Entiendo que Twingl es una plataforma de emparejamiento y no soy empleado, agente ni contratista de Twingl. Soy el único responsable de mis actos y del contenido de mis sesiones.\n\nSeguridad y tolerancia cero: Me comprometo a cumplir las estrictas normas de seguridad de Twingl. Entiendo que cualquier acoso, discriminación o comportamiento inapropiado supondrá la terminación inmediata de mi cuenta y posibles acciones legales.\n\nRenuncia de responsabilidad: Eximo a Twingl, sus propietarios y afiliados de cualquier responsabilidad, reclamación o demanda derivada de mi participación como tutor.';

  @override
  String get studentWaiverTitle =>
      'Asunción de riesgos y renuncia del estudiante';

  @override
  String get studentWaiverText =>
      'Participación voluntaria: Participo voluntariamente en actividades (correr, sesiones de aprendizaje, etc.) conectadas a través de Twingl.\n\nAsunción de riesgos: Entiendo que ciertas actividades, especialmente físicas como correr o senderismo, conllevan riesgos inherentes de lesión. Asumo conscientemente todos esos riesgos, conocidos y desconocidos.\n\nResponsabilidad personal: Reconozco que Twingl no realiza verificaciones de antecedentes a todos los usuarios y soy responsable de tomar las precauciones de seguridad necesarias al reunirme con otros.\n\nRenuncia de reclamaciones: Renuncio a cualquier derecho a demandar a Twingl o sus afiliados por lesión, pérdida o daño asociado a mi participación.';

  @override
  String get parentalConsentTitle =>
      'Consentimiento parental y liberación del tutor';

  @override
  String get parentalConsentText =>
      'Autoridad del tutor: Declaro que soy el padre o tutor legal del menor que se registra en Twingl.\n\nConsentimiento para participar: Doy permiso para que mi hijo participe en actividades y se conecte con otros usuarios en Twingl.\n\nSupervisión y responsabilidad: Entiendo que Twingl es una plataforma comunitaria abierta. Me comprometo a supervisar el uso de la app por parte de mi hijo y asumo la plena responsabilidad de su seguridad y acciones.\n\nTratamiento médico de emergencia: En caso de emergencia durante una actividad relacionada con Twingl, autorizo el tratamiento médico necesario para mi hijo si no puedo ser localizado.';

  @override
  String get agreeToTutorWaiverCheckbox =>
      'He leído y acepto el Acuerdo del tutor y renuncia de responsabilidad';

  @override
  String get agreeToStudentWaiverCheckbox =>
      'He leído y acepto la Asunción de riesgos y renuncia del estudiante';

  @override
  String get agreeToParentalConsentCheckbox =>
      'He leído y acepto el Consentimiento parental y liberación del tutor';

  @override
  String get parentalConsentOnlyForMinors =>
      'El consentimiento parental solo es obligatorio para menores (menores de 18 años).';
}
