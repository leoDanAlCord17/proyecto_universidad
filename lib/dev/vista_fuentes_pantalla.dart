import 'package:flutter/material.dart';
import 'package:uniasist/configuracion/colores_app.dart';

/// Pantalla de desarrollo — muestra cada estilo de texto del tema con sus
/// variantes de FontWeight disponibles.
/// Solo para uso interno del equipo. No incluir en producción.
class VistaFuentesPantalla extends StatelessWidget {
  const VistaFuentesPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresApp.fondo,
      appBar: AppBar(
        title: const Text('Vista de Fuentes — DEV'),
        backgroundColor: ColoresApp.superficiePrimaria,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SeccionEstilo(
              nombre: 'displaySmall',
              uso: 'Título principal: "Bienvenido"',
              base: Theme.of(context).textTheme.displaySmall,
            ),
            _SeccionEstilo(
              nombre: 'headlineSmall',
              uso: 'Títulos de tarjetas: nombre de evento, materia',
              base: Theme.of(context).textTheme.headlineSmall,
            ),
            _SeccionEstilo(
              nombre: 'titleSmall',
              uso: 'Etiquetas de inputs y barras superiores',
              base: Theme.of(context).textTheme.titleSmall,
            ),
            _SeccionEstilo(
              nombre: 'bodyLarge',
              uso: 'Subtítulos de tarjetas: horario, lugar, metadatos',
              base: Theme.of(context).textTheme.bodyLarge,
            ),
            _SeccionEstilo(
              nombre: 'bodyMedium',
              uso: 'Subtítulo: "Sistema de asistencia..."',
              base: Theme.of(context).textTheme.bodyMedium,
            ),
            _SeccionEstilo(
              nombre: 'bodySmall',
              uso: 'Versión o textos muy pequeños',
              base: Theme.of(context).textTheme.bodySmall,
            ),
            _SeccionEstilo(
              nombre: 'labelLarge',
              uso: 'Enlaces y acciones: "¿Olvidaste tu contraseña?"',
              base: Theme.of(context).textTheme.labelLarge,
            ),
            _SeccionEstilo(
              nombre: 'labelSmall',
              uso: 'Insignias, etiquetas de navegación',
              base: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ─── Sección por estilo ───────────────────────────────────────────────────────

class _SeccionEstilo extends StatelessWidget {
  const _SeccionEstilo({
    required this.nombre,
    required this.uso,
    required this.base,
  });

  final String nombre;
  final String uso;
  final TextStyle? base;

  static const _pesos = [
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.w700,
    FontWeight.w800,
    FontWeight.w900,
  ];

  static const _etiquetas = [
    'w400 — Regular',
    'w500 — Medium',
    'w600 — SemiBold',
    'w700 — Bold',
    'w800 — ExtraBold',
    'w900 — Black',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera de sección
          Text(
            nombre.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: ColoresApp.acento,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            uso,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: ColoresApp.textoSecundario,
                ),
          ),
          const SizedBox(height: 8),
          const Divider(color: ColoresApp.bordesuave, height: 1),
          const SizedBox(height: 12),

          // Una fila por FontWeight
          for (var i = 0; i < _pesos.length; i++)
            _FilaPeso(
              etiqueta: _etiquetas[i],
              estilo: base?.copyWith(fontWeight: _pesos[i]),
              esActual: base?.fontWeight == _pesos[i],
            ),
        ],
      ),
    );
  }
}

// ─── Fila individual de peso ──────────────────────────────────────────────────

class _FilaPeso extends StatelessWidget {
  const _FilaPeso({
    required this.etiqueta,
    required this.estilo,
    required this.esActual,
  });

  final String etiqueta;
  final TextStyle? estilo;
  final bool esActual;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Etiqueta del peso
          SizedBox(
            width: 140,
            child: Row(
              children: [
                if (esActual)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child:
                        Icon(Icons.circle, size: 6, color: ColoresApp.acento),
                  ),
                Text(
                  etiqueta,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: esActual
                            ? ColoresApp.acento
                            : ColoresApp.textoTerciario,
                        letterSpacing: 0.2,
                      ),
                ),
              ],
            ),
          ),
          // Muestra del estilo
          Expanded(
            child: Text(
              'UniAsist 0123',
              style: estilo,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
