import 'package:flutter/material.dart';
import 'package:uniasist/compartido/widgets/tarjetas/tarjeta_app.dart';
import 'package:uniasist/configuracion/colores_app.dart';

class TarjetaInfoPersonal extends StatelessWidget {
  const TarjetaInfoPersonal({
    super.key,
    this.cedula,
    this.telefono,
    this.roles             = const [],
    this.tagPrincipal,
    this.tagsSecundarios   = const [],
    this.miembroDesde,
    this.alEditarTap,
  });

  final String?       cedula;
  final String?       telefono;
  final List<String>  roles;
  final String?       tagPrincipal;
  final List<String>  tagsSecundarios;
  final DateTime?     miembroDesde;
  /// Si no es null, muestra el botón de editar en el encabezado.
  final VoidCallback? alEditarTap;

  @override
  Widget build(BuildContext context) {
    return TarjetaApp(
      relleno: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'INFORMACIÓN PERSONAL',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color:         ColoresApp.textoTerciario,
                    fontWeight:    FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              if (alEditarTap != null)
                Material(
                  color:        Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap:        alEditarTap,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child:   Icon(
                        Icons.edit_outlined,
                        size:  18,
                        color: ColoresApp.acento,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (cedula != null) ...[
            _FilaTexto(etiqueta: 'Cédula',    valor: cedula!),
            const _Divisor(),
          ],
          if (telefono != null) ...[
            _FilaTexto(etiqueta: 'Teléfono',  valor: telefono!),
            const _Divisor(),
          ],
          if (roles.isNotEmpty) ...[
            _FilaChips(etiqueta: 'Roles',              chips: roles),
            const _Divisor(),
          ],
          if (tagPrincipal != null) ...[
            _FilaChips(etiqueta: 'Tag principal',     chips: [tagPrincipal!]),
            const _Divisor(),
          ],
          if (tagsSecundarios.isNotEmpty) ...[
            _FilaChips(etiqueta: 'Tags\nsecundarios', chips: tagsSecundarios),
            const _Divisor(),
          ],
          if (miembroDesde != null)
            _FilaTexto(
              etiqueta:  'Miembro desde',
              valor:     _formatearMes(miembroDesde!),
              esNegrita: true,
            ),
        ],
      ),
    );
  }

  static String _formatearMes(DateTime fecha) {
    const meses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
    ];
    return '${meses[fecha.month - 1]} ${fecha.year}';
  }
}

// ─── Fila de texto simple ────────────────────────────────────────────────────

class _FilaTexto extends StatelessWidget {
  const _FilaTexto({
    required this.etiqueta,
    required this.valor,
    this.esNegrita = false,
  });

  final String etiqueta;
  final String valor;
  final bool   esNegrita;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              etiqueta,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: Text(
              valor,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color:      ColoresApp.textoPrimario,
                fontWeight: esNegrita ? FontWeight.w700 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Fila con chips ──────────────────────────────────────────────────────────

class _FilaChips extends StatelessWidget {
  const _FilaChips({
    required this.etiqueta,
    required this.chips,
  });

  final String       etiqueta;
  final List<String> chips;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              etiqueta,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: Wrap(
              alignment:   WrapAlignment.end,
              spacing:     6,
              runSpacing:  6,
              children: chips.map((c) => _ChipEtiqueta(texto: c)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Chip individual ─────────────────────────────────────────────────────────

class _ChipEtiqueta extends StatelessWidget {
  const _ChipEtiqueta({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:        ColoresApp.acentoClaro,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color:      ColoresApp.acento,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Divisor ─────────────────────────────────────────────────────────────────

class _Divisor extends StatelessWidget {
  const _Divisor();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height:    1,
      thickness: 1,
      color:     ColoresApp.superficieTerciar,
    );
  }
}
