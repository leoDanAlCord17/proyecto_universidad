import 'package:flutter/material.dart';

import 'estadisticas_modelo.dart';

class FiltrosEstadisticas {
  const FiltrosEstadisticas({
    required this.rango,
    this.tiposSeleccionados = const [],
    this.creadoresSeleccionados = const [],
    this.tagsSeleccionados = const [],
  });

  final DateTimeRange rango;
  final List<OpcionFiltro> tiposSeleccionados;
  final List<OpcionFiltro> creadoresSeleccionados;
  final List<OpcionFiltro> tagsSeleccionados;

  List<String> get tipoIds => tiposSeleccionados.map((o) => o.id).toList();
  List<String> get creadorIds =>
      creadoresSeleccionados.map((o) => o.id).toList();
  List<String> get tagIds => tagsSeleccionados.map((o) => o.id).toList();

  bool get tieneFiltrosActivos =>
      tiposSeleccionados.isNotEmpty ||
      creadoresSeleccionados.isNotEmpty ||
      tagsSeleccionados.isNotEmpty;

  int get totalFiltrosActivos =>
      tiposSeleccionados.length +
      creadoresSeleccionados.length +
      tagsSeleccionados.length;

  static FiltrosEstadisticas porDefecto() {
    final ahora = DateTime.now();
    return FiltrosEstadisticas(
      rango: DateTimeRange(
        start: DateTime(ahora.year, ahora.month - 1, ahora.day),
        end: ahora,
      ),
    );
  }

  FiltrosEstadisticas copyWith({
    DateTimeRange? rango,
    List<OpcionFiltro>? tiposSeleccionados,
    List<OpcionFiltro>? creadoresSeleccionados,
    List<OpcionFiltro>? tagsSeleccionados,
  }) =>
      FiltrosEstadisticas(
        rango: rango ?? this.rango,
        tiposSeleccionados: tiposSeleccionados ?? this.tiposSeleccionados,
        creadoresSeleccionados:
            creadoresSeleccionados ?? this.creadoresSeleccionados,
        tagsSeleccionados: tagsSeleccionados ?? this.tagsSeleccionados,
      );

  FiltrosEstadisticas sinFiltros() => FiltrosEstadisticas(rango: rango);

  String get etiquetaRango {
    final inicio = rango.start;
    final fin = rango.end;
    final duracion = fin.difference(inicio).inDays;
    if (duracion <= 8) return 'Últimos 7 días';
    if (duracion <= 31) return 'Últimos 30 días';
    if (duracion <= 92) return 'Últimos 90 días';
    if (inicio.year == fin.year && inicio.month == 1 && inicio.day == 1) {
      return 'Año ${inicio.year}';
    }
    return '${_fmt(inicio)} – ${_fmt(fin)}';
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
