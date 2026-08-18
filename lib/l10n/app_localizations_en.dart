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
  String get loginNoDisponible =>
      'Sign-in isn\'t available yet: we\'re still in development.';

  @override
  String get cuentaTooltip => 'Account';

  @override
  String get ajustesTitulo => 'Settings';

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
  String get campoRaza => 'Breed';

  @override
  String get formCampoRut => 'Pet\'s ID number';

  @override
  String get campoNumeroChip => 'Chip number';

  @override
  String get campoSexo => 'Sex';

  @override
  String get campoColores => 'Colors';

  @override
  String get campoPesoKg => 'Weight (kg)';

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
  String get campoObservaciones => 'Notes';

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
  String get editarEventoLabel => 'Edit event';

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
}
