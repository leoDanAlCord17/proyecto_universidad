import 'package:flutter_test/flutter_test.dart';
import 'package:uniasist/funcionalidades/autenticacion/usuario.dart';

void main() {
  const jsonBase = {
    'id':                    'user-id-1',
    'auth_id':               'auth-id-1',
    'primer_nombre':         'Leo',
    'segundo_nombre':        'Daniel',
    'primer_apellido':       'Alvarez',
    'segundo_apellido':      'Cordero',
    'numero_identificacion': '12345678',
    'correo':                'leo@uni.edu',
    'telefono':              '+58123456789',
    'url_avatar':            null,
    'estatus':               true,
    'usuarios_roles':        <dynamic>[],
  };

  group('Usuario.desdeJson', () {
    test('parsea todos los campos correctamente', () {
      final u = Usuario.desdeJson(jsonBase);

      expect(u.id,                   'user-id-1');
      expect(u.authId,               'auth-id-1');
      expect(u.primerNombre,         'Leo');
      expect(u.segundoNombre,        'Daniel');
      expect(u.primerApellido,       'Alvarez');
      expect(u.segundoApellido,      'Cordero');
      expect(u.numeroIdentificacion, '12345678');
      expect(u.correo,               'leo@uni.edu');
      expect(u.telefono,             '+58123456789');
      expect(u.estatus,              isTrue);
    });

    test('usuarios_roles vacío produce roles y permisos vacíos', () {
      final u = Usuario.desdeJson(jsonBase);
      expect(u.roles,    isEmpty);
      expect(u.permisos, isEmpty);
    });

    test('usa valores por defecto cuando faltan campos opcionales', () {
      final u = Usuario.desdeJson({
        'primer_nombre':   'Maria',
        'primer_apellido': 'Gonzalez',
        'correo':          'maria@uni.edu',
        'usuarios_roles':  <dynamic>[],
      });

      expect(u.id,            isNull);
      expect(u.authId,        isNull);
      expect(u.segundoNombre, isNull);
      expect(u.estatus,       isTrue);
    });

    test('extrae solo roles con estatus activo', () {
      final u = Usuario.desdeJson({
        ...jsonBase,
        'usuarios_roles': [
          {
            'estatus': 'activo',
            'roles':   {'nombre': 'admin', 'roles_permisos': <dynamic>[]},
          },
          {
            'estatus': 'inactivo',
            'roles':   {'nombre': 'coordinador', 'roles_permisos': <dynamic>[]},
          },
        ],
      });

      expect(u.roles, ['admin']);
      expect(u.roles, isNot(contains('coordinador')));
    });

    test('extrae permisos sin duplicados cuando dos roles comparten uno', () {
      final u = Usuario.desdeJson({
        ...jsonBase,
        'usuarios_roles': [
          {
            'estatus': 'activo',
            'roles': {
              'nombre': 'admin',
              'roles_permisos': [
                {'permisos': {'nombre': 'ver_eventos'}},
                {'permisos': {'nombre': 'crear_eventos'}},
              ],
            },
          },
          {
            'estatus': 'activo',
            'roles': {
              'nombre': 'profesor',
              'roles_permisos': [
                {'permisos': {'nombre': 'ver_eventos'}}, // duplicado
              ],
            },
          },
        ],
      });

      expect(u.permisos.length, 2);
      expect(u.permisos, containsAll(['ver_eventos', 'crear_eventos']));
    });

    test('ignora roles inactivos al calcular permisos', () {
      final u = Usuario.desdeJson({
        ...jsonBase,
        'usuarios_roles': [
          {
            'estatus': 'inactivo',
            'roles': {
              'nombre': 'admin',
              'roles_permisos': [
                {'permisos': {'nombre': 'eliminar_usuarios'}},
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
      final u = Usuario(
        primerNombre:   'Leo',
        primerApellido: 'Alvarez',
        correo:         'leo@uni.edu',
      );
      expect(u.nombreCompleto, 'Leo Alvarez');
    });

    test('iniciales retorna mayúsculas del nombre y apellido', () {
      final u = Usuario(
        primerNombre:   'Leo',
        primerApellido: 'Alvarez',
        correo:         'leo@uni.edu',
      );
      expect(u.iniciales, 'LA');
    });

    test('iniciales con nombre vacío retorna solo inicial del apellido', () {
      final u = Usuario(
        primerNombre:   '',
        primerApellido: 'Alvarez',
        correo:         'x@x.com',
      );
      expect(u.iniciales, 'A');
    });

    test('iniciales con apellido vacío retorna solo inicial del nombre', () {
      final u = Usuario(
        primerNombre:   'Leo',
        primerApellido: '',
        correo:         'x@x.com',
      );
      expect(u.iniciales, 'L');
    });
  });

  group('tieneRol / tienePermiso', () {
    final u = Usuario(
      primerNombre:   'Leo',
      primerApellido: 'Alvarez',
      correo:         'leo@uni.edu',
      roles:          ['admin', 'profesor'],
      permisos:       ['ver_eventos', 'crear_eventos'],
    );

    test('tieneRol retorna true para rol asignado', () {
      expect(u.tieneRol('admin'), isTrue);
    });

    test('tieneRol retorna false para rol no asignado', () {
      expect(u.tieneRol('estudiante'), isFalse);
    });

    test('tienePermiso retorna true para permiso asignado', () {
      expect(u.tienePermiso('ver_eventos'), isTrue);
    });

    test('tienePermiso retorna false para permiso no asignado', () {
      expect(u.tienePermiso('eliminar_usuarios'), isFalse);
    });
  });

  group('aJson', () {
    test('incluye auth_id cuando está presente', () {
      final u = Usuario(
        authId:         'auth-id-1',
        primerNombre:   'Leo',
        primerApellido: 'Alvarez',
        correo:         'leo@uni.edu',
      );
      expect(u.aJson(), containsPair('auth_id', 'auth-id-1'));
    });

    test('omite auth_id cuando es null', () {
      final u = Usuario(
        primerNombre:   'Leo',
        primerApellido: 'Alvarez',
        correo:         'leo@uni.edu',
      );
      expect(u.aJson().containsKey('auth_id'), isFalse);
    });

    test('incluye correo y nombres', () {
      final u = Usuario(
        primerNombre:   'Leo',
        primerApellido: 'Alvarez',
        correo:         'leo@uni.edu',
      );
      final json = u.aJson();
      expect(json['correo'],          'leo@uni.edu');
      expect(json['primer_nombre'],   'Leo');
      expect(json['primer_apellido'], 'Alvarez');
    });

    test('no incluye roles ni permisos (viven en otras tablas)', () {
      final u = Usuario(
        primerNombre:   'Leo',
        primerApellido: 'Alvarez',
        correo:         'leo@uni.edu',
        roles:          ['admin'],
        permisos:       ['ver_eventos'],
      );
      final json = u.aJson();
      expect(json.containsKey('roles'),    isFalse);
      expect(json.containsKey('permisos'), isFalse);
    });
  });
}
