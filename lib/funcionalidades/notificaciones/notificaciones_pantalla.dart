import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/widgets/formularios/barra_busqueda_app.dart';
import '../../compartido/widgets/navegacion/barra_superior_app.dart';
import '../../compartido/widgets/botones/boton_regresar.dart';
import '../../configuracion/colores_app.dart';
import 'notificaciones_cubit.dart';
import 'notificaciones_estado.dart';

class NotificacionesPantalla extends StatelessWidget {
  const NotificacionesPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificacionesCubit, NotificacionesEstado>(
      builder: (context, estado) => _construirVista(context, estado),
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
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: BarraBusquedaApp(
                hintText:  'Buscar notificaciones...',
                alCambiar: (_) {},
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
      NotificacionesCargando()                           => const Center(
          child: CircularProgressIndicator(color: ColoresApp.acento),
        ),
      NotificacionesInicial() || NotificacionesCargadas() => const _VistaVacia(),
      NotificacionesError(:final mensaje)               => _VistaError(mensaje: mensaje),
    };
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

// ─── Vista de error ───────────────────────────────────────────────────────────

class _VistaError extends StatelessWidget {
  const _VistaError({required this.mensaje});

  final String mensaje;

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
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ColoresApp.textoSecundario,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
