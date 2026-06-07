import 'package:flutter_test/flutter_test.dart';
import 'package:uniasist/funcionalidades/autenticacion/usuario.dart';

void main() {
  const camposBase = {
    'id': 'user-id-1',
    'auth_id': 'auth-id-1',
    'primer_nombre': 'Leo',
    'segundo_nombre': 'Daniel',
    'primer_apellido': 'Alvarez',
    'segundo_apellido': 'Cordero',
    'numero_identificacion': '12345678',
    'correo': 'leo@uni.edu',
    'telefono': '+58123456789',
    'url_avatar': null,
    'estatus': true,
  };

  const jsonBase = {
    ...camposBase,
    'usuarios_roles': <dynamic>[],
  };

  group('Usuario.desdeJson', () {
    test('parsea todos los campos correctamente', () {
      final u = Usuario.desdeJson(jsonBase);

      expect(u.id, 'user-id-1');
      expect(u.authId, 'auth-id-1');
      expect(u.primerNombre, 'Leo');
      expect(u.segundoNombre, 'Daniel');
      expect(u.primerApellido, 'Alvarez');
      expect(u.segundoApellido, 'Cordero');
      expect(u.numeroIdentificacion, '12345678');
      expect(u.correo, 'leo@uni.edu');
      expect(u.telefono, '+58123456789');
      expect(u.estatus, isTrue);
    });

    test('usuarios_roles vacío produce roles y permisos vacíos', () {
      final u = Usuario.desdeJson(jsonBase);
      expect(u.roles, isEmpty);
      expect(u.permisos, isEmpty);
    });

    test('usa valores por defecto cuando faltan campos opcionales', () {
      final u = Usuario.desdeJson(const {
        'primer_nombre': 'Maria',
        'primer_apellido': 'Gonzalez',
        'correo': 'maria@uni.edu',
        'usuarios_roles': <dynamic>[],
      });

      expect(u.id, isNull);
      expect(u.authId, isNull);
      expect(u.segundoNombre, isNull);
      expect(u.estatus, isTrue);
    });

    test('extrae solo roles con estatus activo (boolean true)', () {
      final u = Usuario.desdeJson(const {
        ...camposBase,
        'usuarios_roles': [
          {
            'estatus': true,
            'roles': {
              'nombre': 'admin',
              'estatus': true,
              'roles_permisos': <dynamic>[]
            },
          },
          {
            'estatus': false,
            'roles': {
              'nombre': 'coordinador',
              'estatus': true,
              'roles_permisos': <dynamic>[]
            },
          },
        ],
      });

      expect(u.roles, ['admin']);
      expect(u.roles, isNot(contains('coordinador')));
    });

    test('extrae permisos sin duplicados cuando dos roles comparten uno', () {
      final u = Usuario.desdeJson(const {
        ...camposBase,
        'usuarios_roles': [
          {
            'estatus': true,
            'roles': {
              'nombre': 'admin',
              'estatus': true,
              'roles_permisos': [
                {
                  'estatus': true,
                  'permisos': {'nombre': 'eventos.crear'}
                },
                {
                  'estatus': true,
                  'permisos': {'nombre': 'ajustes.usuarios'}
                },
              ],
            },
          },
          {
            'estatus': true,
            'roles': {
              'nombre': 'profesor',
              'estatus': true,
              'roles_permisos': [
                {
                  'estatus': true,
                  'permisos': {'nombre': 'eventos.crear'}
                }, // duplicado
              ],
            },
          },
        ],
      });

      expect(u.permisos.length, 2);
      expect(u.permisos, containsAll(['eventos.crear', 'ajustes.usuarios']));
    });

    test('ignora roles_permisos con estatus false', () {
      final u = Usuario.desdeJson(const {
        ...camposBase,
        'usuarios_roles': [
          {
            'estatus': true,
            'roles': {
              'nombre': 'admin',
              'estatus': true,
              'roles_permisos': [
                {
                  'estatus': false,
                  'permisos': {'nombre': 'ajustes.usuarios'}
                },
              ],
            },
          },
        ],
      });

      expect(u.permisos, isEmpty);
    });

    test('ignora roles inactivos al calcular permisos', () {
      final u = Usuario.desdeJson(const {
        ...camposBase,
        'usuarios_roles': [
          {
            'estatus': false,
            'roles': {
              'nombre': 'admin',
              'estatus': true,
              'roles_permisos': [
                {
                  'estatus': true,
                  'permisos': {'nombre': 'ajustes.usuarios'}
                },
              ],
            },
          },
        ],
      });

      expect(u.permisos, isEmpty);
    });
  });

  group('Getters', () {
    test('nombreCompleto retorna primer nombre + primer apellido', () {
      const u = Usuario(
        primerNombre: 'Leo',
        primerApellido: 'Alvarez',
        correo: 'leo@uni.edu',
      );
      expect(u.nombreCompleto, 'Leo Alvarez');
    });

    test('iniciales retorna mayúsculas del nombre y apellido', () {
      const u = Usuario(
        primerNombre: 'Leo',
        primerApellido: 'Alvarez',
        correo: 'leo@uni.edu',
      );
      expect(u.iniciales, 'LA');
    });

    test('iniciales con nombre vacío retorna solo inicial del apellido', () {
      const u = Usuario(
        primerNombre: '',
        primerApellido: 'Alvarez',
        correo: 'x@x.com',
      );
      expect(u.iniciales, 'A');
    });

    test('iniciales con apellido vacío retorna solo inicial del nombre', () {
      const u = Usuario(
        primerNombre: 'Leo',
        primerApellido: '',
        correo: 'x@x.com',
      );
      expect(u.iniciales, 'L');
    });
  });

  group('tieneRol / tienePermiso', () {
    // Permisos reales usan formato con punto: 'grupo.accion'
    const u = Usuario(
      primerNombre: 'Leo',
      primerApellido: 'Alvarez',
      correo: 'leo@uni.edu',
      roles: ['admin', 'profesor'],
      permisos: ['eventos.crear', 'ajustes.usuarios'],
    );

    test('tieneRol retorna true para rol asignado', () {
      expect(u.tieneRol('admin'), isTrue);
    });

    test('tieneRol retorna false para rol no asignado', () {
      expect(u.tieneRol('estudiante'), isFalse);
    });

    test('tienePermiso con dot retorna true para coincidencia exacta', () {
      expect(u.tienePermiso('eventos.crear'), isTrue);
    });

    test('tienePermiso sin dot retorna true si algún permiso tiene ese prefijo',
        () {
      expect(u.tienePermiso('eventos'), isTrue);
      expect(u.tienePermiso('ajustes'), isTrue);
    });

    test('tienePermiso retorna false para grupo sin coincidencia', () {
      expect(u.tienePermiso('reportes'), isFalse);
    });

    test('tienePermiso con dot retorna false para permiso exacto no asignado',
        () {
      expect(u.tienePermiso('ajustes.roles'), isFalse);
    });
  });

  group('aJson', () {
    test('incluye auth_id cuando está presente', () {
      const u = Usuario(
        authId: 'auth-id-1',
        primerNombre: 'Leo',
        primerApellido: 'Alvarez',
        correo: 'leo@uni.edu',
      );
      expect(u.aJson(), containsPair('auth_id', 'auth-id-1'));
    });

    test('omite auth_id cuando es null', () {
      const u = Usuario(
        primerNombre: 'Leo',
        primerApellido: 'Alvarez',
        correo: 'leo@uni.edu',
      );
      expect(u.aJson().containsKey('auth_id'), isFalse);
    });

    test('incluye correo y nombres', () {
      const u = Usuario(
        primerNombre: 'Leo',
        primerApellido: 'Alvarez',
        correo: 'leo@uni.edu',
      );
      final json = u.aJson();
      expect(json['correo'], 'leo@uni.edu');
      expect(json['primer_nombre'], 'Leo');
      expect(json['primer_apellido'], 'Alvarez');
    });

    test('no incluye roles ni permisos (viven en otras tablas)', () {
      const u = Usuario(
        primerNombre: 'Leo',
        primerApellido: 'Alvarez',
        correo: 'leo@uni.edu',
        roles: ['admin'],
        permisos: ['ver_eventos'],
      );
      final json = u.aJson();
      expect(json.containsKey('roles'), isFalse);
      expect(json.containsKey('permisos'), isFalse);
    });
  });
}
