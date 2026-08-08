import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:activiti/compartido/errores.dart';
import 'package:activiti/funcionalidades/configuracion_general/configuracion_general_cubit.dart';
import 'package:activiti/funcionalidades/configuracion_general/configuracion_general_estado.dart';
import 'package:activiti/funcionalidades/configuracion_general/configuracion_item.dart';

import '../../helpers.dart';

// ─── Fixtures ────────────────────────────────────────────────────────────────

const _booleano = ConfiguracionItem(
  id: 'c1',
  clave: 'revision_usuario_creacion',
  valor: 1,
  tipo: 'boolean',
  descripcion: 'Requiere aprobación de un administrador para cada cuenta nueva',
  modulo: 'usuarios',
  estatus: true,
);

const _entero = ConfiguracionItem(
  id: 'c2',
  clave: 'max_tags_secundarios_por_usuario',
  valor: 3,
  tipo: 'entero',
  descripcion: 'Máximo de tags secundarios asignables a un usuario',
  modulo: 'tags',
  estatus: true,
);

void main() {
  late MockConfiguracionGeneralRepositorio repositorio;

  setUp(() {
    repositorio = MockConfiguracionGeneralRepositorio();
  });

  ConfiguracionGeneralCubit build() => ConfiguracionGeneralCubit(repositorio);

  group('ConfiguracionGeneralCubit.cargar', () {
    blocTest<ConfiguracionGeneralCubit, ConfiguracionGeneralEstado>(
      'emite [Cargando, Cargado] con los items del repositorio',
      build: build,
      setUp: () => when(() => repositorio.obtenerTodas())
          .thenAnswer((_) async => [_booleano, _entero]),
      act: (c) => c.cargar(),
      expect: () => [
        isA<ConfiguracionGeneralCargando>(),
        isA<ConfiguracionGeneralCargado>()
            .having((s) => s.items, 'items', [_booleano, _entero]).having(
                (s) => s.guardando, 'guardando', isEmpty),
      ],
    );

    blocTest<ConfiguracionGeneralCubit, ConfiguracionGeneralEstado>(
      'emite [Cargando, Error] cuando falla el repositorio',
      build: build,
      setUp: () => when(() => repositorio.obtenerTodas())
          .thenThrow(const FallaServidor('Error en servidor.')),
      act: (c) => c.cargar(),
      expect: () => [
        isA<ConfiguracionGeneralCargando>(),
        isA<ConfiguracionGeneralError>()
            .having((s) => s.mensaje, 'mensaje', 'Error en servidor.'),
      ],
    );
  });

  group('ConfiguracionGeneralCubit.actualizarValor', () {
    blocTest<ConfiguracionGeneralCubit, ConfiguracionGeneralEstado>(
      'actualiza el valor de forma optimista y confirma al guardar',
      build: build,
      seed: () =>
          const ConfiguracionGeneralCargado(items: [_booleano, _entero]),
      setUp: () => when(() => repositorio.actualizarValor('c1', 0))
          .thenAnswer((_) async {}),
      act: (c) => c.actualizarValor('c1', 0),
      expect: () => [
        // Optimista: el valor ya cambió y 'c1' queda marcado como guardando.
        isA<ConfiguracionGeneralCargado>()
            .having((s) => s.items.first.valor, 'valor optimista', 0)
            .having((s) => s.guardando, 'guardando', {'c1'}),
        // Confirmado: se quita de guardando, el valor optimista se mantiene.
        isA<ConfiguracionGeneralCargado>()
            .having((s) => s.items.first.valor, 'valor final', 0)
            .having((s) => s.guardando, 'guardando', isEmpty),
      ],
      verify: (_) {
        verify(() => repositorio.actualizarValor('c1', 0)).called(1);
      },
    );

    blocTest<ConfiguracionGeneralCubit, ConfiguracionGeneralEstado>(
      'revierte el valor y expone errorPuntual si falla el guardado',
      build: build,
      seed: () =>
          const ConfiguracionGeneralCargado(items: [_booleano, _entero]),
      setUp: () => when(() => repositorio.actualizarValor('c1', 0))
          .thenThrow(const FallaServidor('No se pudo guardar.')),
      act: (c) => c.actualizarValor('c1', 0),
      expect: () => [
        isA<ConfiguracionGeneralCargado>()
            .having((s) => s.items.first.valor, 'valor optimista', 0),
        isA<ConfiguracionGeneralCargado>()
            .having((s) => s.items.first.valor, 'valor revertido', 1)
            .having((s) => s.guardando, 'guardando', isEmpty)
            .having(
                (s) => s.errorPuntual, 'errorPuntual', 'No se pudo guardar.'),
      ],
    );

    blocTest<ConfiguracionGeneralCubit, ConfiguracionGeneralEstado>(
      'no hace nada si el estado no es Cargado',
      build: build,
      act: (c) => c.actualizarValor('c1', 0),
      expect: () => [],
    );

    blocTest<ConfiguracionGeneralCubit, ConfiguracionGeneralEstado>(
      'no hace nada si el id no existe en la lista actual',
      build: build,
      seed: () => const ConfiguracionGeneralCargado(items: [_booleano]),
      act: (c) => c.actualizarValor('no-existe', 5),
      expect: () => [],
      verify: (_) {
        verifyNever(() => repositorio.actualizarValor(any(), any()));
      },
    );
  });

  group('ConfiguracionGeneralCubit.actualizarEstatus', () {
    blocTest<ConfiguracionGeneralCubit, ConfiguracionGeneralEstado>(
      'desactiva la configuración de forma optimista y confirma al guardar',
      build: build,
      seed: () => const ConfiguracionGeneralCargado(items: [_booleano]),
      setUp: () => when(() => repositorio.actualizarEstatus('c1', false))
          .thenAnswer((_) async {}),
      act: (c) => c.actualizarEstatus('c1', false),
      expect: () => [
        isA<ConfiguracionGeneralCargado>()
            .having((s) => s.items.first.estatus, 'estatus optimista', false),
        isA<ConfiguracionGeneralCargado>()
            .having((s) => s.items.first.estatus, 'estatus final', false)
            .having((s) => s.guardando, 'guardando', isEmpty),
      ],
    );

    blocTest<ConfiguracionGeneralCubit, ConfiguracionGeneralEstado>(
      'revierte el estatus si falla el guardado',
      build: build,
      seed: () => const ConfiguracionGeneralCargado(items: [_booleano]),
      setUp: () => when(() => repositorio.actualizarEstatus('c1', false))
          .thenThrow(const FallaInesperada('Ocurrió un error inesperado.')),
      act: (c) => c.actualizarEstatus('c1', false),
      expect: () => [
        isA<ConfiguracionGeneralCargado>()
            .having((s) => s.items.first.estatus, 'estatus optimista', false),
        isA<ConfiguracionGeneralCargado>()
            .having((s) => s.items.first.estatus, 'estatus revertido', true)
            .having((s) => s.errorPuntual, 'errorPuntual', isNotNull),
      ],
    );
  });
}
