import 'dart:math' show max;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/widgets/avatares/avatar_usuario.dart';
import '../../compartido/widgets/botones/boton_regresar.dart';
import '../../compartido/widgets/formularios/barra_busqueda_app.dart';
import '../../compartido/widgets/indicadores/insignia_estado.dart';
import '../../compartido/widgets/navegacion/barra_superior_app.dart';
import '../../compartido/widgets/tarjetas/tarjeta_app.dart';
import '../../configuracion/colores_app.dart';
import 'auditoria_evento_cubit.dart';
import 'auditoria_evento_estado.dart';
import 'auditoria_evento_modelo.dart';

class AuditoriaEventoPantalla extends StatefulWidget {
  const AuditoriaEventoPantalla({super.key});

  @override
  State<AuditoriaEventoPantalla> createState() => _AuditoriaEventoPantallaState();
}

class _AuditoriaEventoPantallaState extends State<AuditoriaEventoPantalla> {
  final _controladorBusqueda = TextEditingController();
  bool _estaIniciado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_estaIniciado) return;
    _estaIniciado = true;
    context.read<AuditoriaEventoCubit>().iniciar();
  }

  @override
  void dispose() {
    _controladorBusqueda.dispose();
    super.dispose();
  }

  void _abrirSelectorEvento(BuildContext ctx) {
    showModalBottomSheet<void>(
      context:            ctx,
      useRootNavigator:   true,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      barrierColor:       ColoresApp.sombraBarrera,
      builder: (_) => BlocProvider.value(
        value: ctx.read<AuditoriaEventoCubit>(),
        child: _ModalSelectorEvento(
          alSeleccionar: (evento) {
            Navigator.of(ctx, rootNavigator: true).pop();
            _controladorBusqueda.clear();
            ctx.read<AuditoriaEventoCubit>().seleccionarEvento(evento);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor:          Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness:     Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: ColoresApp.fondo,
        body: BlocBuilder<AuditoriaEventoCubit, AuditoriaEventoEstado>(
          builder: (context, estado) {
            final eventoActual = switch (estado) {
              AuditoriaEventoCargandoAuditoria(:final eventoSeleccionado) =>
                eventoSeleccionado,
              AuditoriaEventoCargada(:final eventoSeleccionado) =>
                eventoSeleccionado,
              _ => null,
            };

            return Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: _BarraSuperiorAuditoria(),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _SelectorEventoCard(
                    evento:  eventoActual,
                    alTocar: () => _abrirSelectorEvento(context),
                  ),
                ),
                Expanded(child: _construirCuerpo(context, estado)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _construirCuerpo(BuildContext context, AuditoriaEventoEstado estado) =>
      switch (estado) {
        AuditoriaEventoInicial() ||
        AuditoriaEventoCargandoLista() =>
          const Center(child: CircularProgressIndicator(color: ColoresApp.acento)),
        AuditoriaEventoListaCargada() => _EstadoVacioSinSeleccion(),
        AuditoriaEventoCargandoAuditoria() =>
          const Center(child: CircularProgressIndicator(color: ColoresApp.acento)),
        final AuditoriaEventoCargada cargada => _CuerpoAuditoria(
            estado:              cargada,
            controladorBusqueda: _controladorBusqueda,
          ),
        AuditoriaEventoError(:final mensaje) => _VistaError(
            mensaje:      mensaje,
            alReintentar: () => context.read<AuditoriaEventoCubit>().iniciar(),
          ),
      };
}

// ─── Barra superior ───────────────────────────────────────────────────────────

class _BarraSuperiorAuditoria extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BarraSuperiorApp(
      izquierda: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BotonRegresar(),
          const SizedBox(width: 12),
          Text(
            'Auditoría',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontSize:   20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Selector de evento ───────────────────────────────────────────────────────

class _SelectorEventoCard extends StatelessWidget {
  const _SelectorEventoCard({
    required this.alTocar,
    this.evento,
  });

  final EventoParaAuditoria? evento;
  final VoidCallback          alTocar;

  @override
  Widget build(BuildContext context) {
    if (evento == null) {
      return Material(
        color:        Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap:        alTocar,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color:        ColoresApp.tealClaro,
              borderRadius: BorderRadius.circular(18),
              border:       Border.all(color: ColoresApp.bordeAviso),
            ),
            child: Row(
              children: [
                const Icon(Icons.touch_app_rounded, color: ColoresApp.teal, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seleccionar evento',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color:      ColoresApp.teal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Toca para elegir el evento a auditar',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ColoresApp.teal,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: ColoresApp.teal, size: 20),
              ],
            ),
          ),
        ),
      );
    }

    return TarjetaApp(
      relleno: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  evento!.titulo,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color:      ColoresApp.textoPrimario,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines:  2,
                  overflow:  TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    InsigniaEstado(
                      estatus: evento!.estatus,
                      tamanio: TamanioInsignia.pequeno,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      evento!.fechaFormateada,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ColoresApp.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color:        Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap:        alTocar,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color:        ColoresApp.acentoClaro,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Cambiar',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color:      ColoresApp.acento,
                    fontWeight: FontWeight.w700,
                    fontSize:   12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Modal selector de evento ─────────────────────────────────────────────────

class _ModalSelectorEvento extends StatefulWidget {
  const _ModalSelectorEvento({required this.alSeleccionar});

  final ValueChanged<EventoParaAuditoria> alSeleccionar;

  @override
  State<_ModalSelectorEvento> createState() => _ModalSelectorEventoState();
}

class _ModalSelectorEventoState extends State<_ModalSelectorEvento> {
  String _busqueda    = '';
  bool   _cargandoMas = false;

  @override
  Widget build(BuildContext context) {
    final cubit     = context.read<AuditoriaEventoCubit>();
    final todos     = cubit.todosEventos;
    final hayMas    = cubit.hayMasEventos;
    final q         = _busqueda.trim().toLowerCase();
    final filtrados = q.isEmpty
        ? todos
        : todos
            .where((e) =>
                e.titulo.toLowerCase().contains(q) ||
                e.fechaFormateada.toLowerCase().contains(q),)
            .toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.70,
      ),
      decoration: const BoxDecoration(
        color:        ColoresApp.superficiePrimaria,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width:  40,
            height: 4,
            decoration: BoxDecoration(
              color:        ColoresApp.superficieTerciar,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Seleccionar evento',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: BarraBusquedaApp(
              hintText:  'Buscar evento...',
              alCambiar: (v) => setState(() => _busqueda = v),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding:          const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount:        filtrados.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                if (i < filtrados.length) {
                  return _FilaEvento(
                    evento:        filtrados[i],
                    alSeleccionar: widget.alSeleccionar,
                  );
                }
                if (_cargandoMas) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child:   Center(
                      child: CircularProgressIndicator(color: ColoresApp.acento),
                    ),
                  );
                }
                if (hayMas) {
                  return Center(
                    child: TextButton.icon(
                      onPressed: () async {
                        setState(() => _cargandoMas = true);
                        await cubit.cargarMasEventos();
                        if (mounted) setState(() => _cargandoMas = false);
                      },
                      icon:  const Icon(Icons.expand_more_rounded),
                      label: const Text('Cargar más'),
                    ),
                  );
                }
                if (filtrados.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        'Sin resultados',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ColoresApp.textoTerciario,
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaEvento extends StatelessWidget {
  const _FilaEvento({required this.evento, required this.alSeleccionar});

  final EventoParaAuditoria               evento;
  final ValueChanged<EventoParaAuditoria> alSeleccionar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color:        Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap:        () => alSeleccionar(evento),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color:        ColoresApp.superficieSecund,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              InsigniaEstado(
                estatus: evento.estatus,
                tamanio: TamanioInsignia.pequeno,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      evento.titulo,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color:      ColoresApp.textoPrimario,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      evento.fechaFormateada,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ColoresApp.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: ColoresApp.textoTerciario,
                size:  18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Cuerpo auditoria ─────────────────────────────────────────────────────────

class _CuerpoAuditoria extends StatelessWidget {
  const _CuerpoAuditoria({
    required this.estado,
    required this.controladorBusqueda,
  });

  final AuditoriaEventoCargada  estado;
  final TextEditingController   controladorBusqueda;

  @override
  Widget build(BuildContext context) {
    final registros = estado.registrosFiltrados;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _EncabezadoEvento(evento: estado.eventoSeleccionado),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _GrillaKpis(resumen: estado.resumen),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _SeccionDistribucion(resumen: estado.resumen),
          ),
        ),
        if (estado.resumen.timelineEntradas.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _SeccionTimeline(timeline: estado.resumen.timelineEntradas),
            ),
          ),
        if (estado.resumen.registradores.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _SeccionRegistradores(
                registradores: estado.resumen.registradores,
                totalEntradas: estado.resumen.haEntrado,
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _EncabezadoParticipantes(
              total:               estado.registros.length,
              filtroActual:        estado.filtro,
              controladorBusqueda: controladorBusqueda,
            ),
          ),
        ),
        if (registros.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'Sin resultados',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColoresApp.textoTerciario,
                  ),
                ),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _TarjetaParticipante(registro: registros[i]),
              ),
              childCount: registros.length,
            ),
          ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
      ],
    );
  }
}

// ─── Encabezado evento ────────────────────────────────────────────────────────

class _EncabezadoEvento extends StatelessWidget {
  const _EncabezadoEvento({required this.evento});

  final EventoParaAuditoria evento;

  @override
  Widget build(BuildContext context) {
    return TarjetaApp(
      relleno: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InsigniaEstado(estatus: evento.estatus),
                const SizedBox(height: 8),
                Text(
                  evento.titulo,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color:      ColoresApp.textoPrimario,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size:  13,
                      color: ColoresApp.textoTerciario,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      evento.fechaFormateada,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ColoresApp.textoSecundario,
                      ),
                    ),
                    if (evento.horaInicio != null) ...[
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.access_time_rounded,
                        size:  13,
                        color: ColoresApp.textoTerciario,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        evento.horaInicio!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ColoresApp.textoSecundario,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Grilla de KPIs ───────────────────────────────────────────────────────────

class _GrillaKpis extends StatelessWidget {
  const _GrillaKpis({required this.resumen});

  final ResumenAuditoria resumen;

  @override
  Widget build(BuildContext context) {
    final tasa = resumen.tasaAsistencia;
    final colorTasa = tasa >= 75
        ? ColoresApp.verde
        : tasa >= 50
            ? ColoresApp.ambar
            : ColoresApp.rojo;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _TarjetaKpi(
                valor:  resumen.haEntrado.toString(),
                label:  'Entraron',
                color:  ColoresApp.verde,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _TarjetaKpi(
                valor: '${tasa.toStringAsFixed(1)}%',
                label: 'Asistencia',
                color: colorTasa,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _TarjetaKpi(
                valor: resumen.totalRegistros.toString(),
                label: 'Total',
                color: ColoresApp.acento,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _TarjetaKpi(
                valor: resumen.foraneos.toString(),
                label: 'Foráneos',
                color: ColoresApp.teal,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _TarjetaKpi(
                valor: resumen.salioAnticipado.toString(),
                label: 'Anticipado',
                color: ColoresApp.ambar,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _TarjetaKpi(
                valor: resumen.ausentes.toString(),
                label: 'Ausentes',
                color: ColoresApp.rojo,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TarjetaKpi extends StatelessWidget {
  const _TarjetaKpi({
    required this.valor,
    required this.label,
    required this.color,
  });

  final String valor;
  final String label;
  final Color  color;

  @override
  Widget build(BuildContext context) {
    return TarjetaApp(
      relleno: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            valor,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color:      color,
              fontWeight: FontWeight.w800,
              fontSize:   22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color:    ColoresApp.textoSecundario,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Distribución donut ───────────────────────────────────────────────────────

class _SeccionDistribucion extends StatelessWidget {
  const _SeccionDistribucion({required this.resumen});

  final ResumenAuditoria resumen;

  @override
  Widget build(BuildContext context) {
    final entraron  = (resumen.presentes + resumen.completados).toDouble();
    final anticipado = resumen.salioAnticipado.toDouble();
    final ausentes  = resumen.ausentes.toDouble();
    final esperados = resumen.esperados.toDouble();
    final total     = entraron + anticipado + ausentes + esperados;

    if (total == 0) return const SizedBox.shrink();

    final sections = <PieChartSectionData>[
      if (entraron > 0)
        PieChartSectionData(
          value:     entraron,
          color:     ColoresApp.verde,
          radius:    40,
          showTitle: false,
        ),
      if (anticipado > 0)
        PieChartSectionData(
          value:     anticipado,
          color:     ColoresApp.ambar,
          radius:    40,
          showTitle: false,
        ),
      if (ausentes > 0)
        PieChartSectionData(
          value:     ausentes,
          color:     ColoresApp.rojo,
          radius:    40,
          showTitle: false,
        ),
      if (esperados > 0)
        PieChartSectionData(
          value:     esperados,
          color:     ColoresApp.superficieTerciar,
          radius:    40,
          showTitle: false,
        ),
    ];

    return TarjetaApp(
      relleno: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DISTRIBUCIÓN',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color:         ColoresApp.textoTerciario,
              fontWeight:    FontWeight.w700,
              letterSpacing: 1.2,
              fontSize:      11,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width:  110,
                height: 110,
                child: PieChart(
                  PieChartData(
                    sections:        sections,
                    centerSpaceRadius: 35,
                    sectionsSpace:   2,
                    startDegreeOffset: -90,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (entraron > 0)
                      _FilaLeyenda(
                        color:  ColoresApp.verde,
                        label:  'Entraron',
                        valor:  entraron.toInt(),
                        total:  total.toInt(),
                      ),
                    if (anticipado > 0)
                      _FilaLeyenda(
                        color:  ColoresApp.ambar,
                        label:  'Anticipado',
                        valor:  anticipado.toInt(),
                        total:  total.toInt(),
                      ),
                    if (ausentes > 0)
                      _FilaLeyenda(
                        color:  ColoresApp.rojo,
                        label:  'Ausentes',
                        valor:  ausentes.toInt(),
                        total:  total.toInt(),
                      ),
                    if (esperados > 0)
                      _FilaLeyenda(
                        color:  ColoresApp.textoTerciario,
                        label:  'Esperados',
                        valor:  esperados.toInt(),
                        total:  total.toInt(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilaLeyenda extends StatelessWidget {
  const _FilaLeyenda({
    required this.color,
    required this.label,
    required this.valor,
    required this.total,
  });

  final Color  color;
  final String label;
  final int    valor;
  final int    total;

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : valor / total * 100;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width:  10,
            height: 10,
            decoration: BoxDecoration(
              color:  color,
              shape:  BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ColoresApp.textoSecundario,
              ),
            ),
          ),
          Text(
            '$valor  ${pct.toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color:      ColoresApp.textoPrimario,
              fontWeight: FontWeight.w700,
              fontSize:   11,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Timeline de entradas ─────────────────────────────────────────────────────

class _SeccionTimeline extends StatelessWidget {
  const _SeccionTimeline({required this.timeline});

  final List<DatoTimeline> timeline;

  @override
  Widget build(BuildContext context) {
    final maxVal = timeline.map((d) => d.cantidad).fold(0, max).toDouble();

    return TarjetaApp(
      relleno: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ENTRADAS POR HORA',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color:         ColoresApp.textoTerciario,
              fontWeight:    FontWeight.w700,
              letterSpacing: 1.2,
              fontSize:      11,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                maxY:            maxVal == 0 ? 1 : maxVal * 1.25,
                gridData:        FlGridData(
                  show:                true,
                  drawVerticalLine:    false,
                  horizontalInterval:  maxVal == 0 ? 1 : (maxVal / 4).ceilToDouble(),
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color:       ColoresApp.bordesuave,
                    strokeWidth: 1,
                  ),
                ),
                borderData:      FlBorderData(show: false),
                titlesData:      FlTitlesData(
                  leftTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles:   true,
                      reservedSize: 28,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= timeline.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            timeline[idx].label,
                            style: const TextStyle(
                              fontSize: 10,
                              color:    ColoresApp.textoTerciario,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(timeline.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY:            timeline[i].cantidad.toDouble(),
                        color:          ColoresApp.acento,
                        width:          18,
                        borderRadius:   BorderRadius.circular(4),
                        backDrawRodData: BackgroundBarChartRodData(
                          show:  true,
                          toY:   maxVal == 0 ? 1 : maxVal * 1.25,
                          color: ColoresApp.acentoClaro,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Registradores ────────────────────────────────────────────────────────────

class _SeccionRegistradores extends StatelessWidget {
  const _SeccionRegistradores({
    required this.registradores,
    required this.totalEntradas,
  });

  final List<DatoRegistrador> registradores;
  final int                   totalEntradas;

  @override
  Widget build(BuildContext context) {
    return TarjetaApp(
      relleno: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REGISTRADORES',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color:         ColoresApp.textoTerciario,
              fontWeight:    FontWeight.w700,
              letterSpacing: 1.2,
              fontSize:      11,
            ),
          ),
          const SizedBox(height: 12),
          ...registradores.take(5).map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _FilaRegistrador(
                registrador:   r,
                totalEntradas: totalEntradas,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaRegistrador extends StatelessWidget {
  const _FilaRegistrador({
    required this.registrador,
    required this.totalEntradas,
  });

  final DatoRegistrador registrador;
  final int             totalEntradas;

  @override
  Widget build(BuildContext context) {
    final pct = registrador.porcentaje(totalEntradas);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                registrador.nombre,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:      ColoresApp.textoPrimario,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${registrador.entradas}  ${pct.toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color:      ColoresApp.textoSecundario,
                fontWeight: FontWeight.w600,
                fontSize:   11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value:            pct / 100,
            minHeight:        6,
            backgroundColor:  ColoresApp.acentoClaro,
            valueColor:       const AlwaysStoppedAnimation<Color>(ColoresApp.acento),
          ),
        ),
      ],
    );
  }
}

// ─── Encabezado participantes + filtros ───────────────────────────────────────

class _EncabezadoParticipantes extends StatelessWidget {
  const _EncabezadoParticipantes({
    required this.total,
    required this.filtroActual,
    required this.controladorBusqueda,
  });

  final int                   total;
  final FiltroParticipantes   filtroActual;
  final TextEditingController controladorBusqueda;

  static const _tabs = [
    (FiltroParticipantes.todos,           'Todos'),
    (FiltroParticipantes.entraron,        'Entraron'),
    (FiltroParticipantes.ausentes,        'Ausentes'),
    (FiltroParticipantes.salioAnticipado, 'Anticipado'),
    (FiltroParticipantes.foraneos,        'Foráneos'),
  ];

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AuditoriaEventoCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PARTICIPANTES ($total)',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color:         ColoresApp.textoTerciario,
            fontWeight:    FontWeight.w700,
            letterSpacing: 1.2,
            fontSize:      11,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _tabs.map((tab) {
              final activo = tab.$1 == filtroActual;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Material(
                  color:        Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap:        () => cubit.cambiarFiltro(tab.$1),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8,),
                      decoration: BoxDecoration(
                        color:        activo ? ColoresApp.acento : ColoresApp.superficiePrimaria,
                        borderRadius: BorderRadius.circular(20),
                        border:       Border.all(
                          color: activo ? ColoresApp.acento : ColoresApp.bordeMedio,
                        ),
                      ),
                      child: Text(
                        tab.$2,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color:      activo ? ColoresApp.blanco : ColoresApp.textoSecundario,
                          fontWeight: FontWeight.w700,
                          fontSize:   12,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),
        BarraBusquedaApp(
          controlador: controladorBusqueda,
          hintText:    'Buscar participante...',
          alCambiar:   cubit.buscarParticipante,
        ),
      ],
    );
  }
}

// ─── Tarjeta participante ─────────────────────────────────────────────────────

class _TarjetaParticipante extends StatelessWidget {
  const _TarjetaParticipante({required this.registro});

  final RegistroAuditoria registro;

  @override
  Widget build(BuildContext context) {
    return TarjetaApp(
      relleno: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarUsuario(
                iniciales: registro.iniciales,
                urlFoto:   registro.urlFoto,
                tamanio:   40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      registro.nombre,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color:      ColoresApp.textoPrimario,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (registro.numeroIdentificacion != null)
                      Text(
                        registro.numeroIdentificacion!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ColoresApp.textoTerciario,
                        ),
                      )
                    else if (registro.contactoForaneo != null)
                      Text(
                        registro.contactoForaneo!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ColoresApp.textoTerciario,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  InsigniaEstado(
                    estatus: registro.estatus,
                    tamanio: TamanioInsignia.pequeno,
                  ),
                  if (registro.esForaneo) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2,),
                      decoration: BoxDecoration(
                        color:        ColoresApp.tealClaro,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        'Foráneo',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color:      ColoresApp.teal,
                          fontSize:   9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          _DetalleRegistro(registro: registro),
        ],
      ),
    );
  }
}

class _DetalleRegistro extends StatelessWidget {
  const _DetalleRegistro({required this.registro});

  final RegistroAuditoria registro;

  @override
  Widget build(BuildContext context) {
    final tieneDetalle = registro.horaEntrada.isNotEmpty ||
        registro.horaSalida.isNotEmpty ||
        (registro.motivoSalidaAnticipada?.isNotEmpty ?? false);

    if (!tieneDetalle) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        const Divider(height: 1, thickness: 1, color: ColoresApp.bordesuave),
        const SizedBox(height: 10),
        if (registro.horaEntrada.isNotEmpty)
          _FilaHora(
            icono:  Icons.login_rounded,
            color:  ColoresApp.verde,
            hora:   registro.horaEntrada,
            regPor: registro.registradoPorNombre,
          ),
        if (registro.horaSalida.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: _FilaHora(
              icono:  Icons.logout_rounded,
              color:  ColoresApp.ambar,
              hora:   registro.horaSalida,
              regPor: registro.salidaRegistradaPorNombre,
            ),
          ),
        if (registro.motivoSalidaAnticipada?.isNotEmpty ?? false)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 14, color: ColoresApp.ambar,),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    registro.motivoSalidaAnticipada!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:     ColoresApp.ambar,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _FilaHora extends StatelessWidget {
  const _FilaHora({
    required this.icono,
    required this.color,
    required this.hora,
    this.regPor,
  });

  final IconData icono;
  final Color    color;
  final String   hora;
  final String?  regPor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          hora,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color:      ColoresApp.textoPrimario,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (regPor != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Reg. por: $regPor',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color:    ColoresApp.textoTerciario,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Estado vacío ─────────────────────────────────────────────────────────────

class _EstadoVacioSinSeleccion extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width:  72,
              height: 72,
              decoration: BoxDecoration(
                color:        ColoresApp.acentoClaro,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.manage_search_rounded,
                size:  36,
                color: ColoresApp.acento,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Selecciona un evento',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color:      ColoresApp.textoPrimario,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Toca la tarjeta superior para elegir\nel evento que deseas auditar.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ColoresApp.textoSecundario,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Vista error ──────────────────────────────────────────────────────────────

class _VistaError extends StatelessWidget {
  const _VistaError({required this.mensaje, required this.alReintentar});

  final String       mensaje;
  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width:  64,
              height: 64,
              decoration: BoxDecoration(
                color:        ColoresApp.rojoClaro,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size:  32,
                color: ColoresApp.rojo,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ColoresApp.textoSecundario,
              ),
            ),
            const SizedBox(height: 16),
            Material(
              color:        Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap:        alReintentar,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color:        ColoresApp.acentoClaro,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Reintentar',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color:      ColoresApp.acento,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
