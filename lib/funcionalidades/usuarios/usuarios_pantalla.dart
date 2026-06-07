import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../compartido/constantes.dart';
import '../../compartido/widgets/avisos/aviso_app.dart';
import '../../compartido/widgets/avatares/avatar_usuario.dart';
import '../../compartido/widgets/formularios/barra_busqueda_app.dart';
import '../../compartido/widgets/navegacion/barra_superior_app.dart';
import '../../compartido/widgets/botones/boton_regresar.dart';
import '../../compartido/widgets/panel/panel_opciones.dart';
import '../../configuracion/colores_app.dart';
import '../autenticacion/auth_cubit.dart';
import '../autenticacion/auth_estado.dart';
import 'usuario_item.dart';
import 'usuarios_cubit.dart';
import 'usuarios_estado.dart';

/// Tipo local para las opciones del selector en lote (rol / tag).
typedef _SelectorOpcion = ({String id, String nombre, String? subtitulo});

class UsuariosPantalla extends StatefulWidget {
  const UsuariosPantalla({super.key});

  @override
  State<UsuariosPantalla> createState() => _UsuariosPantallaState();
}

class _UsuariosPantallaState extends State<UsuariosPantalla> {
  bool _estaIniciado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_estaIniciado) return;
    _estaIniciado = true;
    context.read<UsuariosCubit>().cargar();
  }

  String _adminId() {
    final estado = context.read<AuthCubit>().state;
    return estado is Autenticado ? (estado.usuario.id ?? '') : '';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UsuariosCubit, UsuariosEstado>(
      listenWhen: (prev, curr) {
        if (curr is UsuariosOperacionFallida) return true;
        if (prev is UsuariosCargados && curr is UsuariosCargados) {
          return curr.errorLote != null && curr.errorLote != prev.errorLote;
        }
        return false;
      },
      listener: (context, estado) {
        if (estado is UsuariosOperacionFallida) {
          AvisoApp.mostrar(context,
              texto: estado.mensaje, estilo: EstiloAviso.error);
        } else if (estado is UsuariosCargados && estado.errorLote != null) {
          AvisoApp.mostrar(context,
              texto: estado.errorLote!, estilo: EstiloAviso.error);
        }
      },
      builder: _construirVista,
    );
  }

  Widget _construirVista(BuildContext context, UsuariosEstado estado) {
    final cargados = switch (estado) {
      UsuariosCargados() => estado,
      UsuariosOperacionFallida() => estado.anterior,
      UsuariosCargandoMas() => UsuariosCargados(
          usuarios: estado.usuarios,
          usuariosFiltrados: estado.usuariosFiltrados,
          seleccionados: estado.seleccionados,
          modoSeleccion: estado.modoSeleccion,
          hayMas: true,
        ),
      _ => null,
    };
    final modoSeleccion = cargados?.modoSeleccion ?? false;
    final cantidadSeleccionados = cargados?.seleccionados.length ?? 0;
    final estaEjecutandoLote = cargados?.estaEjecutandoLote ?? false;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: PopScope(
        canPop: !modoSeleccion,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) context.read<UsuariosCubit>().salirModoSeleccion();
        },
        child: Scaffold(
          backgroundColor: ColoresApp.fondo,
          body: Column(
            children: [
              SafeArea(
                bottom: false,
                child: modoSeleccion
                    ? _BarraModoSeleccion(
                        cantidad: cantidadSeleccionados,
                        alCancelar: () =>
                            context.read<UsuariosCubit>().salirModoSeleccion(),
                      )
                    : BarraSuperiorApp(
                        izquierda: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const BotonRegresar(),
                            const SizedBox(width: 12),
                            _CabeceraTitulo(estado: estado),
                          ],
                        ),
                      ),
              ),
              if (!modoSeleccion)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: BarraBusquedaApp(
                    hintText: 'Buscar nombre, email, cédula...',
                    alCambiar: (texto) =>
                        context.read<UsuariosCubit>().filtrar(texto),
                  ),
                ),
              Expanded(child: _Cuerpo(estado: estado)),
            ],
          ),
          bottomNavigationBar: modoSeleccion
              ? _BarraAccionesLote(
                  cantidadSeleccionados: cantidadSeleccionados,
                  estaEjecutando: estaEjecutandoLote,
                  alAsignarRol: () => _mostrarSelectorRol(context),
                  alAsignarTag: () => _mostrarSelectorTag(context),
                  alSuspender: () => _mostrarConfirmarSuspenderLote(
                    context,
                    cantidadSeleccionados,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  // ── Modales de acciones en lote ────────────────────────────────────────────

  void _mostrarSelectorRol(BuildContext context) {
    final cubit = context.read<UsuariosCubit>();
    final adminId = _adminId();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ColoresApp.superficiePrimaria,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _SelectorOpcionModal(
        titulo: 'Asignar rol',
        futureOpciones: cubit.cargarRolesParaSelector().then(
              (roles) => roles
                  .map<_SelectorOpcion>(
                    (r) => (id: r.id, nombre: r.nombre, subtitulo: null),
                  )
                  .toList(),
            ),
        alSeleccionar: (id) {
          Navigator.of(ctx).pop();
          cubit.asignarRolLote(id, adminId);
        },
      ),
    );
  }

  void _mostrarSelectorTag(BuildContext context) {
    final cubit = context.read<UsuariosCubit>();
    final adminId = _adminId();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ColoresApp.superficiePrimaria,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _SelectorOpcionModal(
        titulo: 'Asignar tag',
        futureOpciones: cubit.cargarTagsParaSelector().then(
              (tags) => tags
                  .map<_SelectorOpcion>(
                    (t) => (
                      id: t.id,
                      nombre: t.nombre,
                      subtitulo:
                          t.tipo == 'principal' ? 'Principal' : 'Secundario',
                    ),
                  )
                  .toList(),
            ),
        alSeleccionar: (id) {
          Navigator.of(ctx).pop();
          cubit.asignarTagLote(id, adminId);
        },
      ),
    );
  }

  void _mostrarConfirmarSuspenderLote(BuildContext context, int cantidad) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DialogoConfirmarSuspenderLote(
        cantidad: cantidad,
        alConfirmar: () => context.read<UsuariosCubit>().suspenderLote(),
      ),
    );
  }
}

// ─── Barra superior en modo selección ────────────────────────────────────────

class _BarraModoSeleccion extends StatelessWidget {
  const _BarraModoSeleccion({
    required this.cantidad,
    required this.alCancelar,
  });

  final int cantidad;
  final VoidCallback alCancelar;

  @override
  Widget build(BuildContext context) {
    return BarraSuperiorApp(
      izquierda: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: alCancelar,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.close_rounded,
                  size: 22,
                  color: ColoresApp.textoPrimario,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$cantidad ${cantidad == 1 ? "seleccionado" : "seleccionados"}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: ColoresApp.textoPrimario,
                ),
          ),
        ],
      ),
    );
  }
}

// ─── Cabecera con título y contador ──────────────────────────────────────────

class _CabeceraTitulo extends StatelessWidget {
  const _CabeceraTitulo({required this.estado});

  final UsuariosEstado estado;

  @override
  Widget build(BuildContext context) {
    final total = switch (estado) {
      UsuariosCargados(:final usuariosFiltrados) => usuariosFiltrados.length,
      UsuariosCargandoMas(:final usuariosFiltrados) => usuariosFiltrados.length,
      _ => null,
    };
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Usuarios',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: ColoresApp.textoPrimario,
              ),
        ),
        if (total != null)
          Text(
            '$total registrados',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: ColoresApp.textoSecundario,
                  fontSize: 13,
                ),
          ),
      ],
    );
  }
}

// ─── Cuerpo según estado ──────────────────────────────────────────────────────

class _Cuerpo extends StatelessWidget {
  const _Cuerpo({required this.estado});

  final UsuariosEstado estado;

  @override
  Widget build(BuildContext context) {
    final e = estado;
    return switch (e) {
      UsuariosInicial() || UsuariosCargando() => const Center(
          child: CircularProgressIndicator(color: ColoresApp.acento),
        ),
      UsuariosCargados() => _Lista(estado: e),
      UsuariosCargandoMas() => _Lista(
          estado: UsuariosCargados(
            usuarios: e.usuarios,
            usuariosFiltrados: e.usuariosFiltrados,
            seleccionados: e.seleccionados,
            modoSeleccion: e.modoSeleccion,
            hayMas: true,
          ),
          cargandoMas: true,
        ),
      UsuariosOperacionFallida() => _Lista(estado: e.anterior),
      UsuariosError() => _VistaError(mensaje: e.mensaje),
    };
  }
}

// ─── Lista de usuarios ────────────────────────────────────────────────────────

class _Lista extends StatelessWidget {
  const _Lista({required this.estado, this.cargandoMas = false});

  final UsuariosCargados estado;
  final bool cargandoMas;

  @override
  Widget build(BuildContext context) {
    final items = estado.usuariosFiltrados;

    if (items.isEmpty) {
      return Center(
        child: Text(
          'No hay usuarios',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ColoresApp.textoTerciario,
              ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        if (!estado.modoSeleccion) ...[
          const _EncabezadoColumnas(),
          const SizedBox(height: 12),
        ],
        ...items.map(
          (u) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _TarjetaUsuario(
              usuario: u,
              modoSeleccion: estado.modoSeleccion,
              estaSeleccionado: estado.seleccionados.contains(u.id),
            ),
          ),
        ),
        if (cargandoMas)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Center(
              child: CircularProgressIndicator(color: ColoresApp.acento),
            ),
          )
        else if (estado.hayMas && !estado.modoSeleccion)
          Center(
            child: TextButton.icon(
              onPressed: () => context.read<UsuariosCubit>().cargarMas(),
              icon: const Icon(Icons.expand_more_rounded),
              label: const Text('Cargar más'),
            ),
          ),
      ],
    );
  }
}

// ─── Encabezado de columnas ───────────────────────────────────────────────────

class _EncabezadoColumnas extends StatelessWidget {
  const _EncabezadoColumnas();

  static const _estilo = TextStyle(
    color: ColoresApp.textoTerciario,
    letterSpacing: 0.8,
    fontSize: 13,
    fontWeight: FontWeight.w900,
  );

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Text('USUARIO', style: _estilo),
        Spacer(),
        Text('ESTADO', style: _estilo),
        SizedBox(width: 38),
      ],
    );
  }
}

// ─── Tarjeta de usuario ───────────────────────────────────────────────────────

class _TarjetaUsuario extends StatelessWidget {
  const _TarjetaUsuario({
    required this.usuario,
    required this.modoSeleccion,
    required this.estaSeleccionado,
  });

  final UsuarioItem usuario;
  final bool modoSeleccion;
  final bool estaSeleccionado;

  static (Color, Color) _colorAvatar(String id) {
    final paleta = [
      (ColoresApp.acentoClaro, ColoresApp.acento),
      (ColoresApp.tealClaro, ColoresApp.teal),
      (ColoresApp.verdeClaro, ColoresApp.verde),
      (ColoresApp.ambarClaro, ColoresApp.ambar),
    ];
    return paleta[id.hashCode.abs() % paleta.length];
  }

  void _mostrarOpciones(BuildContext context) {
    PanelOpciones.mostrar(
      context,
      encabezado: _EncabezadoPanel(usuario: usuario),
      opciones: _opciones(context),
    );
  }

  List<OpcionPanel> _opciones(BuildContext context) => [
        OpcionPanel(
          icono: Icons.person_outline_rounded,
          colorFondo: ColoresApp.acentoClaro,
          colorIcono: ColoresApp.acento,
          titulo: 'Ver perfil',
          descripcion: 'Información completa del usuario',
          alPresionar: () {
            Navigator.of(context, rootNavigator: true).pop();
            context.push(Rutas.verPerfilUsuarioUrl(usuario.id));
          },
        ),
        OpcionPanel(
          icono: Icons.people_outline_rounded,
          colorFondo: ColoresApp.tealClaro,
          colorIcono: ColoresApp.teal,
          titulo: 'Gestionar Roles',
          descripcion: 'Asignar o remover roles',
          alPresionar: () {
            Navigator.of(context, rootNavigator: true).pop();
            context.push(Rutas.gestionarRolesUsuarioUrl(usuario.id));
          },
        ),
        OpcionPanel(
          icono: Icons.label_outline_rounded,
          colorFondo: ColoresApp.ambarClaro,
          colorIcono: ColoresApp.ambar,
          titulo: 'Gestionar Tags',
          descripcion: 'Etiquetas y categorías',
          alPresionar: () {
            Navigator.of(context, rootNavigator: true).pop();
            context.push(Rutas.gestionarTagsUsuarioUrl(usuario.id));
          },
        ),
        OpcionPanel(
          icono: Icons.edit_outlined,
          colorFondo: ColoresApp.superficieTerciar,
          colorIcono: ColoresApp.textoSecundario,
          titulo: 'Editar información',
          descripcion: 'Datos personales y contacto',
          alPresionar: () {
            Navigator.of(context, rootNavigator: true).pop();
            context.push(Rutas.editarUsuarioUrl(usuario.id));
          },
        ),
        OpcionPanel(
          icono: Icons.block_rounded,
          colorFondo: ColoresApp.rojoClaro,
          colorIcono: ColoresApp.rojo,
          colorTitulo: ColoresApp.rojo,
          titulo: 'Suspender usuario',
          descripcion: 'Bloquear acceso temporalmente',
          alPresionar: () {
            Navigator.of(context, rootNavigator: true).pop();
            _mostrarDialogoSuspender(context);
          },
        ),
      ];

  void _mostrarDialogoSuspender(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DialogoSuspenderUsuario(
        usuario: usuario,
        alConfirmar: () => context.read<UsuariosCubit>().suspender(usuario.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (colorFondo, colorTexto) = _colorAvatar(usuario.id);
    final cubit = context.read<UsuariosCubit>();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: ColoresApp.sombraTarjeta,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Material(
          color: estaSeleccionado
              ? ColoresApp.acentoClaro
              : ColoresApp.superficiePrimaria,
          child: InkWell(
            onLongPress:
                modoSeleccion ? null : () => cubit.activarSeleccion(usuario.id),
            onTap:
                modoSeleccion ? () => cubit.toggleSeleccion(usuario.id) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  if (modoSeleccion) ...[
                    _CheckboxCircular(activo: estaSeleccionado),
                    const SizedBox(width: 12),
                  ] else ...[
                    AvatarUsuario(
                      iniciales: usuario.iniciales,
                      tamanio: 40,
                      colorFondo: colorFondo,
                      colorTexto: colorTexto,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          usuario.nombreCompleto,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: ColoresApp.textoPrimario,
                                    fontSize: 15,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          usuario.correo,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: ColoresApp.textoSecundario,
                                    fontSize: 13,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _InsigniaEstatus(activo: usuario.estatus),
                  if (!modoSeleccion) ...[
                    const SizedBox(width: 6),
                    _BotonOpciones(
                        alPresionar: () => _mostrarOpciones(context)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Checkbox circular para modo selección ───────────────────────────────────

class _CheckboxCircular extends StatelessWidget {
  const _CheckboxCircular({required this.activo});

  final bool activo;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: activo ? ColoresApp.acento : Colors.transparent,
        border: Border.all(
          color: activo ? ColoresApp.acento : ColoresApp.textoTerciario,
          width: 1.5,
        ),
      ),
      child: activo
          ? const Icon(Icons.check, size: 14, color: ColoresApp.blanco)
          : null,
    );
  }
}

// ─── Barra inferior de acciones en lote ──────────────────────────────────────

class _BarraAccionesLote extends StatelessWidget {
  const _BarraAccionesLote({
    required this.cantidadSeleccionados,
    required this.estaEjecutando,
    required this.alAsignarRol,
    required this.alAsignarTag,
    required this.alSuspender,
  });

  final int cantidadSeleccionados;
  final bool estaEjecutando;
  final VoidCallback alAsignarRol;
  final VoidCallback alAsignarTag;
  final VoidCallback alSuspender;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: ColoresApp.superficiePrimaria,
          boxShadow: [
            BoxShadow(
              color: ColoresApp.sombraTarjeta,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: estaEjecutando
            ? const SizedBox(
                height: 56,
                child: Center(
                  child: CircularProgressIndicator(color: ColoresApp.acento),
                ),
              )
            : Row(
                children: [
                  Expanded(
                    child: _BotonAccionLote(
                      icono: Icons.people_alt_outlined,
                      etiqueta: 'Asignar rol',
                      color: ColoresApp.teal,
                      colorFondo: ColoresApp.tealClaro,
                      alPresionar: alAsignarRol,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _BotonAccionLote(
                      icono: Icons.label_outlined,
                      etiqueta: 'Asignar tag',
                      color: ColoresApp.ambar,
                      colorFondo: ColoresApp.ambarClaro,
                      alPresionar: alAsignarTag,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _BotonAccionLote(
                      icono: Icons.block_rounded,
                      etiqueta: 'Suspender',
                      color: ColoresApp.rojo,
                      colorFondo: ColoresApp.rojoClaro,
                      alPresionar: alSuspender,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _BotonAccionLote extends StatelessWidget {
  const _BotonAccionLote({
    required this.icono,
    required this.etiqueta,
    required this.color,
    required this.colorFondo,
    required this.alPresionar,
  });

  final IconData icono;
  final String etiqueta;
  final Color color;
  final Color colorFondo;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorFondo,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: alPresionar,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icono, size: 22, color: color),
              const SizedBox(height: 4),
              Text(
                etiqueta,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Modal selector de opción (rol / tag) ─────────────────────────────────────

class _SelectorOpcionModal extends StatefulWidget {
  const _SelectorOpcionModal({
    required this.titulo,
    required this.futureOpciones,
    required this.alSeleccionar,
  });

  final String titulo;
  final Future<List<_SelectorOpcion>> futureOpciones;
  final void Function(String id) alSeleccionar;

  @override
  State<_SelectorOpcionModal> createState() => _SelectorOpcionModalState();
}

class _SelectorOpcionModalState extends State<_SelectorOpcionModal> {
  String? _seleccionado;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: ColoresApp.bordeMedio,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text(
              widget.titulo,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: ColoresApp.textoPrimario,
                  ),
            ),
          ),
          // Lista de opciones
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: FutureBuilder<List<_SelectorOpcion>>(
              future: widget.futureOpciones,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 80,
                    child: Center(
                      child:
                          CircularProgressIndicator(color: ColoresApp.acento),
                    ),
                  );
                }
                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No hay opciones disponibles',
                      style: TextStyle(color: ColoresApp.textoSecundario),
                    ),
                  );
                }
                final opciones = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: opciones.length,
                  itemBuilder: (context, i) {
                    final op = opciones[i];
                    final seleccionado = _seleccionado == op.id;
                    return ListTile(
                      leading: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: seleccionado
                              ? ColoresApp.acento
                              : Colors.transparent,
                          border: Border.all(
                            color: seleccionado
                                ? ColoresApp.acento
                                : ColoresApp.bordeMedio,
                          ),
                        ),
                        child: seleccionado
                            ? const Icon(Icons.check,
                                size: 12, color: ColoresApp.blanco)
                            : null,
                      ),
                      title: Text(
                        op.nombre,
                        style: TextStyle(
                          color: ColoresApp.textoPrimario,
                          fontWeight: seleccionado
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: op.subtitulo != null
                          ? Text(
                              op.subtitulo!,
                              style: const TextStyle(
                                color: ColoresApp.textoSecundario,
                                fontSize: 12,
                              ),
                            )
                          : null,
                      onTap: () => setState(() => _seleccionado = op.id),
                    );
                  },
                );
              },
            ),
          ),
          // Botones
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _seleccionado != null
                        ? () => widget.alSeleccionar(_seleccionado!)
                        : null,
                    child: const Text('Confirmar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Diálogo confirmar suspensión en lote ────────────────────────────────────

class _DialogoConfirmarSuspenderLote extends StatelessWidget {
  const _DialogoConfirmarSuspenderLote({
    required this.cantidad,
    required this.alConfirmar,
  });

  final int cantidad;
  final VoidCallback alConfirmar;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ColoresApp.superficiePrimaria,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.block_rounded, color: ColoresApp.rojo, size: 22),
          SizedBox(width: 10),
          Text(
            'Suspender usuarios',
            style: TextStyle(
              color: ColoresApp.textoPrimario,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      content: Text(
        'Se suspenderá el acceso de $cantidad '
        '${cantidad == 1 ? "usuario seleccionado" : "usuarios seleccionados"}. '
        'Esta acción puede revertirse individualmente.',
        style: const TextStyle(
          color: ColoresApp.textoSecundario,
          fontSize: 14,
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: ColoresApp.textoSecundario),
          ),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            alConfirmar();
          },
          style: FilledButton.styleFrom(
            backgroundColor: ColoresApp.rojo,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Suspender'),
        ),
      ],
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
        color: activo ? ColoresApp.verdeClaro : ColoresApp.rojoClaro,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: activo ? ColoresApp.bordeExito : ColoresApp.bordeError,
          width: 0.8,
        ),
      ),
      child: Text(
        activo ? 'Activo' : 'Inactivo',
        style: TextStyle(
          color: activo ? ColoresApp.verde : ColoresApp.rojo,
          fontSize: 11,
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
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: alPresionar,
        borderRadius: BorderRadius.circular(8),
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(
            Icons.more_vert_rounded,
            color: ColoresApp.textoTerciario,
            size: 20,
          ),
        ),
      ),
    );
  }
}

// ─── Encabezado del panel de opciones ────────────────────────────────────────

class _EncabezadoPanel extends StatelessWidget {
  const _EncabezadoPanel({required this.usuario});

  final UsuarioItem usuario;

  @override
  Widget build(BuildContext context) {
    final (colorFondo, colorTexto) = _TarjetaUsuario._colorAvatar(usuario.id);
    return Row(
      children: [
        AvatarUsuario(
          iniciales: usuario.iniciales,
          tamanio: 44,
          colorFondo: colorFondo,
          colorTexto: colorTexto,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                usuario.nombreCompleto,
                style: const TextStyle(
                  color: ColoresApp.textoPrimario,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                usuario.correo,
                style: const TextStyle(
                  color: ColoresApp.textoSecundario,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Diálogo confirmar suspensión individual ─────────────────────────────────

class _DialogoSuspenderUsuario extends StatefulWidget {
  const _DialogoSuspenderUsuario({
    required this.usuario,
    required this.alConfirmar,
  });

  final UsuarioItem usuario;
  final VoidCallback alConfirmar;

  @override
  State<_DialogoSuspenderUsuario> createState() =>
      _DialogoSuspenderUsuarioState();
}

class _DialogoSuspenderUsuarioState extends State<_DialogoSuspenderUsuario> {
  final _ctrl = TextEditingController();
  bool _coincide = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _alCambiar(String valor) {
    final nuevo = valor.trim().toLowerCase() ==
        widget.usuario.nombreCompleto.trim().toLowerCase();
    if (nuevo != _coincide) setState(() => _coincide = nuevo);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ColoresApp.superficiePrimaria,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.block_rounded, color: ColoresApp.rojo, size: 22),
          SizedBox(width: 10),
          Text(
            'Suspender usuario',
            style: TextStyle(
              color: ColoresApp.textoPrimario,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(
                color: ColoresApp.textoSecundario,
                fontSize: 14,
                height: 1.5,
              ),
              children: [
                const TextSpan(
                  text: 'Para confirmar, escribe el nombre completo de ',
                ),
                TextSpan(
                  text: widget.usuario.nombreCompleto,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: ColoresApp.textoPrimario,
                  ),
                ),
                const TextSpan(text: ':'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            onChanged: _alCambiar,
            style: const TextStyle(
              color: ColoresApp.textoPrimario,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'Nombre completo',
              hintStyle: const TextStyle(color: ColoresApp.textoTerciario),
              filled: true,
              fillColor: ColoresApp.fondo,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: ColoresApp.bordeMedio),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: ColoresApp.bordeMedio),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: ColoresApp.acento, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: ColoresApp.textoSecundario),
          ),
        ),
        FilledButton(
          onPressed: _coincide
              ? () {
                  Navigator.of(context).pop();
                  widget.alConfirmar();
                }
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: ColoresApp.rojo,
            disabledBackgroundColor: ColoresApp.rojoClaro,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Suspender'),
        ),
      ],
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
              onPressed: () => context.read<UsuariosCubit>().cargar(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
