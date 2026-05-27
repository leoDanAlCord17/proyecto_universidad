import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniasist/compartido/errores.dart';
import 'package:uniasist/funcionalidades/historial/historial_cubit.dart';
import 'package:uniasist/funcionalidades/historial/historial_estado.dart';

import '../../helpers.dart';

void main() {
  late MockHistorialRepositorio repositorio;

  setUp(() {
    repositorio = MockHistorialRepositorio();
  });

  HistorialCubit build() => HistorialCubit(repositorio);

  group('HistorialCubit', () {
    test('estado inicial es HistorialInicial', () {
      expect(build().state, isA<HistorialInicial>());
    });

    blocTest<HistorialCubit, HistorialEstado>(
      'cargar emite [Cargando, Cargado] con la lista del repositorio',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerHistorial(any()))
            .thenAnswer((_) async => [historialItemEjemplo]);
      },
      act: (c) => c.cargar('user-1'),
      expect: () => [
        isA<HistorialCargando>(),
        isA<HistorialCargado>().having(
          (e) => e.items,
          'items',
          [historialItemEjemplo],
        ),
      ],
      verify: (_) {
        verify(() => repositorio.obtenerHistorial('user-1')).called(1);
      },
    );

    blocTest<HistorialCubit, HistorialEstado>(
      'cargar emite [Cargando, Cargado] con lista vacía',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerHistorial(any()))
            .thenAnswer((_) async => []);
      },
      act: (c) => c.cargar('user-1'),
      expect: () => [
        isA<HistorialCargando>(),
        isA<HistorialCargado>().having((e) => e.items, 'items', isEmpty),
      ],
    );

    blocTest<HistorialCubit, HistorialEstado>(
      'cargar emite [Cargando, HistorialError] cuando FallaServidor',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerHistorial(any()))
            .thenThrow(const FallaServidor('Error de servidor'));
      },
      act: (c) => c.cargar('user-1'),
      expect: () => [
        isA<HistorialCargando>(),
        isA<HistorialError>().having(
          (e) => e.mensaje,
          'mensaje',
          'Error de servidor',
        ),
      ],
    );

    blocTest<HistorialCubit, HistorialEstado>(
      'cargar emite [Cargando, HistorialError] cuando FallaInesperada',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerHistorial(any()))
            .thenThrow(const FallaInesperada('Error inesperado'));
      },
      act: (c) => c.cargar('user-1'),
      expect: () => [
        isA<HistorialCargando>(),
        isA<HistorialError>().having(
          (e) => e.mensaje,
          'mensaje',
          'Error inesperado',
        ),
      ],
    );
  });
}
