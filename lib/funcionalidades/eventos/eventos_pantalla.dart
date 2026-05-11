import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../compartido/constantes.dart';
import '../../compartido/widgets/botones/boton_contorno_icono.dart';
import '../../compartido/widgets/formularios/barra_busqueda_app.dart';
import '../../compartido/widgets/navegacion/barra_navegacion_app.dart';
import '../../compartido/widgets/navegacion/barra_superior_app.dart';
import '../../compartido/widgets/tarjetas/tarjeta_evento.dart';
import '../../compartido/widgets/utilidades/protector_por_permiso.dart';
import '../../configuracion/colores_app.dart';
import '../autenticacion/auth_cubit.dart';
import '../autenticacion/auth_estado.dart';
import '../autenticacion/usuario.dart';
import 'evento.dart';
import 'eventos_cubit.dart';
import 'eventos_estado.dart';

class EventosPantalla extends StatefulWidget {
  const EventosPantalla({super.key});

  @override
  State<EventosPantalla> createState() => _EventosPantallaState();
}

class _EventosPantallaState extends State<EventosPantalla>
    with WidgetsBindingObserver {
  final _busquedaCtrl = TextEditingController();
  bool  _cargado      = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_cargado) return;
    _cargado = true;
    _cargar();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _cargar();
  }

  void _cargar() {
    final authEstado = context.read<AuthCubit>().state;
    if (authEstado is Autenticado && authEstado.usuario.id != null) {
      context.read<EventosCubit>().cargar(authEstado.usuario.id!);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _busquedaCtrl.dispose();
    super.dispose();
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
        body: Column(
          children: [
            SafeArea(
              bottom: false,
              child: BarraSuperiorApp(
                izquierda: const _CabeceraTitulo(),
                derecha: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ProtectorPorPermiso(
                      permisoRequerido: Permisos.eventosCrearEventos,
                      hijo: BotonContornoIcono(
                        icono:       Icons.description_outlined,
                        alPresionar: () => context.push(Rutas.borradores),
                      ),
                    ),
                    const SizedBox(width: 18),
                    const ProtectorPorPermiso(
                      permisoRequerido: Permisos.eventosCrearEventos,
                      hijo: _BotonCrearEvento(),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: BlocSelector<EventosCubit, EventosEstado, DateTimeRange?>(
                selector: (estado) =>
                    estado is EventosCargado ? estado.rangoFechas : null,
                builder: (context, rango) => BarraBusquedaApp(
                  controlador:        _busquedaCtrl,
                  hintText:           'Buscar eventos...',
                  alCambiar:          (texto) =>
                      context.read<EventosCubit>().filtrar(texto, rango),
                  alSeleccionarRango: (r) =>
                      context.read<EventosCubit>().filtrar(_busquedaCtrl.text, r),
                  alLimpiarRango:     () =>
                      context.read<EventosCubit>().filtrar(_busquedaCtrl.text, null),
                  rangoSeleccionado:  rango,
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<EventosCubit, EventosEstado>(
                builder: (context, estado) => switch (estado) {
                  EventosInicial()  => const SizedBox.shrink(),
                  EventosCargando() => const Center(
                    child: CircularProgressIndicator(color: ColoresApp.acento),
                  ),
                  EventosError()    => _VistaError(
                    mensaje:      estado.mensaje,
                    onReintentar: _cargar,
                  ),
                  EventosCargado()  => _VistaContenido(
                    enCurso:  estado.enCurso,
                    proximos: estado.proximos,
                  ),
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: BarraNavegacionApp(
          indiceActual:    1,
          alCambiarIndice: (indice) {
            if (indice == 0) context.go(Rutas.home);
            if (indice == 3) context.push(Rutas.historial);
            if (indice == 4) context.go(Rutas.perfil);
          },
        ),
      ),
    );
  }
}

// ─── Cabecera izquierda ───────────────────────────────────────────────────────

class _CabeceraTitulo extends StatelessWidget {
  const _CabeceraTitulo();

  String _obtenerFecha() {
    final ahora = DateTime.now();
    const dias  = ['Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','Domingo'];
    const meses = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
    return '${dias[ahora.weekday - 1]}, ${ahora.day} ${meses[ahora.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment:  MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mis eventos',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontSize:   20,
            fontWeight: FontWeight.w700,
            color:      ColoresApp.textoPrimario,
          ),
        ),
        Text(
          _obtenerFecha(),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: ColoresApp.textoSecundario,
          ),
        ),
      ],
    );
  }
}

// ─── Botón crear evento ───────────────────────────────────────────────────────

class _BotonCrearEvento extends StatelessWidget {
  const _BotonCrearEvento();

  @override
  Widget build(BuildContext context) {
    return Material(
      color:        Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () async {
          await context.push(Rutas.crearEvento);
          if (!context.mounted) return;
          final authEstado = context.read<AuthCubit>().state;
          if (authEstado is Autenticado && authEstado.usuario.id != null) {
            context.read<EventosCubit>().cargar(authEstado.usuario.id!);
          }
        },
        borderRadius:   BorderRadius.circular(12),
        splashColor:    Colors.white.withValues(alpha: 0.3),
        highlightColor: Colors.white.withValues(alpha: 0.15),
        child: Ink(
          width:  40,
          height: 40,
          decoration: BoxDecoration(
            gradient:     ColoresApp.degradadoPrincipal,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

// ─── Vista contenido ─────────────────────────────────────────────────────────

class _VistaContenido extends StatelessWidget {
  const _VistaContenido({required this.enCurso, required this.proximos});

  final List<EventoConGrupos> enCurso;
  final List<EventoConGrupos> proximos;

  static const _meses = [
    'ene','feb','mar','abr','may','jun',
    'jul','ago','sep','oct','nov','dic',
  ];

  static String _a12h(String hora) {
    final partes = hora.split(':');
    if (partes.length < 2) return hora;
    final h      = int.tryParse(partes[0]) ?? 0;
    final m      = partes[1];
    final periodo = h < 12 ? 'AM' : 'PM';
    final h12    = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:$m $periodo';
  }

  String? _horario(Evento ev, {bool mostrarFecha = false}) {
    String? hora;
    if (ev.horaInicio != null) {
      final inicio = _a12h(ev.horaInicio!);
      final fin    = ev.horaFin != null ? ' – ${_a12h(ev.horaFin!)}' : '';
      hora = '$inicio$fin';
    }
    if (!mostrarFecha || ev.fechaInicio == null) return hora;
    final d     = ev.fechaInicio!;
    final fecha = '${d.day} ${_meses[d.month - 1]}';
    return hora != null ? '$fecha · $hora' : fecha;
  }

  @override
  Widget build(BuildContext context) {
    if (enCurso.isEmpty && proximos.isEmpty) return const _VistaVacia();

    final usuario = context.select<AuthCubit, Usuario?>(
      (c) => c.state is Autenticado ? (c.state as Autenticado).usuario : null,
    );
    final tienePanel = usuario?.tienePermiso(Permisos.eventosPanelControl) ?? false;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (enCurso.isNotEmpty) ...[
          const _SeccionEncabezado(titulo: 'AHORA · EN CURSO', vivo: true),
          const SizedBox(height: 10),
          for (final e in enCurso)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TarjetaEvento(
                titulo:       e.evento.titulo,
                estatus:      e.evento.estatus,
                horario:      _horario(e.evento),
                lugar:        e.evento.lugar,
                descripcion:  e.evento.descripcion,
                colorTitulo:  ColoresApp.textoPrimario,
                alAbrirPanel: tienePanel
                    ? () => context.push(Rutas.panelControlUrl(e.evento.id))
                    : null,
              ),
            ),
          const SizedBox(height: 8),
        ],
        if (proximos.isNotEmpty) ...[
          const _SeccionEncabezado(titulo: 'PRÓXIMOS EVENTOS'),
          const SizedBox(height: 10),
          for (final e in proximos)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TarjetaEvento(
                titulo:  e.evento.titulo,
                estatus: e.evento.estatus,
                horario: _horario(e.evento, mostrarFecha: true),
                lugar:   e.evento.lugar,
              ),
            ),
        ],
      ],
    );
  }
}

// ─── Encabezado de sección ────────────────────────────────────────────────────

class _SeccionEncabezado extends StatelessWidget {
  const _SeccionEncabezado({required this.titulo, this.vivo = false});

  final String titulo;
  final bool   vivo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (vivo) ...[
          Container(
            width:  8,
            height: 8,
            decoration: const BoxDecoration(
              color: ColoresApp.verde,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          titulo,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color:         vivo ? ColoresApp.verde : ColoresApp.textoSecundario,
            fontWeight:    FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

// ─── Vista vacía ──────────────────────────────────────────────────────────────

class _VistaVacia extends StatelessWidget {
  const _VistaVacia();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.event_busy_rounded,
              size:  56,
              color: ColoresApp.textoTerciario,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin eventos por ahora',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: ColoresApp.textoSecundario,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Los eventos programados o en curso aparecerán aquí.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ColoresApp.textoTerciario,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Vista error ──────────────────────────────────────────────────────────────

class _VistaError extends StatelessWidget {
  const _VistaError({required this.mensaje, required this.onReintentar});

  final String        mensaje;
  final VoidCallback  onReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size:  52,
              color: ColoresApp.textoTerciario,
            ),
            const SizedBox(height: 16),
            Text(
              mensaje,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ColoresApp.textoSecundario,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: onReintentar,
              icon:  const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reintentar'),
              style: TextButton.styleFrom(foregroundColor: ColoresApp.acento),
            ),
          ],
        ),
      ),
    );
  }
}
