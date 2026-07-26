import 'package:flutter_test/flutter_test.dart';
import 'package:activiti/funcionalidades/eventos/evento.dart';

void main() {
  // ── Evento.desdeJson ──────────────────────────────────────────────────────

  group('Evento.desdeJson', () {
    test('mapea todos los campos presentes correctamente', () {
      final evento = Evento.desdeJson(const <String, dynamic>{
        'id': 'ev-1',
        'titulo': 'Gran Conferencia',
        'descripcion': 'Descripción detallada',
        'lugar': 'Auditorio A',
        'tipo_evento_id': 'tipo-1',
        'fecha_inicio': '2025-03-15',
        'fecha_fin': '2025-03-16',
        'hora_inicio': '09:00',
        'hora_fin': '18:00',
        'modo_registro': 'auto',
        'estatus': 'programado',
        'alcance': 'general',
        'creado_por': 'user-1',
        'creado_en': '2025-01-01T00:00:00Z',
        'actualizado_en': '2025-01-02T00:00:00Z',
        'permite_qr_evento': false,
        'permite_qr_usuario': false,
        'permite_manual_admin': false,
        'requiere_ciclo_completo': true,
        'permite_salida_anticipada': true,
        'marcar_ausentes_auto': true,
        'permite_foraneos': true,
      });
      expect(evento.id, 'ev-1');
      expect(evento.titulo, 'Gran Conferencia');
      expect(evento.descripcion, 'Descripción detallada');
      expect(evento.lugar, 'Auditorio A');
      expect(evento.tipoEventoId, 'tipo-1');
      expect(evento.fechaInicio, DateTime(2025, 3, 15));
      expect(evento.fechaFin, DateTime(2025, 3, 16));
      expect(evento.horaInicio, '09:00');
      expect(evento.horaFin, '18:00');
      expect(evento.modoRegistro, 'auto');
      expect(evento.estatus, 'programado');
      expect(evento.alcance, 'general');
      expect(evento.creadoPor, 'user-1');
      expect(evento.permiteQrEvento, false);
      expect(evento.permiteQrUsuario, false);
      expect(evento.permiteManualAdmin, false);
      expect(evento.requiereCicloCompleto, true);
      expect(evento.permiteSalidaAnticipada, true);
      expect(evento.marcarAusentesAuto, true);
      expect(evento.permiteForaneos, true);
    });

    test('campos opcionales ausentes resultan en null', () {
      final evento = Evento.desdeJson(const <String, dynamic>{
        'id': 'ev-2',
        'titulo': 'Sin campos opcionales',
        'modo_registro': 'auto',
        'estatus': 'en_curso',
        'creado_en': '2025-01-01T00:00:00Z',
        'actualizado_en': '2025-01-01T00:00:00Z',
        'permite_qr_evento': true,
        'permite_qr_usuario': true,
        'permite_manual_admin': true,
        'requiere_ciclo_completo': false,
        'permite_salida_anticipada': false,
        'marcar_ausentes_auto': false,
        'permite_foraneos': false,
      });
      expect(evento.descripcion, isNull);
      expect(evento.lugar, isNull);
      expect(evento.tipoEventoId, isNull);
      expect(evento.fechaInicio, isNull);
      expect(evento.fechaFin, isNull);
      expect(evento.horaInicio, isNull);
      expect(evento.horaFin, isNull);
      expect(evento.creadoPor, isNull);
    });

    test('booleans ausentes usan valores por defecto correctos', () {
      final evento = Evento.desdeJson(const <String, dynamic>{
        'id': 'ev-3',
        'titulo': 'Defaults',
        'modo_registro': 'auto',
        'estatus': 'programado',
        'creado_en': '2025-01-01T00:00:00Z',
        'actualizado_en': '2025-01-01T00:00:00Z',
      });
      expect(evento.permiteQrEvento, true);
      expect(evento.permiteQrUsuario, true);
      expect(evento.permiteManualAdmin, true);
      expect(evento.requiereCicloCompleto, false);
      expect(evento.permiteSalidaAnticipada, false);
      expect(evento.marcarAusentesAuto, false);
      expect(evento.permiteForaneos, false);
    });

    test('alcance ausente usa general por defecto', () {
      final evento = Evento.desdeJson(const <String, dynamic>{
        'id': 'ev-4',
        'titulo': 'Sin alcance',
        'modo_registro': 'auto',
        'estatus': 'programado',
        'creado_en': '2025-01-01T00:00:00Z',
        'actualizado_en': '2025-01-01T00:00:00Z',
      });
      expect(evento.alcance, 'general');
    });
  });

  // ── Evento.aJson / _formatearFecha ────────────────────────────────────────

  group('Evento.aJson', () {
    test('serializa campos booleanos correctamente', () {
      final evento = Evento(
        id: 'ev-1',
        titulo: 'Test',
        modoRegistro: 'auto',
        estatus: 'programado',
        creadoEn: DateTime.utc(2025),
        actualizadoEn: DateTime.utc(2025),
        permiteQrEvento: true,
        permiteQrUsuario: false,
        permiteManualAdmin: true,
        requiereCicloCompleto: false,
        permiteSalidaAnticipada: true,
        marcarAusentesAuto: false,
        permiteForaneos: false,
      );
      final json = evento.aJson();
      expect(json['titulo'], 'Test');
      expect(json['permite_qr_evento'], true);
      expect(json['permite_qr_usuario'], false);
      expect(json['permite_manual_admin'], true);
      expect(json['requiere_ciclo_completo'], false);
      expect(json['permite_salida_anticipada'], true);
      expect(json['marcar_ausentes_auto'], false);
      expect(json['permite_foraneos'], false);
    });

    test('_formatearFecha produce yyyy-MM-dd con padding correcto', () {
      final evento = Evento.desdeJson(const <String, dynamic>{
        'id': 'x',
        'titulo': 'x',
        'modo_registro': 'auto',
        'estatus': 'programado',
        'fecha_inicio': '2025-01-05',
        'fecha_fin': '2025-12-31',
        'creado_en': '2025-01-01T00:00:00Z',
        'actualizado_en': '2025-01-01T00:00:00Z',
      });
      final json = evento.aJson();
      expect(json['fecha_inicio'], '2025-01-05');
      expect(json['fecha_fin'], '2025-12-31');
    });

    test('fechas null producen null en el json', () {
      final evento = Evento(
        id: 'x',
        titulo: 'x',
        modoRegistro: 'auto',
        estatus: 'programado',
        creadoEn: DateTime.utc(2025),
        actualizadoEn: DateTime.utc(2025),
        permiteQrEvento: true,
        permiteQrUsuario: true,
        permiteManualAdmin: true,
        requiereCicloCompleto: false,
        permiteSalidaAnticipada: false,
        marcarAusentesAuto: false,
        permiteForaneos: false,
      );
      final json = evento.aJson();
      expect(json['fecha_inicio'], isNull);
      expect(json['fecha_fin'], isNull);
    });
  });

  // ── EventoConGrupos._construirGrupos ──────────────────────────────────────

  group('EventoConGrupos._construirGrupos', () {
    Map<String, dynamic> baseJson({
      String alcance = 'general',
      List<Map<String, dynamic>> grupos = const [],
    }) =>
        {
          'id': 'ev-1',
          'titulo': 'T',
          'modo_registro': 'auto',
          'estatus': 'programado',
          'alcance': alcance,
          'creado_en': '2025-01-01T00:00:00Z',
          'actualizado_en': '2025-01-01T00:00:00Z',
          'permite_qr_evento': true,
          'permite_qr_usuario': true,
          'permite_manual_admin': true,
          'requiere_ciclo_completo': false,
          'permite_salida_anticipada': false,
          'marcar_ausentes_auto': false,
          'permite_foraneos': false,
          'evento_grupos_tags': grupos,
        };

    test('sin filas de grupos produce lista vacía', () {
      final ecg = EventoConGrupos.desdeJson(baseJson());
      expect(ecg.grupos, isEmpty);
    });

    test('grupo con solo tag principal se construye correctamente', () {
      final ecg = EventoConGrupos.desdeJson(
        baseJson(
          alcance: 'dirigido',
          grupos: [
            {
              'grupo_index': 0,
              'tag_id': 'tp-1',
              'tags': {'tipo': 'principal', 'nombre': 'Ing'}
            },
          ],
        ),
      );
      expect(ecg.grupos.length, 1);
      expect(ecg.grupos[0].tagPrincipalId, 'tp-1');
      expect(ecg.grupos[0].tagsSecundariosIds, isEmpty);
    });

    test('grupo con principal y secundarios se construye correctamente', () {
      final ecg = EventoConGrupos.desdeJson(
        baseJson(
          alcance: 'dirigido',
          grupos: [
            {
              'grupo_index': 0,
              'tag_id': 'tp-1',
              'tags': {'tipo': 'principal', 'nombre': 'Ing'}
            },
            {
              'grupo_index': 0,
              'tag_id': 'ts-1',
              'tags': {'tipo': 'secundario', 'nombre': 'Sis'}
            },
            {
              'grupo_index': 0,
              'tag_id': 'ts-2',
              'tags': {'tipo': 'secundario', 'nombre': 'Redes'}
            },
          ],
        ),
      );
      expect(ecg.grupos[0].tagsSecundariosIds, containsAll(['ts-1', 'ts-2']));
    });

    test('dos grupos independientes se construyen por separado', () {
      final ecg = EventoConGrupos.desdeJson(
        baseJson(
          alcance: 'dirigido',
          grupos: [
            {
              'grupo_index': 0,
              'tag_id': 'tp-1',
              'tags': {'tipo': 'principal', 'nombre': 'A'}
            },
            {
              'grupo_index': 1,
              'tag_id': 'tp-2',
              'tags': {'tipo': 'principal', 'nombre': 'B'}
            },
          ],
        ),
      );
      expect(ecg.grupos.length, 2);
    });

    test('nombresParaBusqueda agrega todos los nombres de todos los grupos',
        () {
      final ecg = EventoConGrupos.desdeJson(
        baseJson(
          alcance: 'dirigido',
          grupos: [
            {
              'grupo_index': 0,
              'tag_id': 'tp-1',
              'tags': {'tipo': 'principal', 'nombre': 'Ingeniería'}
            },
            {
              'grupo_index': 0,
              'tag_id': 'ts-1',
              'tags': {'tipo': 'secundario', 'nombre': 'Sistemas'}
            },
          ],
        ),
      );
      expect(ecg.nombresParaBusqueda, containsAll(['Ingeniería', 'Sistemas']));
    });

    test('esGeneral es true cuando alcance es general', () {
      final ecg = EventoConGrupos.desdeJson(baseJson());
      expect(ecg.esGeneral, isTrue);
    });

    test('esGeneral es false cuando alcance es dirigido', () {
      final ecg = EventoConGrupos.desdeJson(baseJson(alcance: 'dirigido'));
      expect(ecg.esGeneral, isFalse);
    });

    test('copiarConPresentes preserva evento y grupos', () {
      final ecg = EventoConGrupos.desdeJson(baseJson());
      final copia = ecg.copiarConPresentes(42);
      expect(copia.totalPresentes, 42);
      expect(copia.evento.id, ecg.evento.id);
    });
  });
}
