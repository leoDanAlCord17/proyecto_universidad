import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:activiti/compartido/errores.dart';
import 'package:activiti/funcionalidades/roles/rol.dart';
import 'package:activiti/funcionalidades/roles/roles_cubit.dart';
import 'package:activiti/funcionalidades/roles/roles_estado.dart';

import '../../helpers.dart';

// ─── Fixtures ─────────────────────────────────────────────────────────────────

const _rAdmin = Rol(
  id: 'r-1',
  nombre: 'Administrador',
  descripcion: 'Gestiona todo el sistema',
  esSistema: true,
);
const _rEstudiante = Rol(
  id: 'r-2',
  nombre: 'Estudiante',
  descripcion: 'Usuario estándar',
  esSistema: false,
);
const _rDocente = Rol(
  id: 'r-3',
  nombre: 'Docente',
  descripcion: 'Profesor del programa',
  esSistema: false,
);

const _roles = [_rAdmin, _rEstudiante, _rDocente];
const _conteos = {'r-1': 10, 'r-2': 25};

typedef _Resultado = ({List<Rol> roles, bool hayMas});

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late MockRolesRepositorio repositorio;

  setUp(() => repositorio = MockRolesRepositorio());

  RolesCubit build() => RolesCubit(repositorio);

  void cuandoObtenerRoles(_Resultado resultado) {
    when(
      () => repositorio.obtenerRoles(offset: any(named: 'offset')),
    ).thenAnswer((_) async => resultado);
  }

  RolesCargados cargados({bool hayMas = false}) => RolesCargados(
        roles: _roles,
        rolesFiltrados: _roles,
        hayMas: hayMas,
        conteoUsuarios: _conteos,
      );

  // ── cargarRoles ────────────────────────────────────────────────────────────

  group('RolesCubit.cargarRoles', () {
    test('estado inicial es RolesInicial', () {
      expect(build().state, isA<RolesInicial>());
    });

    blocTest<RolesCubit, RolesEstado>(
      'emite [Cargando, Cargados] con roles y conteoUsuarios del repositorio',
      build: build,
      setUp: () {
        cuandoObtenerRoles((roles: _roles, hayMas: false));
        when(() => repositorio.contarUsuariosPorRol())
            .thenAnswer((_) async => _conteos);
      },
      act: (c) => c.cargarRoles(),
      expect: () => [
        isA<RolesCargando>(),
        isA<RolesCargados>()
            .having((e) => e.roles.length, 'roles.length', 3)
            .having((e) => e.conteoUsuarios, 'conteoUsuarios', _conteos)
            .having((e) => e.rolesFiltrados, 'rolesFiltrados', _roles)
            .having((e) => e.hayMas, 'hayMas', false),
      ],
    );

    blocTest<RolesCubit, RolesEstado>(
      'emite [Cargando, Cargados] con hayMas true cuando hay más páginas',
      build: build,
      setUp: () {
        cuandoObtenerRoles((roles: _roles, hayMas: true));
        when(() => repositorio.contarUsuariosPorRol())
            .thenAnswer((_) async => _conteos);
      },
      act: (c) => c.cargarRoles(),
      expect: () => [
        isA<RolesCargando>(),
        isA<RolesCargados>().having((e) => e.hayMas, 'hayMas', true),
      ],
    );

    blocTest<RolesCubit, RolesEstado>(
      'emite [Cargando, Error] cuando FallaServidor en obtenerRoles',
      build: build,
      setUp: () {
        when(
          () => repositorio.obtenerRoles(offset: any(named: 'offset')),
        ).thenThrow(const FallaServidor('Sin conexión'));
        when(() => repositorio.contarUsuariosPorRol())
            .thenAnswer((_) async => {});
      },
      act: (c) => c.cargarRoles(),
      expect: () => [
        isA<RolesCargando>(),
        isA<RolesError>().having((e) => e.mensaje, 'mensaje', 'Sin conexión'),
      ],
    );

    blocTest<RolesCubit, RolesEstado>(
      'emite [Cargando, Error] cuando FallaInesperada',
      build: build,
      setUp: () {
        when(
          () => repositorio.obtenerRoles(offset: any(named: 'offset')),
        ).thenThrow(const FallaInesperada('Error raro'));
        when(() => repositorio.contarUsuariosPorRol())
            .thenAnswer((_) async => {});
      },
      act: (c) => c.cargarRoles(),
      expect: () => [
        isA<RolesCargando>(),
        isA<RolesError>(),
      ],
    );

    blocTest<RolesCubit, RolesEstado>(
      'conteoUsuarios llega correctamente al estado cargado',
      build: build,
      setUp: () {
        cuandoObtenerRoles((roles: [_rEstudiante], hayMas: false));
        when(() => repositorio.contarUsuariosPorRol())
            .thenAnswer((_) async => {'r-2': 42});
      },
      act: (c) => c.cargarRoles(),
      expect: () => [
        isA<RolesCargando>(),
        isA<RolesCargados>().having(
          (e) => e.conteoUsuarios['r-2'],
          'conteo estudiante',
          42,
        ),
      ],
    );
  });

  // ── filtrar ────────────────────────────────────────────────────────────────

  group('RolesCubit.filtrar', () {
    blocTest<RolesCubit, RolesEstado>(
      'no hace nada si el estado no es Cargados',
      build: build,
      act: (c) => c.filtrar('admin'),
      expect: () => [],
    );

    blocTest<RolesCubit, RolesEstado>(
      'texto vacío después de filtrar restaura todos los roles',
      build: build,
      seed: () => const RolesCargados(
        roles: _roles,
        rolesFiltrados: [_rAdmin],
        hayMas: false,
        conteoUsuarios: _conteos,
      ),
      act: (c) => c.filtrar(''),
      expect: () => [
        isA<RolesCargados>()
            .having((e) => e.rolesFiltrados.length, 'length', 3),
      ],
    );

    blocTest<RolesCubit, RolesEstado>(
      'filtra por nombre (case-insensitive)',
      build: build,
      seed: cargados,
      act: (c) => c.filtrar('estudi'),
      expect: () => [
        isA<RolesCargados>().having(
          (e) => e.rolesFiltrados.map((r) => r.id).toList(),
          'ids',
          ['r-2'],
        ),
      ],
    );

    blocTest<RolesCubit, RolesEstado>(
      'filtra por descripción',
      build: build,
      seed: cargados,
      act: (c) => c.filtrar('Profesor'),
      expect: () => [
        isA<RolesCargados>().having(
          (e) => e.rolesFiltrados.map((r) => r.id).toList(),
          'ids',
          ['r-3'],
        ),
      ],
    );

    blocTest<RolesCubit, RolesEstado>(
      'texto solo espacios después de filtrar restaura todos los roles',
      build: build,
      seed: () => const RolesCargados(
        roles: _roles,
        rolesFiltrados: [_rEstudiante],
        hayMas: false,
        conteoUsuarios: _conteos,
      ),
      act: (c) => c.filtrar('   '),
      expect: () => [
        isA<RolesCargados>()
            .having((e) => e.rolesFiltrados.length, 'length', 3),
      ],
    );

    blocTest<RolesCubit, RolesEstado>(
      'sin coincidencia devuelve lista vacía',
      build: build,
      seed: cargados,
      act: (c) => c.filtrar('zzzzz'),
      expect: () => [
        isA<RolesCargados>()
            .having((e) => e.rolesFiltrados, 'rolesFiltrados', isEmpty),
      ],
    );

    blocTest<RolesCubit, RolesEstado>(
      'el conteoUsuarios se preserva tras filtrar',
      build: build,
      seed: cargados,
      act: (c) => c.filtrar('admin'),
      expect: () => [
        isA<RolesCargados>()
            .having((e) => e.conteoUsuarios, 'conteoUsuarios', _conteos),
      ],
    );
  });
}
