import 'package:flutter/material.dart';
import 'package:activiti/configuracion/colores_app.dart';

class FilaTogle extends StatelessWidget {
  const FilaTogle({
    super.key,
    required this.titulo,
    required this.descripcion,
    required this.valor,
    required this.alCambiar,
    this.icono,
  });

  final String titulo;
  final String descripcion;
  final bool valor;
  final ValueChanged<bool>? alCambiar;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: ColoresApp.superficieSecund,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: ColoresApp.sombraTarjeta,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          if (icono != null) ...[
            Icon(icono, color: ColoresApp.textoSecundario, size: 22),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 3),
                Text(
                  descripcion,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: valor,
            onChanged: alCambiar,
          ),
        ],
      ),
    );
  }
}
