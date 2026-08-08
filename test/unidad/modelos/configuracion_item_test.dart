import 'package:flutter_test/flutter_test.dart';
import 'package:activiti/funcionalidades/configuracion_general/configuracion_item.dart';

void main() {
  group('ConfiguracionItem.desdeJson', () {
    test('parsea una fila booleana correctamente', () {
      final item = ConfiguracionItem.desdeJson({
        'id': 'c1',
        'clave': 'revision_usuario_creacion',
        'valor': 1,
        'tipo': 'boolean',
        'descripcion': 'Requiere aprobación de un administrador',
        'modulo': 'usuarios',
        'estatus': true,
      });

      expect(item.id, 'c1');
      expect(item.clave, 'revision_usuario_creacion');
      expect(item.valor, 1);
      expect(item.tipo, 'boolean');
      expect(item.estatus, isTrue);
    });
  });

  group('ConfiguracionItem.esBooleano / valorBooleano', () {
    test('esBooleano es true solo cuando tipo == boolean', () {
      const booleano = ConfiguracionItem(
        id: 'c1',
        clave: 'x',
        valor: 1,
        tipo: 'boolean',
        descripcion: '',
        modulo: 'm',
        estatus: true,
      );
      const entero = ConfiguracionItem(
        id: 'c2',
        clave: 'y',
        valor: 3,
        tipo: 'entero',
        descripcion: '',
        modulo: 'm',
        estatus: true,
      );

      expect(booleano.esBooleano, isTrue);
      expect(entero.esBooleano, isFalse);
    });

    test('valorBooleano es true solo cuando valor == 1', () {
      const activo = ConfiguracionItem(
        id: 'c1',
        clave: 'x',
        valor: 1,
        tipo: 'boolean',
        descripcion: '',
        modulo: 'm',
        estatus: true,
      );
      const inactivo = ConfiguracionItem(
        id: 'c2',
        clave: 'x',
        valor: 0,
        tipo: 'boolean',
        descripcion: '',
        modulo: 'm',
        estatus: true,
      );

      expect(activo.valorBooleano, isTrue);
      expect(inactivo.valorBooleano, isFalse);
    });
  });

  group('ConfiguracionItem.tituloLegible', () {
    test('convierte snake_case a Title Case', () {
      const item = ConfiguracionItem(
        id: 'c1',
        clave: 'max_tags_secundarios_por_usuario',
        valor: 3,
        tipo: 'entero',
        descripcion: '',
        modulo: 'tags',
        estatus: true,
      );

      expect(item.tituloLegible, 'Max Tags Secundarios Por Usuario');
    });
  });

  group('ConfiguracionItem.copiarCon', () {
    test('cambia solo el campo indicado y preserva el resto', () {
      const original = ConfiguracionItem(
        id: 'c1',
        clave: 'x',
        valor: 1,
        tipo: 'boolean',
        descripcion: 'desc',
        modulo: 'm',
        estatus: true,
      );

      final conNuevoValor = original.copiarCon(valor: 0);
      expect(conNuevoValor.valor, 0);
      expect(conNuevoValor.estatus, isTrue);
      expect(conNuevoValor.id, 'c1');

      final conNuevoEstatus = original.copiarCon(estatus: false);
      expect(conNuevoEstatus.estatus, isFalse);
      expect(conNuevoEstatus.valor, 1);
    });
  });
}
