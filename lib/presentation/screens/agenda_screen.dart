import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:patas_al_dia/data/models/agenda_evento_model.dart';
import 'package:patas_al_dia/data/models/mascota_model.dart';
import 'package:patas_al_dia/presentation/screens/detalle_agenda_evento_screen.dart';
import 'package:patas_al_dia/presentation/screens/formulario_agenda_evento_screen.dart';
import 'package:patas_al_dia/presentation/widgets/menu_usuario_avatar.dart';
import 'package:patas_al_dia/providers/agenda_evento_provider.dart';
import 'package:patas_al_dia/providers/mascota_provider.dart';

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

  @override
  void initState() {
    super.initState();
    if (widget.mascotaIdInicial != null) {
      _mascotaIdsFiltro = {widget.mascotaIdInicial!};
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarEventos());
  }

  void _cargarEventos() {
    final mascotas = ref.read(mascotasProvider);
    final ids =
        _mascotaIdsFiltro?.toList() ?? mascotas.map((m) => m.id).toList();
    ref.read(agendaEventosProvider.notifier).cargarAgendaEventosDeMascotas(ids);
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

  Widget _tileEvento(AgendaEventoModel evento, List<MascotaModel> mascotas) {
    return ListTile(
      leading: Icon(
        evento.fechaRealizada != null ? Icons.check_circle : Icons.event_note,
      ),
      title: Text(evento.titulo),
      subtitle: Text(
        '${_nombreMascota(mascotas, evento.mascotaId)} · '
        '${evento.fechaProgramada.day}/'
        '${evento.fechaProgramada.month}/'
        '${evento.fechaProgramada.year}',
      ),
      onTap: () => _abrirDetalle(evento.id),
    );
  }

  Widget _vistaLista(
    List<AgendaEventoModel> eventos,
    List<MascotaModel> mascotas,
  ) {
    if (eventos.isEmpty) {
      return const Center(child: Text('No hay eventos programados'));
    }
    return ListView.builder(
      itemCount: eventos.length,
      itemBuilder: (context, index) {
        final evento = eventos[index];
        return _tileEvento(evento, mascotas);
      },
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
        TableCalendar<AgendaEventoModel>(
          locale: 'es_ES',
          firstDay: DateTime(2000),
          lastDay: DateTime(2100),
          focusedDay: _diaEnfocado,
          startingDayOfWeek: StartingDayOfWeek.monday,
          calendarFormat: CalendarFormat.month,
          headerStyle: const HeaderStyle(formatButtonVisible: false),
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
            // Al cambiar de mes, el día que estaba seleccionado ya no se ve
            // en la grilla — se limpia la selección para no dejar la lista
            // de abajo mostrando eventos de un día que ya no está a la vista.
            setState(() {
              _diaEnfocado = diaEnfocado;
              _diaSeleccionado = null;
            });
          },
        ),
        const Divider(height: 1),
        Expanded(
          child: diaSeleccionado == null
              ? const Center(child: Text('Toca un día para ver sus eventos'))
              : eventosDelDiaSeleccionado.isEmpty
              ? const Center(child: Text('Sin eventos este día'))
              : ListView.builder(
                  itemCount: eventosDelDiaSeleccionado.length,
                  itemBuilder: (context, index) {
                    final evento = eventosDelDiaSeleccionado[index];
                    return _tileEvento(evento, mascotas);
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

    return Scaffold(
      appBar: AppBar(
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
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrar por mascota',
            onPressed: mascotas.isEmpty ? null : () => _abrirFiltro(mascotas),
          ),
          const MenuUsuarioAvatar(),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Mostrando: ${_tituloFiltro(mascotas)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
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
