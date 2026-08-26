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
  String get linkPoliticaPrivacidad => 'Política de privacidad';

  @override
  String get tituloRegistrarse => 'Crear cuenta';

  @override
  String get botonRegistrarse => 'Registrarme';

  @override
  String get campoEmail => 'Correo electrónico';

  @override
  String get campoContrasena => 'Contraseña';

  @override
  String get campoConfirmarContrasena => 'Confirmar contraseña';

  @override
  String get errorEmailObligatorio => 'Ingresa tu correo';

  @override
  String get errorEmailInvalido => 'Ese correo no parece válido';

  @override
  String get errorContrasenaObligatoria => 'Ingresa una contraseña';

  @override
  String get errorContrasenaCorta =>
      'La contraseña debe tener al menos 8 caracteres, una mayúscula y un número';

  @override
  String get errorContrasenasNoCoinciden => 'Las contraseñas no coinciden';

  @override
  String get linkNoTenesCuenta => '¿No tienes cuenta? Regístrate';

  @override
  String get linkYaTenesCuenta => '¿Ya tienes cuenta? Inicia sesión';

  @override
  String get avisoRevisaCorreo =>
      'Te enviamos un correo para confirmar tu cuenta. Revísalo antes de iniciar sesión en otro dispositivo.';

  @override
  String get errorCredencialesInvalidas => 'Correo o contraseña incorrectos';

  @override
  String get errorEmailNoConfirmado =>
      'Todavía no confirmaste tu correo. Revisa tu bandeja de entrada.';

  @override
  String get errorEmailYaRegistrado => 'Ese correo ya está registrado';

  @override
  String get errorAutenticacionGenerico =>
      'No se pudo completar la operación. Intenta de nuevo.';

  @override
  String get cuentaInvitadoLabel => 'Cuenta de invitado';

  @override
  String get registrarmeSubtitulo => 'Regístrate para no perder tus datos';

  @override
  String get linkOlvideContrasena => '¿Olvidaste tu contraseña?';

  @override
  String get tituloRecuperarContrasena => 'Recuperar contraseña';

  @override
  String get avisoEnlaceEnviado =>
      'Si ese correo está registrado, te enviamos un enlace para restablecer tu contraseña.';

  @override
  String get errorEnlaceInvalido =>
      'El enlace es inválido o venció. Pedí uno nuevo.';

  @override
  String get botonEnviarEnlace => 'Enviar enlace';

  @override
  String get botonRestablecerContrasena => 'Restablecer contraseña';

  @override
  String get contrasenaActualizadaAviso =>
      'Tu contraseña se actualizó correctamente.';

  @override
  String get moderacionTitulo => 'Moderación';

  @override
  String get moderacionSubtitulo => 'Reportes denunciados por otros usuarios';

  @override
  String get sinReportesDenunciados => 'No hay reportes denunciados por ahora.';

  @override
  String cantidadDenunciasLabel(Object n) {
    return '$n denuncias';
  }

  @override
  String get errorPermisoCamaraPermanente =>
      'Patas al Día necesita permiso para usar la cámara. Actívalo desde los ajustes del teléfono.';

  @override
  String get errorPermisoFotosGenerico =>
      'No se pudo acceder a la foto. Revisa los permisos de Patas al Día desde los ajustes del teléfono.';

  @override
  String get abrirAjustesBoton => 'Abrir ajustes';

  @override
  String get campoNuevaContrasena => 'Nueva contraseña';

  @override
  String get tituloCambiarContrasena => 'Cambiar contraseña';

  @override
  String get cambiarContrasenaSubtitulo =>
      'Actualiza la contraseña de tu cuenta';

  @override
  String get campoContrasenaActual => 'Contraseña actual';

  @override
  String get botonCambiarContrasena => 'Cambiar contraseña';

  @override
  String get avisoRequisitosContrasena =>
      'Mínimo 8 caracteres, con al menos una mayúscula y un número.';

  @override
  String get errorContrasenaActualIncorrecta =>
      'La contraseña actual es incorrecta';

  @override
  String get avisoContrasenaActualizada => 'Contraseña actualizada';

  @override
  String get cuentaTooltip => 'Cuenta';

  @override
  String get ajustesTitulo => 'Ajustes';

  @override
  String get seccionApoyoLabel => 'Apoyo';

  @override
  String get seccionAparienciaLabel => 'Apariencia';

  @override
  String get seccionCuentaLabel => 'Cuenta';

  @override
  String get seccionAyudaLabel => 'Ayuda';

  @override
  String get seccionSesionLabel => 'Sesión';

  @override
  String get reportarBugTitulo => 'Reportar un bug';

  @override
  String get reportarBugSubtitulo => 'Avísanos si algo no funciona bien';

  @override
  String get reportarBugIntro =>
      'Cuéntanos qué pasó — puedes adjuntar una captura de pantalla si ayuda a explicarlo.';

  @override
  String get campoDescripcionBug => '¿Qué pasó?';

  @override
  String get errorDescripcionBugObligatoria =>
      'Describe el problema antes de enviar';

  @override
  String get botonEnviarReporte => 'Enviar reporte';

  @override
  String get avisoReporteEnviado => '¡Gracias! Tu reporte fue enviado';

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
  String get campoRaza => 'Raza (opcional)';

  @override
  String get formCampoRut => 'Rut de la mascota (opcional)';

  @override
  String get campoNumeroChip => 'Número de chip (opcional)';

  @override
  String get campoSexo => 'Sexo';

  @override
  String get campoColores => 'Colores (opcional)';

  @override
  String get campoPesoKg => 'Peso (kg, opcional)';

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
  String get idiomaSistemaLabel => 'Auto';

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
  String get cerrarSesionContenidoRegistrado =>
      'Vas a cerrar tu sesión. Puedes volver a iniciarla con tu correo y contraseña cuando quieras.';

  @override
  String get eliminarCuentaLabel => 'Eliminar cuenta';

  @override
  String get eliminarCuentaContenido =>
      'Se van a borrar todos tus datos (mascotas, agenda, documentos) de este dispositivo, de forma permanente. Esta acción no se puede deshacer. ¿Eliminar cuenta de todos modos?';

  @override
  String get eliminarCuentaContenidoRegistrado =>
      'Se va a borrar tu cuenta (no vas a poder volver a iniciar sesión con este correo) y todos tus datos de este dispositivo, de forma permanente. Esta acción no se puede deshacer. ¿Eliminar cuenta de todos modos?';

  @override
  String get sincronizarAhoraLabel => 'Sincronizar ahora';

  @override
  String get ultimaSincronizacionNunca => 'Todavía no se sincronizó';

  @override
  String ultimaSincronizacionConValor(Object tiempo) {
    return 'Última sincronización: $tiempo';
  }

  @override
  String get tiempoRelativoAhora => 'hace un momento';

  @override
  String tiempoRelativoMinutos(Object minutos) {
    return 'hace $minutos min';
  }

  @override
  String tiempoRelativoHoras(Object horas) {
    return 'hace $horas h';
  }

  @override
  String tiempoRelativoDias(Object dias) {
    return 'hace $dias día(s)';
  }

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
  String get campoObservaciones => 'Observaciones (opcional)';

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
  String get campoNotas => 'Notas (opcional)';

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

  @override
  String get reportarMascotaPerdidaLabel => 'Reportar mascota perdida';

  @override
  String get campoUbicacion => 'Ubicación';

  @override
  String get usarUbicacionActualSwitch => 'Usar mi ubicación actual';

  @override
  String get obtenerUbicacionActual => 'Obtener ubicación';

  @override
  String get ubicacionObtenidaLabel => 'Ubicación obtenida';

  @override
  String get sinUbicacionLabel => 'Sin ubicación';

  @override
  String get ayudaDireccionEstimada =>
      'Puedes ingresar una dirección aproximada — el sector alcanza. Si prefieres, agrega los detalles exactos en la descripción.';

  @override
  String get errorServicioUbicacionDeshabilitado =>
      'Activa la ubicación del dispositivo para continuar';

  @override
  String get errorPermisoUbicacionDenegado =>
      'Se necesita permiso de ubicación para continuar';

  @override
  String get errorPermisoUbicacionPermanente =>
      'El permiso de ubicación está bloqueado. Actívalo desde los ajustes del sistema.';

  @override
  String get errorObtenerUbicacion => 'No se pudo obtener la ubicación';

  @override
  String get campoPais => 'País';

  @override
  String get errorPaisObligatorio => 'El país es obligatorio';

  @override
  String get campoCiudad => 'Ciudad';

  @override
  String get errorCiudadObligatoria => 'La ciudad es obligatoria';

  @override
  String get campoComunaOpcional => 'Comuna (opcional)';

  @override
  String get campoDireccion => 'Dirección';

  @override
  String get buscarDireccionBoton => 'Buscar dirección';

  @override
  String get errorGeocodificacion =>
      'No pudimos ubicar esa dirección. Revisa los datos e intenta de nuevo.';

  @override
  String get errorUbicacionObligatoria =>
      'Falta la ubicación. Usa tu ubicación actual o ingresa una dirección válida.';

  @override
  String get campoFotoObligatoria => 'Foto *';

  @override
  String get errorFotoObligatoria => 'La foto es obligatoria';

  @override
  String get errorSubirFoto => 'No se pudo subir la foto. Intenta de nuevo.';

  @override
  String get campoRecompensaSwitch => '¿Ofreces recompensa?';

  @override
  String get campoRecompensaMonto => 'Monto de la recompensa';

  @override
  String get errorRecompensaInvalida => 'Ingresa un monto válido';

  @override
  String get campoContactoEmergenciaObligatorio => 'Contacto de emergencia *';

  @override
  String get errorContactoEmergenciaObligatorio =>
      'El contacto de emergencia es obligatorio';

  @override
  String get avisoContactoEmergencia =>
      'Es la única forma de que alguien pueda contactarte por este reporte.';

  @override
  String get campoDescripcionObligatoria => 'Descripción *';

  @override
  String get errorDescripcionObligatoria => 'La descripción es obligatoria';

  @override
  String get reporteAgradecimientoAviso =>
      '¡Gracias por reportarlo! Tu publicación ya está visible en el mapa para que la comunidad pueda ayudar.';

  @override
  String get errorPublicarReporte =>
      'No se pudo publicar el reporte. Revisa tu conexión e intenta de nuevo.';

  @override
  String get errorAutenticacionReporte =>
      'No se pudo verificar tu identidad para publicar el reporte. Intenta de nuevo en unos segundos.';

  @override
  String get errorLimiteReportesActivos =>
      'Ya tienes el máximo de reportes activos. Marca alguno como encontrado antes de crear uno nuevo.';

  @override
  String get avisoMapaTitulo => 'Antes de usar Mapa';

  @override
  String get avisoMapaContenido =>
      'Este mapa es solo para reportar mascotas perdidas o encontradas. No lo uses para publicar anuncios, ventas ni contenido que no tenga que ver con mascotas perdidas.\n\nSi ves un reporte que no corresponde, puedes denunciarlo para que lo revisemos.';

  @override
  String get avisoMapaEntendido => 'Entendido';

  @override
  String get reportarMascotaEncontradaLabel => 'Reportar mascota encontrada';

  @override
  String get campoNombreMascotaOpcional => 'Nombre de la mascota (si lo sabes)';

  @override
  String get opcionReportarPerdida => 'Perdí una mascota';

  @override
  String get opcionReportarEncontrada => 'Encontré una mascota';

  @override
  String get eligeMascotaReporteTitulo => '¿Cuál mascota?';

  @override
  String get opcionMascotaNoRegistrada => 'Otra mascota (no registrada)';

  @override
  String get denunciarReporteLabel => 'Denunciar este aviso';

  @override
  String get confirmarDenunciaTitulo => 'Denunciar aviso';

  @override
  String get confirmarDenunciaContenido =>
      '¿Denunciar este aviso por no corresponder al uso del mapa?';

  @override
  String get denunciaEnviadaAviso => 'Gracias, vamos a revisarlo';

  @override
  String get marcarComoResueltoLabel => 'Marcar como resuelto';

  @override
  String get confirmarResueltoTitulo => 'Marcar como resuelto';

  @override
  String get confirmarResueltoContenido =>
      '¿Marcar este reporte como resuelto? Va a dejar de verse en el mapa.';

  @override
  String get eliminarReporteTitulo => 'Eliminar reporte';

  @override
  String get eliminarReporteContenido =>
      '¿Eliminar este reporte? Esta acción no se puede deshacer.';

  @override
  String get contactoLabel => 'Contacto';

  @override
  String get recompensaLabel => 'Recompensa';

  @override
  String get fechaPublicacionLabel => 'Publicado';

  @override
  String get tipoPerdidoChip => 'Perdida';

  @override
  String get tipoEncontradoChip => 'Encontrada';

  @override
  String get sinReportesActivos => 'No hay reportes activos por ahora';

  @override
  String get misReportesTitulo => 'Mis reportes';

  @override
  String get sinMisReportesActivos => 'No tienes reportes activos por ahora';

  @override
  String get errorCargarReportes =>
      'No se pudieron cargar los reportes. Revisa tu conexión.';

  @override
  String get accionReportarFab => 'Reportar';

  @override
  String get verPorTipo => 'Ver por tipo';

  @override
  String get verCronologico => 'Ver cronológico';

  @override
  String get vistaCronologicaTitulo => 'Orden cronológico';
}
