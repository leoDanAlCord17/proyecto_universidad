import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/widgets/avisos/aviso_app.dart';
import '../../compartido/widgets/botones/boton_regresar.dart';
import '../../compartido/widgets/navegacion/barra_superior_app.dart';
import '../../configuracion/colores_app.dart';
import '../autenticacion/auth_cubit.dart';
import '../autenticacion/auth_estado.dart';
import 'gestionar_tags_usuario_cubit.dart';
import 'gestionar_tags_usuario_estado.dart';
import 'tag_item.dart';

class GestionarTagsUsuarioPantalla extends StatefulWidget {
  const GestionarTagsUsuarioPantalla({super.key, required this.usuarioId});

  final String usuarioId;

  @override
  State<GestionarTagsUsuarioPantalla> createState() =>
      _GestionarTagsUsuarioState();
}

class _GestionarTagsUsuarioState extends State<GestionarTagsUsuarioPantalla> {
  bool _estaIniciado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_estaIniciado) return;
    _estaIniciado = true;
    final authEstado = context.read<AuthCubit>().state;
    final adminId = authEstado is Autenticado ? authEstado.usuario.id : null;
    context
        .read<GestionarTagsUsuarioCubit>()
        .cargar(widget.usuarioId, adminId: adminId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GestionarTagsUsuarioCubit, GestionarTagsUsuarioEstado>(
      listenWhen: (_, curr) => curr is GestionarTagsUsuarioOperacionFallida,
      listener: (context, estado) {
        if (estado is GestionarTagsUsuarioOperacionFallida) {
          AvisoApp.mostrar(context,
              texto: estado.mensaje, estilo: EstiloAviso.error);
        }
      },
      builder: _construirVista,
    );
  }

  Widget _construirVista(
      BuildContext context, GestionarTagsUsuarioEstado estado) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: ColoresApp.fondo,
        body: Column(
          children: [
            SafeArea(
              bottom: false,
              child: BarraSuperiorApp(
                izquierda: _CabeceraTitulo(estado: estado),
              ),
            ),
            Expanded(child: _Cuerpo(estado: estado)),
          ],
        ),
      ),
    );
  }
}

// ─── Cabecera con título y nombre de usuario ──────────────────────────────────

class _CabeceraTitulo extends StatelessWidget {
  const _CabeceraTitulo({required this.estado});

  final GestionarTagsUsuarioEstado estado;

  @override
  Widget build(BuildContext context) {
    final nombre = estado is GestionarTagsUsuarioCargado
        ? (estado as GestionarTagsUsuarioCargado).nombreUsuario
        : estado is GestionarTagsUsuarioOperacionFallida
            ? (estado as GestionarTagsUsuarioOperacionFallida)
                .anterior
                .nombreUsuario
            : '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BotonRegresar(),
        const SizedBox(width: 12),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gestionar Tags',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: ColoresApp.textoPrimario,
                  ),
            ),
            if (nombre.isNotEmpty)
              Text(
                nombre,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: ColoresApp.textoSecundario,
                      fontSize: 13,
                    ),
              ),
          ],
        ),
      ],
    );
  }
}

// ─── Cuerpo según estado ──────────────────────────────────────────────────────

class _Cuerpo extends StatelessWidget {
  const _Cuerpo({required this.estado});

  final GestionarTagsUsuarioEstado estado;

  @override
  Widget build(BuildContext context) {
    final e = estado;
    return switch (e) {
      GestionarTagsUsuarioInicial() ||
      GestionarTagsUsuarioCargando() =>
        const Center(
          child: CircularProgressIndicator(color: ColoresApp.acento),
        ),
      GestionarTagsUsuarioCargado() => _VistaContenido(estado: e),
      GestionarTagsUsuarioOperacionFallida() =>
        _VistaContenido(estado: e.anterior),
      GestionarTagsUsuarioError() => _VistaError(mensaje: e.mensaje),
    };
  }
}

// ─── Vista de contenido ───────────────────────────────────────────────────────

class _VistaContenido extends StatelessWidget {
  const _VistaContenido({required this.estado});

  final GestionarTagsUsuarioCargado estado;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SeccionPrincipal(estado: estado),
          const SizedBox(height: 32),
          _SeccionSecundarios(estado: estado),
        ],
      ),
    );
  }
}

// ─── Sección tag principal ────────────────────────────────────────────────────

class _SeccionPrincipal extends StatelessWidget {
  const _SeccionPrincipal({required this.estado});

  final GestionarTagsUsuarioCargado estado;

  void _abrirPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: ColoresApp.sombraBarrera,
      builder: (_) => _HojaPickerTag(
        titulo: estado.tagPrincipal != null
            ? 'Cambiar tag principal'
            : 'Asignar tag principal',
        opciones: estado.principalesDisponibles,
        alSeleccionar: (tag) {
          Navigator.of(context, rootNavigator: true).pop();
          context.read<GestionarTagsUsuarioCubit>().asignarPrincipal(tag.id);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _LabelSeccion('TAG PRINCIPAL'),
        const SizedBox(height: 12),
        if (estado.tagPrincipal != null)
          _FilaTagAsignado(
            tag: estado.tagPrincipal!,
            alQuitar: () =>
                context.read<GestionarTagsUsuarioCubit>().quitarPrincipal(),
          )
        else
          const _PlaceholderSinTag(texto: 'Sin tag principal asignado'),
        if (estado.principalesDisponibles.isNotEmpty) ...[
          const SizedBox(height: 10),
          _BotonAccion(
            icono: estado.tagPrincipal != null
                ? Icons.swap_horiz_rounded
                : Icons.add_rounded,
            texto: estado.tagPrincipal != null
                ? 'Cambiar tag principal'
                : 'Asignar tag principal',
            alPresionar: () => _abrirPicker(context),
          ),
        ],
      ],
    );
  }
}

// ─── Sección tags secundarios ─────────────────────────────────────────────────

class _SeccionSecundarios extends StatelessWidget {
  const _SeccionSecundarios({required this.estado});

  final GestionarTagsUsuarioCargado estado;

  void _abrirPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: ColoresApp.sombraBarrera,
      builder: (_) => _HojaPickerTag(
        titulo: 'Agregar tag secundario',
        opciones: estado.secundariosDisponibles,
        alSeleccionar: (tag) {
          Navigator.of(context, rootNavigator: true).pop();
          context.read<GestionarTagsUsuarioCubit>().agregarSecundario(tag.id);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actual = estado.tagsSecundarios.length;
    final maximo = estado.maxSecundarios;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LabelSeccion('TAGS SECUNDARIOS · $actual/$maximo'),
        const SizedBox(height: 12),
        if (estado.tagsSecundarios.isEmpty)
          const _PlaceholderSinTag(texto: 'Sin tags secundarios asignados')
        else
          ...estado.tagsSecundarios.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _FilaTagAsignado(
                tag: t,
                alQuitar: () => context
                    .read<GestionarTagsUsuarioCubit>()
                    .quitarSecundario(t.id),
              ),
            ),
          ),
        const SizedBox(height: 10),
        if (!estado.estaEnLimite && estado.secundariosDisponibles.isNotEmpty)
          _BotonAccion(
            icono: Icons.add_rounded,
            texto: 'Agregar tag secundario',
            alPresionar: () => _abrirPicker(context),
          )
        else if (estado.estaEnLimite)
          _AvisoLimite(maximo: maximo),
      ],
    );
  }
}

// ─── Fila de tag asignado ─────────────────────────────────────────────────────

class _FilaTagAsignado extends StatelessWidget {
  const _FilaTagAsignado({required this.tag, required this.alQuitar});

  final TagItem tag;
  final VoidCallback alQuitar;

  @override
  Widget build(BuildContext context) {
    final color = tag.esPrincipal ? ColoresApp.acento : ColoresApp.ambar;
    final fondo =
        tag.esPrincipal ? ColoresApp.acentoClaro : ColoresApp.ambarClaro;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: ColoresApp.superficiePrimaria,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: ColoresApp.sombraTarjeta,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tag.nombre,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: ColoresApp.textoPrimario,
                    fontSize: 15,
                  ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: fondo,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              tag.esPrincipal ? 'Principal' : 'Secundario',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: alQuitar,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: ColoresApp.textoTerciario,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Placeholder sin tag ──────────────────────────────────────────────────────

class _PlaceholderSinTag extends StatelessWidget {
  const _PlaceholderSinTag({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: ColoresApp.superficiePrimaria,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ColoresApp.bordeMedio),
      ),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ColoresApp.textoTerciario,
            ),
      ),
    );
  }
}

// ─── Botón de acción ──────────────────────────────────────────────────────────

class _BotonAccion extends StatelessWidget {
  const _BotonAccion({
    required this.icono,
    required this.texto,
    required this.alPresionar,
  });

  final IconData icono;
  final String texto;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: alPresionar,
        borderRadius: BorderRadius.circular(12),
        highlightColor: ColoresApp.acentoClaro,
        splashColor: ColoresApp.bordeMedio,
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: ColoresApp.bordeFuerte),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icono, color: ColoresApp.acento, size: 18),
              const SizedBox(width: 8),
              Text(
                texto,
                style: const TextStyle(
                  color: ColoresApp.acento,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Aviso límite alcanzado ───────────────────────────────────────────────────

class _AvisoLimite extends StatelessWidget {
  const _AvisoLimite({required this.maximo});

  final int maximo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ColoresApp.ambarClaro,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColoresApp.ambar, width: 0.8),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: ColoresApp.ambar, size: 16),
          const SizedBox(width: 8),
          Text(
            'Límite alcanzado ($maximo/$maximo tags secundarios)',
            style: const TextStyle(
              color: ColoresApp.ambar,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Label de sección ─────────────────────────────────────────────────────────

class _LabelSeccion extends StatelessWidget {
  const _LabelSeccion(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: ColoresApp.textoTerciario,
            letterSpacing: 0.8,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
    );
  }
}

// ─── Hoja de selección de tag ─────────────────────────────────────────────────

class _HojaPickerTag extends StatefulWidget {
  const _HojaPickerTag({
    required this.titulo,
    required this.opciones,
    required this.alSeleccionar,
  });

  final String titulo;
  final List<TagItem> opciones;
  final ValueChanged<TagItem> alSeleccionar;

  @override
  State<_HojaPickerTag> createState() => _HojaPickerTagState();
}

class _HojaPickerTagState extends State<_HojaPickerTag> {
  String _busqueda = '';

  List<TagItem> get _filtradas {
    if (_busqueda.trim().isEmpty) return widget.opciones;
    final q = _busqueda.toLowerCase();
    return widget.opciones
        .where((t) => t.nombre.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    return ConstrainedBox(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.75),
      child: Container(
        decoration: const BoxDecoration(
          color: ColoresApp.superficiePrimaria,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 14),
            _handle(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                widget.titulo,
                style: const TextStyle(
                  color: ColoresApp.textoPrimario,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _campoBusqueda(),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: ColoresApp.bordesuave),
            Flexible(child: _listaOpciones(bottomPadding)),
          ],
        ),
      ),
    );
  }

  Widget _handle() => Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: ColoresApp.bordeMedio,
          borderRadius: BorderRadius.circular(2),
        ),
      );

  Widget _campoBusqueda() => Container(
        height: 44,
        decoration: BoxDecoration(
          color: ColoresApp.superficieSecund,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            const Icon(Icons.search_rounded,
                color: ColoresApp.textoTerciario, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _busqueda = v),
                style: const TextStyle(
                    color: ColoresApp.textoPrimario, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Buscar...',
                  hintStyle:
                      TextStyle(color: ColoresApp.textoTerciario, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      );

  Widget _listaOpciones(double bottomPadding) {
    final items = _filtradas;
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'No hay tags disponibles',
          style: TextStyle(color: ColoresApp.textoTerciario),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding + 20),
      itemCount: items.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, indent: 16, color: ColoresApp.bordesuave),
      itemBuilder: (_, i) => _ItemPickerTag(
        tag: items[i],
        alSeleccionar: widget.alSeleccionar,
      ),
    );
  }
}

// ─── Ítem en el picker ────────────────────────────────────────────────────────

class _ItemPickerTag extends StatelessWidget {
  const _ItemPickerTag({required this.tag, required this.alSeleccionar});

  final TagItem tag;
  final ValueChanged<TagItem> alSeleccionar;

  @override
  Widget build(BuildContext context) {
    final color = tag.esPrincipal ? ColoresApp.acento : ColoresApp.ambar;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => alSeleccionar(tag),
        borderRadius: BorderRadius.circular(10),
        highlightColor: ColoresApp.superficieSecund,
        splashColor: ColoresApp.bordeMedio,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  tag.nombre,
                  style: const TextStyle(
                    color: ColoresApp.textoPrimario,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: ColoresApp.textoTerciario,
                size: 18,
              ),
            ],
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
              onPressed: () =>
                  context.read<GestionarTagsUsuarioCubit>().cargar(''),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
