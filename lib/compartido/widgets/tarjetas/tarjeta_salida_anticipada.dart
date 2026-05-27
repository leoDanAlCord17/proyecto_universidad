import 'package:flutter/material.dart';
import 'package:uniasist/compartido/widgets/avatares/avatar_usuario.dart';
import 'package:uniasist/compartido/widgets/indicadores/insignia_estado.dart';
import 'package:uniasist/compartido/widgets/tarjetas/tarjeta_app.dart';

class TarjetaSalidaAnticipada extends StatelessWidget {
  const TarjetaSalidaAnticipada({
    super.key,
    required this.iniciales,
    required this.nombre,
    required this.estatus,
    this.horario,
    this.motivo,
    this.urlFoto,
    this.colorNombre,
    this.colorDetalle,
    this.alPresionar,
  });

  final String iniciales;
  final String nombre;
  final String estatus;

  /// Ej: '08:05 → 09:30'
  final String? horario;

  /// Ej: 'Consulta médica'
  final String? motivo;

  final String? urlFoto;
  final Color? colorNombre;
  final Color? colorDetalle;

  /// Si se pasa, toda la tarjeta se vuelve presionable
  final VoidCallback? alPresionar;

  @override
  Widget build(BuildContext context) {
    return TarjetaApp(
      variante:    VarianteTarjeta.normal,
      alPresionar: alPresionar,
      child: Row(
        children: [
          AvatarUsuario(iniciales: iniciales, urlFoto: urlFoto),
          const SizedBox(width: 12),
          Expanded(child: _InfoSalida(
            nombre:       nombre,
            horario:      horario,
            motivo:       motivo,
            colorNombre:  colorNombre,
            colorDetalle: colorDetalle,
          ),),
          InsigniaEstado(estatus: estatus),
        ],
      ),
    );
  }
}

class _InfoSalida extends StatelessWidget {
  const _InfoSalida({
    required this.nombre,
    this.horario,
    this.motivo,
    this.colorNombre,
    this.colorDetalle,
  });

  final String nombre;
  final String? horario;
  final String? motivo;
  final Color? colorNombre;
  final Color? colorDetalle;

  @override
  Widget build(BuildContext context) {
    // Combina horario y motivo en una sola línea si ambos están presentes
    final detalle = [
      if (horario != null) horario!,
      if (motivo  != null) motivo!,
    ].join(' · ');

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
        if (detalle.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            detalle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorDetalle,
            ),
          ),
        ],
      ],
    );
  }
}
