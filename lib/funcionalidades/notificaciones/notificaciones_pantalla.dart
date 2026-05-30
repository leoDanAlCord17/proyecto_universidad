import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/widgets/avisos/vista_error_app.dart';
import '../../compartido/widgets/navegacion/barra_superior_app.dart';
import '../../compartido/widgets/botones/boton_regresar.dart';
import '../../configuracion/colores_app.dart';
import 'notificacion.dart';
import 'notificaciones_cubit.dart';
import 'notificaciones_estado.dart';

class NotificacionesPantalla extends StatefulWidget {
  const NotificacionesPantalla({super.key});

  @override
  State<NotificacionesPantalla> createState() => _NotificacionesPantallaState();
}

class _NotificacionesPantallaState extends State<NotificacionesPantalla> {
  bool _estaIniciado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_estaIniciado) return;
    _estaIniciado = true;
    context.read<NotificacionesCubit>().cargarLista();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificacionesCubit, NotificacionesEstado>(
      builder: _construirVista,
    );
  }

  Widget _construirVista(BuildContext context, NotificacionesEstado estado) {
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
                izquierda: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BotonRegresar(),
                    const SizedBox(width: 12),
                    Text(
                      'Notificaciones',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize:   20,
                        fontWeight: FontWeight.w700,
                        color:      ColoresApp.textoPrimario,
                      ),
                    ),
                  ],
                ),
                derecha: estado is NotificacionesCargadas &&
                        estado.notificaciones.any((n) => !n.leida)
                    ? TextButton(
                        onPressed: () =>
                            context.read<NotificacionesCubit>().marcarTodasLeidas(),
                        child: Text(
                          'Marcar todas',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: ColoresApp.acento,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
            Expanded(child: _Cuerpo(estado: estado)),
          ],
        ),
      ),
    );
  }
}

// ─── Cuerpo según estado ──────────────────────────────────────────────────────

class _Cuerpo extends StatelessWidget {
  const _Cuerpo({required this.estado});

  final NotificacionesEstado estado;

  @override
  Widget build(BuildContext context) {
    return switch (estado) {
      NotificacionesCargando()  => const Center(
          child: CircularProgressIndicator(color: ColoresApp.acento),
        ),
      NotificacionesInicial()   => const _VistaVacia(),
      NotificacionesCargadas(notificaciones: final lista) when lista.isEmpty
                                => const _VistaVacia(),
      NotificacionesCargadas(notificaciones: final lista)
                                => _ListaNotificaciones(notificaciones: lista),
      NotificacionesError(:final mensaje)
                                => VistaErrorApp(mensaje: mensaje, alReintentar: () => context.read<NotificacionesCubit>().cargarLista()),
    };
  }
}

// ─── Lista de notificaciones ──────────────────────────────────────────────────

class _ListaNotificaciones extends StatelessWidget {
  const _ListaNotificaciones({required this.notificaciones});

  final List<Notificacion> notificaciones;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding:     const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount:   notificaciones.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) =>
          _TarjetaNotificacion(notificacion: notificaciones[i]),
    );
  }
}

class _TarjetaNotificacion extends StatelessWidget {
  const _TarjetaNotificacion({required this.notificacion});

  final Notificacion notificacion;

  IconData _icono() => switch (notificacion.tipo) {
    'evento'     => Icons.event_rounded,
    'asistencia' => Icons.how_to_reg_outlined,
    'aprobacion' => Icons.verified_user_outlined,
    _            => Icons.notifications_outlined,
  };

  Color _colorIcono() => switch (notificacion.tipo) {
    'evento'     => ColoresApp.acento,
    'asistencia' => ColoresApp.verde,
    'aprobacion' => ColoresApp.ambar,
    _            => ColoresApp.textoSecundario,
  };

  Color _fondoIcono() => switch (notificacion.tipo) {
    'evento'     => ColoresApp.acentoClaro,
    'asistencia' => ColoresApp.verdeClaro,
    'aprobacion' => ColoresApp.ambarClaro,
    _            => ColoresApp.superficieTerciar,
  };

  String _tiempoRelativo() {
    final diff = DateTime.now().difference(notificacion.creadoEn);
    if (diff.inMinutes < 1)  return 'Ahora';
    if (diff.inHours   < 1)  return 'Hace ${diff.inMinutes} min';
    if (diff.inDays    < 1)  return 'Hace ${diff.inHours} h';
    if (diff.inDays    < 7)  return 'Hace ${diff.inDays} días';
    return '${notificacion.creadoEn.day}/${notificacion.creadoEn.month}/${notificacion.creadoEn.year}';
  }

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return Material(
      color:        notificacion.leida
          ? ColoresApp.superficiePrimaria
          : ColoresApp.acentoClaro,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        splashColor:  ColoresApp.bordeMedio,
        onTap: notificacion.leida
            ? null
            : () => context
                .read<NotificacionesCubit>()
                .marcarLeida(notificacion.id),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width:       40,
                height:      40,
                decoration:  BoxDecoration(
                  color:        _fondoIcono(),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_icono(), color: _colorIcono(), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notificacion.titulo,
                            style: estilos.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize:   14,
                            ),
                          ),
                        ),
                        if (!notificacion.leida)
                          Container(
                            width:      8,
                            height:     8,
                            margin:     const EdgeInsets.only(left: 6, top: 3),
                            decoration: const BoxDecoration(
                              color:  ColoresApp.acento,
                              shape:  BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notificacion.cuerpo,
                      style: estilos.bodySmall?.copyWith(
                        color:  ColoresApp.textoSecundario,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _tiempoRelativo(),
                      style: estilos.labelSmall?.copyWith(
                        color:    ColoresApp.textoTerciario,
                        fontSize: 11,
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
              Icons.notifications_none_rounded,
              size:  56,
              color: ColoresApp.textoTerciario,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin notificaciones',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: ColoresApp.textoSecundario,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cuando tengas notificaciones aparecerán aquí.',
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

