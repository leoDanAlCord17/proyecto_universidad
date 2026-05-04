import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../compartido/constantes.dart';
import '../../compartido/widgets/botones/boton_app.dart';
import '../../compartido/widgets/formularios/campo_texto_app.dart';
import '../../compartido/widgets/indicadores/barra_estadistica.dart';
import '../../compartido/widgets/tarjetas/tarjeta_app.dart';
import '../../compartido/widgets/tarjetas/tarjeta_asistente.dart';
import '../../configuracion/colores_app.dart';
import '../autenticacion/auth_cubit.dart';
import '../autenticacion/auth_estado.dart';
import '../eventos/evento.dart';
import 'panel_control_cubit.dart';
import 'panel_control_estado.dart';

class PanelControlPantalla extends StatefulWidget {
  const PanelControlPantalla({super.key, required this.eventoId});

  final String eventoId;

  @override
  State<PanelControlPantalla> createState() => _PanelControlPantallaState();
}

class _PanelControlPantallaState extends State<PanelControlPantalla> {
  bool _estaCargado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_estaCargado) return;
    _estaCargado = true;
    final authEstado = context.read<AuthCubit>().state;
    final adminId    = authEstado is Autenticado ? authEstado.usuario.id : null;
    context.read<PanelControlCubit>().cargar(widget.eventoId, adminId: adminId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PanelControlCubit, PanelControlEstado>(
      listener: _escucharEstado,
      builder:  _construirCuerpo,
    );
  }

  void _escucharEstado(BuildContext context, PanelControlEstado state) {
    if (state is PanelControlOperacionFallida) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.mensaje)),
      );
    } else if (state is PanelControlEventoCerrado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento cerrado exitosamente.')),
      );
      context.pop();
    }
  }

  Widget _construirCuerpo(BuildContext context, PanelControlEstado state) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor:          Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness:     Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: ColoresApp.fondo,
        body: Column(
          children: [
            Container(height: MediaQuery.paddingOf(context).top, color: ColoresApp.acento),
            Expanded(child: _construirContenido(state)),
          ],
        ),
      ),
    );
  }

  Widget _construirContenido(PanelControlEstado state) => switch (state) {
    PanelControlInicial()          => const SizedBox.shrink(),
    PanelControlCargando()         => const Center(
        child: CircularProgressIndicator(color: ColoresApp.acento),
      ),
    PanelControlCargado()          => _ContenidoCargado(estado: state),
    PanelControlOperacionFallida() => _ContenidoCargado(estado: state.anterior),
    PanelControlError()            => _VistaError(mensaje: state.mensaje),
    PanelControlEventoCerrado()    => const SizedBox.shrink(),
  };
}

// ─── Vista de error de carga ──────────────────────────────────────────────────

class _VistaError extends StatelessWidget {
  const _VistaError({required this.mensaje});
  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          mensaje,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: ColoresApp.rojo),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ─── Contenido principal cargado ─────────────────────────────────────────────

class _ContenidoCargado extends StatelessWidget {
  const _ContenidoCargado({required this.estado});
  final PanelControlCargado estado;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _EncabezadoEvento(estado: estado),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BotonCerrarEvento(
                  estaCerrando: estado.estaCerrando,
                  tituloEvento: estado.evento.titulo,
                ),
                const SizedBox(height: 16),
                _FilaEstadisticas(estado: estado),
                if (estado.tasaConvocatoria != null) ...[
                  const SizedBox(height: 14),
                  _SeccionTasas(estado: estado),
                ],
                const SizedBox(height: 24),
                _SeccionMarcarAsistencia(evento: estado.evento),
                const SizedBox(height: 24),
                _SeccionUsuarios(estado: estado),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Encabezado con degradado (fijo) ─────────────────────────────────────────

class _EncabezadoEvento extends StatelessWidget {
  const _EncabezadoEvento({required this.estado});
  final PanelControlCargado estado;

  @override
  Widget build(BuildContext context) {
    final evento = estado.evento;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: ColoresApp.degradadoPrincipal),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BotonRegresar(),
          const SizedBox(height: 14),
          Text(
            evento.titulo,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color:      Colors.white,
              fontSize:   22,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (evento.lugar != null) ...[
            const SizedBox(height: 4),
            Text(
              evento.lugar!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
          const SizedBox(height: 18),
          _ChipsInfoEvento(estado: estado),
        ],
      ),
    );
  }
}

class _BotonRegresar extends StatelessWidget {
  const _BotonRegresar();

  @override
  Widget build(BuildContext context) {
    return Material(
      color:        Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap:          () => context.pop(),
        borderRadius:   BorderRadius.circular(12),
        splashColor:    Colors.white.withValues(alpha: 0.3),
        highlightColor: Colors.white.withValues(alpha: 0.1),
        child: const Padding(
          padding: EdgeInsets.all(8),
          child:   Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size:  18,
          ),
        ),
      ),
    );
  }
}

// ─── Chips de información distribuidos en la fila ────────────────────────────

class _ChipsInfoEvento extends StatelessWidget {
  const _ChipsInfoEvento({required this.estado});
  final PanelControlCargado estado;

  String _formatearHora(String? hora) {
    if (hora == null) return '--:--';
    final p = hora.split(':');
    if (p.length < 2) return hora;
    final h24  = int.tryParse(p[0]) ?? 0;
    final min  = p[1].padLeft(2, '0');
    final h12  = h24 % 12 == 0 ? 12 : h24 % 12;
    final ampm = h24 < 12 ? 'AM' : 'PM';
    return '$h12:$min $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final e = estado.evento;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ChipInfo(etiqueta: 'INICIO',    valor: _formatearHora(e.horaInicio)),
        _ChipInfo(etiqueta: 'CIERRE',    valor: _formatearHora(e.horaFin)),
        _ChipInfo(
          etiqueta: 'PRESENTES',
          valor: estado.esEventoDirigido
              ? '${estado.presentesEsperados}/${estado.totalAudiencia}'
              : '${estado.totalPresentes}',
        ),
        _ChipInfo(etiqueta: 'MODOS', valor: '${estado.cantidadModos}'),
      ],
    );
  }
}

class _ChipInfo extends StatelessWidget {
  const _ChipInfo({required this.etiqueta, required this.valor});
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color:         Colors.white60,
            fontSize:      12,
            fontWeight:   FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          valor,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color:      Colors.white,
            fontSize:   19,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

// ─── Botón cerrar evento ──────────────────────────────────────────────────────

class _BotonCerrarEvento extends StatelessWidget {
  const _BotonCerrarEvento({
    required this.estaCerrando,
    required this.tituloEvento,
  });

  final bool   estaCerrando;
  final String tituloEvento;

  @override
  Widget build(BuildContext context) {
    return BotonApp(
      variante:     VarianteBoton.rojo,
      texto:        'CERRAR EVENTO',
      estaCargando: estaCerrando,
      alPresionar:  estaCerrando
          ? null
          : () => _DialogoCerrarEvento.mostrar(
                context,
                tituloEvento: tituloEvento,
                alConfirmar:  context.read<PanelControlCubit>().cerrarEvento,
              ),
    );
  }
}

// ─── Estadísticas ─────────────────────────────────────────────────────────────

class _FilaEstadisticas extends StatelessWidget {
  const _FilaEstadisticas({required this.estado});
  final PanelControlCargado estado;

  @override
  Widget build(BuildContext context) {
    return estado.esEventoDirigido
        ? _EstadisticasDirigido(estado: estado)
        : _EstadisticasGeneral(estado: estado);
  }
}

class _EstadisticasDirigido extends StatelessWidget {
  const _EstadisticasDirigido({required this.estado});
  final PanelControlCargado estado;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _TarjetaEstadistica(valor: estado.presentesEsperados, etiqueta: 'Llegaron',   color: ColoresApp.verde)),
            const SizedBox(width: 10),
            Expanded(child: _TarjetaEstadistica(valor: estado.pendientes,         etiqueta: 'Pendientes', color: ColoresApp.ambar)),
            const SizedBox(width: 10),
            Expanded(child: _TarjetaEstadistica(valor: estado.ausentes,           etiqueta: 'Ausentes',   color: ColoresApp.rojo)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _TarjetaEstadistica(valor: estado.presentesNoEsperados, etiqueta: 'No esperados', color: ColoresApp.teal)),
            const SizedBox(width: 10),
            Expanded(child: _TarjetaEstadistica(valor: estado.presentesForaneos,    etiqueta: 'Foráneos',     color: ColoresApp.teal)),
            const SizedBox(width: 10),
            Expanded(child: _TarjetaEstadistica(valor: estado.totalPresentes,       etiqueta: 'Total en sala', color: ColoresApp.textoPrimario)),
          ],
        ),
      ],
    );
  }
}

class _EstadisticasGeneral extends StatelessWidget {
  const _EstadisticasGeneral({required this.estado});
  final PanelControlCargado estado;

  @override
  Widget build(BuildContext context) {
    final delSistema = estado.totalPresentes - estado.presentesForaneos;
    return Row(
      children: [
        Expanded(child: _TarjetaEstadistica(valor: delSistema,              etiqueta: 'Del sistema', color: ColoresApp.verde)),
        const SizedBox(width: 10),
        Expanded(child: _TarjetaEstadistica(valor: estado.presentesForaneos, etiqueta: 'Foráneos',   color: ColoresApp.teal)),
        const SizedBox(width: 10),
        Expanded(child: _TarjetaEstadistica(valor: estado.totalPresentes,    etiqueta: 'Total',      color: ColoresApp.textoPrimario)),
      ],
    );
  }
}

// ─── Gráficas de tasas (solo eventos dirigidos) ───────────────────────────────

class _SeccionTasas extends StatelessWidget {
  const _SeccionTasas({required this.estado});
  final PanelControlCargado estado;

  @override
  Widget build(BuildContext context) {
    final convocatoria = estado.tasaConvocatoria!;
    final ocupacion    = estado.tasaOcupacion!;
    return TarjetaApp(
      variante: VarianteTarjeta.normal,
      child: Column(
        children: [
          BarraEstadistica(
            etiqueta:   'Tasa convocatoria',
            porcentaje: convocatoria,
          ),
          const SizedBox(height: 16),
          BarraEstadistica(
            etiqueta:        'Tasa ocupación',
            porcentaje:      ocupacion,
            colorBarra:      ColoresApp.acento,
            colorPorcentaje: ColoresApp.acento,
          ),
        ],
      ),
    );
  }
}

class _TarjetaEstadistica extends StatelessWidget {
  const _TarjetaEstadistica({
    required this.valor,
    required this.etiqueta,
    required this.color,
  });

  final int    valor;
  final String etiqueta;
  final Color  color;

  @override
  Widget build(BuildContext context) {
    return TarjetaApp(
      variante: VarianteTarjeta.normal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$valor',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color:      color,
              fontSize:   28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            etiqueta,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize:   13,
              fontWeight: FontWeight.w600,
            ),
          ), 
        ],
      ),
    );
  }
}

// ─── Sección Marcar Asistencia ────────────────────────────────────────────────

class _SeccionMarcarAsistencia extends StatelessWidget {
  const _SeccionMarcarAsistencia({required this.evento});
  final Evento evento;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _EncabezadoSeccion(titulo: 'MARCAR ASISTENCIA'),
        const SizedBox(height: 12),
        _BotonesAccion(evento: evento),
      ],
    );
  }
}

class _BotonesAccion extends StatelessWidget {
  const _BotonesAccion({required this.evento});
  final Evento evento;

  @override
  Widget build(BuildContext context) {
    final botones = <_BotonAccion>[
      if (evento.permiteQrEvento)
        _BotonAccion(
          icono:       Icons.qr_code_scanner_rounded,
          etiqueta:    'QR\nEvento',
          alPresionar: () => _ModalQrEvento.mostrar(context, evento: evento),
        ),
      if (evento.permiteQrUsuario)
        _BotonAccion(
          icono:       Icons.qr_code_rounded,
          etiqueta:    'QR\nUsuario',
          alPresionar: () async {
            await context.push(Rutas.escanearQrUsuarioUrl(evento.id));
            if (context.mounted) {
              context.read<PanelControlCubit>().recargarSilencioso();
            }
          },
        ),
      if (evento.permiteManualAdmin)
        _BotonAccion(
          icono:       Icons.person_search_rounded,
          etiqueta:    'Buscar\nusuario',
          alPresionar: () async {
            await context.push(Rutas.buscarAsistenteUrl(evento.id));
            if (context.mounted) {
              context.read<PanelControlCubit>().recargarSilencioso();
            }
          },
        ),
      if (evento.permiteForaneos)
        _BotonAccion(
          icono:       Icons.person_add_rounded,
          etiqueta:    'Foráneo',
          alPresionar: () => _ModalForaneo.mostrar(context, eventoId: evento.id),
        ),
    ];

    if (botones.isEmpty) return const SizedBox.shrink();

    final items = <Widget>[];
    for (int i = 0; i < botones.length; i++) {
      items.add(Expanded(child: botones[i]));
      if (i < botones.length - 1) items.add(const SizedBox(width: 8));
    }
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: items),
    );
  }
}

class _BotonAccion extends StatelessWidget {
  const _BotonAccion({
    required this.icono,
    required this.etiqueta,
    this.alPresionar,
  });
  final IconData      icono;
  final String        etiqueta;
  final VoidCallback? alPresionar;

  @override
  Widget build(BuildContext context) {
    const radio = BorderRadius.all(Radius.circular(18));
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: radio,
        boxShadow: [
          BoxShadow(
            color:      ColoresApp.sombraTarjeta,
            blurRadius: 4,
            offset:     Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color:        Colors.white,
        borderRadius: radio,
        child: InkWell(
          onTap:           alPresionar,
          borderRadius:    radio,
          splashColor:     ColoresApp.acentoClaro,
          highlightColor:  ColoresApp.acentoClaro.withValues(alpha: 0.6),
          child: Ink(
            decoration: const BoxDecoration(
              color:        Colors.white,
              borderRadius: radio,
              border:       Border.fromBorderSide(
                BorderSide(color: ColoresApp.bordesuave),
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize:      MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icono, size: 26, color: ColoresApp.acento),
                const SizedBox(height: 6),
                Text(
                  etiqueta,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize:   11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Sección Usuarios ─────────────────────────────────────────────────────────

class _SeccionUsuarios extends StatelessWidget {
  const _SeccionUsuarios({required this.estado});
  final PanelControlCargado estado;

  @override
  Widget build(BuildContext context) {
    final filtrados = estado.asistentesFiltrados;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _EncabezadoSeccion(titulo: 'USUARIOS REGISTRADOS'),
        const SizedBox(height: 12),
        _FiltrosTabs(
          estado:    estado,
          onFiltrar: context.read<PanelControlCubit>().cambiarFiltro,
        ),
        const SizedBox(height: 12),
        if (filtrados.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'Sin registros para este filtro.',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          )
        else
          ...filtrados.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TarjetaAsistente(
                iniciales:      a.iniciales,
                nombre:         a.nombre,
                estatus:        a.estatus,
                detalle:        a.etiquetaDetalle,
                urlFoto:        a.urlFoto,
                accionTrailing: a.estatus == EstatusAsistencia.esperado
                    ? _BotonRegistrar(eventoId: estado.evento.id)
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Botón Registrar (inline en TarjetaAsistente) ────────────────────────────

class _BotonRegistrar extends StatelessWidget {
  const _BotonRegistrar({required this.eventoId});
  final String eventoId;

  @override
  Widget build(BuildContext context) {
    return Material(
      color:        Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap:        () => context.push(Rutas.buscarAsistenteUrl(eventoId)),
        borderRadius: BorderRadius.circular(20),
        splashColor:  Colors.white.withValues(alpha: 0.3),
        child: Ink(
          decoration: BoxDecoration(
            gradient:     ColoresApp.degradadoPrincipal,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Text(
            'Registrar',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color:      Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Filtros en pills ─────────────────────────────────────────────────────────

class _FiltrosTabs extends StatelessWidget {
  const _FiltrosTabs({
    required this.estado,
    required this.onFiltrar,
  });

  final PanelControlCargado             estado;
  final void Function(FiltroAsistentes) onFiltrar;

  static const _etiquetas = {
    FiltroAsistentes.todos:        'Todos',
    FiltroAsistentes.esperados:    'Esperados',
    FiltroAsistentes.noEsperados:  'No esperados',
    FiltroAsistentes.registrados:  'Llegaron',
    FiltroAsistentes.abandono:     'Abandono',
    FiltroAsistentes.foraneos:     'Foráneos',
  };

  List<FiltroAsistentes> _filtrosVisibles() {
    if (!estado.esEventoDirigido) {
      return FiltroAsistentes.values
          .where((f) =>
              f != FiltroAsistentes.esperados &&
              f != FiltroAsistentes.noEsperados)
          .toList();
    }
    return FiltroAsistentes.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filtrosVisibles().map((filtro) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _ChipFiltro(
              etiqueta: _etiquetas[filtro]!,
              activo:   filtro == estado.filtroActivo,
              onTap:    () => onFiltrar(filtro),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ChipFiltro extends StatelessWidget {
  const _ChipFiltro({
    required this.etiqueta,
    required this.activo,
    required this.onTap,
  });

  final String       etiqueta;
  final bool         activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color:        Colors.transparent,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(30),
        child: activo
            ? Ink(
                decoration: BoxDecoration(
                  gradient:     ColoresApp.degradadoPrincipal,
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                child: Text(
                  etiqueta,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color:      Colors.white,
                    fontSize:   13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  border:       Border.all(color: ColoresApp.bordeMedio),
                  borderRadius: BorderRadius.circular(30),
                  color:        ColoresApp.superficiePrimaria,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                child: Text(
                  etiqueta,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color:      ColoresApp.textoSecundario,
                    fontSize:   13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
      ),
    );
  }
}

// ─── Encabezado de sección ────────────────────────────────────────────────────

class _EncabezadoSeccion extends StatelessWidget {
  const _EncabezadoSeccion({required this.titulo});
  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Text(
      titulo,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color:         ColoresApp.textoSecundario,
        fontWeight:    FontWeight.w800,
        fontSize: 12,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ─── Modal QR del evento ──────────────────────────────────────────────────────

class _ModalQrEvento extends StatefulWidget {
  const _ModalQrEvento({required this.evento});

  final Evento evento;

  static void mostrar(BuildContext context, {required Evento evento}) {
    showDialog<void>(
      context:      context,
      barrierColor: ColoresApp.sombraBarrera,
      builder:      (_) => _ModalQrEvento(evento: evento),
    );
  }

  @override
  State<_ModalQrEvento> createState() => _ModalQrEventoState();
}

class _ModalQrEventoState extends State<_ModalQrEvento> {
  Timer?   _timer;
  Duration _restante = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calcularRestante();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(_calcularRestante),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calcularRestante() {
    final objetivo = _objetivo();
    if (objetivo == null) { _restante = Duration.zero; return; }
    final diff = objetivo.difference(DateTime.now());
    _restante = diff.isNegative ? Duration.zero : diff;
  }

  DateTime? _objetivo() {
    final horaFin = widget.evento.horaFin;
    if (horaFin == null) return null;
    final p = horaFin.split(':');
    if (p.length < 2) return null;
    final h = int.tryParse(p[0]) ?? 0;
    final m = int.tryParse(p[1]) ?? 0;
    final s = p.length >= 3 ? (int.tryParse(p[2]) ?? 0) : 0;
    final base = widget.evento.fechaFin ?? widget.evento.fechaInicio ?? DateTime.now();
    return DateTime(base.year, base.month, base.day, h, m, s);
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  String get _tiempoTexto {
    final h = _restante.inHours;
    final m = _restante.inMinutes.remainder(60);
    final s = _restante.inSeconds.remainder(60);
    return '${_pad(h)}:${_pad(m)}:${_pad(s)}';
  }

  String get _horaCierreTexto {
    final horaFin = widget.evento.horaFin;
    if (horaFin == null) return '--:--';
    final p = horaFin.split(':');
    if (p.length < 2) return horaFin;
    final h  = int.tryParse(p[0]) ?? 0;
    final m  = p[1];
    final periodo = h < 12 ? 'AM' : 'PM';
    final h12     = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:$m $periodo';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding:    const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(24),
          border:       Border.all(color: const Color(0x261A9462), width: 1.5),
          boxShadow: const [
            BoxShadow(color: ColoresApp.sombraGeneral, blurRadius: 28, offset: Offset(0, 8)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SeccionVerdeQr(tiempoTexto: _tiempoTexto, horaCierreTexto: _horaCierreTexto),
            _SeccionBlancoQr(eventoId: widget.evento.id),
          ],
        ),
      ),
    );
  }
}

// ─── Sección verde del modal QR ───────────────────────────────────────────────

class _SeccionVerdeQr extends StatelessWidget {
  const _SeccionVerdeQr({required this.tiempoTexto, required this.horaCierreTexto});
  final String tiempoTexto;
  final String horaCierreTexto;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Container(
      decoration: const BoxDecoration(
        color:        ColoresApp.verdeClaro,
        borderRadius: BorderRadius.only(
          topLeft:  Radius.circular(22),
          topRight: Radius.circular(22),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _LadoIzqVerde(texto: texto, tiempoTexto: tiempoTexto)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Cierre', style: texto.labelSmall?.copyWith(color: ColoresApp.textoSecundario, fontSize: 11)),
              const SizedBox(height: 3),
              Text(horaCierreTexto, style: texto.titleMedium?.copyWith(color: ColoresApp.textoPrimario, fontWeight: FontWeight.w800, fontSize: 17)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LadoIzqVerde extends StatelessWidget {
  const _LadoIzqVerde({required this.texto, required this.tiempoTexto});
  final TextTheme texto;
  final String    tiempoTexto;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10, height: 10,
              decoration: const BoxDecoration(color: ColoresApp.verde, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
            Text('TIEMPO RESTANTE', style: texto.labelSmall?.copyWith(
              color: ColoresApp.textoPrimario, fontWeight: FontWeight.w800,
              letterSpacing: 0.8, fontSize: 11,
            )),
          ],
        ),
        const SizedBox(height: 5),
        Text(tiempoTexto, style: texto.displaySmall?.copyWith(
          color: ColoresApp.verde, fontWeight: FontWeight.w800,
          fontSize: 38, letterSpacing: 1.5, height: 1.0,
        )),
      ],
    );
  }
}

// ─── Sección blanca del modal QR ──────────────────────────────────────────────

class _SeccionBlancoQr extends StatelessWidget {
  const _SeccionBlancoQr({required this.eventoId});
  final String eventoId;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:        Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x1A1A9462), width: 1),
              boxShadow: const [BoxShadow(color: ColoresApp.sombraTarjeta, blurRadius: 10, offset: Offset(0, 3))],
            ),
            child: QrImageView(
              data:            eventoId,
              version:         QrVersions.auto,
              size:            190,
              eyeStyle:        const QrEyeStyle(eyeShape: QrEyeShape.square, color: ColoresApp.acento),
              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: ColoresApp.acento),
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: texto.bodySmall?.copyWith(color: ColoresApp.textoSecundario, height: 1.5),
              children: const [
                TextSpan(text: 'Los asistentes escanean este '),
                TextSpan(text: 'código', style: TextStyle(color: ColoresApp.acento, fontWeight: FontWeight.w700)),
                TextSpan(text: ' para\nregistrarse'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Modal registrar foráneo ──────────────────────────────────────────────────

class _ModalForaneo extends StatefulWidget {
  const _ModalForaneo({required this.eventoId});

  final String eventoId;

  static void mostrar(BuildContext context, {required String eventoId}) {
    final cubit = context.read<PanelControlCubit>();
    showDialog<void>(
      context:      context,
      barrierColor: ColoresApp.sombraBarrera,
      builder:      (_) => BlocProvider.value(
        value: cubit,
        child: _ModalForaneo(eventoId: eventoId),
      ),
    );
  }

  @override
  State<_ModalForaneo> createState() => _ModalForaneoState();
}

class _ModalForaneoState extends State<_ModalForaneo> {
  final _nombreCtrl   = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _cedulaCtrl   = TextEditingController();
  final _contactoCtrl = TextEditingController();
  bool _estaEnviado = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _cedulaCtrl.dispose();
    _contactoCtrl.dispose();
    super.dispose();
  }

  void _registrar(BuildContext ctx) {
    final nombre   = _nombreCtrl.text.trim();
    final apellido = _apellidoCtrl.text.trim();
    final cedula   = _cedulaCtrl.text.trim();
    if (nombre.isEmpty || apellido.isEmpty || cedula.isEmpty) return;
    setState(() => _estaEnviado = true);
    ctx.read<PanelControlCubit>().registrarForaneo(
      primerNombre:   nombre,
      primerApellido: apellido,
      cedula:         cedula,
      contacto:       _contactoCtrl.text.trim().isNotEmpty
                          ? _contactoCtrl.text.trim()
                          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PanelControlCubit, PanelControlEstado>(
      listener: (ctx, state) {
        if (!_estaEnviado) return;
        if (state is PanelControlCargado && !state.estaRegistrando) Navigator.of(ctx).pop();
        if (state is PanelControlOperacionFallida) setState(() => _estaEnviado = false);
      },
      builder: (ctx, state) {
        final guardando = _estaEnviado && state is PanelControlCargado && state.estaRegistrando;
        return _CuerpoModalForaneo(
          guardando:    guardando,
          nombreCtrl:   _nombreCtrl,
          apellidoCtrl: _apellidoCtrl,
          cedulaCtrl:   _cedulaCtrl,
          contactoCtrl: _contactoCtrl,
          onRegistrar:  () => _registrar(ctx),
        );
      },
    );
  }
}

// ─── Widgets del modal foráneo ────────────────────────────────────────────────

class _CuerpoModalForaneo extends StatelessWidget {
  const _CuerpoModalForaneo({
    required this.guardando,
    required this.nombreCtrl,
    required this.apellidoCtrl,
    required this.cedulaCtrl,
    required this.contactoCtrl,
    required this.onRegistrar,
  });

  final bool                  guardando;
  final TextEditingController nombreCtrl;
  final TextEditingController apellidoCtrl;
  final TextEditingController cedulaCtrl;
  final TextEditingController contactoCtrl;
  final VoidCallback          onRegistrar;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding:    const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: ColoresApp.sombraGeneral, blurRadius: 24, offset: Offset(0, 8)),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          mainAxisSize:       MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _EncabezadoForaneo(),
            const SizedBox(height: 16),
            _FilaNombreApellidoForaneo(nombreCtrl: nombreCtrl, apellidoCtrl: apellidoCtrl),
            const SizedBox(height: 12),
            TextFormField(controller: cedulaCtrl, decoration: const InputDecoration(hintText: 'Cédula o pasaporte *')),
            const SizedBox(height: 12),
            TextFormField(controller: contactoCtrl, decoration: const InputDecoration(hintText: 'Contacto (opcional)'), keyboardType: TextInputType.phone),
            const SizedBox(height: 20),
            _BotonRegistrarForaneo(guardando: guardando, onTap: onRegistrar),
          ],
        ),
      ),
    );
  }
}

class _EncabezadoForaneo extends StatelessWidget {
  const _EncabezadoForaneo();

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'REGISTRAR INVITADO FORÁNEO',
          style: texto.labelSmall?.copyWith(
            color: ColoresApp.textoSecundario, fontWeight: FontWeight.w800,
            letterSpacing: 0.8, fontSize: 11,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: ColoresApp.superficieTerciar, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.person_outline_rounded, size: 22, color: ColoresApp.textoSecundario),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Persona sin cuenta en el\nsistema',
                style: texto.titleSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ],
        ),
      ],
    );
  }
}

class _FilaNombreApellidoForaneo extends StatelessWidget {
  const _FilaNombreApellidoForaneo({required this.nombreCtrl, required this.apellidoCtrl});
  final TextEditingController nombreCtrl;
  final TextEditingController apellidoCtrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: TextFormField(controller: nombreCtrl, decoration: const InputDecoration(hintText: 'Primer nombre'), textCapitalization: TextCapitalization.words)),
        const SizedBox(width: 10),
        Expanded(child: TextFormField(controller: apellidoCtrl, decoration: const InputDecoration(hintText: 'Primer apellido'), textCapitalization: TextCapitalization.words)),
      ],
    );
  }
}

class _BotonRegistrarForaneo extends StatelessWidget {
  const _BotonRegistrarForaneo({required this.guardando, required this.onTap});
  final bool         guardando;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color:        ColoresApp.textoPrimario,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap:        guardando ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor:  Colors.white.withValues(alpha: 0.15),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: guardando
                ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Registrar como invitado y\nmarcar entrada',
                          style: texto.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14, height: 1.3),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Diálogo confirmación cierre de evento ────────────────────────────────────

class _DialogoCerrarEvento extends StatefulWidget {
  const _DialogoCerrarEvento({
    required this.tituloEvento,
    required this.alConfirmar,
  });

  final String       tituloEvento;
  final VoidCallback alConfirmar;

  static void mostrar(
    BuildContext context, {
    required String       tituloEvento,
    required VoidCallback alConfirmar,
  }) {
    showDialog<void>(
      context: context,
      builder: (_) => _DialogoCerrarEvento(
        tituloEvento: tituloEvento,
        alConfirmar:  alConfirmar,
      ),
    );
  }

  @override
  State<_DialogoCerrarEvento> createState() => _DialogoCerrarEventoState();
}

class _DialogoCerrarEventoState extends State<_DialogoCerrarEvento> {
  final _controlador = TextEditingController();
  bool  _coincidenNombres    = false;

  @override
  void initState() {
    super.initState();
    _controlador.addListener(_actualizarCoincidencia);
  }

  void _actualizarCoincidencia() {
    final coincide = _controlador.text.trim() == widget.tituloEvento.trim();
    if (coincide != _coincidenNombres) setState(() => _coincidenNombres = coincide);
  }

  @override
  void dispose() {
    _controlador.removeListener(_actualizarCoincidencia);
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding:    const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        decoration: BoxDecoration(
          color:        ColoresApp.superficiePrimaria,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color:      ColoresApp.sombraGeneral,
              blurRadius: 24,
              offset:     Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize:       MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cerrar evento',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 10),
            RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(fontSize: 14, height: 1.5),
                children: [
                  const TextSpan(text: 'Escribe el nombre '),
                  TextSpan(
                    text:  widget.tituloEvento,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize:   14,
                      fontWeight: FontWeight.w700,
                      color:      ColoresApp.textoPrimario,
                    ),
                  ),
                  const TextSpan(text: ' para confirmar el cierre.'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CampoTextoApp(
              etiqueta:   'Nombre del evento',
              hintText:   widget.tituloEvento,
              controller: _controlador,
            ),
            const SizedBox(height: 20),
            BotonApp(
              variante:    VarianteBoton.rojo,
              texto:       'Confirmar cierre',
              alPresionar: _coincidenNombres
                  ? () {
                      Navigator.of(context).pop();
                      widget.alConfirmar();
                    }
                  : null,
            ),
            const SizedBox(height: 10),
            BotonApp(
              variante:    VarianteBoton.ghost,
              texto:       'Cancelar',
              alPresionar: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
