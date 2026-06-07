import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniasist/funcionalidades/estadisticas/estadisticas_modelo.dart';
import 'package:uniasist/funcionalidades/estadisticas/filtros_estadisticas.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

FiltrosEstadisticas _filtroConDuracion(int dias) {
  final ahora = DateTime(2025, 6, 15);
  return FiltrosEstadisticas(
    rango: DateTimeRange(
      start: ahora.subtract(Duration(days: dias)),
      end: ahora,
    ),
  );
}

FiltrosEstadisticas _filtroConOpciones({
  List<OpcionFiltro> tipos = const [],
  List<OpcionFiltro> creadores = const [],
  List<OpcionFiltro> tags = const [],
}) {
  final ahora = DateTime(2025, 6, 15);
  return FiltrosEstadisticas(
    rango: DateTimeRange(
      start: ahora.subtract(const Duration(days: 30)),
      end: ahora,
    ),
    tiposSeleccionados: tipos,
    creadoresSeleccionados: creadores,
    tagsSeleccionados: tags,
  );
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // ── etiquetaRango ─────────────────────────────────────────────────────────

  group('FiltrosEstadisticas.etiquetaRango', () {
    test('≤ 8 días → "Últimos 7 días"', () {
      expect(_filtroConDuracion(7).etiquetaRango, 'Últimos 7 días');
    });

    test('8 días exactos → "Últimos 7 días"', () {
      expect(_filtroConDuracion(8).etiquetaRango, 'Últimos 7 días');
    });

    test('31 días → "Últimos 30 días"', () {
      expect(_filtroConDuracion(31).etiquetaRango, 'Últimos 30 días');
    });

    test('30 días → "Últimos 30 días"', () {
      expect(_filtroConDuracion(30).etiquetaRango, 'Últimos 30 días');
    });

    test('90 días → "Últimos 90 días"', () {
      expect(_filtroConDuracion(90).etiquetaRango, 'Últimos 90 días');
    });

    test('año completo desde 1 enero → "Año XXXX"', () {
      const anio = 2024;
      final filtro = FiltrosEstadisticas(
        rango: DateTimeRange(
          start: DateTime(anio),
          end: DateTime(anio, 12, 31),
        ),
      );
      expect(filtro.etiquetaRango, 'Año $anio');
    });

    test('rango personalizado largo → "d/m/yyyy – d/m/yyyy"', () {
      final filtro = FiltrosEstadisticas(
        rango: DateTimeRange(
          start: DateTime(2024, 3, 5),
          end: DateTime(2025, 6, 15),
        ),
      );
      expect(filtro.etiquetaRango, '5/3/2024 – 15/6/2025');
    });
  });

  // ── tieneFiltrosActivos ───────────────────────────────────────────────────

  group('FiltrosEstadisticas.tieneFiltrosActivos', () {
    test('sin filtros → false', () {
      expect(_filtroConOpciones().tieneFiltrosActivos, false);
    });

    test('con tipo seleccionado → true', () {
      const opcion = OpcionFiltro(id: 'tipo-1', nombre: 'Conferencia');
      expect(_filtroConOpciones(tipos: [opcion]).tieneFiltrosActivos, true);
    });

    test('con creador seleccionado → true', () {
      const opcion = OpcionFiltro(id: 'u-1', nombre: 'Leo');
      expect(_filtroConOpciones(creadores: [opcion]).tieneFiltrosActivos, true);
    });

    test('con tag seleccionado → true', () {
      const opcion = OpcionFiltro(id: 'tag-1', nombre: 'Ing');
      expect(_filtroConOpciones(tags: [opcion]).tieneFiltrosActivos, true);
    });
  });

  // ── totalFiltrosActivos ───────────────────────────────────────────────────

  group('FiltrosEstadisticas.totalFiltrosActivos', () {
    test('sin filtros → 0', () {
      expect(_filtroConOpciones().totalFiltrosActivos, 0);
    });

    test('suma tipos + creadores + tags', () {
      const t = OpcionFiltro(id: 't', nombre: 'T');
      final filtro = _filtroConOpciones(
        tipos: [t],
        creadores: [t, t],
        tags: [t],
      );
      expect(filtro.totalFiltrosActivos, 4);
    });
  });

  // ── tipoIds / creadorIds / tagIds ─────────────────────────────────────────

  group('FiltrosEstadisticas getters de IDs', () {
    test('tipoIds extrae los IDs de tiposSeleccionados', () {
      final filtro = _filtroConOpciones(
        tipos: [
          const OpcionFiltro(id: 'tipo-1', nombre: 'A'),
          const OpcionFiltro(id: 'tipo-2', nombre: 'B'),
        ],
      );
      expect(filtro.tipoIds, ['tipo-1', 'tipo-2']);
    });

    test('creadorIds extrae los IDs de creadoresSeleccionados', () {
      final filtro = _filtroConOpciones(
        creadores: [const OpcionFiltro(id: 'u-5', nombre: 'Leo')],
      );
      expect(filtro.creadorIds, ['u-5']);
    });

    test('tagIds extrae los IDs de tagsSeleccionados', () {
      final filtro = _filtroConOpciones(
        tags: [const OpcionFiltro(id: 'tag-9', nombre: 'Ing')],
      );
      expect(filtro.tagIds, ['tag-9']);
    });
  });

  // ── sinFiltros ────────────────────────────────────────────────────────────

  group('FiltrosEstadisticas.sinFiltros', () {
    test('limpia todas las listas pero conserva el rango', () {
      const opcion = OpcionFiltro(id: 'x', nombre: 'X');
      final original = _filtroConOpciones(
        tipos: [opcion],
        creadores: [opcion],
        tags: [opcion],
      );
      final limpio = original.sinFiltros();
      expect(limpio.tieneFiltrosActivos, false);
      expect(limpio.rango, original.rango);
    });
  });

  // ── copyWith ──────────────────────────────────────────────────────────────

  group('FiltrosEstadisticas.copyWith', () {
    test('rango null preserva el rango original', () {
      final original = _filtroConDuracion(30);
      final copia = original.copyWith();
      expect(copia.rango, original.rango);
    });

    test('nuevo rango reemplaza el original', () {
      final original = _filtroConDuracion(30);
      final nuevoRango = DateTimeRange(
        start: DateTime(2025, 1, 1),
        end: DateTime(2025, 1, 31),
      );
      final copia = original.copyWith(rango: nuevoRango);
      expect(copia.rango, nuevoRango);
    });
  });

  // ── porDefecto ────────────────────────────────────────────────────────────

  group('FiltrosEstadisticas.porDefecto', () {
    test('genera rango terminado en hoy con inicio aprox un mes antes', () {
      final filtro = FiltrosEstadisticas.porDefecto();
      final ahora = DateTime.now();
      // El rango termina hoy o muy cerca
      expect(filtro.rango.end.day, ahora.day);
      // Sin filtros activos
      expect(filtro.tieneFiltrosActivos, false);
    });
  });
}
