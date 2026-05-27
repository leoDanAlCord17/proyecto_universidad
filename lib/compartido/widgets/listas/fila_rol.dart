import 'package:flutter/material.dart';
import 'package:uniasist/compartido/widgets/botones/boton_app.dart';
import 'package:uniasist/compartido/widgets/tarjetas/tarjeta_app.dart';
import 'package:uniasist/configuracion/colores_app.dart';

class FilaRol extends StatelessWidget {
  const FilaRol({
    super.key,
    required this.nombre,
    this.descripcion,
    this.esSistema = false,
    this.textoBoton,
    this.varianteBoton = VarianteBoton.rojo,
    this.alPresionarBoton,
    this.alPresionar,
    this.colorNombre,
    this.colorDescripcion,
  });

  final String nombre;
  final String? descripcion;

  /// Si es true, muestra la insignia 'Sistema' en lugar del botón
  final bool esSistema;

  /// Texto del botón de acción. Si es null, no se muestra botón.
  final String? textoBoton;
  final VarianteBoton varianteBoton;
  final VoidCallback? alPresionarBoton;

  /// Hace toda la fila presionable como tarjeta
  final VoidCallback? alPresionar;

  final Color? colorNombre;
  final Color? colorDescripcion;

  @override
  Widget build(BuildContext context) {
    return TarjetaApp(
      variante:    VarianteTarjeta.normal,
      alPresionar: alPresionar,
      child: Row(
        children: [
          Expanded(child: _InfoRol(
            nombre:           nombre,
            descripcion:      descripcion,
            colorNombre:      colorNombre,
            colorDescripcion: colorDescripcion,
          ),),
          const SizedBox(width: 12),
          if (esSistema)
            const _InsigniaSistema()
          else if (textoBoton != null)
            BotonApp(
              texto:       textoBoton!,
              variante:    varianteBoton,
              alPresionar: alPresionarBoton,
              ancho:       90,
            ),
        ],
      ),
    );
  }
}

class _InfoRol extends StatelessWidget {
  const _InfoRol({
    required this.nombre,
    this.descripcion,
    this.colorNombre,
    this.colorDescripcion,
  });

  final String nombre;
  final String? descripcion;
  final Color? colorNombre;
  final Color? colorDescripcion;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          nombre,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color:      colorNombre,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (descripcion != null) ...[
          const SizedBox(height: 2),
          Text(
            descripcion!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorDescripcion,
            ),
          ),
        ],
      ],
    );
  }
}

class _InsigniaSistema extends StatelessWidget {
  const _InsigniaSistema();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:        ColoresApp.superficieTerciar,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        'Sistema',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: ColoresApp.textoSecundario,
        ),
      ),
    );
  }
}
