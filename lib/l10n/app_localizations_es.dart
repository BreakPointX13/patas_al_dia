// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitulo => 'Patas al Día';

  @override
  String get accionGuardar => 'Guardar';

  @override
  String get accionCancelar => 'Cancelar';

  @override
  String get accionEliminar => 'Eliminar';

  @override
  String get accionEditar => 'Editar';

  @override
  String get valorSi => 'Sí';

  @override
  String get valorNo => 'No';

  @override
  String get noEspecificado => 'No especificado';

  @override
  String get noEspecificada => 'No especificada';

  @override
  String aniosCantidad(Object n) {
    return '$n años';
  }

  @override
  String get navMascotas => 'Mascotas';

  @override
  String get navAgenda => 'Agenda';

  @override
  String get navMapa => 'Mapa';

  @override
  String get loginEslogan => 'Gestiona la salud de tu mascota, donde estés';

  @override
  String get loginIniciarSesion => 'Iniciar sesión';

  @override
  String get loginContinuarInvitado => 'Continuar como invitado';

  @override
  String get loginNoDisponible =>
      'Inicio de sesión no disponible todavía: estamos en fase de desarrollo.';

  @override
  String get cuentaTooltip => 'Cuenta';

  @override
  String get ajustesTitulo => 'Ajustes';

  @override
  String get homeTitulo => 'Mis Mascotas';

  @override
  String get homeVacio => 'Aún no tienes mascotas registradas';

  @override
  String get homeAgregarMascota => 'Agregar mascota';

  @override
  String get credencialTooltip => 'Credencial';

  @override
  String get formMascotaTituloEditar => 'Editar mascota';

  @override
  String get fotoAnadir => 'Añadir foto';

  @override
  String get fotoCambiar => 'Cambiar foto';

  @override
  String get campoNombreObligatorio => 'Nombre *';

  @override
  String get errorNombreObligatorio => 'El nombre es obligatorio';

  @override
  String get campoEspecie => 'Especie';

  @override
  String get campoEspecificaEspecie => 'Especifica la especie';

  @override
  String get campoRaza => 'Raza';

  @override
  String get formCampoRut => 'Rut de la mascota';

  @override
  String get campoNumeroChip => 'Número de chip';

  @override
  String get campoSexo => 'Sexo';

  @override
  String get campoColores => 'Colores';

  @override
  String get campoPesoKg => 'Peso (kg)';

  @override
  String get errorPesoInvalido => 'Ingresa un peso válido';

  @override
  String get campoEsterilizado => 'Esterilizado';

  @override
  String get campoFechaEstimadaSwitch => 'No sé la fecha exacta de nacimiento';

  @override
  String get campoEdadEstimadaAnios => 'Edad estimada (años)';

  @override
  String get errorEdadEstimadaVacia => 'Ingresa la edad estimada';

  @override
  String get errorEdadEstimadaInvalida =>
      'Ingresa una edad válida (1 a 30 años)';

  @override
  String get fechaNacimientoNoSeleccionada =>
      'Fecha de nacimiento no seleccionada';

  @override
  String fechaNacimientoConValor(Object fecha) {
    return 'Fecha de nacimiento: $fecha';
  }

  @override
  String get elegirFecha => 'Elegir fecha';

  @override
  String get especiePerro => 'Perro';

  @override
  String get especieGato => 'Gato';

  @override
  String get especieConejo => 'Conejo';

  @override
  String get especieHamster => 'Hamster';

  @override
  String get especieCobaya => 'Cobaya';

  @override
  String get especieJerbo => 'Jerbo';

  @override
  String get especieRata => 'Rata';

  @override
  String get especieChinchilla => 'Chinchilla';

  @override
  String get especieErizo => 'Erizo';

  @override
  String get especiePez => 'Pez';

  @override
  String get especieTortuga => 'Tortuga';

  @override
  String get especieHuron => 'Hurón';

  @override
  String get especieAve => 'Ave';

  @override
  String get especieOtro => 'Otro';

  @override
  String get sexoMacho => 'Macho';

  @override
  String get sexoHembra => 'Hembra';

  @override
  String get rutMascotaLabel => 'RUT de la mascota';

  @override
  String get pesoLabel => 'Peso';

  @override
  String get edadEstimadaLabel => 'Edad estimada';

  @override
  String get fechaNacimientoLabel => 'Fecha de nacimiento';

  @override
  String get edadLabel => 'Edad';

  @override
  String get accionAgenda => 'Agenda';

  @override
  String get accionDocumentos => 'Documentos';

  @override
  String get eliminarMascotaTitulo => 'Eliminar mascota';

  @override
  String eliminarMascotaContenido(Object nombre) {
    return '¿Eliminar a $nombre? Se van a borrar también su agenda y sus documentos. Esta acción no se puede deshacer.';
  }

  @override
  String get compartirTooltip => 'Compartir';

  @override
  String compartirTexto(Object nombre) {
    return 'Credencial de $nombre';
  }

  @override
  String get temaLabel => 'Tema';

  @override
  String get temaSistema => 'Sistema';

  @override
  String get temaClaro => 'Claro';

  @override
  String get temaOscuro => 'Oscuro';

  @override
  String get tamanoLetraLabel => 'Tamaño de letra';

  @override
  String get tamanoPequeno => 'Pequeño';

  @override
  String get tamanoNormal => 'Normal';

  @override
  String get tamanoGrande => 'Grande';

  @override
  String get idiomaLabel => 'Idioma';

  @override
  String get aportesVoluntariosLabel => 'Aportes voluntarios';

  @override
  String get aportesVoluntariosSubtitulo =>
      'Si quieres apoyar el proyecto, es en Ko-fi';

  @override
  String get errorAbrirEnlace => 'No se pudo abrir el enlace';

  @override
  String get cerrarSesionLabel => 'Cerrar sesión';

  @override
  String get cerrarSesionContenido =>
      'Como invitado, no hay forma de volver a esta sesión después de cerrarla: no vas a poder ver de nuevo tus mascotas ni los datos cargados. ¿Cerrar sesión de todos modos?';

  @override
  String get valorOtro => 'Otro';

  @override
  String get tipoEventoVacuna => 'Vacuna';

  @override
  String get tipoEventoDesparasitacion => 'Desparasitación';

  @override
  String get tipoEventoPeluqueria => 'Peluquería';

  @override
  String get tipoEventoOperacion => 'Operación';

  @override
  String get tipoEventoControl => 'Control';

  @override
  String get tipoEventoExamen => 'Examen';

  @override
  String get tipoDocumentoCarnetVacunacion => 'Carnet de vacunación';

  @override
  String get tipoDocumentoReceta => 'Receta';

  @override
  String get tipoDocumentoExamen => 'Examen';

  @override
  String get tipoDocumentoCertificado => 'Certificado';

  @override
  String get tipoDocumentoBoleta => 'Boleta';

  @override
  String get tipoPresentacionComprimido => 'Comprimido';

  @override
  String get tipoPresentacionLiquido => 'Líquido';

  @override
  String get tipoPresentacionInyectable => 'Inyectable';

  @override
  String get tipoPresentacionPomada => 'Pomada/crema';

  @override
  String get tipoPresentacionGotas => 'Gotas';

  @override
  String get tipoPresentacionPipeta => 'Pipeta';

  @override
  String get recordatorio1Dia => '1 día antes';

  @override
  String get recordatorio12Horas => '12 horas antes';

  @override
  String get recordatorio6Horas => '6 horas antes';

  @override
  String get recordatorio1Hora => '1 hora antes';

  @override
  String recordatorioHorasGenerico(Object h) {
    return '$h horas antes';
  }

  @override
  String get filtrarPorMascotaTitulo => 'Filtrar por mascota';

  @override
  String get filtroTodas => 'Todas';

  @override
  String get accionAplicar => 'Aplicar';

  @override
  String get eventoFuturoTitulo => 'Evento futuro';

  @override
  String get eventoFuturoSubtitulo => 'Recordatorio para una próxima cita';

  @override
  String get eventoPasadoTitulo => 'Evento pasado';

  @override
  String get eventoPasadoSubtitulo => 'Registrar una consulta ya realizada';

  @override
  String get filtroTodasLasMascotas => 'Todas las mascotas';

  @override
  String get filtroSinMascotasSeleccionadas => 'Sin mascotas seleccionadas';

  @override
  String get mascotaFallback => 'Mascota';

  @override
  String get proximoEventoLabel => 'Próximo evento';

  @override
  String get proximosEventosLabel => 'Próximos eventos';

  @override
  String get etiquetaProximo => 'PRÓXIMO';

  @override
  String get diasAtrasado => 'Atrasado';

  @override
  String get diasHoy => 'Hoy';

  @override
  String get diasManana => 'Mañana';

  @override
  String diasEnNumero(Object n) {
    return 'En $n días';
  }

  @override
  String get documentoAdjuntoLabel => 'Documento adjunto';

  @override
  String get noEventosProgramados => 'No hay eventos programados';

  @override
  String get tocaUnDiaParaVerEventos => 'Toca un día para ver sus eventos';

  @override
  String get sinEventosEsteDia => 'Sin eventos este día';

  @override
  String get noMasEventosProgramados => 'No hay más eventos programados';

  @override
  String get verComoLista => 'Ver como lista';

  @override
  String get verCalendario => 'Ver calendario';

  @override
  String mostrandoFiltro(Object filtro) {
    return 'Mostrando: $filtro';
  }

  @override
  String get noHayMascotasCreadas => 'No hay mascotas creadas';

  @override
  String get agregarEvento => 'Agregar evento';

  @override
  String get eliminarEventoTitulo => 'Eliminar evento';

  @override
  String eliminarEventoContenido(Object titulo) {
    return '¿Eliminar \"$titulo\"? Los medicamentos registrados se eliminan con el evento; los documentos adjuntos se conservan, solo pierden el vínculo con este evento.';
  }

  @override
  String get campoMascota => 'Mascota';

  @override
  String get campoTipoEvento => 'Tipo de evento';

  @override
  String get campoFechaProgramada => 'Fecha programada';

  @override
  String get campoObservaciones => 'Observaciones';

  @override
  String get sinObservaciones => 'Sin observaciones';

  @override
  String get campoRecordatorio => 'Recordatorio';

  @override
  String get sinRecordatorio => 'Sin recordatorio';

  @override
  String get realizadoLabel => 'Realizado';

  @override
  String get marcarComoRealizado => 'Marcar como realizado';

  @override
  String get medicamentosLabel => 'Medicamentos';

  @override
  String get sinMedicamentosRegistrados => 'Sin medicamentos registrados';

  @override
  String get documentosAdjuntosLabel => 'Documentos adjuntos';

  @override
  String get sinDocumentosAdjuntos => 'Sin documentos adjuntos';

  @override
  String get editarEventoLabel => 'Editar evento';

  @override
  String get formEventoTituloEditar => 'Editar evento';

  @override
  String get formEventoTituloAgregarPasado => 'Agregar evento pasado';

  @override
  String get formEventoTituloAgregarFuturo => 'Agregar evento futuro';

  @override
  String get campoMascotaObligatorio => 'Mascota *';

  @override
  String get errorSeleccionaMascota => 'Selecciona una mascota';

  @override
  String get campoTituloObligatorio => 'Título *';

  @override
  String get errorTituloObligatorio => 'El título es obligatorio';

  @override
  String get campoEspecificaElTipo => 'Especifica el tipo';

  @override
  String get fechaHoraNoSeleccionadas => 'Fecha y hora no seleccionadas';

  @override
  String fechaConValor(Object fecha) {
    return 'Fecha: $fecha';
  }

  @override
  String get accionElegir => 'Elegir';

  @override
  String get avisarLabel => 'Avisar';

  @override
  String get accionAgregar => 'Agregar';

  @override
  String get campoProgramarProximaConsulta => 'Programar próxima consulta';

  @override
  String get elegirElDia => 'Elige el día';

  @override
  String get horaNoPaso =>
      'La hora elegida todavía no pasó. Elige una hora anterior a la actual.';

  @override
  String get segundaMitadDeshabilitadaAviso =>
      'El resto de la información (observaciones, medicamentos, documentos) se habilita cuando llegue la fecha del evento.';

  @override
  String get agregarMedicamentoTitulo => 'Agregar medicamento';

  @override
  String get editarMedicamentoTitulo => 'Editar medicamento';

  @override
  String get campoPresentacion => 'Presentación';

  @override
  String get datosDocumentoTitulo => 'Datos del documento';

  @override
  String get campoTipo => 'Tipo';

  @override
  String get tomarFoto => 'Tomar foto';

  @override
  String get elegirImagenGaleria => 'Elegir imagen de galería';

  @override
  String get elegirPdf => 'Elegir PDF';

  @override
  String get seleccionaMascotaPrimero => 'Selecciona una mascota primero';

  @override
  String get errorFechaYHora => 'Selecciona fecha y hora';

  @override
  String get agregarDocumentoLabel => 'Agregar documento';

  @override
  String get editarDocumentoLabel => 'Editar documento';

  @override
  String get sinArchivoElegido => 'Sin archivo elegido';

  @override
  String get archivoElegido => 'Archivo elegido';

  @override
  String get accionCambiar => 'Cambiar';

  @override
  String get fechaEmisionNoEspecificada => 'Fecha de emisión no especificada';

  @override
  String fechaEmitidaConValor(Object fecha) {
    return 'Emitido: $fecha';
  }

  @override
  String get fechaVencimientoOpcional => 'Fecha de vencimiento (opcional)';

  @override
  String fechaVenceConValor(Object fecha) {
    return 'Vence: $fecha';
  }

  @override
  String get recordatorioVencimientoLabel => 'Recordatorio de vencimiento';

  @override
  String get recordatorioVencimientoAviso =>
      'Por ahora solo queda guardado como dato, todavía no envía una notificación.';

  @override
  String get campoNotas => 'Notas';

  @override
  String get eligeFotoOPdf => 'Elige una foto o un PDF';

  @override
  String get eliminarDocumentoTitulo => 'Eliminar documento';

  @override
  String eliminarDocumentoContenido(Object titulo) {
    return '¿Eliminar \"$titulo\"?';
  }

  @override
  String get fechaEmisionLabel => 'Fecha de emisión';

  @override
  String get fechaVencimientoLabel => 'Fecha de vencimiento';

  @override
  String get conRecordatorioSufijo => ' (con recordatorio)';

  @override
  String get sinNotas => 'Sin notas';

  @override
  String get vinculadoAlEventoLabel => 'Vinculado al evento';

  @override
  String get abrirDocumentoLabel => 'Abrir documento';

  @override
  String get verPantallaCompletaLabel => 'Ver a pantalla completa';
}
