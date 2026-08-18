import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:patas_al_dia/data/models/agenda_evento_model.dart';
import 'package:patas_al_dia/data/models/mascota_model.dart';
import 'package:patas_al_dia/presentation/screens/detalle_agenda_evento_screen.dart';
import 'package:patas_al_dia/presentation/screens/formulario_agenda_evento_screen.dart';
import 'package:patas_al_dia/presentation/widgets/logo_barra_superior.dart';
import 'package:patas_al_dia/presentation/widgets/menu_usuario_avatar.dart';
import 'package:patas_al_dia/providers/agenda_evento_provider.dart';
import 'package:patas_al_dia/providers/documento_provider.dart';
import 'package:patas_al_dia/providers/mascota_provider.dart';

const _iconosPorTipoEvento = {
  'Vacuna': 'assets/icons/eventos/vacuna.svg',
  'Desparasitación': 'assets/icons/eventos/desparasitacion.svg',
  'Peluquería': 'assets/icons/eventos/peluqueria.svg',
  'Operación': 'assets/icons/eventos/operacion.svg',
  'Control': 'assets/icons/eventos/control.svg',
  'Examen': 'assets/icons/eventos/examen.svg',
  'Otro': 'assets/icons/eventos/otro.svg',
};

String _iconoEvento(String? tipoEvento) =>
    _iconosPorTipoEvento[tipoEvento] ?? _iconosPorTipoEvento['Otro']!;

// Los textos de `agenda_screen.dart` casi siempre van dentro de tarjetas
// claras (Durazno/Crema clara) que no cambian con el tema, así que su color
// hardcodeado (Café texto/texto secundario) queda bien en los dos modos. Las
// únicas excepciones son los textos que van directo sobre el fondo de la
// pantalla (sin tarjeta detrás) — esos sí necesitan invertirse en modo
// oscuro, o quedarían ilegibles sobre el fondo oscuro nuevo.
Color _colorTextoSobreFondo(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFFFFF7EC)
    : const Color(0xFF7A4A22);

Color _colorTextoSecundarioSobreFondo(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFFFFF7EC).withValues(alpha: 0.7)
    : const Color(0xFFA06A35);

// Las tarjetas de "Próximo evento" y del timeline usan Crema clara de fondo
// en modo claro (más sutil, casi el mismo tono que el fondo Crema de la
// pantalla). En modo oscuro, Crema clara se vería demasiado brillante contra
// el fondo oscuro nuevo — se usa Durazno en su lugar, el mismo tono que ya
// usan todas las demás tarjetas de la app (`TarjetaClara`), para que las
// tarjetas se vean consistentes entre sí.
Color _colorTarjetaAgenda(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFFF3C98F)
    : const Color(0xFFFFF7EC);

String _tipoEventoTexto(AgendaEventoModel evento) {
  if (evento.tipoEvento == 'Otro' && evento.tipoEventoPersonalizado != null) {
    return evento.tipoEventoPersonalizado!;
  }
  return evento.tipoEvento ?? 'Otro';
}

String _capitalizar(String texto) =>
    texto.isEmpty ? texto : texto[0].toUpperCase() + texto.substring(1);

class AgendaScreen extends ConsumerStatefulWidget {
  final String? mascotaIdInicial;

  const AgendaScreen({super.key, this.mascotaIdInicial});

  @override
  ConsumerState<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends ConsumerState<AgendaScreen> {
  Set<String>? _mascotaIdsFiltro;
  bool _vistaCalendario = true;
  DateTime _diaEnfocado = DateTime.now();
  DateTime? _diaSeleccionado = DateTime.now();
  Set<String> _eventoIdsConDocumento = {};

  @override
  void initState() {
    super.initState();
    if (widget.mascotaIdInicial != null) {
      _mascotaIdsFiltro = {widget.mascotaIdInicial!};
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarEventos());
  }

  Future<void> _cargarEventos() async {
    final mascotas = ref.read(mascotasProvider);
    final ids =
        _mascotaIdsFiltro?.toList() ?? mascotas.map((m) => m.id).toList();
    await ref
        .read(agendaEventosProvider.notifier)
        .cargarAgendaEventosDeMascotas(ids);
    if (!mounted) {
      return;
    }
    final eventoIds = ref.read(agendaEventosProvider).map((e) => e.id).toList();
    final idsConDocumento = await ref
        .read(documentoRepositoryProvider)
        .obtenerEventoIdsConDocumento(eventoIds);
    if (!mounted) {
      return;
    }
    setState(() => _eventoIdsConDocumento = idsConDocumento);
  }

  Future<void> _abrirFiltro(List<MascotaModel> mascotas) async {
    var seleccionTemporal = Set<String>.from(
      _mascotaIdsFiltro ?? mascotas.map((m) => m.id),
    );

    final aplicar = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialogo) => AlertDialog(
          title: const Text('Filtrar por mascota'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  title: const Text('Todas'),
                  value: seleccionTemporal.length == mascotas.length,
                  onChanged: (marcado) {
                    setStateDialogo(() {
                      if (marcado ?? false) {
                        seleccionTemporal = mascotas.map((m) => m.id).toSet();
                      } else {
                        seleccionTemporal.clear();
                      }
                    });
                  },
                ),
                const Divider(),
                for (final mascota in mascotas)
                  CheckboxListTile(
                    title: Text(mascota.nombre),
                    value: seleccionTemporal.contains(mascota.id),
                    onChanged: (marcado) {
                      setStateDialogo(() {
                        if (marcado ?? false) {
                          seleccionTemporal.add(mascota.id);
                        } else {
                          seleccionTemporal.remove(mascota.id);
                        }
                      });
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );

    if (aplicar ?? false) {
      setState(() {
        _mascotaIdsFiltro = seleccionTemporal.length == mascotas.length
            ? null
            : seleccionTemporal;
      });
      _cargarEventos();
    }
  }

  Future<void> _irAAgregarEvento() async {
    final esPasado = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.event_available),
              title: const Text('Evento futuro'),
              subtitle: const Text('Recordatorio para una próxima cita'),
              onTap: () => Navigator.of(context).pop(false),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Evento pasado'),
              subtitle: const Text('Registrar una consulta ya realizada'),
              onTap: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );

    if (esPasado == null || !mounted) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FormularioAgendaEventoScreen(
          mascotaIdInicial: _mascotaIdsFiltro?.length == 1
              ? _mascotaIdsFiltro!.first
              : null,
          esEventoPasado: esPasado,
        ),
      ),
    );
  }

  void _abrirDetalle(String eventoId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DetalleAgendaEventoScreen(eventoId: eventoId),
      ),
    );
  }

  String _tituloFiltro(List<MascotaModel> mascotas) {
    if (_mascotaIdsFiltro == null ||
        _mascotaIdsFiltro!.length == mascotas.length) {
      return 'Todas las mascotas';
    }
    final nombres = mascotas
        .where((m) => _mascotaIdsFiltro!.contains(m.id))
        .map((m) => m.nombre)
        .join(', ');
    return nombres.isEmpty ? 'Sin mascotas seleccionadas' : nombres;
  }

  List<AgendaEventoModel> _eventosDelDia(
    List<AgendaEventoModel> eventos,
    DateTime dia,
  ) {
    return eventos.where((e) => isSameDay(e.fechaProgramada, dia)).toList();
  }

  String _nombreMascota(List<MascotaModel> mascotas, String mascotaId) {
    for (final mascota in mascotas) {
      if (mascota.id == mascotaId) {
        return mascota.nombre;
      }
    }
    // Puede pasar momentáneamente al cerrar sesión: mascotasProvider ya se
    // vació para la sesión nueva, pero un evento viejo todavía no terminó
    // de recargarse — no hay que crashear por eso, solo mostrar algo.
    return 'Mascota';
  }

  Widget _etiquetaSeccion(String texto) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: Text(
        texto,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: _colorTextoSecundarioSobreFondo(context),
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _tarjetaProximoEvento(
    AgendaEventoModel evento,
    List<MascotaModel> mascotas,
    bool mostrarNombreMascota,
  ) {
    final dias = evento.fechaProgramada
        .difference(DateTime.now())
        .inDays;
    final etiquetaDias = dias < 0
        ? 'Atrasado'
        : dias == 0
        ? 'Hoy'
        : dias == 1
        ? 'Mañana'
        : 'En $dias días';
    final fechaTexto = DateFormat(
      'd MMM y',
      'es_ES',
    ).format(evento.fechaProgramada);
    final subtitulo = mostrarNombreMascota
        ? '${_nombreMascota(mascotas, evento.mascotaId)} · '
              '${_tipoEventoTexto(evento)}'
        : _tipoEventoTexto(evento);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _abrirDetalle(evento.id),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _colorTarjetaAgenda(context),
            border: Border.all(color: const Color(0xFFE0812F), width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBF0E2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'PRÓXIMO',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: Color(0xFFD06D1F),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$etiquetaDias · $fechaTexto',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFA06A35),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBF0E2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SvgPicture.asset(_iconoEvento(evento.tipoEvento)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          evento.titulo,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Color(0xFF7A4A22),
                          ),
                        ),
                        Text(
                          subtitulo,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFFA06A35),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tarjetaEventoTimeline(
    AgendaEventoModel evento,
    List<MascotaModel> mascotas,
    bool mostrarNombreMascota,
  ) {
    final fechaTexto = DateFormat(
      'd MMM y',
      'es_ES',
    ).format(evento.fechaProgramada);
    final tipoTexto = _tipoEventoTexto(evento);
    final detalle = evento.observaciones?.trim().isNotEmpty == true
        ? evento.observaciones!.trim()
        : tipoTexto;
    final subtitulo = mostrarNombreMascota
        ? '${_nombreMascota(mascotas, evento.mascotaId)} · $detalle'
        : detalle;
    final tieneDocumento = _eventoIdsConDocumento.contains(evento.id);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _abrirDetalle(evento.id),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          decoration: BoxDecoration(
            color: _colorTarjetaAgenda(context),
            border: Border.all(color: const Color(0xFFF0DCC0)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 26,
                height: 26,
                child: SvgPicture.asset(_iconoEvento(evento.tipoEvento)),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      evento.titulo,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF7A4A22),
                      ),
                    ),
                    Text(
                      subtitulo,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFA06A35),
                      ),
                    ),
                    Text(
                      fechaTexto,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB8946A),
                      ),
                    ),
                    if (tieneDocumento)
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBF0E2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.attach_file,
                              size: 12,
                              color: Color(0xFFD06D1F),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Documento adjunto',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFD06D1F),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vistaLista(
    List<AgendaEventoModel> eventos,
    List<MascotaModel> mascotas,
  ) {
    if (eventos.isEmpty) {
      return const Center(child: Text('No hay eventos programados'));
    }

    final mostrarNombreMascota =
        _mascotaIdsFiltro == null || _mascotaIdsFiltro!.length != 1;

    AgendaEventoModel? proximo;
    for (final evento in eventos) {
      if (evento.fechaRealizada == null &&
          (proximo == null ||
              evento.fechaProgramada.isBefore(proximo.fechaProgramada))) {
        proximo = evento;
      }
    }

    final restoOrdenado = [for (final e in eventos) if (e != proximo) e]
      ..sort((a, b) => a.fechaProgramada.compareTo(b.fechaProgramada));

    final grupos = <String, List<AgendaEventoModel>>{};
    for (final evento in restoOrdenado) {
      final clave = DateFormat(
        'MMMM y',
        'es_ES',
      ).format(evento.fechaProgramada);
      grupos.putIfAbsent(clave, () => []).add(evento);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (proximo != null) ...[
          _etiquetaSeccion('Próximo evento'),
          _tarjetaProximoEvento(proximo, mascotas, mostrarNombreMascota),
          const SizedBox(height: 8),
        ],
        for (final grupo in grupos.entries) ...[
          _etiquetaSeccion(_capitalizar(grupo.key)),
          for (final evento in grupo.value)
            _tarjetaEventoTimeline(evento, mascotas, mostrarNombreMascota),
        ],
      ],
    );
  }

  Widget _vistaCalendarioWidget(
    List<AgendaEventoModel> eventos,
    List<MascotaModel> mascotas,
  ) {
    final diaSeleccionado = _diaSeleccionado;
    final eventosDelDiaSeleccionado = diaSeleccionado == null
        ? <AgendaEventoModel>[]
        : (_eventosDelDia(eventos, diaSeleccionado)
            ..sort((a, b) => a.fechaProgramada.compareTo(b.fechaProgramada)));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              color: const Color(0xFFF3C98F),
              padding: const EdgeInsets.only(bottom: 10),
              child: TableCalendar<AgendaEventoModel>(
                locale: 'es_ES',
                firstDay: DateTime(2000),
                lastDay: DateTime(2100),
                focusedDay: _diaEnfocado,
                startingDayOfWeek: StartingDayOfWeek.monday,
                calendarFormat: CalendarFormat.month,
                rowHeight: 42,
                daysOfWeekHeight: 20,
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleTextStyle: TextStyle(
                    color: Color(0xFF7A4A22),
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color: Color(0xFF7A4A22),
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: Color(0xFF7A4A22),
                  ),
                ),
                calendarStyle: const CalendarStyle(
                  defaultTextStyle: TextStyle(color: Color(0xFF7A4A22)),
                  weekendTextStyle: TextStyle(color: Color(0xFF7A4A22)),
                  outsideTextStyle: TextStyle(color: Color(0xFFA06A35)),
                  selectedDecoration: BoxDecoration(
                    color: Color(0xFFF6B64D),
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: TextStyle(
                    color: Color(0xFF7A4A22),
                    fontWeight: FontWeight.bold,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Color(0xFFE0812F),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: TextStyle(color: Color(0xFFFBF0E2)),
                ),
                selectedDayPredicate: (dia) =>
                    diaSeleccionado != null && isSameDay(dia, diaSeleccionado),
                eventLoader: (dia) => _eventosDelDia(eventos, dia),
                onDaySelected: (diaSeleccionado, diaEnfocado) {
                  setState(() {
                    _diaSeleccionado = diaSeleccionado;
                    _diaEnfocado = diaEnfocado;
                  });
                },
                onPageChanged: (diaEnfocado) {
                  // Al cambiar de mes, el día que estaba seleccionado ya no
                  // se ve en la grilla — se limpia la selección para no
                  // dejar la lista de abajo mostrando eventos de un día que
                  // ya no está a la vista.
                  setState(() {
                    _diaEnfocado = diaEnfocado;
                    _diaSeleccionado = null;
                  });
                },
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: diaSeleccionado == null
              ? const Center(child: Text('Toca un día para ver sus eventos'))
              : eventosDelDiaSeleccionado.isEmpty
              ? _sinEventosDelDia(diaSeleccionado, eventos, mascotas)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: eventosDelDiaSeleccionado.length,
                  itemBuilder: (context, index) {
                    final evento = eventosDelDiaSeleccionado[index];
                    return _tarjetaEventoTimeline(
                      evento,
                      mascotas,
                      _mascotaIdsFiltro == null ||
                          _mascotaIdsFiltro!.length != 1,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _sinEventosDelDia(
    DateTime dia,
    List<AgendaEventoModel> eventos,
    List<MascotaModel> mascotas,
  ) {
    final mostrarNombreMascota =
        _mascotaIdsFiltro == null || _mascotaIdsFiltro!.length != 1;
    final proximos =
        [
            for (final e in eventos)
              if (e.fechaRealizada == null &&
                  e.fechaProgramada.isAfter(DateTime.now()))
                e,
          ]
          ..sort((a, b) => a.fechaProgramada.compareTo(b.fechaProgramada));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
          child: Text(
            DateFormat('d MMM y', 'es_ES').format(dia),
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: _colorTextoSobreFondo(context),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Sin eventos este día',
            style: TextStyle(
              fontSize: 12,
              color: _colorTextoSecundarioSobreFondo(context),
            ),
          ),
        ),
        if (proximos.isEmpty)
          const Expanded(
            child: Center(child: Text('No hay más eventos programados')),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              itemCount: proximos.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _etiquetaSeccion('Próximos eventos');
                }
                final evento = proximos[index - 1];
                return _tarjetaEventoTimeline(
                  evento,
                  mascotas,
                  mostrarNombreMascota,
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<List<MascotaModel>>(mascotasProvider, (previous, next) {
      _cargarEventos();
    });

    final mascotas = ref.watch(mascotasProvider);
    final eventos = [...ref.watch(agendaEventosProvider)]
      ..sort((a, b) => a.fechaProgramada.compareTo(b.fechaProgramada));

    // Si se abrió desde una mascota puntual (DetalleMascotaScreen), esta
    // pantalla es un push dentro del Navigator de esa pestaña, no la
    // pestaña raíz "Agenda" — necesita la flecha de "atrás" en vez del
    // logo, y el filtro por mascota no tiene sentido: ya está fijo a esa
    // única mascota.
    final esPantallaRaiz = widget.mascotaIdInicial == null;

    return Scaffold(
      appBar: AppBar(
        leading: esPantallaRaiz ? const LogoBarraSuperior() : null,
        title: const Text('Agenda'),
        actions: [
          IconButton(
            icon: Icon(
              _vistaCalendario ? Icons.view_list : Icons.calendar_month,
            ),
            tooltip: _vistaCalendario ? 'Ver como lista' : 'Ver calendario',
            onPressed: () =>
                setState(() => _vistaCalendario = !_vistaCalendario),
          ),
          if (esPantallaRaiz)
            IconButton(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filtrar por mascota',
              onPressed: mascotas.isEmpty
                  ? null
                  : () => _abrirFiltro(mascotas),
            ),
          const MenuUsuarioAvatar(),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  'Mostrando: ${_tituloFiltro(mascotas)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (mascotas.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Text(
                      'No hay mascotas creadas',
                      style: TextStyle(
                        color: Colors.red.shade900,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _vistaCalendario
                ? _vistaCalendarioWidget(eventos, mascotas)
                : _vistaLista(eventos, mascotas),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: mascotas.isEmpty ? null : _irAAgregarEvento,
        icon: const Icon(Icons.add),
        label: const Text('Agregar evento'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
