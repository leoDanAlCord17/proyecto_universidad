import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../configuracion/colores_app.dart';
import 'estadisticas_cubit.dart';
import 'estadisticas_estado.dart';
import 'estadisticas_modelo.dart';
import 'filtros_estadisticas.dart';
import 'vistas/cuerpo_estadisticas.dart';
import 'vistas/barra_titulo.dart';
import 'vistas/estilos_estadisticas.dart';
import 'vistas/modal_detalle.dart';
import 'vistas/panel_filtros.dart';

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
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: ColoresApp.sombraBarrera,
      builder: (_) => PanelFiltros(
        filtrosActuales: _filtros,
        opciones: opciones,
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
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: ColoresApp.sombraBarrera,
      builder: (_) => BlocProvider.value(
        value: context.read<EstadisticasCubit>(),
        child: ModalDetalle(
          titulo: dato.etiqueta,
          dimension: dimension,
          valor: dato.valorSql ?? dato.etiqueta,
          filtros: _filtros,
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
      tiposSeleccionados:
          _filtros.tiposSeleccionados.where((o) => o.id != opcion.id).toList(),
    );
    setState(() => _filtros = nuevos);
    context.read<EstadisticasCubit>().cargar(nuevos);
  }

  void _quitarFiltroCreador(OpcionFiltro opcion) {
    final nuevos = _filtros.copyWith(
      creadoresSeleccionados: _filtros.creadoresSeleccionados
          .where((o) => o.id != opcion.id)
          .toList(),
    );
    setState(() => _filtros = nuevos);
    context.read<EstadisticasCubit>().cargar(nuevos);
  }

  void _quitarFiltroTag(OpcionFiltro opcion) {
    final nuevos = _filtros.copyWith(
      tagsSeleccionados:
          _filtros.tagsSeleccionados.where((o) => o.id != opcion.id).toList(),
    );
    setState(() => _filtros = nuevos);
    context.read<EstadisticasCubit>().cargar(nuevos);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EstadisticasCubit, EstadisticasEstado>(
      builder: (context, estado) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: ColoresApp.fondo,
          body: Column(
            children: [
              SafeArea(
                bottom: false,
                child: BarraTitulo(
                  filtros: _filtros,
                  alFiltrar: () => _abrirFiltros(
                    estado is EstadisticasCargadas
                        ? estado.opciones
                        : OpcionesFiltros.vacio(),
                  ),
                  alLimpiar: _limpiarFiltros,
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
        EstadisticasCargadas() => CuerpoEstadisticas(
            datos: estado,
            onDetalle: _abrirDetalle,
            onQuitarTipo: _quitarFiltroTipo,
            onQuitarCreador: _quitarFiltroCreador,
            onQuitarTag: _quitarFiltroTag,
          ),
        final EstadisticasError e => VistaError(
            mensaje: e.mensaje,
            alReintentar: () =>
                context.read<EstadisticasCubit>().cargar(_filtros),
          ),
      };
}
