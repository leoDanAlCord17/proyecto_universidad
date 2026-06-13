import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../compartido/constantes.dart';
import '../compartido/navegacion.dart';
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

  @override
  void initState() {
    super.initState();
    pestanaActiva.addListener(_alCambiarPestana);
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    final actual = pestanaActiva.value;
    // Anula el gesto "atrás" del sistema/navegador en la PWA instalada en
    // Android. Al deslizar desde el borde izquierdo, Chrome dispara el back del
    // historial; como cada context.push deja una entrada, el gesto asomaba y
    // abría la pantalla anterior. Este shell queda montado mientras navegas a
    // las pantallas internas (push), así que su BackButtonListener conserva la
    // prioridad y atrapa ese back: devolver true significa "ya lo manejé, no
    // propagar". La navegación interna (botón Regresar → context.pop /
    // context.go) NO pasa por el BackButtonDispatcher, así que sigue igual.
    //
    // Debe vivir AQUÍ (debajo del Router de go_router) y no en el builder de
    // MaterialApp.router, que está por encima del Router y haría que
    // Router.of(context) lance "context does not include a Router".
    return BackButtonListener(
      onBackButtonPressed: () async => true,
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
