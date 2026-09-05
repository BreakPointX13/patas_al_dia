// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitulo => 'Patas al Día';

  @override
  String get accionGuardar => 'Save';

  @override
  String get accionCancelar => 'Cancel';

  @override
  String get accionEliminar => 'Delete';

  @override
  String get accionEditar => 'Edit';

  @override
  String get valorSi => 'Yes';

  @override
  String get valorNo => 'No';

  @override
  String get noEspecificado => 'Not specified';

  @override
  String get noEspecificada => 'Not specified';

  @override
  String aniosCantidad(Object n) {
    return '$n years';
  }

  @override
  String get navMascotas => 'Pets';

  @override
  String get navAgenda => 'Schedule';

  @override
  String get navMapa => 'Map';

  @override
  String get loginEslogan => 'Manage your pet\'s health, wherever you are';

  @override
  String get loginIniciarSesion => 'Sign in';

  @override
  String get loginContinuarInvitado => 'Continue as guest';

  @override
  String get linkPoliticaPrivacidad => 'Privacy policy';

  @override
  String get tituloRegistrarse => 'Create account';

  @override
  String get botonRegistrarse => 'Sign up';

  @override
  String get campoEmail => 'Email';

  @override
  String get campoContrasena => 'Password';

  @override
  String get campoConfirmarContrasena => 'Confirm password';

  @override
  String get errorEmailObligatorio => 'Enter your email';

  @override
  String get errorEmailInvalido => 'That email doesn\'t look valid';

  @override
  String get errorContrasenaObligatoria => 'Enter a password';

  @override
  String get errorContrasenaCorta =>
      'Password must be at least 8 characters, with one uppercase letter and one number';

  @override
  String get ayudaRequisitosContrasena =>
      'At least 8 characters, with one uppercase letter and one number';

  @override
  String get errorContrasenasNoCoinciden => 'Passwords don\'t match';

  @override
  String get linkNoTenesCuenta => 'Don\'t have an account? Sign up';

  @override
  String get linkYaTenesCuenta => 'Already have an account? Sign in';

  @override
  String get avisoRevisaCorreo =>
      'We sent you an email to confirm your account. Check it before signing in on another device.';

  @override
  String get errorCredencialesInvalidas => 'Incorrect email or password';

  @override
  String get errorEmailNoConfirmado =>
      'You haven\'t confirmed your email yet. Check your inbox.';

  @override
  String get errorEmailYaRegistrado => 'That email is already registered';

  @override
  String get errorAutenticacionGenerico =>
      'Couldn\'t complete the operation. Try again.';

  @override
  String get cuentaInvitadoLabel => 'Guest account';

  @override
  String get registrarmeSubtitulo => 'Sign up so you don\'t lose your data';

  @override
  String get linkOlvideContrasena => 'Forgot your password?';

  @override
  String get tituloRecuperarContrasena => 'Recover password';

  @override
  String get avisoEnlaceEnviado =>
      'If that email is registered, we sent you a link to reset your password.';

  @override
  String get errorEnlaceInvalido =>
      'The link is invalid or expired. Request a new one.';

  @override
  String get botonEnviarEnlace => 'Send link';

  @override
  String get botonRestablecerContrasena => 'Reset password';

  @override
  String get contrasenaActualizadaAviso =>
      'Your password was updated successfully.';

  @override
  String get moderacionTitulo => 'Moderation';

  @override
  String get moderacionSubtitulo => 'Reports flagged by other users';

  @override
  String get sinReportesDenunciados => 'No flagged reports right now.';

  @override
  String cantidadDenunciasLabel(Object n) {
    return '$n reports';
  }

  @override
  String get errorPermisoCamaraPermanente =>
      'Patas al Día needs permission to use the camera. Turn it on from your phone\'s settings.';

  @override
  String get errorPermisoFotosGenerico =>
      'Couldn\'t access the photo. Check Patas al Día\'s permissions from your phone\'s settings.';

  @override
  String get abrirAjustesBoton => 'Open settings';

  @override
  String get campoNuevaContrasena => 'New password';

  @override
  String get tituloCambiarContrasena => 'Change password';

  @override
  String get cambiarContrasenaSubtitulo => 'Update your account password';

  @override
  String get campoContrasenaActual => 'Current password';

  @override
  String get botonCambiarContrasena => 'Change password';

  @override
  String get avisoRequisitosContrasena =>
      'At least 8 characters, with one uppercase letter and one number.';

  @override
  String get errorContrasenaActualIncorrecta =>
      'The current password is incorrect';

  @override
  String get avisoContrasenaActualizada => 'Password updated';

  @override
  String get cuentaTooltip => 'Account';

  @override
  String get ajustesTitulo => 'Settings';

  @override
  String get seccionApoyoLabel => 'Support';

  @override
  String get seccionAparienciaLabel => 'Appearance';

  @override
  String get seccionCuentaLabel => 'Account';

  @override
  String get seccionAyudaLabel => 'Help';

  @override
  String get seccionSesionLabel => 'Session';

  @override
  String get reportarBugTitulo => 'Report a bug';

  @override
  String get reportarBugSubtitulo => 'Let us know if something isn\'t working';

  @override
  String get reportarBugIntro =>
      'Tell us what happened — you can attach a screenshot if it helps explain it.';

  @override
  String get campoDescripcionBug => 'What happened?';

  @override
  String get errorDescripcionBugObligatoria =>
      'Describe the problem before sending';

  @override
  String get botonEnviarReporte => 'Send report';

  @override
  String get avisoReporteEnviado => 'Thanks! Your report was sent';

  @override
  String get homeTitulo => 'My Pets';

  @override
  String get homeVacio => 'You don\'t have any pets registered yet';

  @override
  String get homeAgregarMascota => 'Add pet';

  @override
  String get credencialTooltip => 'ID card';

  @override
  String get formMascotaTituloEditar => 'Edit pet';

  @override
  String get fotoAnadir => 'Add photo';

  @override
  String get fotoCambiar => 'Change photo';

  @override
  String get campoNombreObligatorio => 'Name *';

  @override
  String get errorNombreObligatorio => 'Name is required';

  @override
  String get campoEspecie => 'Species';

  @override
  String get campoEspecificaEspecie => 'Specify the species';

  @override
  String get campoRaza => 'Breed (optional)';

  @override
  String get formCampoRut => 'Pet\'s ID number (optional)';

  @override
  String get campoNumeroChip => 'Chip number (optional)';

  @override
  String get campoSexo => 'Sex';

  @override
  String get campoColores => 'Colors (optional)';

  @override
  String get campoPesoKg => 'Weight (kg, optional)';

  @override
  String get errorPesoInvalido => 'Enter a valid weight';

  @override
  String get campoEsterilizado => 'Neutered/Spayed';

  @override
  String get campoFechaEstimadaSwitch => 'I don\'t know the exact birth date';

  @override
  String get campoEdadEstimadaAnios => 'Estimated age (years)';

  @override
  String get errorEdadEstimadaVacia => 'Enter the estimated age';

  @override
  String get errorEdadEstimadaInvalida => 'Enter a valid age (1 to 30 years)';

  @override
  String get fechaNacimientoNoSeleccionada => 'Birth date not selected';

  @override
  String fechaNacimientoConValor(Object fecha) {
    return 'Birth date: $fecha';
  }

  @override
  String get elegirFecha => 'Choose date';

  @override
  String get especiePerro => 'Dog';

  @override
  String get especieGato => 'Cat';

  @override
  String get especieConejo => 'Rabbit';

  @override
  String get especieHamster => 'Hamster';

  @override
  String get especieCobaya => 'Guinea pig';

  @override
  String get especieJerbo => 'Gerbil';

  @override
  String get especieRata => 'Rat';

  @override
  String get especieChinchilla => 'Chinchilla';

  @override
  String get especieErizo => 'Hedgehog';

  @override
  String get especiePez => 'Fish';

  @override
  String get especieTortuga => 'Turtle';

  @override
  String get especieHuron => 'Ferret';

  @override
  String get especieAve => 'Bird';

  @override
  String get especieOtro => 'Other';

  @override
  String get sexoMacho => 'Male';

  @override
  String get sexoHembra => 'Female';

  @override
  String get rutMascotaLabel => 'Pet\'s ID number';

  @override
  String get pesoLabel => 'Weight';

  @override
  String get edadEstimadaLabel => 'Estimated age';

  @override
  String get fechaNacimientoLabel => 'Birth date';

  @override
  String get edadLabel => 'Age';

  @override
  String get accionAgenda => 'Schedule';

  @override
  String get accionDocumentos => 'Documents';

  @override
  String get eliminarMascotaTitulo => 'Delete pet';

  @override
  String eliminarMascotaContenido(Object nombre) {
    return 'Delete $nombre? Their schedule and documents will be deleted too. This action can\'t be undone.';
  }

  @override
  String get compartirTooltip => 'Share';

  @override
  String compartirTexto(Object nombre) {
    return '$nombre\'s ID card';
  }

  @override
  String get temaLabel => 'Theme';

  @override
  String get temaSistema => 'System';

  @override
  String get temaClaro => 'Light';

  @override
  String get temaOscuro => 'Dark';

  @override
  String get tamanoLetraLabel => 'Text size';

  @override
  String get tamanoPequeno => 'Small';

  @override
  String get tamanoNormal => 'Normal';

  @override
  String get tamanoGrande => 'Large';

  @override
  String get idiomaLabel => 'Language';

  @override
  String get idiomaSistemaLabel => 'Auto';

  @override
  String get aportesVoluntariosLabel => 'Support the project';

  @override
  String get aportesVoluntariosSubtitulo =>
      'If you\'d like to support the project, it\'s on Ko-fi';

  @override
  String get errorAbrirEnlace => 'Couldn\'t open the link';

  @override
  String get cerrarSesionLabel => 'Sign out';

  @override
  String get cerrarSesionContenido =>
      'As a guest, there\'s no way to get back to this session after signing out: you won\'t be able to see your pets or your saved data again. Sign out anyway?';

  @override
  String get cerrarSesionContenidoRegistrado =>
      'You\'re about to sign out. You can sign back in with your email and password whenever you want.';

  @override
  String get eliminarCuentaLabel => 'Delete account';

  @override
  String get eliminarCuentaContenido =>
      'All your data (pets, schedule, documents) on this device will be permanently deleted. This can\'t be undone. Delete account anyway?';

  @override
  String get eliminarCuentaContenidoRegistrado =>
      'Your account will be deleted (you won\'t be able to sign in with this email again) along with all your data on this device, permanently. This can\'t be undone. Delete account anyway?';

  @override
  String get sincronizarAhoraLabel => 'Sync now';

  @override
  String get ultimaSincronizacionNunca => 'Not synced yet';

  @override
  String ultimaSincronizacionConValor(Object tiempo) {
    return 'Last synced: $tiempo';
  }

  @override
  String get tiempoRelativoAhora => 'just now';

  @override
  String tiempoRelativoMinutos(Object minutos) {
    return '$minutos min ago';
  }

  @override
  String tiempoRelativoHoras(Object horas) {
    return '$horas h ago';
  }

  @override
  String tiempoRelativoDias(Object dias) {
    return '$dias day(s) ago';
  }

  @override
  String get valorOtro => 'Other';

  @override
  String get tipoEventoVacuna => 'Vaccine';

  @override
  String get tipoEventoDesparasitacion => 'Deworming';

  @override
  String get tipoEventoPeluqueria => 'Grooming';

  @override
  String get tipoEventoOperacion => 'Surgery';

  @override
  String get tipoEventoControl => 'Check-up';

  @override
  String get tipoEventoExamen => 'Exam';

  @override
  String get tipoDocumentoCarnetVacunacion => 'Vaccination record';

  @override
  String get tipoDocumentoReceta => 'Prescription';

  @override
  String get tipoDocumentoExamen => 'Test result';

  @override
  String get tipoDocumentoCertificado => 'Certificate';

  @override
  String get tipoDocumentoBoleta => 'Receipt';

  @override
  String get tipoPresentacionComprimido => 'Tablet';

  @override
  String get tipoPresentacionLiquido => 'Liquid';

  @override
  String get tipoPresentacionInyectable => 'Injectable';

  @override
  String get tipoPresentacionPomada => 'Ointment/cream';

  @override
  String get tipoPresentacionGotas => 'Drops';

  @override
  String get tipoPresentacionPipeta => 'Spot-on';

  @override
  String get recordatorio1Dia => '1 day before';

  @override
  String get recordatorio12Horas => '12 hours before';

  @override
  String get recordatorio6Horas => '6 hours before';

  @override
  String get recordatorio1Hora => '1 hour before';

  @override
  String recordatorioHorasGenerico(Object h) {
    return '$h hours before';
  }

  @override
  String get filtrarPorMascotaTitulo => 'Filter by pet';

  @override
  String get filtroTodas => 'All';

  @override
  String get accionAplicar => 'Apply';

  @override
  String get eventoFuturoTitulo => 'Upcoming event';

  @override
  String get eventoFuturoSubtitulo => 'Reminder for an upcoming visit';

  @override
  String get eventoPasadoTitulo => 'Past event';

  @override
  String get eventoPasadoSubtitulo => 'Log a visit that already happened';

  @override
  String get filtroTodasLasMascotas => 'All pets';

  @override
  String get filtroSinMascotasSeleccionadas => 'No pets selected';

  @override
  String get mascotaFallback => 'Pet';

  @override
  String get proximoEventoLabel => 'Next event';

  @override
  String get proximosEventosLabel => 'Upcoming events';

  @override
  String get etiquetaProximo => 'NEXT';

  @override
  String get diasAtrasado => 'Overdue';

  @override
  String get diasHoy => 'Today';

  @override
  String get diasManana => 'Tomorrow';

  @override
  String diasEnNumero(Object n) {
    return 'In $n days';
  }

  @override
  String get documentoAdjuntoLabel => 'Attached document';

  @override
  String get noEventosProgramados => 'No events scheduled';

  @override
  String get tocaUnDiaParaVerEventos => 'Tap a day to see its events';

  @override
  String get sinEventosEsteDia => 'No events this day';

  @override
  String get noMasEventosProgramados => 'No more events scheduled';

  @override
  String get verComoLista => 'View as list';

  @override
  String get verCalendario => 'View calendar';

  @override
  String mostrandoFiltro(Object filtro) {
    return 'Showing: $filtro';
  }

  @override
  String get noHayMascotasCreadas => 'No pets added yet';

  @override
  String get agregarEvento => 'Add event';

  @override
  String get eliminarEventoTitulo => 'Delete event';

  @override
  String eliminarEventoContenido(Object titulo) {
    return 'Delete \"$titulo\"? The recorded medications will be deleted along with the event; attached documents are kept, they just lose the link to this event.';
  }

  @override
  String get campoMascota => 'Pet';

  @override
  String get campoTipoEvento => 'Event type';

  @override
  String get campoFechaProgramada => 'Scheduled date';

  @override
  String get campoObservaciones => 'Notes (optional)';

  @override
  String get sinObservaciones => 'No notes';

  @override
  String get campoRecordatorio => 'Reminder';

  @override
  String get sinRecordatorio => 'No reminder';

  @override
  String get realizadoLabel => 'Completed';

  @override
  String get marcarComoRealizado => 'Mark as completed';

  @override
  String get medicamentosLabel => 'Medications';

  @override
  String get sinMedicamentosRegistrados => 'No medications recorded';

  @override
  String get documentosAdjuntosLabel => 'Attached documents';

  @override
  String get sinDocumentosAdjuntos => 'No attached documents';

  @override
  String get formEventoTituloEditar => 'Edit event';

  @override
  String get formEventoTituloAgregarPasado => 'Add past event';

  @override
  String get formEventoTituloAgregarFuturo => 'Add upcoming event';

  @override
  String get campoMascotaObligatorio => 'Pet *';

  @override
  String get errorSeleccionaMascota => 'Select a pet';

  @override
  String get campoTituloObligatorio => 'Title *';

  @override
  String get errorTituloObligatorio => 'Title is required';

  @override
  String get campoEspecificaElTipo => 'Specify the type';

  @override
  String get fechaHoraNoSeleccionadas => 'Date and time not selected';

  @override
  String fechaConValor(Object fecha) {
    return 'Date: $fecha';
  }

  @override
  String get accionElegir => 'Choose';

  @override
  String get avisarLabel => 'Notify';

  @override
  String get accionAgregar => 'Add';

  @override
  String get campoProgramarProximaConsulta => 'Schedule next visit';

  @override
  String get elegirElDia => 'Choose the day';

  @override
  String get horaNoPaso =>
      'The chosen time hasn\'t passed yet. Choose an earlier time.';

  @override
  String get segundaMitadDeshabilitadaAviso =>
      'The rest of the information (notes, medications, documents) unlocks once the event\'s date arrives.';

  @override
  String get agregarMedicamentoTitulo => 'Add medication';

  @override
  String get editarMedicamentoTitulo => 'Edit medication';

  @override
  String get campoPresentacion => 'Form';

  @override
  String get datosDocumentoTitulo => 'Document details';

  @override
  String get campoTipo => 'Type';

  @override
  String get tomarFoto => 'Take photo';

  @override
  String get elegirImagenGaleria => 'Choose image from gallery';

  @override
  String get elegirPdf => 'Choose PDF';

  @override
  String get seleccionaMascotaPrimero => 'Select a pet first';

  @override
  String get errorFechaYHora => 'Select a date and time';

  @override
  String get agregarDocumentoLabel => 'Add document';

  @override
  String get editarDocumentoLabel => 'Edit document';

  @override
  String get sinArchivoElegido => 'No file chosen';

  @override
  String get archivoElegido => 'File chosen';

  @override
  String get accionCambiar => 'Change';

  @override
  String get fechaEmisionNoEspecificada => 'Issue date not specified';

  @override
  String fechaEmitidaConValor(Object fecha) {
    return 'Issued: $fecha';
  }

  @override
  String get fechaVencimientoOpcional => 'Expiration date (optional)';

  @override
  String fechaVenceConValor(Object fecha) {
    return 'Expires: $fecha';
  }

  @override
  String get recordatorioVencimientoLabel => 'Expiration reminder';

  @override
  String get recordatorioVencimientoAviso =>
      'For now this is just saved as a note, it doesn\'t send a notification yet.';

  @override
  String get campoNotas => 'Notes (optional)';

  @override
  String get eligeFotoOPdf => 'Choose a photo or a PDF';

  @override
  String get eliminarDocumentoTitulo => 'Delete document';

  @override
  String eliminarDocumentoContenido(Object titulo) {
    return 'Delete \"$titulo\"?';
  }

  @override
  String get fechaEmisionLabel => 'Issue date';

  @override
  String get fechaVencimientoLabel => 'Expiration date';

  @override
  String get conRecordatorioSufijo => ' (with reminder)';

  @override
  String get sinNotas => 'No notes';

  @override
  String get vinculadoAlEventoLabel => 'Linked to event';

  @override
  String get abrirDocumentoLabel => 'Open document';

  @override
  String get verPantallaCompletaLabel => 'View full screen';

  @override
  String get reportarMascotaPerdidaLabel => 'Report a lost pet';

  @override
  String get campoUbicacion => 'Location';

  @override
  String get usarUbicacionActualSwitch => 'Use my current location';

  @override
  String get obtenerUbicacionActual => 'Get location';

  @override
  String get ubicacionObtenidaLabel => 'Location obtained';

  @override
  String get sinUbicacionLabel => 'No location';

  @override
  String get ayudaDireccionEstimada =>
      'You can enter an approximate address — the general area is enough. If you prefer, add exact details in the description.';

  @override
  String get errorServicioUbicacionDeshabilitado =>
      'Turn on device location to continue';

  @override
  String get errorPermisoUbicacionDenegado =>
      'Location permission is needed to continue';

  @override
  String get errorPermisoUbicacionPermanente =>
      'Location permission is blocked. Enable it from your system settings.';

  @override
  String get errorObtenerUbicacion => 'Couldn\'t get your location';

  @override
  String get campoPais => 'Country';

  @override
  String get errorPaisObligatorio => 'Country is required';

  @override
  String get campoCiudad => 'City';

  @override
  String get errorCiudadObligatoria => 'City is required';

  @override
  String get campoComunaOpcional => 'District/borough (optional)';

  @override
  String get campoDireccion => 'Address';

  @override
  String get buscarDireccionBoton => 'Search address';

  @override
  String get errorGeocodificacion =>
      'We couldn\'t locate that address. Check the details and try again.';

  @override
  String get errorUbicacionObligatoria =>
      'Location is missing. Use your current location or enter a valid address.';

  @override
  String get campoFotoObligatoria => 'Photo *';

  @override
  String get errorFotoObligatoria => 'Photo is required';

  @override
  String get errorSubirFoto => 'Couldn\'t upload the photo. Try again.';

  @override
  String get campoRecompensaSwitch => 'Offering a reward?';

  @override
  String get campoRecompensaMonto => 'Reward amount';

  @override
  String get errorRecompensaInvalida => 'Enter a valid amount';

  @override
  String get campoContactoEmergenciaObligatorio => 'Emergency contact *';

  @override
  String get errorContactoEmergenciaObligatorio =>
      'Emergency contact is required';

  @override
  String get avisoContactoEmergencia =>
      'It\'s the only way someone can reach you about this report.';

  @override
  String get campoDescripcionObligatoria => 'Description *';

  @override
  String get errorDescripcionObligatoria => 'Description is required';

  @override
  String get reporteAgradecimientoAviso =>
      'Thanks for reporting it! Your post is now visible on the map so the community can help.';

  @override
  String get errorPublicarReporte =>
      'Couldn\'t publish the report. Check your connection and try again.';

  @override
  String get errorAutenticacionReporte =>
      'Couldn\'t verify your identity to publish the report. Try again in a few seconds.';

  @override
  String get errorLimiteReportesActivos =>
      'You already have the maximum number of active reports. Mark one as found before creating a new one.';

  @override
  String get avisoMapaTitulo => 'Before you use Map';

  @override
  String get avisoMapaContenido =>
      'This map is only for reporting lost or found pets. Don\'t use it to post ads, sell things, or share content unrelated to lost pets.\n\nIf you see a report that doesn\'t belong, please report it so we can review it.';

  @override
  String get avisoMapaEntendido => 'Got it';

  @override
  String get reportarMascotaEncontradaLabel => 'Report a found pet';

  @override
  String get campoNombreMascotaOpcional => 'Pet\'s name (if you know it)';

  @override
  String get opcionReportarPerdida => 'I lost a pet';

  @override
  String get opcionReportarEncontrada => 'I found a pet';

  @override
  String get eligeMascotaReporteTitulo => 'Which pet?';

  @override
  String get opcionMascotaNoRegistrada => 'Another pet (not registered)';

  @override
  String get denunciarReporteLabel => 'Report this listing';

  @override
  String get confirmarDenunciaTitulo => 'Report listing';

  @override
  String get confirmarDenunciaContenido =>
      'Report this listing for not belonging on the map?';

  @override
  String get denunciaEnviadaAviso => 'Thanks, we\'ll review it';

  @override
  String get marcarComoResueltoLabel => 'Mark as resolved';

  @override
  String get confirmarResueltoTitulo => 'Mark as resolved';

  @override
  String get confirmarResueltoContenido =>
      'Mark this report as resolved? It will stop showing on the map.';

  @override
  String get eliminarReporteTitulo => 'Delete report';

  @override
  String get eliminarReporteContenido =>
      'Delete this report? This action can\'t be undone.';

  @override
  String get contactoLabel => 'Contact';

  @override
  String get recompensaLabel => 'Reward';

  @override
  String get fechaPublicacionLabel => 'Published';

  @override
  String get tipoPerdidoChip => 'Lost';

  @override
  String get tipoEncontradoChip => 'Found';

  @override
  String get sinReportesActivos => 'No active reports right now';

  @override
  String get misReportesTitulo => 'My reports';

  @override
  String get sinMisReportesActivos =>
      'You don\'t have any active reports right now';

  @override
  String get errorCargarReportes =>
      'Couldn\'t load the reports. Check your connection.';

  @override
  String get accionReportarFab => 'Report';

  @override
  String get verPorTipo => 'View by type';

  @override
  String get verCronologico => 'View chronologically';

  @override
  String get vistaCronologicaTitulo => 'Chronological order';
}
