import 'package:flutter_test/flutter_test.dart';
import 'package:uniasist/funcionalidades/usuarios/usuario_item.dart';

void main() {
  // ── UsuarioItem.desdeJson ─────────────────────────────────────────────────

  group('UsuarioItem.desdeJson', () {
    test('mapea todos los campos presentes correctamente', () {
      final item = UsuarioItem.desdeJson(const <String, dynamic>{
        'id':                   'u-1',
        'primer_nombre':        'Leo',
        'primer_apellido':      'Alvarez',
        'correo':               'leo@uni.edu',
        'estatus':              true,
        'numero_identificacion': 'CI-12345',
      });
      expect(item.id,                   'u-1');
      expect(item.primerNombre,         'Leo');
      expect(item.primerApellido,       'Alvarez');
      expect(item.correo,               'leo@uni.edu');
      expect(item.estatus,              true);
      expect(item.numeroIdentificacion, 'CI-12345');
    });

    test('campos null producen strings vacíos y default true para estatus', () {
      final item = UsuarioItem.desdeJson(const <String, dynamic>{
        'id':                    'u-2',
        'primer_nombre':         null,
        'primer_apellido':       null,
        'correo':                null,
        'estatus':               null,
        'numero_identificacion': null,
      });
      expect(item.primerNombre,         '');
      expect(item.primerApellido,       '');
      expect(item.correo,               '');
      expect(item.estatus,              true);
      expect(item.numeroIdentificacion, isNull);
    });

    test('estatus false se preserva', () {
      final item = UsuarioItem.desdeJson(const <String, dynamic>{
        'id': 'u-3', 'primer_nombre': 'X', 'primer_apellido': 'Y',
        'correo': 'x@y.com', 'estatus': false,
      });
      expect(item.estatus, false);
    });
  });

  // ── UsuarioItem.nombreCompleto ────────────────────────────────────────────

  group('UsuarioItem.nombreCompleto', () {
    test('concatena nombre y apellido con espacio', () {
      const item = UsuarioItem(
        id: 'u-1', primerNombre: 'Leo', primerApellido: 'Alvarez',
        correo: 'leo@uni.edu', estatus: true,
      );
      expect(item.nombreCompleto, 'Leo Alvarez');
    });

    test('nombre vacío produce string con espacio al inicio', () {
      const item = UsuarioItem(
        id: 'u-1', primerNombre: '', primerApellido: 'Alvarez',
        correo: 'leo@uni.edu', estatus: true,
      );
      expect(item.nombreCompleto, ' Alvarez');
    });
  });

  // ── UsuarioItem.iniciales ─────────────────────────────────────────────────

  group('UsuarioItem.iniciales', () {
    test('caso normal: primera letra de nombre y apellido en mayúsculas', () {
      const item = UsuarioItem(
        id: 'u-1', primerNombre: 'Leo', primerApellido: 'Alvarez',
        correo: '', estatus: true,
      );
      expect(item.iniciales, 'LA');
    });

    test('nombre vacío solo genera inicial del apellido', () {
      const item = UsuarioItem(
        id: 'u-1', primerNombre: '', primerApellido: 'Alvarez',
        correo: '', estatus: true,
      );
      expect(item.iniciales, 'A');
    });

    test('apellido vacío solo genera inicial del nombre', () {
      const item = UsuarioItem(
        id: 'u-1', primerNombre: 'Leo', primerApellido: '',
        correo: '', estatus: true,
      );
      expect(item.iniciales, 'L');
    });

    test('ambos vacíos produce string vacío', () {
      const item = UsuarioItem(
        id: 'u-1', primerNombre: '', primerApellido: '',
        correo: '', estatus: true,
      );
      expect(item.iniciales, '');
    });

    test('minúsculas se convierten a mayúsculas', () {
      const item = UsuarioItem(
        id: 'u-1', primerNombre: 'ana', primerApellido: 'gomez',
        correo: '', estatus: true,
      );
      expect(item.iniciales, 'AG');
    });
  });
}
