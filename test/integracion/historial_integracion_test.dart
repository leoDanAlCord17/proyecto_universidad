import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:activiti/compartido/constantes.dart';
import 'package:activiti/compartido/errores.dart';
import 'package:activiti/funcionalidades/autenticacion/auth_cubit.dart';
import 'package:activiti/funcionalidades/autenticacion/auth_estado.dart';
import 'package:activiti/funcionalidades/historial/historial_cubit.dart';
import 'package:activiti/funcionalidades/historial/historial_item.dart';
import 'package:activiti/funcionalidades/historial/historial_pantalla.dart';

import '../helpers.dart';

Widget _marco(HistorialCubit historial, MockAuthCubit auth) {
  final router = GoRouter(
    initialLocation: Rutas.historial,
    routes: [
      GoRoute(
        path: Rutas.historial,
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider<HistorialCubit>.value(value: historial),
            BlocProvider<AuthCubit>.value(value: auth),
          ],
          child: const HistorialPantalla(),
        ),
      ),
      GoRoute(path: Rutas.home, builder: (_, __) => const SizedBox()),
      GoRoute(path: Rutas.eventos, builder: (_, __) => const SizedBox()),
      GoRoute(path: Rutas.perfil, builder: (_, __) => const SizedBox()),
      GoRoute(path: Rutas.escanear, builder: (_, __) => const SizedBox()),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
  late MockHistorialRepositorio repositorio;
  late MockAuthCubit authCubit;

  setUp(() {
    registrarFallbacks();
    repositorio = MockHistorialRepositorio();
    authCubit = MockAuthCubit();
    when(() => authCubit.state).thenReturn(Autenticado(usuarioEjemplo));
  });

  group('Historial — integración cubit + pantalla', () {
    testWidgets(
        'carga exitosa: cubit emite HistorialCargado y pantalla muestra el título del evento',
        (tester) async {
      when(() =>
              repositorio.obtenerHistorial(any(), offset: any(named: 'offset')))
          .thenAnswer(
        (_) async => (
          items: [historialItemEjemplo],
          hayMas: false,
        ),
      );

      final cubit = HistorialCubit(repositorio);

      await tester.pumpWidget(_marco(cubit, authCubit));
      await tester.pump(); // future del repositorio resuelve
      await tester.pump(); // pantalla reconstruye con HistorialCargado

      expect(find.text('Charla de Flutter'), findsOneWidget);
    });

    testWidgets(
        'lista vacía: cubit emite HistorialCargado sin items y pantalla muestra estado vacío',
        (tester) async {
      // Se agranda el viewport y se fija DPR=1 para que los píxeles físicos
      // coincidan con los lógicos en cualquier máquina host y _VistaVacia quepa
      // sin desbordes.
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      when(() =>
              repositorio.obtenerHistorial(any(), offset: any(named: 'offset')))
          .thenAnswer((_) async => (items: <HistorialItem>[], hayMas: false));

      final cubit = HistorialCubit(repositorio);

      await tester.pumpWidget(_marco(cubit, authCubit));
      await tester.pump();
      await tester.pump();

      expect(find.text('Sin eventos aún'), findsOneWidget);
    });

    testWidgets(
        'error de red: cubit emite HistorialError y pantalla muestra el mensaje',
        (tester) async {
      when(() =>
              repositorio.obtenerHistorial(any(), offset: any(named: 'offset')))
          .thenThrow(const FallaServidor('Error al obtener historial.'));

      final cubit = HistorialCubit(repositorio);

      await tester.pumpWidget(_marco(cubit, authCubit));
      await tester.pump();
      await tester.pump();

      expect(find.text('Error al obtener historial.'), findsOneWidget);
    });
  });
}
