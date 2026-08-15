import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
            child: eventos.isEmpty
                ? const Center(child: Text('No hay eventos programados'))
                : ListView.builder(
                    itemCount: eventos.length,
                    itemBuilder: (context, index) {
                      final evento = eventos[index];
                      final mascota = mascotas.firstWhere(
                        (m) => m.id == evento.mascotaId,
                        orElse: () => mascotas.first,
                      );
                      return ListTile(
                        leading: Icon(
                          evento.fechaRealizada != null
                              ? Icons.check_circle
                              : Icons.event_note,
                        ),
                        title: Text(evento.titulo),
                        subtitle: Text(
                          '${mascota.nombre} · '
                          '${evento.fechaProgramada.day}/'
                          '${evento.fechaProgramada.month}/'
                          '${evento.fechaProgramada.year}',
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  DetalleAgendaEventoScreen(eventoId: evento.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
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
