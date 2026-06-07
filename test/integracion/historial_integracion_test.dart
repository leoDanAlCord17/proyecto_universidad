import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniasist/compartido/errores.dart';
import 'package:uniasist/funcionalidades/autenticacion/auth_cubit.dart';
import 'package:uniasist/funcionalidades/autenticacion/auth_estado.dart';
import 'package:uniasist/funcionalidades/historial/historial_cubit.dart';
import 'package:uniasist/funcionalidades/historial/historial_item.dart';
import 'package:uniasist/funcionalidades/historial/historial_pantalla.dart';

import '../helpers.dart';

Widget _marco(HistorialCubit historial, MockAuthCubit auth) => MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<HistorialCubit>.value(value: historial),
          BlocProvider<AuthCubit>.value(value: auth),
        ],
        child: const HistorialPantalla(),
      ),
    );

void main() {
  late MockHistorialRepositorio repositorio;
  late MockAuthCubit authCubit;

  setUp(() {
    registrarFallbacks();
    repositorio = MockHistorialRepositorio();
    authCubit   = MockAuthCubit();
    when(() => authCubit.state)
        .thenReturn(Autenticado(usuarioEjemplo));
  });

  group('Historial — integración cubit + pantalla', () {
    testWidgets(
        'carga exitosa: cubit emite HistorialCargado y pantalla muestra el título del evento',
        (tester) async {
      when(() => repositorio.obtenerHistorial(any(), offset: any(named: 'offset')))
          .thenAnswer((_) async => (
                items:  [historialItemEjemplo],
                hayMas: false,
              ),);

      final cubit = HistorialCubit(repositorio);

      await tester.pumpWidget(_marco(cubit, authCubit));
      await tester.pump(); // future del repositorio resuelve
      await tester.pump(); // pantalla reconstruye con HistorialCargado

      expect(find.text('Charla de Flutter'), findsOneWidget);
    });

    testWidgets(
        'lista vacía: cubit emite HistorialCargado sin items y pantalla muestra estado vacío',
        (tester) async {
      when(() => repositorio.obtenerHistorial(any(), offset: any(named: 'offset')))
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
      when(() => repositorio.obtenerHistorial(any(), offset: any(named: 'offset')))
          .thenThrow(const FallaServidor('Error al obtener historial.'));

      final cubit = HistorialCubit(repositorio);

      await tester.pumpWidget(_marco(cubit, authCubit));
      await tester.pump();
      await tester.pump();

      expect(find.text('Error al obtener historial.'), findsOneWidget);
    });
  });
}
