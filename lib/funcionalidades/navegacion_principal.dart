import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../compartido/constantes.dart';
import '../compartido/historial_navegador.dart';
import '../compartido/logger.dart';
import '../compartido/navegacion.dart';
import '../compartido/widgets/dialogo/dialogo_confirmacion.dart';
import '../compartido/widgets/navegacion/barra_navegacion_app.dart';
import '../configuracion/dependencias.dart';
import 'eventos/eventos_cubit.dart';
import 'eventos/eventos_pantalla.dart';
import 'historial/historial_cubit.dart';
import 'historial/historial_pantalla.dart';
import 'inicio/eventos_en_curso_cubit.dart';
import 'inicio/inicio_cubit.dart';
import 'inicio/inicio_pantalla.dart';
import 'perfil/perfil_cubit.dart';
import 'perfil/perfil_pantalla.dart';

/// Contenedor de las pestañas principales (Inicio, Eventos, Asistencia, Perfil).
///
/// Las pestañas viven en un [IndexedStack] y se cambian por estado interno
/// (escuchando [pestanaActiva]), NO navegando por el router. Así el historial
/// del navegador nunca acumula entradas por pestaña y el gesto de retroceso del
/// sistema no tiene ninguna pantalla anterior que mostrar (era la causa del bug
/// de "swipe" en la PWA instalada en Android).
///
/// Cada pestaña se construye solo la primera vez que se visita (carga perezosa)
/// y, una vez construida, conserva su estado al cambiar de pestaña.
class NavegacionPrincipal extends StatefulWidget {
  const NavegacionPrincipal({super.key});

  @override
  State<NavegacionPrincipal> createState() => _NavegacionPrincipalState();
}

class _NavegacionPrincipalState extends State<NavegacionPrincipal> {
  /// Índices de las pestañas reales, en el orden del IndexedStack.
  /// (El 2 — Escanear — no es pestaña: abre una pantalla aparte con push.)
  static const List<int> _ordenTabs = [0, 1, 3, 4];

  final Set<int> _visitadas = {0};
  VoidCallback? _cancelarCentinela;

  @override
  void initState() {
    super.initState();
    pestanaActiva.addListener(_alCambiarPestana);
    // Ver la nota junto a PopScope en build(): en web, el back/swipe del
    // sistema depende del truco de la entrada centinela, no de PopScope.
    if (kIsWeb) {
      _cancelarCentinela = activarCentinelaAtras(_alConsumirCentinela);
    }
  }

  @override
  void dispose() {
    _cancelarCentinela?.call();
    pestanaActiva.removeListener(_alCambiarPestana);
    super.dispose();
  }

  void _alCambiarPestana() {
    if (!mounted) return;
    setState(() => _visitadas.add(pestanaActiva.value));
  }

  void _seleccionar(int indice) {
    // Escanear no es una pestaña: abre su propia pantalla.
    if (indice == 2) {
      context.push(Rutas.escanear);
      return;
    }
    if (pestanaActiva.value == indice) return;
    pestanaActiva.value = indice; // dispara _alCambiarPestana → setState
  }

  Widget _contenido(int indice) {
    switch (indice) {
      case 0:
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => obtenerIt<InicioCubit>()),
            BlocProvider(create: (_) => obtenerIt<EventosEnCursoCubit>()),
          ],
          child: const InicioPantalla(),
        );
      case 1:
        return BlocProvider(
          create: (_) => obtenerIt<EventosCubit>(),
          child: const EventosPantalla(),
        );
      case 3:
        return BlocProvider(
          create: (_) => obtenerIt<HistorialCubit>(),
          child: const HistorialPantalla(),
        );
      case 4:
        return BlocProvider(
          create: (_) => obtenerIt<PerfilCubit>(),
          child: const PerfilPantalla(),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // Se dispara cuando el sistema consume la entrada centinela del historial
  // (ver activarCentinelaAtras en historial_navegador_web.dart). Esa entrada
  // vive en el historial del NAVEGADOR, no en la pila de rutas de Flutter,
  // así que también se consume — sin querer — cuando el back real le
  // pertenece a una pantalla empujada encima (p. ej. Escanear QR): en ese
  // caso este widget ya no es la ruta actual, y dejamos que GoRouter la
  // cierre solo como corresponde, sin interferir.
  void _alConsumirCentinela() {
    // Se difiere al siguiente frame a propósito: este callback corre en
    // reacción directa al evento `popstate` del navegador, en el mismo
    // instante en que el Router de Flutter también puede estar reaccionando
    // a ese mismo evento (aunque la ruta no cambie). Abrir el diálogo de
    // inmediato, en ese momento, arriesga que el Overlay/Navigator todavía
    // esté inestable y el diálogo no llegue a mostrarse sin ningún error
    // visible. Postergarlo un frame evita la carrera.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        unawaited(
          Sentry.captureMessage(
            '🔍 [debug back] centinela consumido pero widget ya no está montado',
            level: SentryLevel.info,
          ),
        );
        return;
      }
      if (ModalRoute.of(context)?.isCurrent != true) {
        unawaited(
          Sentry.captureMessage(
            '🔍 [debug back] centinela consumido pero la ruta no es la actual',
            level: SentryLevel.info,
          ),
        );
        return;
      }
      unawaited(
        Sentry.captureMessage(
          '🔍 [debug back] centinela consumido, pestanaActiva=${pestanaActiva.value}',
          level: SentryLevel.info,
        ),
      );
      unawaited(_alPresionarAtras(context));
    });
  }

  // Atrás en el shell principal: primero vuelve a la pestaña Inicio, y solo
  // si ya estabas ahí pide confirmación para salir. Es semántica de la app
  // (cambiar de pestaña / confirmar salida), no navegación real — por eso
  // no depende de hacer pop de una ruta.
  Future<void> _alPresionarAtras(BuildContext context) async {
    if (pestanaActiva.value != 0) {
      pestanaActiva.value = 0;
      return;
    }
    unawaited(
      Sentry.captureMessage(
        '🔍 [debug back] a punto de mostrar diálogo de salida',
        level: SentryLevel.info,
      ),
    );
    bool? confirmo;
    try {
      confirmo = await DialogoConfirmacion.mostrar(
        context,
        titulo: '¿Salir de la aplicación?',
        descripcion: '¿Estás seguro de que deseas salir?',
        textoConfirmar: 'Cancelar',
        textoCancelar: 'Salir',
      );
    } catch (e, st) {
      reportarError(e, stack: st);
      return;
    }
    unawaited(
      Sentry.captureMessage(
        '🔍 [debug back] diálogo resuelto con confirmo=$confirmo',
        level: SentryLevel.info,
      ),
    );
    if (confirmo == false) {
      await SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final actual = pestanaActiva.value;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // En web esto lo maneja activarCentinelaAtras (initState) — el
        // historial colapsado a 1 entrada hace que este callback no sea
        // confiable ahí (confirmado en dispositivo real: el back cerraba la
        // app sin llegar a dispararlo). Se deja activo para plataformas
        // nativas, donde sí es el mecanismo estándar de Flutter.
        if (kIsWeb) return;
        unawaited(_alPresionarAtras(context));
      },
      child: Scaffold(
        body: IndexedStack(
          index: _ordenTabs.indexOf(actual),
          children: [
            for (final i in _ordenTabs)
              _visitadas.contains(i) ? _contenido(i) : const SizedBox.shrink(),
          ],
        ),
        bottomNavigationBar: BarraNavegacionApp(
          indiceActual: actual,
          alCambiarIndice: _seleccionar,
        ),
      ),
    );
  }
}
