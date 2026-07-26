import 'dart:math' show max;

import 'package:flutter/material.dart';

import '../../../configuracion/colores_app.dart';
import '../estadisticas_modelo.dart';
import 'estilos_estadisticas.dart';

class SeccionPorCreador extends StatelessWidget {
  const SeccionPorCreador({required this.porCreador, required this.onTap});
  final List<DatoCreador> porCreador;
  final ValueChanged<DatoCreador> onTap;

  @override
  Widget build(BuildContext context) {
    if (porCreador.isEmpty) return const SizedBox.shrink();
    final maxCant = porCreador.map((d) => d.cantidad.toDouble()).reduce(max);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColoresApp.superficiePrimaria,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: ColoresApp.sombraTarjeta,
              blurRadius: 8,
              offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Eventos por organizador',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 2),
          Text(
            'Toca un nombre para ver sus eventos',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: ColoresApp.textoTerciario),
          ),
          const SizedBox(height: 16),
          ...porCreador.map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _FilaCreador(
                  dato: d, maxCant: maxCant, onTap: () => onTap(d)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaCreador extends StatelessWidget {
  const _FilaCreador(
      {required this.dato, required this.maxCant, required this.onTap});
  final DatoCreador dato;
  final double maxCant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pctEventos = maxCant == 0 ? 0.0 : dato.cantidad / maxCant;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      dato.nombre,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: ColoresApp.textoPrimario,
                            fontSize: 13,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${dato.cantidad} eventos · ${dato.presentes} presentes',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: ColoresApp.textoTerciario,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pctEventos,
                  backgroundColor: ColoresApp.acentoClaro,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(ColoresApp.acento),
                  minHeight: 7,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Top asistentes ───────────────────────────────────────────────────────────

class SeccionTopAsistentes extends StatelessWidget {
  const SeccionTopAsistentes({required this.datos});
  final List<AsistenteFrecuente> datos;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColoresApp.superficiePrimaria,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: ColoresApp.sombraTarjeta,
              blurRadius: 8,
              offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Asistentes más frecuentes',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 2),
          Text(
            'Usuarios con mayor presencia en eventos',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: ColoresApp.textoTerciario),
          ),
          const SizedBox(height: 16),
          ...datos.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _FilaAsistente(puesto: e.key + 1, dato: e.value),
                ),
              ),
        ],
      ),
    );
  }
}

class _FilaAsistente extends StatelessWidget {
  const _FilaAsistente({required this.puesto, required this.dato});
  final int puesto;
  final AsistenteFrecuente dato;

  @override
  Widget build(BuildContext context) {
    final color = colorTasa(dato.tasa);
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: puesto <= 3
                ? ColoresApp.acentoClaro
                : ColoresApp.superficieTerciar,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$puesto',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color:
                    puesto <= 3 ? ColoresApp.acento : ColoresApp.textoTerciario,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      dato.nombre,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${dato.tasa.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  const Icon(Icons.event_outlined,
                      size: 11, color: ColoresApp.textoTerciario),
                  const SizedBox(width: 3),
                  Text(
                    '${dato.totalAsistencias} asistencias en ${dato.totalEventos} eventos',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ColoresApp.textoTerciario,
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Top tags ─────────────────────────────────────────────────────────────────

class SeccionTopTags extends StatelessWidget {
  const SeccionTopTags({required this.datos, required this.onTap});
  final List<DatoTag> datos;
  final ValueChanged<DatoGrafica> onTap;

  @override
  Widget build(BuildContext context) {
    final maxCant = datos.map((d) => d.cantidad.toDouble()).reduce(max);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColoresApp.superficiePrimaria,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: ColoresApp.sombraTarjeta,
              blurRadius: 8,
              offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tags más usados',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 2),
          Text(
            'Etiquetas por cantidad de eventos y tasa de asistencia',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: ColoresApp.textoTerciario),
          ),
          const SizedBox(height: 16),
          ...datos.map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _FilaTag(
                dato: d,
                maxCant: maxCant,
                onTap: () => onTap(
                  DatoGrafica(etiqueta: d.nombre, valor: d.cantidad.toDouble()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaTag extends StatelessWidget {
  const _FilaTag(
      {required this.dato, required this.maxCant, required this.onTap});
  final DatoTag dato;
  final double maxCant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pct = maxCant == 0 ? 0.0 : dato.cantidad / maxCant;
    final color = colorTasa(dato.tasa);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: ColoresApp.ambarClaro,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: ColoresApp.ambar.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.tag,
                            size: 11, color: ColoresApp.ambar),
                        const SizedBox(width: 3),
                        Text(
                          dato.nombre,
                          style: const TextStyle(
                            fontSize: 11,
                            color: ColoresApp.ambar,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${dato.cantidad} eventos',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: ColoresApp.textoTerciario,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${dato.tasa.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: ColoresApp.ambarClaro,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(ColoresApp.ambar),
                  minHeight: 5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Top 5 eventos ────────────────────────────────────────────────────────────

class SeccionTopEventos extends StatelessWidget {
  const SeccionTopEventos({required this.topEventos});
  final List<EventoTopStat> topEventos;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColoresApp.superficiePrimaria,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: ColoresApp.sombraTarjeta,
              blurRadius: 8,
              offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top eventos por asistencia',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 2),
          Text(
            'Los 5 con mayor participación',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: ColoresApp.textoTerciario),
          ),
          const SizedBox(height: 16),
          if (topEventos.isEmpty)
            const SinDatos()
          else
            ...topEventos.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _FilaTopEvento(rango: e.key + 1, evento: e.value),
                  ),
                ),
        ],
      ),
    );
  }
}

class _FilaTopEvento extends StatelessWidget {
  const _FilaTopEvento({required this.rango, required this.evento});
  final int rango;
  final EventoTopStat evento;

  @override
  Widget build(BuildContext context) {
    final pct = evento.porcentajeAsistencia;
    final color = colorTasa(pct * 100);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: pct >= 0.75
                ? ColoresApp.verdeClaro
                : ColoresApp.superficieTerciar,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$rango',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color:
                    pct >= 0.75 ? ColoresApp.verde : ColoresApp.textoTerciario,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      evento.titulo,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: ColoresApp.textoPrimario,
                            fontSize: 13,
                          ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(pct * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: color.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 7,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${evento.totalPresentes} de ${evento.totalEsperados} asistentes',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ColoresApp.textoTerciario,
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
