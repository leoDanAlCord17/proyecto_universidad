import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../compartido/constantes.dart';
import '../../compartido/widgets/avisos/aviso_app.dart';
import '../../compartido/widgets/dialogo/dialogo_confirmacion.dart';
import '../../compartido/widgets/formularios/barra_busqueda_app.dart';
import '../../compartido/widgets/navegacion/barra_superior_app.dart';
import '../../compartido/widgets/botones/boton_regresar.dart';
import '../../compartido/widgets/panel/panel_opciones.dart';
import '../../configuracion/colores_app.dart';
import 'tag.dart';
import 'tags_cubit.dart';
import 'tags_estado.dart';

class TagsPantalla extends StatefulWidget {
  const TagsPantalla({super.key});

  @override
  State<TagsPantalla> createState() => _TagsPantallaState();
}

class _TagsPantallaState extends State<TagsPantalla> {
  bool _estaIniciado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_estaIniciado) return;
    _estaIniciado = true;
    context.read<TagsCubit>().cargarTags();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TagsCubit, TagsEstado>(
      listenWhen: (_, curr) => curr is TagsOperacionFallida,
      listener: (context, estado) {
        if (estado is TagsOperacionFallida) {
          AvisoApp.mostrar(context, texto: estado.mensaje, estilo: EstiloAviso.error);
        }
      },
      builder: (context, estado) => _construirVista(context, estado),
    );
  }

  Widget _construirVista(BuildContext context, TagsEstado estado) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor:          Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness:     Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: ColoresApp.fondo,
        body: Column(
          children: [
            SafeArea(
              bottom: false,
              child: BarraSuperiorApp(
                izquierda: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BotonRegresar(),
                    const SizedBox(width: 12),
                    Text(
                      'Tags',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize:   20,
                        fontWeight: FontWeight.w700,
                        color:      ColoresApp.textoPrimario,
                      ),
                    ),
                  ],
                ),
                derecha: const _BotonCrearTag(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: BarraBusquedaApp(
                hintText:  'Buscar tags...',
                alCambiar: (texto) => context.read<TagsCubit>().filtrar(texto),
              ),
            ),
            Expanded(child: _Cuerpo(estado: estado)),
          ],
        ),
      ),
    );
  }
}

// ─── Botón crear tag ──────────────────────────────────────────────────────────

class _BotonCrearTag extends StatelessWidget {
  const _BotonCrearTag();

  @override
  Widget build(BuildContext context) {
    return Material(
      color:        Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () async {
          await context.push(Rutas.crearTag);
          if (context.mounted) context.read<TagsCubit>().cargarTags();
        },
        borderRadius:   BorderRadius.circular(12),
        splashColor:    Colors.white.withValues(alpha: 0.3),
        highlightColor: Colors.white.withValues(alpha: 0.15),
        child: Ink(
          width:  40,
          height: 40,
          decoration: BoxDecoration(
            gradient:     ColoresApp.degradadoPrincipal,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size:  22,
          ),
        ),
      ),
    );
  }
}

// ─── Cuerpo según estado ──────────────────────────────────────────────────────

class _Cuerpo extends StatelessWidget {
  const _Cuerpo({required this.estado});

  final TagsEstado estado;

  @override
  Widget build(BuildContext context) {
    final e = estado;
    return switch (e) {
      TagsInicial() || TagsCargando()   => const Center(
          child: CircularProgressIndicator(color: ColoresApp.acento),
        ),
      TagsCargados()                    => _Lista(estado: e),
      TagsOperacionFallida()            => _Lista(estado: e.anterior),
      TagsError()                       => _VistaError(mensaje: e.mensaje),
    };
  }
}

// ─── Lista de tags ────────────────────────────────────────────────────────────

class _Lista extends StatelessWidget {
  const _Lista({required this.estado});

  final TagsCargados estado;

  @override
  Widget build(BuildContext context) {
    final items = estado.tagsFiltrados;

    if (items.isEmpty) {
      return Center(
        child: Text(
          'No hay tags',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: ColoresApp.textoTerciario,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Text(
          'TAG',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color:         ColoresApp.textoTerciario,
            letterSpacing: 0.8,
            fontSize:      13,
            fontWeight:    FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        ...items.map((t) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child:   _TarjetaTag(tag: t),
        )),
      ],
    );
  }
}

// ─── Tarjeta de tag ───────────────────────────────────────────────────────────

class _TarjetaTag extends StatelessWidget {
  const _TarjetaTag({required this.tag});

  final Tag tag;

  void _mostrarOpciones(BuildContext context) {
    PanelOpciones.mostrar(context, opciones: [
      OpcionPanel(
        icono:       Icons.edit_outlined,
        colorFondo:  ColoresApp.acentoClaro,
        colorIcono:  ColoresApp.acento,
        titulo:      'Editar',
        descripcion: 'Editar tag',
        alPresionar: () {
          Navigator.of(context, rootNavigator: true).pop();
          _navegarYRecargar(context, Rutas.editarTagUrl(tag.id));
        },
      ),
      _opcionToggle(context),
      OpcionPanel(
        icono:       Icons.add_rounded,
        colorFondo:  ColoresApp.superficieTerciar,
        colorIcono:  ColoresApp.textoSecundario,
        titulo:      'Crear tag',
        descripcion: 'Crear nuevo tag',
        alPresionar: () {
          Navigator.of(context, rootNavigator: true).pop();
          _navegarYRecargar(context, Rutas.crearTag);
        },
      ),
    ]);
  }

  Future<void> _navegarYRecargar(BuildContext context, String ruta) async {
    await context.push(ruta);
    if (context.mounted) context.read<TagsCubit>().cargarTags();
  }

  OpcionPanel _opcionToggle(BuildContext context) => OpcionPanel(
    icono:       tag.estatus ? Icons.toggle_off_outlined         : Icons.toggle_on_outlined,
    colorFondo:  tag.estatus ? ColoresApp.rojoClaro              : ColoresApp.verdeClaro,
    colorIcono:  tag.estatus ? ColoresApp.rojo                   : ColoresApp.verde,
    titulo:      tag.estatus ? 'Desactivar'                      : 'Activar',
    descripcion: tag.estatus ? 'Desactiva el tag y asignaciones' : 'Activa el tag',
    alPresionar: () {
      Navigator.of(context, rootNavigator: true).pop();
      if (tag.estatus) {
        _confirmarDesactivar(context);
      } else {
        _confirmarActivar(context);
      }
    },
  );

  Future<void> _confirmarActivar(BuildContext context) async {
    final confirmo = await DialogoConfirmacion.mostrar(
      context,
      titulo:         'Activar tag',
      descripcion:    'Se activará "${tag.nombre}". Las asignaciones previas a usuarios no se reactivarán automáticamente; deberán reasignarse manualmente.',
      textoConfirmar: 'Activar',
      textoCancelar:  'Cancelar',
    );
    if (confirmo != true || !context.mounted) return;
    context.read<TagsCubit>().activar(tag.id);
  }

  Future<void> _confirmarDesactivar(BuildContext context) async {
    final confirmo = await _DialogoDesactivarTag.mostrar(context, tag: tag);
    if (confirmo != true || !context.mounted) return;
    context.read<TagsCubit>().desactivar(tag.id);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color:        ColoresApp.superficiePrimaria,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color:      ColoresApp.sombraTarjeta,
            blurRadius: 8,
            offset:     Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tag.nombre,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color:      ColoresApp.textoPrimario,
                          fontSize:   16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _InsigniaTag(esPrincipal: tag.esPrincipal),
                    const SizedBox(width: 6),
                    _InsigniaEstatus(activo: tag.estatus),
                    const SizedBox(width: 6),
                    _InsigniaUsuarios(total: tag.totalUsuarios),
                  ],
                ),
                if (tag.descripcion.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    tag.descripcion,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:    ColoresApp.textoSecundario,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          _BotonOpciones(alPresionar: () => _mostrarOpciones(context)),
        ],
      ),
    );
  }
}

// ─── Insignia tipo ────────────────────────────────────────────────────────────

class _InsigniaTag extends StatelessWidget {
  const _InsigniaTag({required this.esPrincipal});

  final bool esPrincipal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:        esPrincipal ? ColoresApp.acentoClaro : ColoresApp.ambarClaro,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: esPrincipal ? ColoresApp.acentoBorde : ColoresApp.ambar,
          width: 0.8,
        ),
      ),
      child: Text(
        esPrincipal ? 'Principal' : 'Secundario',
        style: TextStyle(
          color:      esPrincipal ? ColoresApp.acento : ColoresApp.ambar,
          fontSize:   11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Insignia estatus ─────────────────────────────────────────────────────────

class _InsigniaEstatus extends StatelessWidget {
  const _InsigniaEstatus({required this.activo});

  final bool activo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:        activo ? ColoresApp.verdeClaro : ColoresApp.rojoClaro,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: activo ? ColoresApp.bordeExito : ColoresApp.bordeError,
          width: 0.8,
        ),
      ),
      child: Text(
        activo ? 'Activo' : 'Inactivo',
        style: TextStyle(
          color:      activo ? ColoresApp.verde : ColoresApp.rojo,
          fontSize:   11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Insignia usuarios ────────────────────────────────────────────────────────

class _InsigniaUsuarios extends StatelessWidget {
  const _InsigniaUsuarios({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:        ColoresApp.superficieTerciar,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        '$total',
        style: const TextStyle(
          color:      ColoresApp.textoSecundario,
          fontSize:   11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Botón tres puntos ────────────────────────────────────────────────────────

class _BotonOpciones extends StatelessWidget {
  const _BotonOpciones({required this.alPresionar});

  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color:        Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap:        alPresionar,
        borderRadius: BorderRadius.circular(8),
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(
            Icons.more_vert_rounded,
            color: ColoresApp.textoTerciario,
            size:  20,
          ),
        ),
      ),
    );
  }
}

// ─── Vista de error ───────────────────────────────────────────────────────────

class _VistaError extends StatelessWidget {
  const _VistaError({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: ColoresApp.rojo, size: 48),
            const SizedBox(height: 16),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ColoresApp.textoSecundario,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.read<TagsCubit>().cargarTags(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Diálogo desactivar tag ───────────────────────────────────────────────────

class _DialogoDesactivarTag extends StatefulWidget {
  const _DialogoDesactivarTag({required this.tag});

  final Tag tag;

  static Future<bool?> mostrar(BuildContext context, {required Tag tag}) =>
      showDialog<bool>(
        context: context,
        builder: (_) => _DialogoDesactivarTag(tag: tag),
      );

  @override
  State<_DialogoDesactivarTag> createState() => _DialogoDesactivarTagState();
}

class _DialogoDesactivarTagState extends State<_DialogoDesactivarTag> {
  final _ctrl     = TextEditingController();
  bool  _coincide = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding:    const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        decoration: BoxDecoration(
          color:        ColoresApp.superficiePrimaria,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: ColoresApp.sombraGeneral, blurRadius: 24, offset: Offset(0, 8)),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize:       MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Desactivar tag',
              style: TextStyle(
                color:      ColoresApp.textoPrimario,
                fontSize:   17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Al desactivar "${widget.tag.nombre}", todas sus asignaciones a usuarios también se desactivarán. Esta acción puede afectar a múltiples usuarios.\n\nEscribe el nombre exacto del tag para confirmar:',
              style: const TextStyle(
                color:  ColoresApp.textoSecundario,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              onChanged:  (v) => setState(() => _coincide = v == widget.tag.nombre),
              decoration: InputDecoration(
                hintText: widget.tag.nombre,
                hintStyle: const TextStyle(color: ColoresApp.textoTerciario),
                filled:    true,
                fillColor: ColoresApp.superficieSecund,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:   BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:   const BorderSide(color: ColoresApp.bordeFuerte),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 24),
            _BotonDesactivarConfirmar(
              habilitado:  _coincide,
              alPresionar: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 10),
            _BotonCancelarDialogo(
              alPresionar: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Botones del diálogo ──────────────────────────────────────────────────────

class _BotonDesactivarConfirmar extends StatelessWidget {
  const _BotonDesactivarConfirmar({required this.habilitado, required this.alPresionar});

  final bool         habilitado;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:  double.infinity,
      height: 48,
      child: Material(
        color:        Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap:          habilitado ? alPresionar : null,
          borderRadius:   BorderRadius.circular(12),
          splashColor:    habilitado ? Colors.white.withValues(alpha: 0.3) : null,
          highlightColor: habilitado ? Colors.white.withValues(alpha: 0.15) : null,
          child: Ink(
            decoration: BoxDecoration(
              gradient:     habilitado ? ColoresApp.degradadoPrincipal : null,
              color:        habilitado ? null : ColoresApp.superficieTerciar,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'Desactivar',
                style: TextStyle(
                  color:      habilitado ? Colors.white : ColoresApp.textoTerciario,
                  fontSize:   14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BotonCancelarDialogo extends StatelessWidget {
  const _BotonCancelarDialogo({required this.alPresionar});

  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:  double.infinity,
      height: 48,
      child: Material(
        color:        Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap:          alPresionar,
          borderRadius:   BorderRadius.circular(12),
          highlightColor: ColoresApp.rojoClaro,
          splashColor:    ColoresApp.bordeError,
          child: Ink(
            decoration: BoxDecoration(
              border:       Border.all(color: ColoresApp.bordeError),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color:      ColoresApp.rojo,
                  fontSize:   14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
