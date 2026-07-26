import 'package:flutter_test/flutter_test.dart';
import 'package:activiti/funcionalidades/auditoria_evento/auditoria_evento_modelo.dart';

// ─── Fixtures ────────────────────────────────────────────────────────────────

Map<String, dynamic> _jsonEvento({
  String id = 'ev-1',
  String titulo = 'Congreso',
  String estatus = 'en_curso',
  String? fechaInicio = '2024-05-10T08:00:00.000Z',
}) =>
    {
      'id': id,
      'titulo': titulo,
      'estatus': estatus,
      'fecha_inicio': fechaInicio,
      'hora_inicio': '08:00',
    };

Map<String, dynamic> _jsonRegistroUsuario({
  String id = 'reg-1',
  String usuarioId = 'user-1',
  String estatus = 'presente',
  String? horaEntrada,
  String? horaSalida,
}) =>
    {
      'id': id,
      'usuario_id': usuarioId,
      'estatus': estatus,
      'hora_entrada': horaEntrada,
      'hora_salida': horaSalida,
      'asistente': {
        'primer_nombre': 'Leo',
        'primer_apellido': 'Alvarez',
        'url_avatar': null,
        'numero_identificacion': '12345678',
      },
      'reg_entrada': null,
      'reg_salida': null,
      'motivo_salida_anticipada': null,
      'visitante_primer_nombre': null,
      'visitante_primer_apellido': null,
      'visitante_contacto': null,
      'visitante_numero_identificacion': null,
    };

Map<String, dynamic> _jsonRegistroForaneo({
  String id = 'reg-2',
  String nombre = 'Maria',
  String apellido = 'Lopez',
}) =>
    {
      'id': id,
      'usuario_id': null,
      'estatus': 'esperado',
      'hora_entrada': null,
      'hora_salida': null,
      'asistente': null,
      'reg_entrada': null,
      'reg_salida': null,
      'motivo_salida_anticipada': null,
      'visitante_primer_nombre': nombre,
      'visitante_primer_apellido': apellido,
      'visitante_contacto': '+58123456789',
      'visitante_numero_identificacion': '87654321',
    };

RegistroAuditoria _registroConEstatus(String estatus,
        {bool esForaneo = false}) =>
    RegistroAuditoria(
      id: 'reg-$estatus',
      nombre: 'Test',
      iniciales: 'T',
      estatus: estatus,
      esForaneo: esForaneo,
      horaEntrada: '',
      horaSalida: '',
    );

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  // ── EventoParaAuditoria ──────────────────────────────────────────────────

  group('EventoParaAuditoria.desdeJson', () {
    test('parsea todos los campos correctamente', () {
      final e = EventoParaAuditoria.desdeJson(_jsonEvento());
      expect(e.id, 'ev-1');
      expect(e.titulo, 'Congreso');
      expect(e.estatus, 'en_curso');
      expect(e.fechaInicio, isNotNull);
    });

    test('fechaInicio es null cuando falta el campo', () {
      final e = EventoParaAuditoria.desdeJson(_jsonEvento(fechaInicio: null));
      expect(e.fechaInicio, isNull);
    });

    test('fechaInicio es null cuando la fecha es inválida', () {
      final e = EventoParaAuditoria.desdeJson(
        _jsonEvento(fechaInicio: 'not-a-date'),
      );
      expect(e.fechaInicio, isNull);
    });

    test('usa cadena vacía para campos faltantes', () {
      final e = EventoParaAuditoria.desdeJson({});
      expect(e.id, isEmpty);
      expect(e.titulo, isEmpty);
      expect(e.estatus, isEmpty);
    });
  });

  group('EventoParaAuditoria.etiquetaEstatus', () {
    test(
        'en_curso → "En curso"',
        () => expect(
            EventoParaAuditoria.desdeJson(_jsonEvento(estatus: 'en_curso'))
                .etiquetaEstatus,
            'En curso'));
    test(
        'programado → "Programado"',
        () => expect(
            EventoParaAuditoria.desdeJson(_jsonEvento(estatus: 'programado'))
                .etiquetaEstatus,
            'Programado'));
    test(
        'finalizado → "Finalizado"',
        () => expect(
            EventoParaAuditoria.desdeJson(_jsonEvento(estatus: 'finalizado'))
                .etiquetaEstatus,
            'Finalizado'));
    test(
        'cancelado → "Cancelado"',
        () => expect(
            EventoParaAuditoria.desdeJson(_jsonEvento(estatus: 'cancelado'))
                .etiquetaEstatus,
            'Cancelado'));
    test(
        'borrador → "Borrador"',
        () => expect(
            EventoParaAuditoria.desdeJson(_jsonEvento(estatus: 'borrador'))
                .etiquetaEstatus,
            'Borrador'));
    test(
        'desconocido → raw',
        () => expect(
            EventoParaAuditoria.desdeJson(_jsonEvento(estatus: 'foo'))
                .etiquetaEstatus,
            'foo'));
  });

  group('EventoParaAuditoria.fechaFormateada', () {
    test('retorna "Sin fecha" cuando fechaInicio es null', () {
      final e = EventoParaAuditoria.desdeJson(_jsonEvento(fechaInicio: null));
      expect(e.fechaFormateada, 'Sin fecha');
    });

    test('retorna formato "D de mes, AAAA"', () {
      // 2024-05-10 → "10 de mayo, 2024"
      final e = EventoParaAuditoria.desdeJson(
        _jsonEvento(fechaInicio: '2024-05-10T00:00:00.000Z'),
      );
      expect(e.fechaFormateada, contains('mayo'));
      expect(e.fechaFormateada, contains('2024'));
    });
  });

  // ── RegistroAuditoria ────────────────────────────────────────────────────

  group('RegistroAuditoria.desdeJson — usuario registrado', () {
    test('nombre se construye de primer_nombre + primer_apellido', () {
      final r = RegistroAuditoria.desdeJson(_jsonRegistroUsuario());
      expect(r.nombre, 'Leo Alvarez');
    });

    test('iniciales son LA para Leo Alvarez', () {
      final r = RegistroAuditoria.desdeJson(_jsonRegistroUsuario());
      expect(r.iniciales, 'LA');
    });

    test('esForaneo es false cuando usuario_id no es null', () {
      final r = RegistroAuditoria.desdeJson(_jsonRegistroUsuario());
      expect(r.esForaneo, isFalse);
    });

    test('horaEntrada es cadena vacía cuando hora_entrada es null', () {
      final r = RegistroAuditoria.desdeJson(_jsonRegistroUsuario());
      expect(r.horaEntrada, isEmpty);
    });

    test('horaEntrada tiene formato AM/PM cuando hora_entrada es ISO válido',
        () {
      final r = RegistroAuditoria.desdeJson(
        _jsonRegistroUsuario(horaEntrada: '2024-05-10T14:30:00.000Z'),
      );
      expect(r.horaEntrada, anyOf(contains('AM'), contains('PM')));
    });

    test('estatus se mapea correctamente', () {
      final r = RegistroAuditoria.desdeJson(
          _jsonRegistroUsuario(estatus: 'completado'));
      expect(r.estatus, 'completado');
    });

    test('nombre es "Sin nombre" cuando asistente no tiene datos', () {
      final json = _jsonRegistroUsuario();
      (json['asistente'] as Map<String, dynamic>)['primer_nombre'] = '';
      (json['asistente'] as Map<String, dynamic>)['primer_apellido'] = '';
      final r = RegistroAuditoria.desdeJson(json);
      expect(r.nombre, 'Sin nombre');
    });
  });

  group('RegistroAuditoria.desdeJson — foráneo', () {
    test('esForaneo es true cuando usuario_id es null', () {
      final r = RegistroAuditoria.desdeJson(_jsonRegistroForaneo());
      expect(r.esForaneo, isTrue);
    });

    test('nombre se construye de visitante_primer_nombre + apellido', () {
      final r = RegistroAuditoria.desdeJson(_jsonRegistroForaneo());
      expect(r.nombre, 'Maria Lopez');
    });

    test('iniciales son ML para Maria Lopez', () {
      final r = RegistroAuditoria.desdeJson(_jsonRegistroForaneo());
      expect(r.iniciales, 'ML');
    });
  });

  group('RegistroAuditoria.haEntrado', () {
    test('true para "presente"',
        () => expect(_registroConEstatus('presente').haEntrado, isTrue));
    test('true para "completado"',
        () => expect(_registroConEstatus('completado').haEntrado, isTrue));
    test(
        'true para "salio_anticipado"',
        () =>
            expect(_registroConEstatus('salio_anticipado').haEntrado, isTrue));
    test('false para "ausente"',
        () => expect(_registroConEstatus('ausente').haEntrado, isFalse));
    test('false para "esperado"',
        () => expect(_registroConEstatus('esperado').haEntrado, isFalse));
    test('false para "anulado"',
        () => expect(_registroConEstatus('anulado').haEntrado, isFalse));
  });

  group('RegistroAuditoria.etiquetaEstatus', () {
    test(
        'presente → "Presente"',
        () => expect(
            _registroConEstatus('presente').etiquetaEstatus, 'Presente'));
    test(
        'completado → "Completado"',
        () => expect(
            _registroConEstatus('completado').etiquetaEstatus, 'Completado'));
    test(
        'ausente → "Ausente"',
        () =>
            expect(_registroConEstatus('ausente').etiquetaEstatus, 'Ausente'));
    test(
        'esperado → "Esperado"',
        () => expect(
            _registroConEstatus('esperado').etiquetaEstatus, 'Esperado'));
    test(
        'salio_anticipado → "Anticipado"',
        () => expect(_registroConEstatus('salio_anticipado').etiquetaEstatus,
            'Anticipado'));
    test(
        'anulado → "Anulado"',
        () =>
            expect(_registroConEstatus('anulado').etiquetaEstatus, 'Anulado'));
    test('desconocido → raw',
        () => expect(_registroConEstatus('foo').etiquetaEstatus, 'foo'));
  });

  // ── ResumenAuditoria.calcular ────────────────────────────────────────────

  group('ResumenAuditoria.calcular', () {
    test('lista vacía retorna todo en cero', () {
      final r = ResumenAuditoria.calcular([]);
      expect(r.totalRegistros, 0);
      expect(r.haEntrado, 0);
      expect(r.tasaAsistencia, 0.0);
      expect(r.timelineEntradas, isEmpty);
      expect(r.registradores, isEmpty);
    });

    test('cuenta totalRegistros correctamente', () {
      final registros = [
        _registroConEstatus('presente'),
        _registroConEstatus('ausente'),
        _registroConEstatus('esperado'),
      ];
      expect(ResumenAuditoria.calcular(registros).totalRegistros, 3);
    });

    test('cuenta haEntrado solo para presente/completado/salio_anticipado', () {
      final registros = [
        _registroConEstatus('presente'),
        _registroConEstatus('completado'),
        _registroConEstatus('salio_anticipado'),
        _registroConEstatus('ausente'),
        _registroConEstatus('esperado'),
      ];
      final r = ResumenAuditoria.calcular(registros);
      expect(r.haEntrado, 3);
    });

    test('tasaAsistencia es porcentaje correcto', () {
      final registros = [
        _registroConEstatus('presente'),
        _registroConEstatus('ausente'),
      ];
      final r = ResumenAuditoria.calcular(registros);
      expect(r.tasaAsistencia, closeTo(50.0, 0.001));
    });

    test('foraneos cuenta solo registros con esForaneo true', () {
      final registros = [
        _registroConEstatus('presente', esForaneo: true),
        _registroConEstatus('presente', esForaneo: false),
        _registroConEstatus('esperado', esForaneo: true),
      ];
      expect(ResumenAuditoria.calcular(registros).foraneos, 2);
    });

    test('timeline agrupa entradas por hora', () {
      final registros = [
        const RegistroAuditoria(
          id: '1',
          nombre: 'A',
          iniciales: 'A',
          estatus: 'presente',
          esForaneo: false,
          horaEntrada: '',
          horaSalida: '',
          horaEntradaHora: 10,
        ),
        const RegistroAuditoria(
          id: '2',
          nombre: 'B',
          iniciales: 'B',
          estatus: 'presente',
          esForaneo: false,
          horaEntrada: '',
          horaSalida: '',
          horaEntradaHora: 10,
        ),
        const RegistroAuditoria(
          id: '3',
          nombre: 'C',
          iniciales: 'C',
          estatus: 'presente',
          esForaneo: false,
          horaEntrada: '',
          horaSalida: '',
          horaEntradaHora: 14,
        ),
      ];
      final r = ResumenAuditoria.calcular(registros);
      expect(r.timelineEntradas.length, 2);
      expect(r.timelineEntradas.first.hora, 10);
      expect(r.timelineEntradas.first.cantidad, 2);
      expect(r.timelineEntradas.last.hora, 14);
      expect(r.timelineEntradas.last.cantidad, 1);
    });

    test('registradores se ordenan por mayor cantidad de entradas', () {
      final registros = [
        const RegistroAuditoria(
          id: '1',
          nombre: 'A',
          iniciales: 'A',
          estatus: 'presente',
          esForaneo: false,
          horaEntrada: '',
          horaSalida: '',
          registradoPorNombre: 'Ana',
        ),
        const RegistroAuditoria(
          id: '2',
          nombre: 'B',
          iniciales: 'B',
          estatus: 'presente',
          esForaneo: false,
          horaEntrada: '',
          horaSalida: '',
          registradoPorNombre: 'Ana',
        ),
        const RegistroAuditoria(
          id: '3',
          nombre: 'C',
          iniciales: 'C',
          estatus: 'presente',
          esForaneo: false,
          horaEntrada: '',
          horaSalida: '',
          registradoPorNombre: 'Bob',
        ),
      ];
      final r = ResumenAuditoria.calcular(registros);
      expect(r.registradores.first.nombre, 'Ana');
      expect(r.registradores.first.entradas, 2);
      expect(r.registradores.last.nombre, 'Bob');
    });
  });

  group('DatoRegistrador.porcentaje', () {
    test('retorna 0 cuando total es 0', () {
      const d = DatoRegistrador(nombre: 'Ana', entradas: 5);
      expect(d.porcentaje(0), 0.0);
    });

    test('retorna porcentaje correcto', () {
      const d = DatoRegistrador(nombre: 'Ana', entradas: 3);
      expect(d.porcentaje(10), closeTo(30.0, 0.001));
    });
  });
}
