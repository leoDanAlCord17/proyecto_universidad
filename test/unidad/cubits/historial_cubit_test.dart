import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:activiti/compartido/errores.dart';
import 'package:activiti/funcionalidades/historial/historial_cubit.dart';
import 'package:activiti/funcionalidades/historial/historial_estado.dart';
import 'package:activiti/funcionalidades/historial/historial_item.dart';

import '../../helpers.dart';

typedef _Resultado = ({List<HistorialItem> items, bool hayMas});

const _itemDos = HistorialItem(
  id: 'historial-id-2',
  eventoId: 'evento-id-2',
  eventoTitulo: 'Conferencia Dart',
  estatus: 'presente',
);

void main() {
  late MockHistorialRepositorio repositorio;

  setUp(() => repositorio = MockHistorialRepositorio());

  HistorialCubit build() => HistorialCubit(repositorio);

  _Resultado pagina1({bool hayMas = false}) =>
      (items: [historialItemEjemplo], hayMas: hayMas);

  _Resultado pagina2() => (items: [_itemDos], hayMas: false);

  void cuandoRetorna(_Resultado resultado) {
    when(
      () => repositorio.obtenerHistorial(
        any(),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((_) async => resultado);
  }

  group('HistorialCubit', () {
    test('estado inicial es HistorialInicial', () {
      expect(build().state, isA<HistorialInicial>());
    });

    // ── cargar ─────────────────────────────────────────────────────────────

    group('cargar', () {
      blocTest<HistorialCubit, HistorialEstado>(
        'emite [Cargando, Cargado] con los items del repositorio',
        build: build,
        setUp: () => cuandoRetorna(pagina1()),
        act: (c) => c.cargar('user-1'),
        expect: () => [
          isA<HistorialCargando>(),
          isA<HistorialCargado>()
              .having((e) => e.items, 'items', [historialItemEjemplo]).having(
                  (e) => e.hayMas, 'hayMas', false),
        ],
        verify: (_) =>
            verify(() => repositorio.obtenerHistorial('user-1', offset: 0))
                .called(1),
      );

      blocTest<HistorialCubit, HistorialEstado>(
        'emite [Cargando, Cargado] con hayMas true cuando hay más páginas',
        build: build,
        setUp: () => cuandoRetorna(pagina1(hayMas: true)),
        act: (c) => c.cargar('user-1'),
        expect: () => [
          isA<HistorialCargando>(),
          isA<HistorialCargado>().having((e) => e.hayMas, 'hayMas', true),
        ],
      );

      blocTest<HistorialCubit, HistorialEstado>(
        'emite [Cargando, Cargado] con lista vacía',
        build: build,
        setUp: () => cuandoRetorna((items: [], hayMas: false)),
        act: (c) => c.cargar('user-1'),
        expect: () => [
          isA<HistorialCargando>(),
          isA<HistorialCargado>().having((e) => e.items, 'items', isEmpty),
        ],
      );

      blocTest<HistorialCubit, HistorialEstado>(
        'emite [Cargando, HistorialError] en FallaServidor',
        build: build,
        setUp: () {
          when(
            () => repositorio.obtenerHistorial(
              any(),
              offset: any(named: 'offset'),
            ),
          ).thenThrow(const FallaServidor('Error de servidor'));
        },
        act: (c) => c.cargar('user-1'),
        expect: () => [
          isA<HistorialCargando>(),
          isA<HistorialError>()
              .having((e) => e.mensaje, 'mensaje', 'Error de servidor'),
        ],
      );

      blocTest<HistorialCubit, HistorialEstado>(
        'emite [Cargando, HistorialError] en FallaRed',
        build: build,
        setUp: () {
          when(
            () => repositorio.obtenerHistorial(
              any(),
              offset: any(named: 'offset'),
            ),
          ).thenThrow(const FallaRed('Sin conexión'));
        },
        act: (c) => c.cargar('user-1'),
        expect: () => [
          isA<HistorialCargando>(),
          isA<HistorialError>()
              .having((e) => e.mensaje, 'mensaje', 'Sin conexión'),
        ],
      );

      blocTest<HistorialCubit, HistorialEstado>(
        'emite [Cargando, HistorialError] en FallaInesperada',
        build: build,
        setUp: () {
          when(
            () => repositorio.obtenerHistorial(
              any(),
              offset: any(named: 'offset'),
            ),
          ).thenThrow(const FallaInesperada('Error inesperado'));
        },
        act: (c) => c.cargar('user-1'),
        expect: () => [
          isA<HistorialCargando>(),
          isA<HistorialError>()
              .having((e) => e.mensaje, 'mensaje', 'Error inesperado'),
        ],
      );

      blocTest<HistorialCubit, HistorialEstado>(
        'reinicia el offset al llamarse por segunda vez',
        build: build,
        setUp: () => cuandoRetorna(pagina1(hayMas: true)),
        act: (c) async {
          await c.cargar('user-1');
          await c.cargar('user-1');
        },
        verify: (_) =>
            verify(() => repositorio.obtenerHistorial('user-1', offset: 0))
                .called(2),
      );
    });

    // ── cargarMas ──────────────────────────────────────────────────────────

    group('cargarMas', () {
      blocTest<HistorialCubit, HistorialEstado>(
        'no emite nada si el estado no es HistorialCargado',
        build: build,
        act: (c) => c.cargarMas(),
        expect: () => <HistorialEstado>[],
      );

      blocTest<HistorialCubit, HistorialEstado>(
        'no emite nada si hayMas es false',
        build: build,
        setUp: () => cuandoRetorna(pagina1(hayMas: false)),
        act: (c) async {
          await c.cargar('user-1');
          await c.cargarMas();
        },
        expect: () => [
          isA<HistorialCargando>(),
          isA<HistorialCargado>().having((e) => e.hayMas, 'hayMas', false),
          // cargarMas no debe emitir nada más
        ],
      );

      blocTest<HistorialCubit, HistorialEstado>(
        'emite [CargandoMas, Cargado] con items acumulados de ambas páginas',
        build: build,
        setUp: () {
          var llamadas = 0;
          when(
            () => repositorio.obtenerHistorial(
              any(),
              offset: any(named: 'offset'),
            ),
          ).thenAnswer((_) async {
            llamadas++;
            return llamadas == 1 ? pagina1(hayMas: true) : pagina2();
          });
        },
        act: (c) async {
          await c.cargar('user-1');
          await c.cargarMas();
        },
        expect: () => [
          isA<HistorialCargando>(),
          isA<HistorialCargado>()
              .having((e) => e.items.length, 'items.length', 1)
              .having((e) => e.hayMas, 'hayMas', true),
          isA<HistorialCargandoMas>()
              .having((e) => e.items, 'items', [historialItemEjemplo]),
          isA<HistorialCargado>()
              .having((e) => e.items.length, 'items.length', 2)
              .having((e) => e.items.last, 'items.last', _itemDos)
              .having((e) => e.hayMas, 'hayMas', false),
        ],
        verify: (_) {
          verify(() => repositorio.obtenerHistorial('user-1', offset: 0))
              .called(1);
          verify(() => repositorio.obtenerHistorial('user-1', offset: 1))
              .called(1);
        },
      );

      blocTest<HistorialCubit, HistorialEstado>(
        'revierte al estado anterior cuando cargarMas falla',
        build: build,
        setUp: () {
          var llamadas = 0;
          when(
            () => repositorio.obtenerHistorial(
              any(),
              offset: any(named: 'offset'),
            ),
          ).thenAnswer((_) async {
            llamadas++;
            if (llamadas == 1) return pagina1(hayMas: true);
            throw const FallaServidor('fallo');
          });
        },
        act: (c) async {
          await c.cargar('user-1');
          await c.cargarMas();
        },
        expect: () => [
          isA<HistorialCargando>(),
          isA<HistorialCargado>()
              .having((e) => e.items, 'items', [historialItemEjemplo]).having(
                  (e) => e.hayMas, 'hayMas', true),
          isA<HistorialCargandoMas>(),
          isA<HistorialCargado>()
              .having((e) => e.items, 'items', [historialItemEjemplo]).having(
                  (e) => e.hayMas, 'hayMas', true),
        ],
      );
    });
  });
}
