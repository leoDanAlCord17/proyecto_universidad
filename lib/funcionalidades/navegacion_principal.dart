import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../compartido/constantes.dart';
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

  // Atrás en el shell principal: primero vuelve a la pestaña Inicio, y solo
  // si ya estabas ahí pide confirmación para salir. `canPop: false` porque
  // este widget es la raíz post-login — no hay a dónde hacer pop dentro del
  // Navigator; lo que "atrás" debe hacer aquí es semántica de la app
  // (cambiar de pestaña / confirmar salida), no navegación real.
  //
  // Nota: en la PWA instalada en Android, el historial del navegador se
  // colapsa a una sola entrada (ver historial_navegador_web.dart) para evitar
  // que el gesto de borde "asome" una pantalla anterior. Eso significa que el
  // gesto de swipe puede no llegar a disparar este PopScope en absoluto (no
  // hay entrada de historial a la que retroceder) — el botón atrás
  // físico/predictivo de Android sí debería dispararlo con normalidad. Probar
  // en un dispositivo real tras desplegar.
  Future<void> _alPresionarAtras(BuildContext context) async {
    if (pestanaActiva.value != 0) {
      pestanaActiva.value = 0;
      return;
    }
    final confirmo = await DialogoConfirmacion.mostrar(
      context,
      titulo: '¿Salir de la aplicación?',
      descripcion: '¿Estás seguro de que deseas salir?',
      textoConfirmar: 'Cancelar',
      textoCancelar: 'Salir',
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
