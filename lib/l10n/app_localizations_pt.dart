// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitulo => 'Patas al Día';

  @override
  String get accionGuardar => 'Salvar';

  @override
  String get accionCancelar => 'Cancelar';

  @override
  String get accionEliminar => 'Excluir';

  @override
  String get accionEditar => 'Editar';

  @override
  String get valorSi => 'Sim';

  @override
  String get valorNo => 'Não';

  @override
  String get noEspecificado => 'Não especificado';

  @override
  String get noEspecificada => 'Não especificada';

  @override
  String aniosCantidad(Object n) {
    return '$n anos';
  }

  @override
  String get navMascotas => 'Pets';

  @override
  String get navAgenda => 'Agenda';

  @override
  String get navMapa => 'Mapa';

  @override
  String get loginEslogan => 'Cuide da saúde do seu pet, onde você estiver';

  @override
  String get loginIniciarSesion => 'Entrar';

  @override
  String get loginContinuarInvitado => 'Continuar como convidado';

  @override
  String get loginNoDisponible =>
      'Login ainda não disponível: estamos em fase de desenvolvimento.';

  @override
  String get cuentaTooltip => 'Conta';

  @override
  String get ajustesTitulo => 'Configurações';

  @override
  String get homeTitulo => 'Meus Pets';

  @override
  String get homeVacio => 'Você ainda não tem pets cadastrados';

  @override
  String get homeAgregarMascota => 'Adicionar pet';

  @override
  String get credencialTooltip => 'Carteirinha';

  @override
  String get formMascotaTituloEditar => 'Editar pet';

  @override
  String get fotoAnadir => 'Adicionar foto';

  @override
  String get fotoCambiar => 'Trocar foto';

  @override
  String get campoNombreObligatorio => 'Nome *';

  @override
  String get errorNombreObligatorio => 'O nome é obrigatório';

  @override
  String get campoEspecie => 'Espécie';

  @override
  String get campoEspecificaEspecie => 'Especifique a espécie';

  @override
  String get campoRaza => 'Raça';

  @override
  String get formCampoRut => 'Identificação do pet';

  @override
  String get campoNumeroChip => 'Número do chip';

  @override
  String get campoSexo => 'Sexo';

  @override
  String get campoColores => 'Cores';

  @override
  String get campoPesoKg => 'Peso (kg)';

  @override
  String get errorPesoInvalido => 'Digite um peso válido';

  @override
  String get campoEsterilizado => 'Castrado';

  @override
  String get campoFechaEstimadaSwitch => 'Não sei a data exata de nascimento';

  @override
  String get campoEdadEstimadaAnios => 'Idade estimada (anos)';

  @override
  String get errorEdadEstimadaVacia => 'Digite a idade estimada';

  @override
  String get errorEdadEstimadaInvalida =>
      'Digite uma idade válida (1 a 30 anos)';

  @override
  String get fechaNacimientoNoSeleccionada =>
      'Data de nascimento não selecionada';

  @override
  String fechaNacimientoConValor(Object fecha) {
    return 'Data de nascimento: $fecha';
  }

  @override
  String get elegirFecha => 'Escolher data';

  @override
  String get especiePerro => 'Cachorro';

  @override
  String get especieGato => 'Gato';

  @override
  String get especieConejo => 'Coelho';

  @override
  String get especieHamster => 'Hamster';

  @override
  String get especieCobaya => 'Porquinho-da-índia';

  @override
  String get especieJerbo => 'Gerbo';

  @override
  String get especieRata => 'Rato';

  @override
  String get especieChinchilla => 'Chinchila';

  @override
  String get especieErizo => 'Ouriço';

  @override
  String get especiePez => 'Peixe';

  @override
  String get especieTortuga => 'Tartaruga';

  @override
  String get especieHuron => 'Furão';

  @override
  String get especieAve => 'Ave';

  @override
  String get especieOtro => 'Outro';

  @override
  String get sexoMacho => 'Macho';

  @override
  String get sexoHembra => 'Fêmea';

  @override
  String get rutMascotaLabel => 'Identificação do pet';

  @override
  String get pesoLabel => 'Peso';

  @override
  String get edadEstimadaLabel => 'Idade estimada';

  @override
  String get fechaNacimientoLabel => 'Data de nascimento';

  @override
  String get edadLabel => 'Idade';

  @override
  String get accionAgenda => 'Agenda';

  @override
  String get accionDocumentos => 'Documentos';

  @override
  String get eliminarMascotaTitulo => 'Excluir pet';

  @override
  String eliminarMascotaContenido(Object nombre) {
    return 'Excluir $nombre? A agenda e os documentos associados também serão excluídos. Esta ação não pode ser desfeita.';
  }

  @override
  String get compartirTooltip => 'Compartilhar';

  @override
  String compartirTexto(Object nombre) {
    return 'Carteirinha de $nombre';
  }

  @override
  String get temaLabel => 'Tema';

  @override
  String get temaSistema => 'Sistema';

  @override
  String get temaClaro => 'Claro';

  @override
  String get temaOscuro => 'Escuro';

  @override
  String get tamanoLetraLabel => 'Tamanho do texto';

  @override
  String get tamanoPequeno => 'Pequeno';

  @override
  String get tamanoNormal => 'Normal';

  @override
  String get tamanoGrande => 'Grande';

  @override
  String get idiomaLabel => 'Idioma';

  @override
  String get aportesVoluntariosLabel => 'Apoie o projeto';

  @override
  String get aportesVoluntariosSubtitulo =>
      'Se quiser apoiar o projeto, é pelo Ko-fi';

  @override
  String get errorAbrirEnlace => 'Não foi possível abrir o link';

  @override
  String get cerrarSesionLabel => 'Sair';

  @override
  String get cerrarSesionContenido =>
      'Como convidado, não há como voltar a esta sessão depois de sair: você não vai poder ver seus pets nem os dados salvos novamente. Sair mesmo assim?';

  @override
  String get valorOtro => 'Outro';

  @override
  String get tipoEventoVacuna => 'Vacina';

  @override
  String get tipoEventoDesparasitacion => 'Vermifugação';

  @override
  String get tipoEventoPeluqueria => 'Banho e tosa';

  @override
  String get tipoEventoOperacion => 'Cirurgia';

  @override
  String get tipoEventoControl => 'Consulta';

  @override
  String get tipoEventoExamen => 'Exame';

  @override
  String get tipoDocumentoCarnetVacunacion => 'Carteira de vacinação';

  @override
  String get tipoDocumentoReceta => 'Receita';

  @override
  String get tipoDocumentoExamen => 'Resultado de exame';

  @override
  String get tipoDocumentoCertificado => 'Certificado';

  @override
  String get tipoDocumentoBoleta => 'Recibo';

  @override
  String get tipoPresentacionComprimido => 'Comprimido';

  @override
  String get tipoPresentacionLiquido => 'Líquido';

  @override
  String get tipoPresentacionInyectable => 'Injetável';

  @override
  String get tipoPresentacionPomada => 'Pomada/creme';

  @override
  String get tipoPresentacionGotas => 'Gotas';

  @override
  String get tipoPresentacionPipeta => 'Pipeta';

  @override
  String get recordatorio1Dia => '1 dia antes';

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
  String get filtrarPorMascotaTitulo => 'Filtrar por pet';

  @override
  String get filtroTodas => 'Todos';

  @override
  String get accionAplicar => 'Aplicar';

  @override
  String get eventoFuturoTitulo => 'Evento futuro';

  @override
  String get eventoFuturoSubtitulo => 'Lembrete para uma próxima consulta';

  @override
  String get eventoPasadoTitulo => 'Evento passado';

  @override
  String get eventoPasadoSubtitulo => 'Registrar uma consulta já realizada';

  @override
  String get filtroTodasLasMascotas => 'Todos os pets';

  @override
  String get filtroSinMascotasSeleccionadas => 'Nenhum pet selecionado';

  @override
  String get mascotaFallback => 'Pet';

  @override
  String get proximoEventoLabel => 'Próximo evento';

  @override
  String get proximosEventosLabel => 'Próximos eventos';

  @override
  String get etiquetaProximo => 'PRÓXIMO';

  @override
  String get diasAtrasado => 'Atrasado';

  @override
  String get diasHoy => 'Hoje';

  @override
  String get diasManana => 'Amanhã';

  @override
  String diasEnNumero(Object n) {
    return 'Em $n dias';
  }

  @override
  String get documentoAdjuntoLabel => 'Documento anexado';

  @override
  String get noEventosProgramados => 'Nenhum evento agendado';

  @override
  String get tocaUnDiaParaVerEventos => 'Toque em um dia para ver seus eventos';

  @override
  String get sinEventosEsteDia => 'Nenhum evento neste dia';

  @override
  String get noMasEventosProgramados => 'Não há mais eventos agendados';

  @override
  String get verComoLista => 'Ver como lista';

  @override
  String get verCalendario => 'Ver calendário';

  @override
  String mostrandoFiltro(Object filtro) {
    return 'Mostrando: $filtro';
  }

  @override
  String get noHayMascotasCreadas => 'Nenhum pet cadastrado';

  @override
  String get agregarEvento => 'Adicionar evento';

  @override
  String get eliminarEventoTitulo => 'Excluir evento';

  @override
  String eliminarEventoContenido(Object titulo) {
    return 'Excluir \"$titulo\"? Os medicamentos registrados serão excluídos junto com o evento; os documentos anexados são mantidos, só perdem o vínculo com este evento.';
  }

  @override
  String get campoMascota => 'Pet';

  @override
  String get campoTipoEvento => 'Tipo de evento';

  @override
  String get campoFechaProgramada => 'Data agendada';

  @override
  String get campoObservaciones => 'Observações';

  @override
  String get sinObservaciones => 'Sem observações';

  @override
  String get campoRecordatorio => 'Lembrete';

  @override
  String get sinRecordatorio => 'Sem lembrete';

  @override
  String get realizadoLabel => 'Realizado';

  @override
  String get marcarComoRealizado => 'Marcar como realizado';

  @override
  String get medicamentosLabel => 'Medicamentos';

  @override
  String get sinMedicamentosRegistrados => 'Nenhum medicamento registrado';

  @override
  String get documentosAdjuntosLabel => 'Documentos anexados';

  @override
  String get sinDocumentosAdjuntos => 'Nenhum documento anexado';

  @override
  String get editarEventoLabel => 'Editar evento';

  @override
  String get formEventoTituloEditar => 'Editar evento';

  @override
  String get formEventoTituloAgregarPasado => 'Adicionar evento passado';

  @override
  String get formEventoTituloAgregarFuturo => 'Adicionar evento futuro';

  @override
  String get campoMascotaObligatorio => 'Pet *';

  @override
  String get errorSeleccionaMascota => 'Selecione um pet';

  @override
  String get campoTituloObligatorio => 'Título *';

  @override
  String get errorTituloObligatorio => 'O título é obrigatório';

  @override
  String get campoEspecificaElTipo => 'Especifique o tipo';

  @override
  String get fechaHoraNoSeleccionadas => 'Data e hora não selecionadas';

  @override
  String fechaConValor(Object fecha) {
    return 'Data: $fecha';
  }

  @override
  String get accionElegir => 'Escolher';

  @override
  String get avisarLabel => 'Avisar';

  @override
  String get accionAgregar => 'Adicionar';

  @override
  String get campoProgramarProximaConsulta => 'Agendar próxima consulta';

  @override
  String get elegirElDia => 'Escolha o dia';

  @override
  String get horaNoPaso =>
      'O horário escolhido ainda não passou. Escolha um horário anterior ao atual.';

  @override
  String get segundaMitadDeshabilitadaAviso =>
      'O restante das informações (observações, medicamentos, documentos) fica disponível quando chegar a data do evento.';

  @override
  String get agregarMedicamentoTitulo => 'Adicionar medicamento';

  @override
  String get editarMedicamentoTitulo => 'Editar medicamento';

  @override
  String get campoPresentacion => 'Apresentação';

  @override
  String get datosDocumentoTitulo => 'Dados do documento';

  @override
  String get campoTipo => 'Tipo';

  @override
  String get tomarFoto => 'Tirar foto';

  @override
  String get elegirImagenGaleria => 'Escolher imagem da galeria';

  @override
  String get elegirPdf => 'Escolher PDF';

  @override
  String get seleccionaMascotaPrimero => 'Selecione um pet primeiro';

  @override
  String get errorFechaYHora => 'Selecione data e hora';

  @override
  String get agregarDocumentoLabel => 'Adicionar documento';

  @override
  String get editarDocumentoLabel => 'Editar documento';

  @override
  String get sinArchivoElegido => 'Nenhum arquivo selecionado';

  @override
  String get archivoElegido => 'Arquivo selecionado';

  @override
  String get accionCambiar => 'Trocar';

  @override
  String get fechaEmisionNoEspecificada => 'Data de emissão não especificada';

  @override
  String fechaEmitidaConValor(Object fecha) {
    return 'Emitido em: $fecha';
  }

  @override
  String get fechaVencimientoOpcional => 'Data de validade (opcional)';

  @override
  String fechaVenceConValor(Object fecha) {
    return 'Válido até: $fecha';
  }

  @override
  String get recordatorioVencimientoLabel => 'Lembrete de vencimento';

  @override
  String get recordatorioVencimientoAviso =>
      'Por enquanto isso só fica salvo como informação, ainda não envia uma notificação.';

  @override
  String get campoNotas => 'Notas';

  @override
  String get eligeFotoOPdf => 'Escolha uma foto ou um PDF';

  @override
  String get eliminarDocumentoTitulo => 'Excluir documento';

  @override
  String eliminarDocumentoContenido(Object titulo) {
    return 'Excluir \"$titulo\"?';
  }

  @override
  String get fechaEmisionLabel => 'Data de emissão';

  @override
  String get fechaVencimientoLabel => 'Data de validade';

  @override
  String get conRecordatorioSufijo => ' (com lembrete)';

  @override
  String get sinNotas => 'Sem notas';

  @override
  String get vinculadoAlEventoLabel => 'Vinculado ao evento';

  @override
  String get abrirDocumentoLabel => 'Abrir documento';

  @override
  String get verPantallaCompletaLabel => 'Ver em tela cheia';
}
