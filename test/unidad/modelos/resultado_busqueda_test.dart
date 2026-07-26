import 'package:flutter_test/flutter_test.dart';
import 'package:activiti/compartido/constantes.dart';
import 'package:activiti/funcionalidades/buscar_asistente/resultado_busqueda.dart';

void main() {
  // ── ResultadoBusqueda.desdeUsuario ────────────────────────────────────────

  group('ResultadoBusqueda.desdeUsuario', () {
    const filaBase = <String, dynamic>{
      'id': 'u-1',
      'primer_nombre': 'Leo',
      'primer_apellido': 'Alvarez',
      'url_avatar': null,
      'numero_identificacion': 'CI-123',
    };

    test('sin asistencia: nombre, iniciales y sin estatus', () {
      final r = ResultadoBusqueda.desdeUsuario(filaBase);
      expect(r.usuarioId, 'u-1');
      expect(r.nombre, 'Leo Alvarez');
      expect(r.iniciales, 'LA');
      expect(r.estatus, isNull);
      expect(r.esForaneo, false);
      expect(r.numeroIdentificacion, 'CI-123');
    });

    test('con asistencia: hereda estatus y asistenciaId', () {
      final r = ResultadoBusqueda.desdeUsuario(
        filaBase,
        asistencia: const {
          'id': 'a-1',
          'estatus': EstatusAsistencia.presente,
          'hora_entrada': null,
          'hora_salida': null,
          'entrada_registrada_por': null,
        },
      );
      expect(r.asistenciaId, 'a-1');
      expect(r.estatus, EstatusAsistencia.presente);
    });

    test('nombre vacío resulta en "Sin nombre"', () {
      final r = ResultadoBusqueda.desdeUsuario(const <String, dynamic>{
        'id': 'u-2',
        'primer_nombre': null,
        'primer_apellido': null,
        'url_avatar': null,
        'numero_identificacion': null,
      });
      expect(r.nombre, 'Sin nombre');
    });

    test('registradoPorNombre se mapea correctamente', () {
      final r = ResultadoBusqueda.desdeUsuario(
        filaBase,
        registradoPorNombre: 'Admin López',
      );
      expect(r.registradoPorNombre, 'Admin López');
    });
  });

  // ── ResultadoBusqueda.desdeForaneo ────────────────────────────────────────

  group('ResultadoBusqueda.desdeForaneo', () {
    test('mapea nombre y estatus de la fila foránea', () {
      final r = ResultadoBusqueda.desdeForaneo(const <String, dynamic>{
        'id': 'f-1',
        'visitante_primer_nombre': 'Juan',
        'visitante_primer_apellido': 'Perez',
        'estatus': EstatusAsistencia.presente,
        'hora_entrada': null,
      });
      expect(r.usuarioId, 'f-1');
      expect(r.nombre, 'Juan Perez');
      expect(r.iniciales, 'JP');
      expect(r.esForaneo, true);
    });

    test('nombre vacío en foráneo resulta en "Visitante"', () {
      final r = ResultadoBusqueda.desdeForaneo(const <String, dynamic>{
        'id': 'f-2',
        'visitante_primer_nombre': null,
        'visitante_primer_apellido': null,
        'estatus': EstatusAsistencia.presente,
        'hora_entrada': null,
      });
      expect(r.nombre, 'Visitante');
    });
  });

  // ── _iniciales ────────────────────────────────────────────────────────────

  group('ResultadoBusqueda._iniciales', () {
    String iniciales(String nombre) => ResultadoBusqueda.desdeUsuario(
        {'id': 'x', 'primer_nombre': nombre, 'primer_apellido': ''}).iniciales;

    test('dos palabras → primera letra de cada una en mayúsculas', () {
      final r = ResultadoBusqueda.desdeUsuario(const {
        'id': 'x',
        'primer_nombre': 'leo',
        'primer_apellido': 'gomez'
      });
      expect(r.iniciales, 'LG');
    });

    test('una palabra → primera letra en mayúscula', () {
      expect(iniciales('Ana'), 'A');
    });

    test('vacío → "?"', () {
      expect(iniciales(''), '?');
    });
  });

  // ── _parsearHora ──────────────────────────────────────────────────────────

  group('ResultadoBusqueda._parsearHora', () {
    test('null produce null', () {
      final r = ResultadoBusqueda.desdeUsuario(
        const {'id': 'u-1', 'primer_nombre': 'X', 'primer_apellido': 'Y'},
        asistencia: const {'estatus': 'presente', 'hora_entrada': null},
      );
      expect(r.horaEntrada, isNull);
    });

    test('ISO string se convierte a formato 12h AM/PM', () {
      // 14:30 UTC → "2:30 PM" en hora local (esto depende del timezone del test runner)
      final r = ResultadoBusqueda.desdeUsuario(
        const {'id': 'u-1', 'primer_nombre': 'X', 'primer_apellido': 'Y'},
        asistencia: const {
          'estatus': 'presente',
          'hora_entrada': '2025-03-15T14:30:00Z',
        },
      );
      // Solo verificamos que no es null y tiene el formato correcto (H:MM AM/PM)
      expect(r.horaEntrada, isNotNull);
      expect(r.horaEntrada, matches(RegExp(r'^\d{1,2}:\d{2} (AM|PM)$')));
    });
  });

  // ── Propiedades calculadas ────────────────────────────────────────────────

  group('ResultadoBusqueda propiedades calculadas', () {
    ResultadoBusqueda conEstatus(String? estatus) => ResultadoBusqueda(
          usuarioId: 'u-1',
          nombre: 'Test',
          iniciales: 'T',
          estatus: estatus,
        );

    test('estaActivo es true para presente, completado y salioAnticipado', () {
      expect(conEstatus(EstatusAsistencia.presente).estaActivo, true);
      expect(conEstatus(EstatusAsistencia.completado).estaActivo, true);
      expect(conEstatus(EstatusAsistencia.salioAnticipado).estaActivo, true);
    });

    test('estaActivo es false para otros estatuses', () {
      expect(conEstatus(EstatusAsistencia.esperado).estaActivo, false);
      expect(conEstatus(EstatusAsistencia.ausente).estaActivo, false);
      expect(conEstatus(null).estaActivo, false);
    });

    test('esEsperado es true solo para esperado', () {
      expect(conEstatus(EstatusAsistencia.esperado).esEsperado, true);
      expect(conEstatus(EstatusAsistencia.presente).esEsperado, false);
      expect(conEstatus(null).esEsperado, false);
    });

    test('esNoEsperado es true cuando no es foráneo y estatus es null', () {
      expect(conEstatus(null).esNoEsperado, true);
      expect(conEstatus(EstatusAsistencia.esperado).esNoEsperado, false);
    });

    test('esNoEsperado es false cuando es foráneo aunque estatus sea null', () {
      const r = ResultadoBusqueda(
        usuarioId: 'f-1',
        nombre: 'Visitante',
        iniciales: 'V',
        esForaneo: true,
      );
      expect(r.esNoEsperado, false);
    });
  });
}
