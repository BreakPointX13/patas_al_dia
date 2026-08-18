import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('en'),
    Locale('es'),
    Locale('pt'),
  ];

  /// No description provided for @appTitulo.
  ///
  /// In es, this message translates to:
  /// **'Patas al Día'**
  String get appTitulo;

  /// No description provided for @accionGuardar.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get accionGuardar;

  /// No description provided for @accionCancelar.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get accionCancelar;

  /// No description provided for @accionEliminar.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get accionEliminar;

  /// No description provided for @accionEditar.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get accionEditar;

  /// No description provided for @valorSi.
  ///
  /// In es, this message translates to:
  /// **'Sí'**
  String get valorSi;

  /// No description provided for @valorNo.
  ///
  /// In es, this message translates to:
  /// **'No'**
  String get valorNo;

  /// No description provided for @noEspecificado.
  ///
  /// In es, this message translates to:
  /// **'No especificado'**
  String get noEspecificado;

  /// No description provided for @noEspecificada.
  ///
  /// In es, this message translates to:
  /// **'No especificada'**
  String get noEspecificada;

  /// No description provided for @aniosCantidad.
  ///
  /// In es, this message translates to:
  /// **'{n} años'**
  String aniosCantidad(Object n);

  /// No description provided for @navMascotas.
  ///
  /// In es, this message translates to:
  /// **'Mascotas'**
  String get navMascotas;

  /// No description provided for @navAgenda.
  ///
  /// In es, this message translates to:
  /// **'Agenda'**
  String get navAgenda;

  /// No description provided for @navMapa.
  ///
  /// In es, this message translates to:
  /// **'Mapa'**
  String get navMapa;

  /// No description provided for @loginEslogan.
  ///
  /// In es, this message translates to:
  /// **'Gestiona la salud de tu mascota, donde estés'**
  String get loginEslogan;

  /// No description provided for @loginIniciarSesion.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get loginIniciarSesion;

  /// No description provided for @loginContinuarInvitado.
  ///
  /// In es, this message translates to:
  /// **'Continuar como invitado'**
  String get loginContinuarInvitado;

  /// No description provided for @loginNoDisponible.
  ///
  /// In es, this message translates to:
  /// **'Inicio de sesión no disponible todavía: estamos en fase de desarrollo.'**
  String get loginNoDisponible;

  /// No description provided for @cuentaTooltip.
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get cuentaTooltip;

  /// No description provided for @ajustesTitulo.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get ajustesTitulo;

  /// No description provided for @homeTitulo.
  ///
  /// In es, this message translates to:
  /// **'Mis Mascotas'**
  String get homeTitulo;

  /// No description provided for @homeVacio.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes mascotas registradas'**
  String get homeVacio;

  /// No description provided for @homeAgregarMascota.
  ///
  /// In es, this message translates to:
  /// **'Agregar mascota'**
  String get homeAgregarMascota;

  /// No description provided for @credencialTooltip.
  ///
  /// In es, this message translates to:
  /// **'Credencial'**
  String get credencialTooltip;

  /// No description provided for @formMascotaTituloEditar.
  ///
  /// In es, this message translates to:
  /// **'Editar mascota'**
  String get formMascotaTituloEditar;

  /// No description provided for @fotoAnadir.
  ///
  /// In es, this message translates to:
  /// **'Añadir foto'**
  String get fotoAnadir;

  /// No description provided for @fotoCambiar.
  ///
  /// In es, this message translates to:
  /// **'Cambiar foto'**
  String get fotoCambiar;

  /// No description provided for @campoNombreObligatorio.
  ///
  /// In es, this message translates to:
  /// **'Nombre *'**
  String get campoNombreObligatorio;

  /// No description provided for @errorNombreObligatorio.
  ///
  /// In es, this message translates to:
  /// **'El nombre es obligatorio'**
  String get errorNombreObligatorio;

  /// No description provided for @campoEspecie.
  ///
  /// In es, this message translates to:
  /// **'Especie'**
  String get campoEspecie;

  /// No description provided for @campoEspecificaEspecie.
  ///
  /// In es, this message translates to:
  /// **'Especifica la especie'**
  String get campoEspecificaEspecie;

  /// No description provided for @campoRaza.
  ///
  /// In es, this message translates to:
  /// **'Raza'**
  String get campoRaza;

  /// No description provided for @formCampoRut.
  ///
  /// In es, this message translates to:
  /// **'Rut de la mascota'**
  String get formCampoRut;

  /// No description provided for @campoNumeroChip.
  ///
  /// In es, this message translates to:
  /// **'Número de chip'**
  String get campoNumeroChip;

  /// No description provided for @campoSexo.
  ///
  /// In es, this message translates to:
  /// **'Sexo'**
  String get campoSexo;

  /// No description provided for @campoColores.
  ///
  /// In es, this message translates to:
  /// **'Colores'**
  String get campoColores;

  /// No description provided for @campoPesoKg.
  ///
  /// In es, this message translates to:
  /// **'Peso (kg)'**
  String get campoPesoKg;

  /// No description provided for @errorPesoInvalido.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un peso válido'**
  String get errorPesoInvalido;

  /// No description provided for @campoEsterilizado.
  ///
  /// In es, this message translates to:
  /// **'Esterilizado'**
  String get campoEsterilizado;

  /// No description provided for @campoFechaEstimadaSwitch.
  ///
  /// In es, this message translates to:
  /// **'No sé la fecha exacta de nacimiento'**
  String get campoFechaEstimadaSwitch;

  /// No description provided for @campoEdadEstimadaAnios.
  ///
  /// In es, this message translates to:
  /// **'Edad estimada (años)'**
  String get campoEdadEstimadaAnios;

  /// No description provided for @errorEdadEstimadaVacia.
  ///
  /// In es, this message translates to:
  /// **'Ingresa la edad estimada'**
  String get errorEdadEstimadaVacia;

  /// No description provided for @errorEdadEstimadaInvalida.
  ///
  /// In es, this message translates to:
  /// **'Ingresa una edad válida (1 a 30 años)'**
  String get errorEdadEstimadaInvalida;

  /// No description provided for @fechaNacimientoNoSeleccionada.
  ///
  /// In es, this message translates to:
  /// **'Fecha de nacimiento no seleccionada'**
  String get fechaNacimientoNoSeleccionada;

  /// No description provided for @fechaNacimientoConValor.
  ///
  /// In es, this message translates to:
  /// **'Fecha de nacimiento: {fecha}'**
  String fechaNacimientoConValor(Object fecha);

  /// No description provided for @elegirFecha.
  ///
  /// In es, this message translates to:
  /// **'Elegir fecha'**
  String get elegirFecha;

  /// No description provided for @especiePerro.
  ///
  /// In es, this message translates to:
  /// **'Perro'**
  String get especiePerro;

  /// No description provided for @especieGato.
  ///
  /// In es, this message translates to:
  /// **'Gato'**
  String get especieGato;

  /// No description provided for @especieConejo.
  ///
  /// In es, this message translates to:
  /// **'Conejo'**
  String get especieConejo;

  /// No description provided for @especieHamster.
  ///
  /// In es, this message translates to:
  /// **'Hamster'**
  String get especieHamster;

  /// No description provided for @especieCobaya.
  ///
  /// In es, this message translates to:
  /// **'Cobaya'**
  String get especieCobaya;

  /// No description provided for @especieJerbo.
  ///
  /// In es, this message translates to:
  /// **'Jerbo'**
  String get especieJerbo;

  /// No description provided for @especieRata.
  ///
  /// In es, this message translates to:
  /// **'Rata'**
  String get especieRata;

  /// No description provided for @especieChinchilla.
  ///
  /// In es, this message translates to:
  /// **'Chinchilla'**
  String get especieChinchilla;

  /// No description provided for @especieErizo.
  ///
  /// In es, this message translates to:
  /// **'Erizo'**
  String get especieErizo;

  /// No description provided for @especiePez.
  ///
  /// In es, this message translates to:
  /// **'Pez'**
  String get especiePez;

  /// No description provided for @especieTortuga.
  ///
  /// In es, this message translates to:
  /// **'Tortuga'**
  String get especieTortuga;

  /// No description provided for @especieHuron.
  ///
  /// In es, this message translates to:
  /// **'Hurón'**
  String get especieHuron;

  /// No description provided for @especieAve.
  ///
  /// In es, this message translates to:
  /// **'Ave'**
  String get especieAve;

  /// No description provided for @especieOtro.
  ///
  /// In es, this message translates to:
  /// **'Otro'**
  String get especieOtro;

  /// No description provided for @sexoMacho.
  ///
  /// In es, this message translates to:
  /// **'Macho'**
  String get sexoMacho;

  /// No description provided for @sexoHembra.
  ///
  /// In es, this message translates to:
  /// **'Hembra'**
  String get sexoHembra;

  /// No description provided for @rutMascotaLabel.
  ///
  /// In es, this message translates to:
  /// **'RUT de la mascota'**
  String get rutMascotaLabel;

  /// No description provided for @pesoLabel.
  ///
  /// In es, this message translates to:
  /// **'Peso'**
  String get pesoLabel;

  /// No description provided for @edadEstimadaLabel.
  ///
  /// In es, this message translates to:
  /// **'Edad estimada'**
  String get edadEstimadaLabel;

  /// No description provided for @fechaNacimientoLabel.
  ///
  /// In es, this message translates to:
  /// **'Fecha de nacimiento'**
  String get fechaNacimientoLabel;

  /// No description provided for @edadLabel.
  ///
  /// In es, this message translates to:
  /// **'Edad'**
  String get edadLabel;

  /// No description provided for @accionAgenda.
  ///
  /// In es, this message translates to:
  /// **'Agenda'**
  String get accionAgenda;

  /// No description provided for @accionDocumentos.
  ///
  /// In es, this message translates to:
  /// **'Documentos'**
  String get accionDocumentos;

  /// No description provided for @eliminarMascotaTitulo.
  ///
  /// In es, this message translates to:
  /// **'Eliminar mascota'**
  String get eliminarMascotaTitulo;

  /// No description provided for @eliminarMascotaContenido.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar a {nombre}? Se van a borrar también su agenda y sus documentos. Esta acción no se puede deshacer.'**
  String eliminarMascotaContenido(Object nombre);

  /// No description provided for @compartirTooltip.
  ///
  /// In es, this message translates to:
  /// **'Compartir'**
  String get compartirTooltip;

  /// No description provided for @compartirTexto.
  ///
  /// In es, this message translates to:
  /// **'Credencial de {nombre}'**
  String compartirTexto(Object nombre);

  /// No description provided for @temaLabel.
  ///
  /// In es, this message translates to:
  /// **'Tema'**
  String get temaLabel;

  /// No description provided for @temaSistema.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get temaSistema;

  /// No description provided for @temaClaro.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get temaClaro;

  /// No description provided for @temaOscuro.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get temaOscuro;

  /// No description provided for @tamanoLetraLabel.
  ///
  /// In es, this message translates to:
  /// **'Tamaño de letra'**
  String get tamanoLetraLabel;

  /// No description provided for @tamanoPequeno.
  ///
  /// In es, this message translates to:
  /// **'Pequeño'**
  String get tamanoPequeno;

  /// No description provided for @tamanoNormal.
  ///
  /// In es, this message translates to:
  /// **'Normal'**
  String get tamanoNormal;

  /// No description provided for @tamanoGrande.
  ///
  /// In es, this message translates to:
  /// **'Grande'**
  String get tamanoGrande;

  /// No description provided for @idiomaLabel.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get idiomaLabel;

  /// No description provided for @aportesVoluntariosLabel.
  ///
  /// In es, this message translates to:
  /// **'Aportes voluntarios'**
  String get aportesVoluntariosLabel;

  /// No description provided for @aportesVoluntariosSubtitulo.
  ///
  /// In es, this message translates to:
  /// **'Si quieres apoyar el proyecto, es en Ko-fi'**
  String get aportesVoluntariosSubtitulo;

  /// No description provided for @errorAbrirEnlace.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir el enlace'**
  String get errorAbrirEnlace;

  /// No description provided for @cerrarSesionLabel.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get cerrarSesionLabel;

  /// No description provided for @cerrarSesionContenido.
  ///
  /// In es, this message translates to:
  /// **'Como invitado, no hay forma de volver a esta sesión después de cerrarla: no vas a poder ver de nuevo tus mascotas ni los datos cargados. ¿Cerrar sesión de todos modos?'**
  String get cerrarSesionContenido;

  /// No description provided for @valorOtro.
  ///
  /// In es, this message translates to:
  /// **'Otro'**
  String get valorOtro;

  /// No description provided for @tipoEventoVacuna.
  ///
  /// In es, this message translates to:
  /// **'Vacuna'**
  String get tipoEventoVacuna;

  /// No description provided for @tipoEventoDesparasitacion.
  ///
  /// In es, this message translates to:
  /// **'Desparasitación'**
  String get tipoEventoDesparasitacion;

  /// No description provided for @tipoEventoPeluqueria.
  ///
  /// In es, this message translates to:
  /// **'Peluquería'**
  String get tipoEventoPeluqueria;

  /// No description provided for @tipoEventoOperacion.
  ///
  /// In es, this message translates to:
  /// **'Operación'**
  String get tipoEventoOperacion;

  /// No description provided for @tipoEventoControl.
  ///
  /// In es, this message translates to:
  /// **'Control'**
  String get tipoEventoControl;

  /// No description provided for @tipoEventoExamen.
  ///
  /// In es, this message translates to:
  /// **'Examen'**
  String get tipoEventoExamen;

  /// No description provided for @tipoDocumentoCarnetVacunacion.
  ///
  /// In es, this message translates to:
  /// **'Carnet de vacunación'**
  String get tipoDocumentoCarnetVacunacion;

  /// No description provided for @tipoDocumentoReceta.
  ///
  /// In es, this message translates to:
  /// **'Receta'**
  String get tipoDocumentoReceta;

  /// No description provided for @tipoDocumentoExamen.
  ///
  /// In es, this message translates to:
  /// **'Examen'**
  String get tipoDocumentoExamen;

  /// No description provided for @tipoDocumentoCertificado.
  ///
  /// In es, this message translates to:
  /// **'Certificado'**
  String get tipoDocumentoCertificado;

  /// No description provided for @tipoDocumentoBoleta.
  ///
  /// In es, this message translates to:
  /// **'Boleta'**
  String get tipoDocumentoBoleta;

  /// No description provided for @tipoPresentacionComprimido.
  ///
  /// In es, this message translates to:
  /// **'Comprimido'**
  String get tipoPresentacionComprimido;

  /// No description provided for @tipoPresentacionLiquido.
  ///
  /// In es, this message translates to:
  /// **'Líquido'**
  String get tipoPresentacionLiquido;

  /// No description provided for @tipoPresentacionInyectable.
  ///
  /// In es, this message translates to:
  /// **'Inyectable'**
  String get tipoPresentacionInyectable;

  /// No description provided for @tipoPresentacionPomada.
  ///
  /// In es, this message translates to:
  /// **'Pomada/crema'**
  String get tipoPresentacionPomada;

  /// No description provided for @tipoPresentacionGotas.
  ///
  /// In es, this message translates to:
  /// **'Gotas'**
  String get tipoPresentacionGotas;

  /// No description provided for @tipoPresentacionPipeta.
  ///
  /// In es, this message translates to:
  /// **'Pipeta'**
  String get tipoPresentacionPipeta;

  /// No description provided for @recordatorio1Dia.
  ///
  /// In es, this message translates to:
  /// **'1 día antes'**
  String get recordatorio1Dia;

  /// No description provided for @recordatorio12Horas.
  ///
  /// In es, this message translates to:
  /// **'12 horas antes'**
  String get recordatorio12Horas;

  /// No description provided for @recordatorio6Horas.
  ///
  /// In es, this message translates to:
  /// **'6 horas antes'**
  String get recordatorio6Horas;

  /// No description provided for @recordatorio1Hora.
  ///
  /// In es, this message translates to:
  /// **'1 hora antes'**
  String get recordatorio1Hora;

  /// No description provided for @recordatorioHorasGenerico.
  ///
  /// In es, this message translates to:
  /// **'{h} horas antes'**
  String recordatorioHorasGenerico(Object h);

  /// No description provided for @filtrarPorMascotaTitulo.
  ///
  /// In es, this message translates to:
  /// **'Filtrar por mascota'**
  String get filtrarPorMascotaTitulo;

  /// No description provided for @filtroTodas.
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get filtroTodas;

  /// No description provided for @accionAplicar.
  ///
  /// In es, this message translates to:
  /// **'Aplicar'**
  String get accionAplicar;

  /// No description provided for @eventoFuturoTitulo.
  ///
  /// In es, this message translates to:
  /// **'Evento futuro'**
  String get eventoFuturoTitulo;

  /// No description provided for @eventoFuturoSubtitulo.
  ///
  /// In es, this message translates to:
  /// **'Recordatorio para una próxima cita'**
  String get eventoFuturoSubtitulo;

  /// No description provided for @eventoPasadoTitulo.
  ///
  /// In es, this message translates to:
  /// **'Evento pasado'**
  String get eventoPasadoTitulo;

  /// No description provided for @eventoPasadoSubtitulo.
  ///
  /// In es, this message translates to:
  /// **'Registrar una consulta ya realizada'**
  String get eventoPasadoSubtitulo;

  /// No description provided for @filtroTodasLasMascotas.
  ///
  /// In es, this message translates to:
  /// **'Todas las mascotas'**
  String get filtroTodasLasMascotas;

  /// No description provided for @filtroSinMascotasSeleccionadas.
  ///
  /// In es, this message translates to:
  /// **'Sin mascotas seleccionadas'**
  String get filtroSinMascotasSeleccionadas;

  /// No description provided for @mascotaFallback.
  ///
  /// In es, this message translates to:
  /// **'Mascota'**
  String get mascotaFallback;

  /// No description provided for @proximoEventoLabel.
  ///
  /// In es, this message translates to:
  /// **'Próximo evento'**
  String get proximoEventoLabel;

  /// No description provided for @proximosEventosLabel.
  ///
  /// In es, this message translates to:
  /// **'Próximos eventos'**
  String get proximosEventosLabel;

  /// No description provided for @etiquetaProximo.
  ///
  /// In es, this message translates to:
  /// **'PRÓXIMO'**
  String get etiquetaProximo;

  /// No description provided for @diasAtrasado.
  ///
  /// In es, this message translates to:
  /// **'Atrasado'**
  String get diasAtrasado;

  /// No description provided for @diasHoy.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get diasHoy;

  /// No description provided for @diasManana.
  ///
  /// In es, this message translates to:
  /// **'Mañana'**
  String get diasManana;

  /// No description provided for @diasEnNumero.
  ///
  /// In es, this message translates to:
  /// **'En {n} días'**
  String diasEnNumero(Object n);

  /// No description provided for @documentoAdjuntoLabel.
  ///
  /// In es, this message translates to:
  /// **'Documento adjunto'**
  String get documentoAdjuntoLabel;

  /// No description provided for @noEventosProgramados.
  ///
  /// In es, this message translates to:
  /// **'No hay eventos programados'**
  String get noEventosProgramados;

  /// No description provided for @tocaUnDiaParaVerEventos.
  ///
  /// In es, this message translates to:
  /// **'Toca un día para ver sus eventos'**
  String get tocaUnDiaParaVerEventos;

  /// No description provided for @sinEventosEsteDia.
  ///
  /// In es, this message translates to:
  /// **'Sin eventos este día'**
  String get sinEventosEsteDia;

  /// No description provided for @noMasEventosProgramados.
  ///
  /// In es, this message translates to:
  /// **'No hay más eventos programados'**
  String get noMasEventosProgramados;

  /// No description provided for @verComoLista.
  ///
  /// In es, this message translates to:
  /// **'Ver como lista'**
  String get verComoLista;

  /// No description provided for @verCalendario.
  ///
  /// In es, this message translates to:
  /// **'Ver calendario'**
  String get verCalendario;

  /// No description provided for @mostrandoFiltro.
  ///
  /// In es, this message translates to:
  /// **'Mostrando: {filtro}'**
  String mostrandoFiltro(Object filtro);

  /// No description provided for @noHayMascotasCreadas.
  ///
  /// In es, this message translates to:
  /// **'No hay mascotas creadas'**
  String get noHayMascotasCreadas;

  /// No description provided for @agregarEvento.
  ///
  /// In es, this message translates to:
  /// **'Agregar evento'**
  String get agregarEvento;

  /// No description provided for @eliminarEventoTitulo.
  ///
  /// In es, this message translates to:
  /// **'Eliminar evento'**
  String get eliminarEventoTitulo;

  /// No description provided for @eliminarEventoContenido.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar \"{titulo}\"? Los medicamentos registrados se eliminan con el evento; los documentos adjuntos se conservan, solo pierden el vínculo con este evento.'**
  String eliminarEventoContenido(Object titulo);

  /// No description provided for @campoMascota.
  ///
  /// In es, this message translates to:
  /// **'Mascota'**
  String get campoMascota;

  /// No description provided for @campoTipoEvento.
  ///
  /// In es, this message translates to:
  /// **'Tipo de evento'**
  String get campoTipoEvento;

  /// No description provided for @campoFechaProgramada.
  ///
  /// In es, this message translates to:
  /// **'Fecha programada'**
  String get campoFechaProgramada;

  /// No description provided for @campoObservaciones.
  ///
  /// In es, this message translates to:
  /// **'Observaciones'**
  String get campoObservaciones;

  /// No description provided for @sinObservaciones.
  ///
  /// In es, this message translates to:
  /// **'Sin observaciones'**
  String get sinObservaciones;

  /// No description provided for @campoRecordatorio.
  ///
  /// In es, this message translates to:
  /// **'Recordatorio'**
  String get campoRecordatorio;

  /// No description provided for @sinRecordatorio.
  ///
  /// In es, this message translates to:
  /// **'Sin recordatorio'**
  String get sinRecordatorio;

  /// No description provided for @realizadoLabel.
  ///
  /// In es, this message translates to:
  /// **'Realizado'**
  String get realizadoLabel;

  /// No description provided for @marcarComoRealizado.
  ///
  /// In es, this message translates to:
  /// **'Marcar como realizado'**
  String get marcarComoRealizado;

  /// No description provided for @medicamentosLabel.
  ///
  /// In es, this message translates to:
  /// **'Medicamentos'**
  String get medicamentosLabel;

  /// No description provided for @sinMedicamentosRegistrados.
  ///
  /// In es, this message translates to:
  /// **'Sin medicamentos registrados'**
  String get sinMedicamentosRegistrados;

  /// No description provided for @documentosAdjuntosLabel.
  ///
  /// In es, this message translates to:
  /// **'Documentos adjuntos'**
  String get documentosAdjuntosLabel;

  /// No description provided for @sinDocumentosAdjuntos.
  ///
  /// In es, this message translates to:
  /// **'Sin documentos adjuntos'**
  String get sinDocumentosAdjuntos;

  /// No description provided for @editarEventoLabel.
  ///
  /// In es, this message translates to:
  /// **'Editar evento'**
  String get editarEventoLabel;

  /// No description provided for @formEventoTituloEditar.
  ///
  /// In es, this message translates to:
  /// **'Editar evento'**
  String get formEventoTituloEditar;

  /// No description provided for @formEventoTituloAgregarPasado.
  ///
  /// In es, this message translates to:
  /// **'Agregar evento pasado'**
  String get formEventoTituloAgregarPasado;

  /// No description provided for @formEventoTituloAgregarFuturo.
  ///
  /// In es, this message translates to:
  /// **'Agregar evento futuro'**
  String get formEventoTituloAgregarFuturo;

  /// No description provided for @campoMascotaObligatorio.
  ///
  /// In es, this message translates to:
  /// **'Mascota *'**
  String get campoMascotaObligatorio;

  /// No description provided for @errorSeleccionaMascota.
  ///
  /// In es, this message translates to:
  /// **'Selecciona una mascota'**
  String get errorSeleccionaMascota;

  /// No description provided for @campoTituloObligatorio.
  ///
  /// In es, this message translates to:
  /// **'Título *'**
  String get campoTituloObligatorio;

  /// No description provided for @errorTituloObligatorio.
  ///
  /// In es, this message translates to:
  /// **'El título es obligatorio'**
  String get errorTituloObligatorio;

  /// No description provided for @campoEspecificaElTipo.
  ///
  /// In es, this message translates to:
  /// **'Especifica el tipo'**
  String get campoEspecificaElTipo;

  /// No description provided for @fechaHoraNoSeleccionadas.
  ///
  /// In es, this message translates to:
  /// **'Fecha y hora no seleccionadas'**
  String get fechaHoraNoSeleccionadas;

  /// No description provided for @fechaConValor.
  ///
  /// In es, this message translates to:
  /// **'Fecha: {fecha}'**
  String fechaConValor(Object fecha);

  /// No description provided for @accionElegir.
  ///
  /// In es, this message translates to:
  /// **'Elegir'**
  String get accionElegir;

  /// No description provided for @avisarLabel.
  ///
  /// In es, this message translates to:
  /// **'Avisar'**
  String get avisarLabel;

  /// No description provided for @accionAgregar.
  ///
  /// In es, this message translates to:
  /// **'Agregar'**
  String get accionAgregar;

  /// No description provided for @campoProgramarProximaConsulta.
  ///
  /// In es, this message translates to:
  /// **'Programar próxima consulta'**
  String get campoProgramarProximaConsulta;

  /// No description provided for @elegirElDia.
  ///
  /// In es, this message translates to:
  /// **'Elige el día'**
  String get elegirElDia;

  /// No description provided for @horaNoPaso.
  ///
  /// In es, this message translates to:
  /// **'La hora elegida todavía no pasó. Elige una hora anterior a la actual.'**
  String get horaNoPaso;

  /// No description provided for @segundaMitadDeshabilitadaAviso.
  ///
  /// In es, this message translates to:
  /// **'El resto de la información (observaciones, medicamentos, documentos) se habilita cuando llegue la fecha del evento.'**
  String get segundaMitadDeshabilitadaAviso;

  /// No description provided for @agregarMedicamentoTitulo.
  ///
  /// In es, this message translates to:
  /// **'Agregar medicamento'**
  String get agregarMedicamentoTitulo;

  /// No description provided for @editarMedicamentoTitulo.
  ///
  /// In es, this message translates to:
  /// **'Editar medicamento'**
  String get editarMedicamentoTitulo;

  /// No description provided for @campoPresentacion.
  ///
  /// In es, this message translates to:
  /// **'Presentación'**
  String get campoPresentacion;

  /// No description provided for @datosDocumentoTitulo.
  ///
  /// In es, this message translates to:
  /// **'Datos del documento'**
  String get datosDocumentoTitulo;

  /// No description provided for @campoTipo.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get campoTipo;

  /// No description provided for @tomarFoto.
  ///
  /// In es, this message translates to:
  /// **'Tomar foto'**
  String get tomarFoto;

  /// No description provided for @elegirImagenGaleria.
  ///
  /// In es, this message translates to:
  /// **'Elegir imagen de galería'**
  String get elegirImagenGaleria;

  /// No description provided for @elegirPdf.
  ///
  /// In es, this message translates to:
  /// **'Elegir PDF'**
  String get elegirPdf;

  /// No description provided for @seleccionaMascotaPrimero.
  ///
  /// In es, this message translates to:
  /// **'Selecciona una mascota primero'**
  String get seleccionaMascotaPrimero;

  /// No description provided for @errorFechaYHora.
  ///
  /// In es, this message translates to:
  /// **'Selecciona fecha y hora'**
  String get errorFechaYHora;

  /// No description provided for @agregarDocumentoLabel.
  ///
  /// In es, this message translates to:
  /// **'Agregar documento'**
  String get agregarDocumentoLabel;

  /// No description provided for @editarDocumentoLabel.
  ///
  /// In es, this message translates to:
  /// **'Editar documento'**
  String get editarDocumentoLabel;

  /// No description provided for @sinArchivoElegido.
  ///
  /// In es, this message translates to:
  /// **'Sin archivo elegido'**
  String get sinArchivoElegido;

  /// No description provided for @archivoElegido.
  ///
  /// In es, this message translates to:
  /// **'Archivo elegido'**
  String get archivoElegido;

  /// No description provided for @accionCambiar.
  ///
  /// In es, this message translates to:
  /// **'Cambiar'**
  String get accionCambiar;

  /// No description provided for @fechaEmisionNoEspecificada.
  ///
  /// In es, this message translates to:
  /// **'Fecha de emisión no especificada'**
  String get fechaEmisionNoEspecificada;

  /// No description provided for @fechaEmitidaConValor.
  ///
  /// In es, this message translates to:
  /// **'Emitido: {fecha}'**
  String fechaEmitidaConValor(Object fecha);

  /// No description provided for @fechaVencimientoOpcional.
  ///
  /// In es, this message translates to:
  /// **'Fecha de vencimiento (opcional)'**
  String get fechaVencimientoOpcional;

  /// No description provided for @fechaVenceConValor.
  ///
  /// In es, this message translates to:
  /// **'Vence: {fecha}'**
  String fechaVenceConValor(Object fecha);

  /// No description provided for @recordatorioVencimientoLabel.
  ///
  /// In es, this message translates to:
  /// **'Recordatorio de vencimiento'**
  String get recordatorioVencimientoLabel;

  /// No description provided for @recordatorioVencimientoAviso.
  ///
  /// In es, this message translates to:
  /// **'Por ahora solo queda guardado como dato, todavía no envía una notificación.'**
  String get recordatorioVencimientoAviso;

  /// No description provided for @campoNotas.
  ///
  /// In es, this message translates to:
  /// **'Notas'**
  String get campoNotas;

  /// No description provided for @eligeFotoOPdf.
  ///
  /// In es, this message translates to:
  /// **'Elige una foto o un PDF'**
  String get eligeFotoOPdf;

  /// No description provided for @eliminarDocumentoTitulo.
  ///
  /// In es, this message translates to:
  /// **'Eliminar documento'**
  String get eliminarDocumentoTitulo;

  /// No description provided for @eliminarDocumentoContenido.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar \"{titulo}\"?'**
  String eliminarDocumentoContenido(Object titulo);

  /// No description provided for @fechaEmisionLabel.
  ///
  /// In es, this message translates to:
  /// **'Fecha de emisión'**
  String get fechaEmisionLabel;

  /// No description provided for @fechaVencimientoLabel.
  ///
  /// In es, this message translates to:
  /// **'Fecha de vencimiento'**
  String get fechaVencimientoLabel;

  /// No description provided for @conRecordatorioSufijo.
  ///
  /// In es, this message translates to:
  /// **' (con recordatorio)'**
  String get conRecordatorioSufijo;

  /// No description provided for @sinNotas.
  ///
  /// In es, this message translates to:
  /// **'Sin notas'**
  String get sinNotas;

  /// No description provided for @vinculadoAlEventoLabel.
  ///
  /// In es, this message translates to:
  /// **'Vinculado al evento'**
  String get vinculadoAlEventoLabel;

  /// No description provided for @abrirDocumentoLabel.
  ///
  /// In es, this message translates to:
  /// **'Abrir documento'**
  String get abrirDocumentoLabel;

  /// No description provided for @verPantallaCompletaLabel.
  ///
  /// In es, this message translates to:
  /// **'Ver a pantalla completa'**
  String get verPantallaCompletaLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
