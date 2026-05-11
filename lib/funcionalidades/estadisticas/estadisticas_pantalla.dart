import 'dart:math' show max;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../compartido/constantes.dart';
import '../../compartido/widgets/botones/boton_regresar.dart';
import '../../compartido/widgets/navegacion/barra_superior_app.dart';
import '../../configuracion/colores_app.dart';
import 'estadisticas_cubit.dart';
import 'estadisticas_estado.dart';
import 'estadisticas_modelo.dart';
import 'filtros_estadisticas.dart';

// ─── Paleta y helpers de color ───────────────────────────────────────────────

const _paleta = [
  ColoresApp.acento,
  ColoresApp.verde,
  ColoresApp.ambar,
  ColoresApp.rojo,
  ColoresApp.teal,
  ColoresApp.acento2,
];

Color _colorEstatus(String etiqueta) => switch (etiqueta) {
      'Presente'    => ColoresApp.verde,
      'Completado'  => ColoresApp.verde,
      'Salió antes' => ColoresApp.ambar,
      'Ausente'     => ColoresApp.rojo,
      'Esperado'    => ColoresApp.textoTerciario,
      _             => ColoresApp.teal,
    };

Color _colorEstatusEvento(String etiqueta) => switch (etiqueta) {
      'Finalizado' => ColoresApp.verde,
      'En curso'   => ColoresApp.acento,
      'Programado' => ColoresApp.ambar,
      'Cancelado'  => ColoresApp.rojo,
      _            => ColoresApp.textoTerciario,
    };

Color _colorTasa(double tasa) =>
    tasa >= 75 ? ColoresApp.verde : tasa >= 50 ? ColoresApp.ambar : ColoresApp.rojo;

// ─── Pantalla principal ───────────────────────────────────────────────────────

class EstadisticasPantalla extends StatefulWidget {
  const EstadisticasPantalla({super.key});

  @override
  State<EstadisticasPantalla> createState() => _EstadisticasPantallaState();
}

class _EstadisticasPantallaState extends State<EstadisticasPantalla> {
  late FiltrosEstadisticas _filtros;
  bool _estaIniciado = false;

  @override
  void initState() {
    super.initState();
    _filtros = FiltrosEstadisticas.porDefecto();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_estaIniciado) return;
    _estaIniciado = true;
    context.read<EstadisticasCubit>().cargar(_filtros);
  }

  void _abrirFiltros(OpcionesFiltros opciones) {
    showModalBottomSheet<FiltrosEstadisticas>(
      context:            context,
      useRootNavigator:   true,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      barrierColor:       ColoresApp.sombraBarrera,
      builder: (_) => _PanelFiltros(
        filtrosActuales: _filtros,
        opciones:        opciones,
        alAplicar: (nuevos) {
          Navigator.of(context, rootNavigator: true).pop();
          setState(() => _filtros = nuevos);
          context.read<EstadisticasCubit>().cargar(nuevos);
        },
      ),
    );
  }

  void _abrirDetalle(String dimension, DatoGrafica dato) {
    showModalBottomSheet<void>(
      context:            context,
      useRootNavigator:   true,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      barrierColor:       ColoresApp.sombraBarrera,
      builder: (_) => BlocProvider.value(
        value: context.read<EstadisticasCubit>(),
        child: _ModalDetalle(
          titulo:    dato.etiqueta,
          dimension: dimension,
          valor:     dato.valorSql ?? dato.etiqueta,
          filtros:   _filtros,
        ),
      ),
    );
  }

  void _limpiarFiltros() {
    final nuevos = _filtros.sinFiltros();
    setState(() => _filtros = nuevos);
    context.read<EstadisticasCubit>().cargar(nuevos);
  }

  void _quitarFiltroTipo(OpcionFiltro opcion) {
    final nuevos = _filtros.copyWith(
      tiposSeleccionados: _filtros.tiposSeleccionados.where((o) => o.id != opcion.id).toList(),
    );
    setState(() => _filtros = nuevos);
    context.read<EstadisticasCubit>().cargar(nuevos);
  }

  void _quitarFiltroCreador(OpcionFiltro opcion) {
    final nuevos = _filtros.copyWith(
      creadoresSeleccionados: _filtros.creadoresSeleccionados.where((o) => o.id != opcion.id).toList(),
    );
    setState(() => _filtros = nuevos);
    context.read<EstadisticasCubit>().cargar(nuevos);
  }

  void _quitarFiltroTag(OpcionFiltro opcion) {
    final nuevos = _filtros.copyWith(
      tagsSeleccionados: _filtros.tagsSeleccionados.where((o) => o.id != opcion.id).toList(),
    );
    setState(() => _filtros = nuevos);
    context.read<EstadisticasCubit>().cargar(nuevos);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EstadisticasCubit, EstadisticasEstado>(
      builder: (context, estado) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor:          Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness:     Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: ColoresApp.fondo,
          body: Column(
            children: [
              SafeArea(
                bottom: false,
                child: _BarraTitulo(
                  filtros:    _filtros,
                  alFiltrar:  () => _abrirFiltros(
                    estado is EstadisticasCargadas
                        ? estado.opciones
                        : OpcionesFiltros.vacio(),
                  ),
                  alLimpiar:  _limpiarFiltros,
                ),
              ),
              Expanded(child: _construirCuerpo(estado)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirCuerpo(EstadisticasEstado estado) => switch (estado) {
        EstadisticasInicial() || EstadisticasCargando() => const Center(
            child: CircularProgressIndicator(color: ColoresApp.acento),
          ),
        EstadisticasCargadas() => _CuerpoEstadisticas(
            datos:           estado,
            onDetalle:       _abrirDetalle,
            onQuitarTipo:    _quitarFiltroTipo,
            onQuitarCreador: _quitarFiltroCreador,
            onQuitarTag:     _quitarFiltroTag,
          ),
        final EstadisticasError e => _VistaError(
            mensaje:      e.mensaje,
            alReintentar: () => context.read<EstadisticasCubit>().cargar(_filtros),
          ),
      };
}

// ─── Barra de título ──────────────────────────────────────────────────────────

class _BarraTitulo extends StatelessWidget {
  const _BarraTitulo({
    required this.filtros,
    required this.alFiltrar,
    required this.alLimpiar,
  });

  final FiltrosEstadisticas filtros;
  final VoidCallback         alFiltrar;
  final VoidCallback         alLimpiar;

  @override
  Widget build(BuildContext context) {
    final totalActivos = filtros.totalFiltrosActivos;
    return BarraSuperiorApp(
      izquierda: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BotonRegresar(),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize:       MainAxisSize.min,
            children: [
              Text(
                'Estadísticas',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize:   20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                filtros.etiquetaRango,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:      ColoresApp.acento,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
      derecha: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (totalActivos > 0) ...[
            Material(
              color:        ColoresApp.rojoClaro,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap:        alLimpiar,
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Icon(Icons.filter_alt_off_rounded, color: ColoresApp.rojo, size: 15),
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Material(
            color:        Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap:        alFiltrar,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color:        totalActivos > 0 ? ColoresApp.acento : ColoresApp.acentoClaro,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tune_rounded,
                      color: totalActivos > 0 ? ColoresApp.blanco : ColoresApp.acento, size: 15),
                    const SizedBox(width: 4),
                    Text(
                      totalActivos > 0 ? 'Filtros ($totalActivos)' : 'Filtros',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color:      totalActivos > 0 ? ColoresApp.blanco : ColoresApp.acento,
                        fontWeight: FontWeight.w700,
                        fontSize:   12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Cuerpo principal ─────────────────────────────────────────────────────────

class _CuerpoEstadisticas extends StatelessWidget {
  const _CuerpoEstadisticas({
    required this.datos,
    required this.onDetalle,
    required this.onQuitarTipo,
    required this.onQuitarCreador,
    required this.onQuitarTag,
  });

  final EstadisticasCargadas               datos;
  final void Function(String, DatoGrafica) onDetalle;
  final ValueChanged<OpcionFiltro>         onQuitarTipo;
  final ValueChanged<OpcionFiltro>         onQuitarCreador;
  final ValueChanged<OpcionFiltro>         onQuitarTag;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (datos.filtros.tieneFiltrosActivos) ...[
            _ChipsFiltrosActivos(
              filtros:         datos.filtros,
              onQuitarTipo:    onQuitarTipo,
              onQuitarCreador: onQuitarCreador,
              onQuitarTag:     onQuitarTag,
            ),
            const SizedBox(height: 12),
          ],
          ..._seccionSuperior(context),
          ..._seccionMedia(),
          ..._seccionInferior(),
        ],
      ),
    );
  }

  List<Widget> _seccionSuperior(BuildContext context) => [
    Material(
      color:        Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap:        () => context.push(Rutas.auditoriaEvento),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width:   double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color:        ColoresApp.tealClaro,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.manage_search_rounded, color: ColoresApp.teal, size: 18),
              const SizedBox(width: 8),
              Text(
                'Auditoría por evento',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color:      ColoresApp.teal,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    const SizedBox(height: 10),
    _SeccionKpis(resumen: datos.resumen),
    const SizedBox(height: 12),
    _TarjetaGrafica(
      titulo:    'Embudo de asistencia',
      subtitulo: 'Conversión de convocados a completados',
      child: _GraficaEmbudo(porEstatus: datos.porEstatus),
    ),
    const SizedBox(height: 16),
    _SeccionEstadoEventos(estadoEventos: datos.estadoEventos),
    const SizedBox(height: 16),
    _TarjetaGrafica(
      titulo:    'Tendencia mensual',
      subtitulo: 'Volumen de eventos y tasa de asistencia por mes',
      altura:    220,
      child: _GraficaTendenciaDual(
        datos:  datos.tendenciaDual,
        onTap: (d) => onDetalle('mes', d),
      ),
    ),
    const SizedBox(height: 16),
    if (datos.composicionMensual.isNotEmpty) ...[
      _TarjetaGrafica(
        titulo:    'Composición por tipo',
        subtitulo: 'Distribución de tipos de evento por mes',
        altura:    240,
        child: _GraficaComposicion(
          datos:  datos.composicionMensual,
          onTap: (d) => onDetalle('mes', d),
        ),
      ),
      const SizedBox(height: 16),
    ],
  ];

  List<Widget> _seccionMedia() => [
    _TarjetaGrafica(
      titulo:    'Por tipo de evento',
      subtitulo: 'Distribución según categoría',
      altura:    220,
      child: _GraficaDonut(
        datos:  datos.porTipo,
        onTap: (d) => onDetalle('tipo', d),
      ),
    ),
    const SizedBox(height: 16),
    if (datos.tasaPorTipo.isNotEmpty) ...[
      _TarjetaGrafica(
        titulo:    'Calidad por tipo de evento',
        subtitulo: 'Tasa de asistencia según categoría',
        child: _GraficaTasaPorTipo(datos: datos.tasaPorTipo),
      ),
      const SizedBox(height: 16),
    ],
    _TarjetaGrafica(
      titulo:    'Asistencia por estatus',
      subtitulo: 'Toca una barra para ver los eventos',
      altura:    200,
      child: _GraficaBarrasEstatus(
        datos:  datos.porEstatus,
        onTap: (d) => onDetalle('estatus_asistencia', d),
      ),
    ),
    const SizedBox(height: 16),
    _SeccionPorCreador(
      porCreador: datos.porCreador,
      onTap: (d) => onDetalle('creador', d.toDatoGrafica()),
    ),
    const SizedBox(height: 16),
    if (datos.topAsistentes.isNotEmpty) ...[
      _SeccionTopAsistentes(datos: datos.topAsistentes),
      const SizedBox(height: 16),
    ],
  ];

  List<Widget> _seccionInferior() => [
    _TarjetaGrafica(
      titulo:    'Actividad por día',
      subtitulo: 'Asistentes presentes según día de semana',
      altura:    180,
      child: _GraficaBarrasDia(
        datos:  datos.porDiaSemana,
        onTap: (d) => onDetalle('dia_semana', d),
      ),
    ),
    const SizedBox(height: 16),
    if (datos.heatmapHora.isNotEmpty) ...[
      _TarjetaGrafica(
        titulo:    'Horario de asistencia',
        subtitulo: 'Entradas registradas por hora y día de semana',
        child: _GraficaHeatmap(datos: datos.heatmapHora),
      ),
      const SizedBox(height: 16),
    ],
    _TarjetaGrafica(
      titulo:    'Escala de eventos',
      subtitulo: 'Distribución por número de asistentes',
      altura:    180,
      child: _GraficaEscala(datos: datos.escalaPorTamano),
    ),
    const SizedBox(height: 16),
    if (datos.topTags.isNotEmpty) ...[
      _SeccionTopTags(
        datos:  datos.topTags,
        onTap: (d) => onDetalle('tipo', d),
      ),
      const SizedBox(height: 16),
    ],
    _SeccionTopEventos(topEventos: datos.topEventos),
  ];
}

// ─── Chips de filtros activos ─────────────────────────────────────────────────

class _ChipsFiltrosActivos extends StatelessWidget {
  const _ChipsFiltrosActivos({
    required this.filtros,
    required this.onQuitarTipo,
    required this.onQuitarCreador,
    required this.onQuitarTag,
  });

  final FiltrosEstadisticas    filtros;
  final ValueChanged<OpcionFiltro> onQuitarTipo;
  final ValueChanged<OpcionFiltro> onQuitarCreador;
  final ValueChanged<OpcionFiltro> onQuitarTag;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8, runSpacing: 6,
      children: [
        for (final o in filtros.tiposSeleccionados)
          _ChipFiltro(prefijo: 'Tipo',    nombre: o.nombre,
            color: ColoresApp.acento, fondo: ColoresApp.acentoClaro,
            alQuitar: () => onQuitarTipo(o)),
        for (final o in filtros.creadoresSeleccionados)
          _ChipFiltro(prefijo: 'Creador', nombre: o.nombre,
            color: ColoresApp.teal, fondo: ColoresApp.tealClaro,
            alQuitar: () => onQuitarCreador(o)),
        for (final o in filtros.tagsSeleccionados)
          _ChipFiltro(prefijo: 'Tag',     nombre: o.nombre,
            color: ColoresApp.ambar, fondo: ColoresApp.ambarClaro,
            alQuitar: () => onQuitarTag(o)),
      ],
    );
  }
}

class _ChipFiltro extends StatelessWidget {
  const _ChipFiltro({
    required this.prefijo,
    required this.nombre,
    required this.color,
    required this.fondo,
    required this.alQuitar,
  });

  final String       prefijo;
  final String       nombre;
  final Color        color;
  final Color        fondo;
  final VoidCallback alQuitar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 4, top: 5, bottom: 5),
      decoration: BoxDecoration(
        color:        fondo,
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$prefijo: ',
            style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.7), fontWeight: FontWeight.w500)),
          Text(nombre,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          Material(
            color:        Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap:        alQuitar,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close_rounded, size: 16, color: color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── KPIs ─────────────────────────────────────────────────────────────────────

class _SeccionKpis extends StatelessWidget {
  const _SeccionKpis({required this.resumen});
  final ResumenEstadisticas resumen;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [
          Expanded(child: _TarjetaKpi(icono: Icons.event_outlined,
            valor: '${resumen.totalEventos}', label: 'Eventos',
            color: ColoresApp.acento, fondo: ColoresApp.acentoClaro)),
          const SizedBox(width: 12),
          Expanded(child: _TarjetaKpi(icono: Icons.people_outline_rounded,
            valor: '${resumen.totalAsistencias}', label: 'Asistencias',
            color: ColoresApp.verde, fondo: ColoresApp.verdeClaro)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _TarjetaKpi(icono: Icons.percent_rounded,
            valor: '${resumen.tasaAsistencia.toStringAsFixed(1)}%', label: 'Tasa asistencia',
            color: ColoresApp.ambar, fondo: ColoresApp.ambarClaro)),
          const SizedBox(width: 12),
          Expanded(child: _TarjetaKpi(icono: Icons.person_outline_rounded,
            valor: '${resumen.usuariosActivos}', label: 'Usuarios activos',
            color: ColoresApp.teal, fondo: ColoresApp.tealClaro)),
        ]),
      ],
    );
  }
}

class _TarjetaKpi extends StatelessWidget {
  const _TarjetaKpi({
    required this.icono,
    required this.valor,
    required this.label,
    required this.color,
    required this.fondo,
  });

  final IconData icono;
  final String   valor;
  final String   label;
  final Color    color;
  final Color    fondo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        ColoresApp.superficiePrimaria,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: ColoresApp.sombraTarjeta, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize:        MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(10)),
            child: Icon(icono, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(valor, style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontSize: 22, fontWeight: FontWeight.w800, color: ColoresApp.textoPrimario,
          )),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: ColoresApp.textoTerciario,
          )),
        ],
      ),
    );
  }
}

// ─── Contenedor de gráfica ────────────────────────────────────────────────────

class _TarjetaGrafica extends StatelessWidget {
  const _TarjetaGrafica({
    required this.titulo,
    required this.child,
    this.subtitulo,
    this.altura,
  });

  final String  titulo;
  final String? subtitulo;
  final Widget  child;
  final double? altura;

  @override
  Widget build(BuildContext context) {
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        ColoresApp.superficiePrimaria,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: ColoresApp.sombraTarjeta, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: Theme.of(context).textTheme.headlineSmall),
          if (subtitulo != null) ...[
            const SizedBox(height: 2),
            Text(subtitulo!, style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ColoresApp.textoTerciario,
            )),
          ],
          const SizedBox(height: 16),
          altura != null ? SizedBox(height: altura!, child: child) : child,
        ],
      ),
    );
  }
}

// ─── Embudo de asistencia ─────────────────────────────────────────────────────

class _GraficaEmbudo extends StatelessWidget {
  const _GraficaEmbudo({required this.porEstatus});
  final List<DatoGrafica> porEstatus;

  @override
  Widget build(BuildContext context) {
    final m = MetricasEmbudo.desdeEstatus(porEstatus);
    if (!m.hayDatos) return const _SinDatos();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FilaEmbudo(etiqueta: 'Convocados',  cantidad: m.total,       pct: 1.0,
            color: ColoresApp.acento),
        const SizedBox(height: 10),
        _FilaEmbudo(etiqueta: 'Llegaron',    cantidad: m.llegaron,    pct: m.total == 0 ? 0 : m.llegaron / m.total,
            color: ColoresApp.verde),
        const SizedBox(height: 10),
        _FilaEmbudo(etiqueta: 'Completaron', cantidad: m.completaron, pct: m.total == 0 ? 0 : m.completaron / m.total,
            color: ColoresApp.teal),
        const SizedBox(height: 10),
        _FilaEmbudo(etiqueta: 'No llegaron', cantidad: m.ausentes,    pct: m.total == 0 ? 0 : m.ausentes / m.total,
            color: ColoresApp.rojo),
      ],
    );
  }
}

class _FilaEmbudo extends StatelessWidget {
  const _FilaEmbudo({
    required this.etiqueta,
    required this.cantidad,
    required this.pct,
    required this.color,
  });

  final String etiqueta;
  final double cantidad;
  final double pct;
  final Color  color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(etiqueta, style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: ColoresApp.textoSecundario, fontWeight: FontWeight.w600,
          )),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value:           pct,
              minHeight:       14,
              valueColor:      AlwaysStoppedAnimation<Color>(color),
              backgroundColor: color.withValues(alpha: 0.1),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text('${(pct * 100).toStringAsFixed(0)}%',
            textAlign: TextAlign.end,
            style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 28,
          child: Text('${cantidad.toInt()}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ColoresApp.textoTerciario, fontSize: 11,
            )),
        ),
      ],
    );
  }
}

// ─── Salud operacional de eventos ─────────────────────────────────────────────

class _SeccionEstadoEventos extends StatelessWidget {
  const _SeccionEstadoEventos({required this.estadoEventos});
  final List<DatoGrafica> estadoEventos;

  @override
  Widget build(BuildContext context) {
    if (estadoEventos.isEmpty) return const SizedBox.shrink();
    final total = estadoEventos.fold(0.0, (s, d) => s + d.valor);
    if (total == 0) return const SizedBox.shrink();

    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        ColoresApp.superficiePrimaria,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: ColoresApp.sombraTarjeta, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Salud operacional', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 2),
          Text('Estado de los eventos en el período',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: ColoresApp.textoTerciario)),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: estadoEventos.map((d) => Flexible(
                flex: d.valor.toInt().clamp(1, 9999),
                child: Container(
                  height: 16,
                  color: _colorEstatusEvento(d.etiqueta),
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: estadoEventos.map((d) {
              final color = _colorEstatusEvento(d.etiqueta);
              final pct   = (d.valor / total * 100).toStringAsFixed(0);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color:        color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border:       Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text(d.etiqueta, style: TextStyle(
                      fontSize: 12, color: color, fontWeight: FontWeight.w600,
                    )),
                    const SizedBox(width: 5),
                    Text('${d.valor.toInt()} ($pct%)', style: TextStyle(
                      fontSize: 12, color: color, fontWeight: FontWeight.w800,
                    )),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Gráfica de tendencia dual ────────────────────────────────────────────────

class _GraficaTendenciaDual extends StatelessWidget {
  const _GraficaTendenciaDual({required this.datos, required this.onTap});

  final List<DatoTendenciaDual>    datos;
  final ValueChanged<DatoGrafica>  onTap;

  LineTouchData _touchData(double maxCant) => LineTouchData(
    touchCallback: (event, response) {
      if (!event.isInterestedForInteractions) return;
      final spots = response?.lineBarSpots;
      if (spots == null || spots.isEmpty) return;
      final i = spots.first.spotIndex;
      if (i >= 0 && i < datos.length) {
        onTap(DatoGrafica(etiqueta: datos[i].mes, valor: datos[i].cantidad, valorSql: datos[i].mes));
      }
    },
    touchTooltipData: LineTouchTooltipData(
      getTooltipColor: (_) => ColoresApp.textoPrimario,
      getTooltipItems: (spots) => spots.map((s) {
        final isRate = s.barIndex == 1;
        return LineTooltipItem(
          isRate
              ? '${s.y.toStringAsFixed(0)}% tasa'
              : '${(maxCant == 0 ? 0 : s.y / 100 * maxCant).toInt()} eventos',
          TextStyle(
            color: isRate ? ColoresApp.verde : ColoresApp.acento2,
            fontWeight: FontWeight.w700, fontSize: 12,
          ),
        );
      }).toList(),
    ),
  );

  FlTitlesData _titlesData() => FlTitlesData(
    leftTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    topTitles:    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true, reservedSize: 28, interval: 1,
        getTitlesWidget: (valor, meta) {
          final i = valor.toInt();
          if (i < 0 || i >= datos.length) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(datos[i].mes, style: const TextStyle(
              fontSize: 10, color: ColoresApp.textoTerciario, fontWeight: FontWeight.w500,
            )),
          );
        },
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (datos.length < 2) return const _SinDatos();
    final maxCant = datos.map((d) => d.cantidad).reduce(max);

    return Column(
      children: [
        Expanded(
          child: LineChart(LineChartData(
            minX: 0, maxX: (datos.length - 1).toDouble(),
            minY: 0, maxY: 100,
            gridData: FlGridData(
              show: true, drawVerticalLine: false, horizontalInterval: 25,
              getDrawingHorizontalLine: (_) =>
                  const FlLine(color: ColoresApp.bordesuave, strokeWidth: 1),
            ),
            borderData:    FlBorderData(show: false),
            lineTouchData: _touchData(maxCant),
            titlesData:    _titlesData(),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(datos.length, (i) => FlSpot(
                  i.toDouble(),
                  maxCant == 0 ? 0 : (datos[i].cantidad / maxCant * 100),
                )),
                isCurved: true, color: ColoresApp.acento, barWidth: 2.5,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: true,
                    color: ColoresApp.acento.withValues(alpha: 0.06)),
              ),
              LineChartBarData(
                spots: List.generate(datos.length, (i) =>
                    FlSpot(i.toDouble(), datos[i].tasa)),
                isCurved: true, color: ColoresApp.verde, barWidth: 2.5,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: true,
                    color: ColoresApp.verde.withValues(alpha: 0.06)),
                dashArray: [6, 3],
              ),
            ],
          )),
        ),
        const SizedBox(height: 10),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PuntoLeyenda(color: ColoresApp.acento, label: 'Eventos (relativo)'),
            SizedBox(width: 20),
            _PuntoLeyenda(color: ColoresApp.verde,  label: 'Tasa asistencia %'),
          ],
        ),
      ],
    );
  }
}

class _PuntoLeyenda extends StatelessWidget {
  const _PuntoLeyenda({required this.color, required this.label});
  final Color  color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 20, height: 3, decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(2),
        )),
        const SizedBox(width: 5),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: ColoresApp.textoSecundario, fontSize: 11,
        )),
      ],
    );
  }
}

// ─── Composición mensual (barras apiladas) ────────────────────────────────────

class _GraficaComposicion extends StatelessWidget {
  const _GraficaComposicion({required this.datos, required this.onTap});

  final List<ComposicionMes>       datos;
  final ValueChanged<DatoGrafica>  onTap;

  List<BarChartGroupData> _construirBarras(List<String> tipos) =>
      List.generate(datos.length, (i) {
        final mes = datos[i];
        double acum = 0;
        final stackItems = <BarChartRodStackItem>[];
        for (int j = 0; j < tipos.length; j++) {
          final val = mes.porTipo[tipos[j]] ?? 0;
          if (val > 0) {
            stackItems.add(BarChartRodStackItem(acum, acum + val, _paleta[j % _paleta.length]));
            acum += val;
          }
        }
        return BarChartGroupData(
          x: i,
          barRods: [BarChartRodData(
            toY: acum, rodStackItems: stackItems, width: 18,
            borderRadius: BorderRadius.circular(4),
          )],
        );
      });

  BarTouchData _touchData() => BarTouchData(
    touchCallback: (event, response) {
      if (!event.isInterestedForInteractions) return;
      if (event is! FlTapUpEvent) return;
      final i = response?.spot?.touchedBarGroupIndex ?? -1;
      if (i >= 0 && i < datos.length) {
        onTap(DatoGrafica(etiqueta: datos[i].mes, valor: datos[i].total, valorSql: datos[i].mes));
      }
    },
    touchTooltipData: BarTouchTooltipData(
      getTooltipColor: (_) => ColoresApp.textoPrimario,
      getTooltipItem: (group, _, rod, __) => BarTooltipItem(
        '${rod.toY.toInt()} eventos',
        const TextStyle(color: ColoresApp.blanco, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (datos.isEmpty) return const _SinDatos();

    final tiposSet = <String>{};
    for (final m in datos) { tiposSet.addAll(m.porTipo.keys); }
    final tipos = tiposSet.toList()..sort();
    final maxY  = datos.map((m) => m.total).fold(0.0, max);

    return Column(
      children: [
        Expanded(
          child: BarChart(BarChartData(
            maxY: (maxY * 1.3).ceilToDouble(),
            gridData: FlGridData(
              show: true, drawVerticalLine: false,
              getDrawingHorizontalLine: (_) =>
                  const FlLine(color: ColoresApp.bordesuave, strokeWidth: 1),
            ),
            borderData:   FlBorderData(show: false),
            barTouchData: _touchData(),
            titlesData: FlTitlesData(
              leftTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true, reservedSize: 28, interval: 1,
                  getTitlesWidget: (val, meta) {
                    final i = val.toInt();
                    if (i < 0 || i >= datos.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(datos[i].mes, style: const TextStyle(
                        fontSize: 10, color: ColoresApp.textoTerciario, fontWeight: FontWeight.w500,
                      )),
                    );
                  },
                ),
              ),
            ),
            barGroups: _construirBarras(tipos),
          )),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10, runSpacing: 6,
          children: List.generate(tipos.length, (j) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(
                color: _paleta[j % _paleta.length], borderRadius: BorderRadius.circular(2),
              )),
              const SizedBox(width: 5),
              Text(tipos[j], style: const TextStyle(
                fontSize: 11, color: ColoresApp.textoSecundario,
              )),
            ],
          )),
        ),
      ],
    );
  }
}

// ─── Gráfica donut ────────────────────────────────────────────────────────────

class _GraficaDonut extends StatefulWidget {
  const _GraficaDonut({required this.datos, required this.onTap});
  final List<DatoGrafica>      datos;
  final ValueChanged<DatoGrafica> onTap;

  @override
  State<_GraficaDonut> createState() => _GraficaDonutState();
}

class _GraficaDonutState extends State<_GraficaDonut> {
  int? _seleccionado;

  @override
  Widget build(BuildContext context) {
    if (widget.datos.isEmpty) return const _SinDatos();
    final total = widget.datos.fold<double>(0, (s, d) => s + d.valor);

    return Row(
      children: [
        Expanded(
          child: PieChart(PieChartData(
            pieTouchData: PieTouchData(
              touchCallback: (event, response) {
                if (!event.isInterestedForInteractions) {
                  setState(() => _seleccionado = null);
                  return;
                }
                final i = response?.touchedSection?.touchedSectionIndex ?? -1;
                setState(() => _seleccionado = i >= 0 ? i : null);
                if (event is FlTapUpEvent && i >= 0 && i < widget.datos.length) {
                  widget.onTap(widget.datos[i]);
                }
              },
            ),
            sections: List.generate(widget.datos.length, (i) {
              final d      = widget.datos[i];
              final color  = _paleta[i % _paleta.length];
              final activo = _seleccionado == i;
              final pct    = total == 0 ? 0.0 : d.valor / total;
              return PieChartSectionData(
                value:  d.valor, color: color,
                radius: activo ? 58 : 50,
                title:  '${(pct * 100).toStringAsFixed(0)}%',
                titleStyle: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: ColoresApp.blanco,
                ),
              );
            }),
            centerSpaceRadius: 44, sectionsSpace: 2,
          )),
        ),
        const SizedBox(width: 16),
        Expanded(child: _LeyendaDonut(datos: widget.datos, seleccionado: _seleccionado)),
      ],
    );
  }
}

class _LeyendaDonut extends StatelessWidget {
  const _LeyendaDonut({required this.datos, required this.seleccionado});
  final List<DatoGrafica> datos;
  final int?              seleccionado;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment:  MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(datos.length, (i) {
        final color  = _paleta[i % _paleta.length];
        final activo = seleccionado == i;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Container(
              width: activo ? 12 : 10, height: activo ? 12 : 10,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(datos[i].etiqueta, overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:      activo ? ColoresApp.textoPrimario : ColoresApp.textoSecundario,
                  fontWeight: activo ? FontWeight.w700 : FontWeight.w500, fontSize: 12,
                )),
            ),
            Text('${datos[i].valor.toInt()}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: activo ? color : ColoresApp.textoPrimario,
                fontWeight: FontWeight.w700, fontSize: 12,
              )),
          ]),
        );
      }),
    );
  }
}

// ─── Tasa de asistencia por tipo ──────────────────────────────────────────────

class _GraficaTasaPorTipo extends StatelessWidget {
  const _GraficaTasaPorTipo({required this.datos});
  final List<DatoTasaTipo> datos;

  @override
  Widget build(BuildContext context) {
    if (datos.isEmpty) return const _SinDatos();
    return Column(
      children: datos.map((d) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(d.tipoNombre,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600, fontSize: 13,
                  ), overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Text('${d.tasa.toStringAsFixed(0)}%', style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800,
                color: _colorTasa(d.tasa),
              )),
            ]),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value:           d.tasa / 100,
                minHeight:       10,
                backgroundColor: ColoresApp.superficieTerciar,
                valueColor:      AlwaysStoppedAnimation<Color>(_colorTasa(d.tasa)),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${d.presentes} presentes · ${d.totalRegistros} registros · ${d.totalEventos} eventos',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ColoresApp.textoTerciario, fontSize: 11,
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}

// ─── Barras por estatus ───────────────────────────────────────────────────────

class _GraficaBarrasEstatus extends StatelessWidget {
  const _GraficaBarrasEstatus({required this.datos, required this.onTap});
  final List<DatoGrafica>      datos;
  final ValueChanged<DatoGrafica> onTap;

  @override
  Widget build(BuildContext context) {
    if (datos.isEmpty) return const _SinDatos();
    final maxY = datos.map((d) => d.valor).reduce(max);

    return BarChart(BarChartData(
      maxY: (maxY * 1.35).ceilToDouble(),
      gridData: FlGridData(
        show: true, drawVerticalLine: false,
        getDrawingHorizontalLine: (_) =>
            const FlLine(color: ColoresApp.bordesuave, strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      barTouchData: BarTouchData(
        touchCallback: (event, response) {
          if (!event.isInterestedForInteractions) return;
          if (event is! FlTapUpEvent) return;
          final i = response?.spot?.touchedBarGroupIndex ?? -1;
          if (i >= 0 && i < datos.length) onTap(datos[i]);
        },
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => ColoresApp.textoPrimario,
          getTooltipItem: (group, _, rod, __) => BarTooltipItem(
            '${rod.toY.toInt()}',
            const TextStyle(color: ColoresApp.blanco, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ),
      ),
      titlesData: FlTitlesData(
        leftTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true, reservedSize: 36,
            getTitlesWidget: (valor, meta) {
              final i = valor.toInt();
              if (i < 0 || i >= datos.length) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(datos[i].etiqueta, textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10, color: ColoresApp.textoTerciario, fontWeight: FontWeight.w500,
                  )),
              );
            },
          ),
        ),
      ),
      barGroups: List.generate(datos.length, (i) => BarChartGroupData(
        x: i,
        barRods: [BarChartRodData(
          toY:          datos[i].valor,
          color:        _colorEstatus(datos[i].etiqueta),
          width:        28,
          borderRadius: BorderRadius.circular(6),
        )],
      )),
    ));
  }
}

// ─── Barras por día de semana ─────────────────────────────────────────────────

class _GraficaBarrasDia extends StatelessWidget {
  const _GraficaBarrasDia({required this.datos, required this.onTap});
  final List<DatoGrafica>      datos;
  final ValueChanged<DatoGrafica> onTap;

  @override
  Widget build(BuildContext context) {
    if (datos.isEmpty) return const _SinDatos();
    final maxY = datos.map((d) => d.valor).reduce(max);

    return BarChart(BarChartData(
      maxY: (maxY * 1.35).ceilToDouble(),
      gridData: FlGridData(
        show: true, drawVerticalLine: false,
        getDrawingHorizontalLine: (_) =>
            const FlLine(color: ColoresApp.bordesuave, strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      barTouchData: BarTouchData(
        touchCallback: (event, response) {
          if (!event.isInterestedForInteractions) return;
          if (event is! FlTapUpEvent) return;
          final i = response?.spot?.touchedBarGroupIndex ?? -1;
          if (i >= 0 && i < datos.length) onTap(datos[i]);
        },
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => ColoresApp.textoPrimario,
          getTooltipItem: (group, _, rod, __) => BarTooltipItem(
            '${rod.toY.toInt()} asistentes',
            const TextStyle(color: ColoresApp.blanco, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ),
      ),
      titlesData: FlTitlesData(
        leftTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true, reservedSize: 32,
            getTitlesWidget: (valor, meta) {
              final i = valor.toInt();
              if (i < 0 || i >= datos.length) return const SizedBox.shrink();
              final activo = datos[i].valor == maxY;
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(datos[i].etiqueta, style: TextStyle(
                  fontSize: 11,
                  fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
                  color: activo ? ColoresApp.teal : ColoresApp.textoTerciario,
                )),
              );
            },
          ),
        ),
      ),
      barGroups: List.generate(datos.length, (i) {
        final activo = datos[i].valor == maxY;
        return BarChartGroupData(
          x: i,
          barRods: [BarChartRodData(
            toY:          datos[i].valor,
            color:        activo ? ColoresApp.teal : ColoresApp.teal.withValues(alpha: 0.45),
            width:        22,
            borderRadius: BorderRadius.circular(6),
          )],
        );
      }),
    ));
  }
}

// ─── Mapa de calor de hora de entrada ────────────────────────────────────────

class _GraficaHeatmap extends StatelessWidget {
  const _GraficaHeatmap({required this.datos});
  final List<DatoHeatmap> datos;

  static const _dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  @override
  Widget build(BuildContext context) {
    if (datos.isEmpty) return const _SinDatos();

    final maxCant = datos.map((d) => d.cantidad).reduce(max).toDouble();
    final horas   = datos.map((d) => d.hora).toSet().toList()..sort();
    final mapa    = {for (final d in datos) '${d.dia}_${d.hora}': d.cantidad};

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const SizedBox(width: 44),
            ..._dias.map((d) => SizedBox(
              width: 38,
              child: Text(d, textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10, color: ColoresApp.textoTerciario, fontWeight: FontWeight.w700,
                )),
            )),
          ]),
          const SizedBox(height: 6),
          ...horas.map((hora) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              SizedBox(
                width: 44,
                child: Text('${hora.toString().padLeft(2, '0')}h',
                  style: const TextStyle(fontSize: 10, color: ColoresApp.textoTerciario)),
              ),
              ..._dias.map((dia) {
                final cant      = mapa['${dia}_$hora'] ?? 0;
                final intensity = maxCant == 0 ? 0.0 : cant / maxCant;
                return Container(
                  width: 34, height: 24,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: intensity == 0
                        ? ColoresApp.superficieTerciar
                        : ColoresApp.acento.withValues(alpha: 0.15 + intensity * 0.85),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: cant > 0
                      ? Center(child: Text('$cant', style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: intensity > 0.55 ? Colors.white : ColoresApp.acento,
                        )))
                      : null,
                );
              }),
            ]),
          )),
        ],
      ),
    );
  }
}

// ─── Escala de eventos (histograma) ──────────────────────────────────────────

class _GraficaEscala extends StatelessWidget {
  const _GraficaEscala({required this.datos});
  final List<DatoGrafica> datos;

  @override
  Widget build(BuildContext context) {
    if (datos.isEmpty) return const _SinDatos();
    final maxY = datos.map((d) => d.valor).reduce(max);

    return BarChart(BarChartData(
      maxY: (maxY * 1.35).ceilToDouble(),
      gridData: FlGridData(
        show: true, drawVerticalLine: false,
        getDrawingHorizontalLine: (_) =>
            const FlLine(color: ColoresApp.bordesuave, strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => ColoresApp.textoPrimario,
          getTooltipItem: (group, _, rod, __) => BarTooltipItem(
            '${rod.toY.toInt()} eventos',
            const TextStyle(color: ColoresApp.blanco, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ),
      ),
      titlesData: FlTitlesData(
        leftTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true, reservedSize: 32,
            getTitlesWidget: (valor, meta) {
              final i = valor.toInt();
              if (i < 0 || i >= datos.length) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(datos[i].etiqueta, style: const TextStyle(
                  fontSize: 10, color: ColoresApp.textoTerciario, fontWeight: FontWeight.w500,
                )),
              );
            },
          ),
        ),
      ),
      barGroups: List.generate(datos.length, (i) {
        final pct = maxY == 0 ? 0.0 : datos[i].valor / maxY;
        return BarChartGroupData(
          x: i,
          barRods: [BarChartRodData(
            toY:          datos[i].valor,
            color:        ColoresApp.acento.withValues(alpha: 0.3 + pct * 0.7),
            width:        32,
            borderRadius: BorderRadius.circular(6),
          )],
        );
      }),
    ));
  }
}

// ─── Por organizador ──────────────────────────────────────────────────────────

class _SeccionPorCreador extends StatelessWidget {
  const _SeccionPorCreador({required this.porCreador, required this.onTap});
  final List<DatoCreador>          porCreador;
  final ValueChanged<DatoCreador>  onTap;

  @override
  Widget build(BuildContext context) {
    if (porCreador.isEmpty) return const SizedBox.shrink();
    final maxCant = porCreador.map((d) => d.cantidad.toDouble()).reduce(max);

    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        ColoresApp.superficiePrimaria,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: ColoresApp.sombraTarjeta, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Eventos por organizador', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 2),
          Text('Toca un nombre para ver sus eventos',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: ColoresApp.textoTerciario)),
          const SizedBox(height: 16),
          ...porCreador.map((d) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child:   _FilaCreador(dato: d, maxCant: maxCant, onTap: () => onTap(d)),
          )),
        ],
      ),
    );
  }
}

class _FilaCreador extends StatelessWidget {
  const _FilaCreador({required this.dato, required this.maxCant, required this.onTap});
  final DatoCreador  dato;
  final double       maxCant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pctEventos   = maxCant == 0 ? 0.0 : dato.cantidad / maxCant;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(dato.nombre,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600, color: ColoresApp.textoPrimario, fontSize: 13,
                    ), overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                Text('${dato.cantidad} eventos · ${dato.presentes} presentes',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: ColoresApp.textoTerciario,
                  )),
              ]),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value:           pctEventos,
                  backgroundColor: ColoresApp.acentoClaro,
                  valueColor:      const AlwaysStoppedAnimation<Color>(ColoresApp.acento),
                  minHeight:       7,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Top asistentes ───────────────────────────────────────────────────────────

class _SeccionTopAsistentes extends StatelessWidget {
  const _SeccionTopAsistentes({required this.datos});
  final List<AsistenteFrecuente> datos;

  @override
  Widget build(BuildContext context) {
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        ColoresApp.superficiePrimaria,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: ColoresApp.sombraTarjeta, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Asistentes más frecuentes', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 2),
          Text('Usuarios con mayor presencia en eventos',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: ColoresApp.textoTerciario)),
          const SizedBox(height: 16),
          ...datos.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child:   _FilaAsistente(puesto: e.key + 1, dato: e.value),
          )),
        ],
      ),
    );
  }
}

class _FilaAsistente extends StatelessWidget {
  const _FilaAsistente({required this.puesto, required this.dato});
  final int              puesto;
  final AsistenteFrecuente dato;

  @override
  Widget build(BuildContext context) {
    final color = _colorTasa(dato.tasa);
    return Row(
      children: [
        Container(
          width: 26, height: 26,
          decoration: BoxDecoration(
            color:  puesto <= 3 ? ColoresApp.acentoClaro : ColoresApp.superficieTerciar,
            shape:  BoxShape.circle,
          ),
          child: Center(child: Text('$puesto', style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w800,
            color: puesto <= 3 ? ColoresApp.acento : ColoresApp.textoTerciario,
          ))),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(dato.nombre,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600, fontSize: 13,
                    ), overflow: TextOverflow.ellipsis),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:        color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${dato.tasa.toStringAsFixed(0)}%', style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w800, color: color,
                  )),
                ),
              ]),
              const SizedBox(height: 3),
              Row(children: [
                const Icon(Icons.event_outlined, size: 11, color: ColoresApp.textoTerciario),
                const SizedBox(width: 3),
                Text('${dato.totalAsistencias} asistencias en ${dato.totalEventos} eventos',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ColoresApp.textoTerciario, fontSize: 11,
                  )),
              ]),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Top tags ─────────────────────────────────────────────────────────────────

class _SeccionTopTags extends StatelessWidget {
  const _SeccionTopTags({required this.datos, required this.onTap});
  final List<DatoTag>              datos;
  final ValueChanged<DatoGrafica>  onTap;

  @override
  Widget build(BuildContext context) {
    final maxCant = datos.map((d) => d.cantidad.toDouble()).reduce(max);
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        ColoresApp.superficiePrimaria,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: ColoresApp.sombraTarjeta, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tags más usados', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 2),
          Text('Etiquetas por cantidad de eventos y tasa de asistencia',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: ColoresApp.textoTerciario)),
          const SizedBox(height: 16),
          ...datos.map((d) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child:   _FilaTag(dato: d, maxCant: maxCant, onTap: () => onTap(
              DatoGrafica(etiqueta: d.nombre, valor: d.cantidad.toDouble()),
            )),
          )),
        ],
      ),
    );
  }
}

class _FilaTag extends StatelessWidget {
  const _FilaTag({required this.dato, required this.maxCant, required this.onTap});
  final DatoTag      dato;
  final double       maxCant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pct       = maxCant == 0 ? 0.0 : dato.cantidad / maxCant;
    final colorTasa = _colorTasa(dato.tasa);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:        ColoresApp.ambarClaro,
                    borderRadius: BorderRadius.circular(12),
                    border:       Border.all(color: ColoresApp.ambar.withValues(alpha: 0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.tag, size: 11, color: ColoresApp.ambar),
                    const SizedBox(width: 3),
                    Text(dato.nombre, style: const TextStyle(
                      fontSize: 11, color: ColoresApp.ambar, fontWeight: FontWeight.w700,
                    )),
                  ]),
                ),
                const Spacer(),
                Text('${dato.cantidad} eventos',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: ColoresApp.textoTerciario,
                  )),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color:        colorTasa.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${dato.tasa.toStringAsFixed(0)}%', style: TextStyle(
                    fontSize: 11, color: colorTasa, fontWeight: FontWeight.w700,
                  )),
                ),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value:           pct,
                  backgroundColor: ColoresApp.ambarClaro,
                  valueColor:      const AlwaysStoppedAnimation<Color>(ColoresApp.ambar),
                  minHeight:       5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Top 5 eventos ────────────────────────────────────────────────────────────

class _SeccionTopEventos extends StatelessWidget {
  const _SeccionTopEventos({required this.topEventos});
  final List<EventoTopStat> topEventos;

  @override
  Widget build(BuildContext context) {
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        ColoresApp.superficiePrimaria,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: ColoresApp.sombraTarjeta, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top eventos por asistencia', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 2),
          Text('Los 5 con mayor participación',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: ColoresApp.textoTerciario)),
          const SizedBox(height: 16),
          if (topEventos.isEmpty)
            const _SinDatos()
          else
            ...topEventos.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child:   _FilaTopEvento(rango: e.key + 1, evento: e.value),
            )),
        ],
      ),
    );
  }
}

class _FilaTopEvento extends StatelessWidget {
  const _FilaTopEvento({required this.rango, required this.evento});
  final int           rango;
  final EventoTopStat evento;

  @override
  Widget build(BuildContext context) {
    final pct   = evento.porcentajeAsistencia;
    final color = _colorTasa(pct * 100);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24, height: 24,
          decoration: BoxDecoration(
            color:  pct >= 0.75 ? ColoresApp.verdeClaro : ColoresApp.superficieTerciar,
            shape:  BoxShape.circle,
          ),
          child: Center(child: Text('$rango', style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w800,
            color: pct >= 0.75 ? ColoresApp.verde : ColoresApp.textoTerciario,
          ))),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(evento.titulo,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600, color: ColoresApp.textoPrimario, fontSize: 13,
                  ), overflow: TextOverflow.ellipsis, maxLines: 1)),
                const SizedBox(width: 8),
                Text('${(pct * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color, fontWeight: FontWeight.w700, fontSize: 12,
                  )),
              ]),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value:           pct,
                  backgroundColor: color.withValues(alpha: 0.12),
                  valueColor:      AlwaysStoppedAnimation<Color>(color),
                  minHeight:       7,
                ),
              ),
              const SizedBox(height: 3),
              Text('${evento.totalPresentes} de ${evento.totalEsperados} asistentes',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ColoresApp.textoTerciario, fontSize: 11,
                )),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Modal drill-down ─────────────────────────────────────────────────────────

class _ModalDetalle extends StatefulWidget {
  const _ModalDetalle({
    required this.titulo,
    required this.dimension,
    required this.valor,
    required this.filtros,
  });

  final String              titulo;
  final String              dimension;
  final String              valor;
  final FiltrosEstadisticas filtros;

  @override
  State<_ModalDetalle> createState() => _ModalDetalleState();
}

class _ModalDetalleState extends State<_ModalDetalle> {
  List<EventoResumido>? _eventos;
  bool                  _cargando = true;
  String?               _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final eventos = await context.read<EstadisticasCubit>().cargarDetalle(
        filtros:   widget.filtros,
        dimension: widget.dimension,
        valor:     widget.valor,
      );
      if (mounted) setState(() { _eventos = eventos; _cargando = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _cargando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
      decoration: const BoxDecoration(
        color:        ColoresApp.superficiePrimaria,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 14),
          Container(width: 36, height: 4,
            decoration: BoxDecoration(color: ColoresApp.bordeMedio, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              const Icon(Icons.bar_chart_rounded, color: ColoresApp.acento, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_etiquetaDimension(), style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: ColoresApp.acento, letterSpacing: 1.1,
                  )),
                  Text(widget.titulo, style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ), overflow: TextOverflow.ellipsis),
                ],
              )),
            ]),
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
      return const Center(child: CircularProgressIndicator(color: ColoresApp.acento));
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: ColoresApp.rojo)));
    }
    final lista = _eventos ?? [];
    if (lista.isEmpty) return const _SinDatos();
    return ListView.separated(
      padding:          EdgeInsets.fromLTRB(20, 0, 20, bottomPadding + 24),
      itemCount:        lista.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: ColoresApp.bordesuave),
      itemBuilder:      (_, i)  => _FilaEventoDetalle(evento: lista[i]),
    );
  }

  String _etiquetaDimension() => switch (widget.dimension) {
        'tipo'               => 'TIPO DE EVENTO',
        'creador'            => 'ORGANIZADOR',
        'mes'                => 'MES',
        'estatus_asistencia' => 'ESTATUS DE ASISTENCIA',
        'dia_semana'         => 'DÍA DE SEMANA',
        _                    => 'FILTRO',
      };
}

class _FilaEventoDetalle extends StatelessWidget {
  const _FilaEventoDetalle({required this.evento});
  final EventoResumido evento;

  @override
  Widget build(BuildContext context) {
    final pct       = evento.tasa;
    final color     = _colorTasa(pct * 100);
    final fecha     = evento.fechaInicio;
    final fechaStr  = fecha != null ? '${fecha.day}/${fecha.month}/${fecha.year}' : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(evento.titulo,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600, color: ColoresApp.textoPrimario,
                ), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Row(children: [
                const Icon(Icons.category_outlined, size: 11, color: ColoresApp.textoTerciario),
                const SizedBox(width: 3),
                Text(evento.tipoNombre, style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ColoresApp.textoTerciario, fontSize: 11,
                )),
                if (fechaStr.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  const Icon(Icons.calendar_today_outlined, size: 11, color: ColoresApp.textoTerciario),
                  const SizedBox(width: 3),
                  Text(fechaStr, style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ColoresApp.textoTerciario, fontSize: 11,
                  )),
                ],
              ]),
              const SizedBox(height: 3),
              Row(children: [
                const Icon(Icons.person_outline_rounded, size: 11, color: ColoresApp.textoTerciario),
                const SizedBox(width: 3),
                Expanded(child: Text(evento.creadorNombre,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ColoresApp.textoTerciario, fontSize: 11,
                  ), overflow: TextOverflow.ellipsis)),
              ]),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${(pct * 100).toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
            Text('${evento.presentes}/${evento.total}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ColoresApp.textoTerciario, fontSize: 11,
              )),
          ],
        ),
      ]),
    );
  }
}

// ─── Sin datos / Error ───────────────────────────────────────────────────────

class _SinDatos extends StatelessWidget {
  const _SinDatos();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bar_chart_outlined, color: ColoresApp.textoTerciario, size: 36),
            const SizedBox(height: 8),
            Text('Sin datos para este período',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: ColoresApp.textoTerciario)),
          ],
        ),
      ),
    );
  }
}

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
            const Icon(Icons.error_outline, color: ColoresApp.rojo, size: 48),
            const SizedBox(height: 16),
            Text(mensaje, textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: ColoresApp.textoSecundario)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: alReintentar,
              icon:  const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Panel de filtros avanzados ───────────────────────────────────────────────

class _PanelFiltros extends StatefulWidget {
  const _PanelFiltros({
    required this.filtrosActuales,
    required this.opciones,
    required this.alAplicar,
  });

  final FiltrosEstadisticas              filtrosActuales;
  final OpcionesFiltros                  opciones;
  final ValueChanged<FiltrosEstadisticas> alAplicar;

  @override
  State<_PanelFiltros> createState() => _PanelFiltrosState();
}

class _PanelFiltrosState extends State<_PanelFiltros>
    with SingleTickerProviderStateMixin {
  late TabController       _tabController;
  late DateTimeRange       _rango;
  late List<OpcionFiltro>  _tiposSeleccionados;
  late List<OpcionFiltro>  _creadoresSeleccionados;
  late List<OpcionFiltro>  _tagsSeleccionados;

  @override
  void initState() {
    super.initState();
    _tabController          = TabController(length: 4, vsync: this);
    _rango                  = widget.filtrosActuales.rango;
    _tiposSeleccionados     = List.from(widget.filtrosActuales.tiposSeleccionados);
    _creadoresSeleccionados = List.from(widget.filtrosActuales.creadoresSeleccionados);
    _tagsSeleccionados      = List.from(widget.filtrosActuales.tagsSeleccionados);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _seleccionarRango(int dias) {
    final ahora = DateTime.now();
    setState(() => _rango = DateTimeRange(
      start: ahora.subtract(Duration(days: dias)),
      end:   ahora,
    ));
  }

  void _seleccionarAnio() {
    final ahora = DateTime.now();
    setState(() => _rango = DateTimeRange(
      start: DateTime(ahora.year, 1, 1),
      end:   ahora,
    ));
  }

  Future<void> _seleccionarPersonalizado() async {
    final resultado = await showDateRangePicker(
      context:          context,
      firstDate:        DateTime(2020),
      lastDate:         DateTime.now(),
      initialDateRange: _rango,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: ColoresApp.acento),
        ),
        child: child!,
      ),
    );
    if (resultado != null) setState(() => _rango = resultado);
  }

  void _toggleTipo(OpcionFiltro o) => setState(() {
    _tiposSeleccionados.any((e) => e.id == o.id)
        ? _tiposSeleccionados.removeWhere((e) => e.id == o.id)
        : _tiposSeleccionados.add(o);
  });

  void _toggleCreador(OpcionFiltro o) => setState(() {
    _creadoresSeleccionados.any((e) => e.id == o.id)
        ? _creadoresSeleccionados.removeWhere((e) => e.id == o.id)
        : _creadoresSeleccionados.add(o);
  });

  void _toggleTag(OpcionFiltro o) => setState(() {
    _tagsSeleccionados.any((e) => e.id == o.id)
        ? _tagsSeleccionados.removeWhere((e) => e.id == o.id)
        : _tagsSeleccionados.add(o);
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final totalActivos  = _tiposSeleccionados.length +
        _creadoresSeleccionados.length +
        _tagsSeleccionados.length;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.88),
      child: Container(
        decoration: const BoxDecoration(
          color:        ColoresApp.superficiePrimaria,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 14),
            Container(width: 36, height: 4,
              decoration: BoxDecoration(color: ColoresApp.bordeMedio, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Text('Filtros', style: Theme.of(context).textTheme.headlineSmall),
                const Spacer(),
                if (totalActivos > 0)
                  TextButton(
                    onPressed: () => setState(() {
                      _tiposSeleccionados.clear();
                      _creadoresSeleccionados.clear();
                      _tagsSeleccionados.clear();
                    }),
                    child: const Text('Limpiar todo',
                      style: TextStyle(color: ColoresApp.rojo, fontSize: 13)),
                  ),
              ]),
            ),
            const SizedBox(height: 8),
            _TabsFiltros(controller: _tabController, totalActivos: totalActivos),
            const SizedBox(height: 4),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _TabPeriodo(
                    rango:             _rango,
                    alSeleccionar7:    () => _seleccionarRango(7),
                    alSeleccionar30:   () => _seleccionarRango(30),
                    alSeleccionar90:   () => _seleccionarRango(90),
                    alSeleccionarAnio: _seleccionarAnio,
                    alPersonalizado:   _seleccionarPersonalizado,
                  ),
                  _TabMultiselect(
                    opciones:      widget.opciones.tipos,
                    seleccionados: _tiposSeleccionados,
                    onToggle:      _toggleTipo,
                    etiquetaVacia: 'No hay tipos de evento disponibles para el período',
                  ),
                  _TabMultiselect(
                    opciones:      widget.opciones.creadores,
                    seleccionados: _creadoresSeleccionados,
                    onToggle:      _toggleCreador,
                    etiquetaVacia: 'No hay organizadores disponibles para el período',
                  ),
                  _TabMultiselect(
                    opciones:      widget.opciones.tags,
                    seleccionados: _tagsSeleccionados,
                    onToggle:      _toggleTag,
                    etiquetaVacia: 'No hay tags disponibles para el período',
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding + 16),
              child: FilledButton(
                onPressed: () => widget.alAplicar(FiltrosEstadisticas(
                  rango:                  _rango,
                  tiposSeleccionados:     _tiposSeleccionados,
                  creadoresSeleccionados: _creadoresSeleccionados,
                  tagsSeleccionados:      _tagsSeleccionados,
                )),
                style: FilledButton.styleFrom(
                  backgroundColor: ColoresApp.acento,
                  minimumSize:     const Size.fromHeight(50),
                  shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Aplicar filtros',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tabs del panel ───────────────────────────────────────────────────────────

class _TabsFiltros extends StatelessWidget {
  const _TabsFiltros({required this.controller, required this.totalActivos});
  final TabController controller;
  final int           totalActivos;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color:        ColoresApp.superficieSecund,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller:           controller,
        isScrollable:         false,
        dividerColor:         Colors.transparent,
        indicatorSize:        TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color:        ColoresApp.acento,
          borderRadius: BorderRadius.circular(10),
        ),
        labelColor:           ColoresApp.blanco,
        unselectedLabelColor: ColoresApp.textoSecundario,
        labelStyle:           const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.all(4),
        tabs: const [
          Tab(text: 'Período'),
          Tab(text: 'Tipo'),
          Tab(text: 'Creador'),
          Tab(text: 'Tag'),
        ],
      ),
    );
  }
}

// ─── Tab Período ──────────────────────────────────────────────────────────────

class _TabPeriodo extends StatelessWidget {
  const _TabPeriodo({
    required this.rango,
    required this.alSeleccionar7,
    required this.alSeleccionar30,
    required this.alSeleccionar90,
    required this.alSeleccionarAnio,
    required this.alPersonalizado,
  });

  final DateTimeRange rango;
  final VoidCallback  alSeleccionar7;
  final VoidCallback  alSeleccionar30;
  final VoidCallback  alSeleccionar90;
  final VoidCallback  alSeleccionarAnio;
  final VoidCallback  alPersonalizado;

  @override
  Widget build(BuildContext context) {
    final dias = rango.end.difference(rango.start).inDays;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rango activo', style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 1.1, color: ColoresApp.textoTerciario,
          )),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color:        ColoresApp.acentoClaro,
              borderRadius: BorderRadius.circular(12),
              border:       Border.all(color: ColoresApp.acentoBorde),
            ),
            child: Row(children: [
              const Icon(Icons.calendar_today_outlined, color: ColoresApp.acento, size: 16),
              const SizedBox(width: 8),
              Text(
                '${rango.start.day}/${rango.start.month}/${rango.start.year}'
                '  →  '
                '${rango.end.day}/${rango.end.month}/${rango.end.year}',
                style: const TextStyle(
                  color: ColoresApp.acento, fontWeight: FontWeight.w600, fontSize: 13,
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          Text('Presets', style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 1.1, color: ColoresApp.textoTerciario,
          )),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              _ChipPreset(label: '7 días',   activo: dias <= 8,   alTap: alSeleccionar7),
              _ChipPreset(label: '30 días',  activo: dias > 8 && dias <= 31,  alTap: alSeleccionar30),
              _ChipPreset(label: '90 días',  activo: dias > 31 && dias <= 92, alTap: alSeleccionar90),
              _ChipPreset(label: 'Este año',
                activo: rango.start.month == 1 && rango.start.day == 1,
                alTap: alSeleccionarAnio),
              _ChipPreset(label: 'Personalizado',
                icono: Icons.edit_calendar_outlined, activo: false, alTap: alPersonalizado),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChipPreset extends StatelessWidget {
  const _ChipPreset({required this.label, required this.activo, required this.alTap, this.icono});
  final String     label;
  final bool       activo;
  final VoidCallback alTap;
  final IconData?  icono;

  @override
  Widget build(BuildContext context) {
    return Material(
      color:        activo ? ColoresApp.acento : ColoresApp.superficieSecund,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap:        alTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            border:       Border.all(color: activo ? ColoresApp.acento : ColoresApp.bordeMedio),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icono != null) ...[
                Icon(icono, size: 14,
                  color: activo ? ColoresApp.blanco : ColoresApp.textoSecundario),
                const SizedBox(width: 6),
              ],
              Text(label, style: TextStyle(
                fontSize:   13,
                fontWeight: FontWeight.w600,
                color:      activo ? ColoresApp.blanco : ColoresApp.textoSecundario,
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tab multi-selección ──────────────────────────────────────────────────────

class _TabMultiselect extends StatelessWidget {
  const _TabMultiselect({
    required this.opciones,
    required this.seleccionados,
    required this.onToggle,
    required this.etiquetaVacia,
  });

  final List<OpcionFiltro>     opciones;
  final List<OpcionFiltro>     seleccionados;
  final ValueChanged<OpcionFiltro> onToggle;
  final String                 etiquetaVacia;

  @override
  Widget build(BuildContext context) {
    if (opciones.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(etiquetaVacia, textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: ColoresApp.textoTerciario)),
        ),
      );
    }

    return ListView.separated(
      padding:          const EdgeInsets.fromLTRB(20, 12, 20, 0),
      itemCount:        opciones.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: ColoresApp.bordesuave),
      itemBuilder: (_, i) {
        final opcion = opciones[i];
        final activo = seleccionados.any((e) => e.id == opcion.id);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap:        () => onToggle(opcion),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
              child: Row(children: [
                Expanded(child: Text(opcion.nombre,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
                    color:      activo ? ColoresApp.acento : ColoresApp.textoPrimario,
                  ))),
                if (activo)
                  const Icon(Icons.check_circle_rounded, color: ColoresApp.acento, size: 22)
                else
                  const Icon(Icons.radio_button_unchecked_rounded, color: ColoresApp.bordeMedio, size: 22),
              ]),
            ),
          ),
        );
      },
    );
  }
}
