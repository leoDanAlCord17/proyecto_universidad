import 'package:flutter/material.dart';

import '../../../configuracion/colores_app.dart';

// ─── Modelo de opción ─────────────────────────────────────────────────────────

class OpcionPanel {
  const OpcionPanel({
    required this.icono,
    required this.colorFondo,
    required this.colorIcono,
    required this.titulo,
    required this.descripcion,
    this.colorTitulo,
    this.alPresionar,
  });

  final IconData      icono;
  final Color         colorFondo;
  final Color         colorIcono;
  final String        titulo;
  final String        descripcion;
  final Color?        colorTitulo;
  final VoidCallback? alPresionar;
}

// ─── Panel ────────────────────────────────────────────────────────────────────

class PanelOpciones {
  /// Muestra el panel deslizante desde abajo, sobre la barra de navegación.
  /// [encabezado] es opcional; si se pasa, se muestra entre el handle y las opciones.
  static void mostrar(
    BuildContext context, {
    required List<OpcionPanel> opciones,
    Widget? encabezado,
  }) {
    showModalBottomSheet<void>(
      context:            context,
      useRootNavigator:   true,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      barrierColor:       ColoresApp.sombraBarrera,
      builder:            (_) => _ContenidoPanel(opciones: opciones, encabezado: encabezado),
    );
  }
}

// ─── Contenido del panel ──────────────────────────────────────────────────────

class _ContenidoPanel extends StatelessWidget {
  const _ContenidoPanel({required this.opciones, this.encabezado});

  final List<OpcionPanel> opciones;
  final Widget?           encabezado;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color:        ColoresApp.superficiePrimaria,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 14),
            const _Handle(),
            if (encabezado != null) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: encabezado!,
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: ColoresApp.bordesuave),
            ] else
              const SizedBox(height: 20),
            Flexible(
              child: ListView.separated(
                shrinkWrap:       true,
                padding:          EdgeInsets.fromLTRB(16, 8, 16, bottomPadding + 20),
                itemCount:        opciones.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  indent: 74,
                  color:  ColoresApp.bordesuave,
                ),
                itemBuilder: (_, i) => _ItemOpcion(opcion: opciones[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Handle de arrastre ───────────────────────────────────────────────────────

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  36,
      height: 4,
      decoration: BoxDecoration(
        color:        ColoresApp.bordeMedio,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

// ─── Ítem de opción ───────────────────────────────────────────────────────────

class _ItemOpcion extends StatelessWidget {
  const _ItemOpcion({required this.opcion});

  final OpcionPanel opcion;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:          opcion.alPresionar ?? () {},
        borderRadius:   BorderRadius.circular(12),
        highlightColor: ColoresApp.superficieSecund,
        splashColor:    ColoresApp.bordeMedio,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 13),
          child: Row(
            children: [
              Container(
                width:  46,
                height: 46,
                decoration: BoxDecoration(
                  color:        opcion.colorFondo,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(opcion.icono, color: opcion.colorIcono, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opcion.titulo,
                      style: TextStyle(
                        color:      opcion.colorTitulo ?? ColoresApp.textoPrimario,
                        fontSize:   15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      opcion.descripcion,
                      style: const TextStyle(
                        color:    ColoresApp.textoTerciario,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: ColoresApp.textoTerciario,
                size:  20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
