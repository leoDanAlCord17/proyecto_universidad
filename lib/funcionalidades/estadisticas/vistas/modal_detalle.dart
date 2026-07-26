import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../configuracion/colores_app.dart';
import '../estadisticas_cubit.dart';
import '../estadisticas_modelo.dart';
import '../filtros_estadisticas.dart';
import 'estilos_estadisticas.dart';

class ModalDetalle extends StatefulWidget {
  const ModalDetalle({
    required this.titulo,
    required this.dimension,
    required this.valor,
    required this.filtros,
  });

  final String titulo;
  final String dimension;
  final String valor;
  final FiltrosEstadisticas filtros;

  @override
  State<ModalDetalle> createState() => _ModalDetalleState();
}

class _ModalDetalleState extends State<ModalDetalle> {
  List<EventoResumido>? _eventos;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final eventos = await context.read<EstadisticasCubit>().cargarDetalle(
            filtros: widget.filtros,
            dimension: widget.dimension,
            valor: widget.valor,
          );
      if (mounted)
        setState(() {
          _eventos = eventos;
          _cargando = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _cargando = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
      decoration: const BoxDecoration(
        color: ColoresApp.superficiePrimaria,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 14),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: ColoresApp.bordeMedio,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.bar_chart_rounded,
                    color: ColoresApp.acento, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _etiquetaDimension(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: ColoresApp.acento,
                              letterSpacing: 1.1,
                            ),
                      ),
                      Text(
                        widget.titulo,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Divider(height: 24),
          Expanded(child: _construirCuerpo(bottomPadding)),
        ],
      ),
    );
  }

  Widget _construirCuerpo(double bottomPadding) {
    if (_cargando) {
      return const Center(
          child: CircularProgressIndicator(color: ColoresApp.acento));
    }
    if (_error != null) {
      return Center(
          child: Text(_error!, style: const TextStyle(color: ColoresApp.rojo)));
    }
    final lista = _eventos ?? [];
    if (lista.isEmpty) return const SinDatos();
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPadding + 24),
      itemCount: lista.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: ColoresApp.bordesuave),
      itemBuilder: (_, i) => _FilaEventoDetalle(evento: lista[i]),
    );
  }

  String _etiquetaDimension() => switch (widget.dimension) {
        'tipo' => 'TIPO DE EVENTO',
        'creador' => 'ORGANIZADOR',
        'mes' => 'MES',
        'estatus_asistencia' => 'ESTATUS DE ASISTENCIA',
        'dia_semana' => 'DÍA DE SEMANA',
        _ => 'FILTRO',
      };
}

class _FilaEventoDetalle extends StatelessWidget {
  const _FilaEventoDetalle({required this.evento});
  final EventoResumido evento;

  @override
  Widget build(BuildContext context) {
    final pct = evento.tasa;
    final color = colorTasa(pct * 100);
    final fecha = evento.fechaInicio;
    final fechaStr =
        fecha != null ? '${fecha.day}/${fecha.month}/${fecha.year}' : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  evento.titulo,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ColoresApp.textoPrimario,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.category_outlined,
                        size: 11, color: ColoresApp.textoTerciario),
                    const SizedBox(width: 3),
                    Text(
                      evento.tipoNombre,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ColoresApp.textoTerciario,
                            fontSize: 11,
                          ),
                    ),
                    if (fechaStr.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      const Icon(Icons.calendar_today_outlined,
                          size: 11, color: ColoresApp.textoTerciario),
                      const SizedBox(width: 3),
                      Text(
                        fechaStr,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: ColoresApp.textoTerciario,
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded,
                        size: 11, color: ColoresApp.textoTerciario),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        evento.creadorNombre,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: ColoresApp.textoTerciario,
                              fontSize: 11,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(pct * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: color),
              ),
              Text(
                '${evento.presentes}/${evento.total}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ColoresApp.textoTerciario,
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
