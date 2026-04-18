import 'package:flutter/material.dart';
import 'package:uniasist/compartido/widgets/avatares/avatar_usuario.dart';
import 'package:uniasist/compartido/widgets/botones/boton_app.dart';
import 'package:uniasist/compartido/widgets/indicadores/insignia_estado.dart';
import 'package:uniasist/compartido/widgets/tarjetas/tarjeta_app.dart';

class TarjetaAsistente extends StatelessWidget {
  const TarjetaAsistente({
    super.key,
    required this.iniciales,
    required this.nombre,
    required this.estatus,
    this.detalle,
    this.urlFoto,
    this.textoBoton,
    this.alPresionarBoton,
    this.colorNombre,
    this.colorDetalle,
    this.alPresionar,
  });

  final String iniciales;
  final String nombre;
  final String estatus;

  /// Ej: 'V-22.100.004 · Estudiante'
  final String? detalle;

  final String? urlFoto;

  /// Texto del botón de acción. Ej: '✓ Registrar entrada'. Si es null no se muestra.
  final String? textoBoton;
  final VoidCallback? alPresionarBoton;

  final Color? colorNombre;
  final Color? colorDetalle;

  /// Si se pasa, toda la tarjeta se vuelve presionable
  final VoidCallback? alPresionar;

  @override
  Widget build(BuildContext context) {
    return TarjetaApp(
      variante:    VarianteTarjeta.normal,
      alPresionar: alPresionar,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              AvatarUsuario(iniciales: iniciales, urlFoto: urlFoto),
              const SizedBox(width: 12),
              Expanded(child: _InfoAsistente(
                nombre:       nombre,
                detalle:      detalle,
                colorNombre:  colorNombre,
                colorDetalle: colorDetalle,
              )),
              InsigniaEstado(estatus: estatus),
            ],
          ),
          if (textoBoton != null) ...[
            const SizedBox(height: 12),
            BotonApp(
              texto:       textoBoton!,
              alPresionar: alPresionarBoton,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoAsistente extends StatelessWidget {
  const _InfoAsistente({
    required this.nombre,
    this.detalle,
    this.colorNombre,
    this.colorDetalle,
  });

  final String nombre;
  final String? detalle;
  final Color? colorNombre;
  final Color? colorDetalle;

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
        if (detalle != null) ...[
          const SizedBox(height: 2),
          Text(
            detalle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorDetalle,
            ),
          ),
        ],
      ],
    );
  }
}
