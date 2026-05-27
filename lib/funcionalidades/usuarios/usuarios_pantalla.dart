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
import 'usuario_item.dart';
import 'usuarios_cubit.dart';
import 'usuarios_estado.dart';

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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UsuariosCubit, UsuariosEstado>(
      listenWhen: (_, curr) => curr is UsuariosOperacionFallida,
      listener: (context, estado) {
        if (estado is UsuariosOperacionFallida) {
          AvisoApp.mostrar(context, texto: estado.mensaje, estilo: EstiloAviso.error);
        }
      },
      builder: _construirVista,
    );
  }

  Widget _construirVista(BuildContext context, UsuariosEstado estado) {
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
                    _CabeceraTitulo(estado: estado),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: BarraBusquedaApp(
                hintText:  'Buscar nombre, email, cédula...',
                alCambiar: (texto) => context.read<UsuariosCubit>().filtrar(texto),
              ),
            ),
            Expanded(child: _Cuerpo(estado: estado)),
          ],
        ),
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
    final total = estado is UsuariosCargados
        ? (estado as UsuariosCargados).usuariosFiltrados.length
        : null;
    return Column(
      mainAxisAlignment:  MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Usuarios',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontSize:   20,
            fontWeight: FontWeight.w700,
            color:      ColoresApp.textoPrimario,
          ),
        ),
        if (total != null)
          Text(
            '$total registrados',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color:    ColoresApp.textoSecundario,
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
      UsuariosCargados()          => _Lista(estado: e),
      UsuariosOperacionFallida()  => _Lista(estado: e.anterior),
      UsuariosError()             => _VistaError(mensaje: e.mensaje),
    };
  }
}

// ─── Lista de usuarios ────────────────────────────────────────────────────────

class _Lista extends StatelessWidget {
  const _Lista({required this.estado});

  final UsuariosCargados estado;

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
        const _EncabezadoColumnas(),
        const SizedBox(height: 12),
        ...items.map((u) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child:   _TarjetaUsuario(usuario: u),
        ),),
      ],
    );
  }
}

// ─── Encabezado de columnas ───────────────────────────────────────────────────

class _EncabezadoColumnas extends StatelessWidget {
  const _EncabezadoColumnas();

  static const _estilo = TextStyle(
    color:         ColoresApp.textoTerciario,
    letterSpacing: 0.8,
    fontSize:      13,
    fontWeight:    FontWeight.w900,
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
  const _TarjetaUsuario({required this.usuario});

  final UsuarioItem usuario;

  static (Color, Color) _colorAvatar(String id) {
    final paleta = [
      (ColoresApp.acentoClaro, ColoresApp.acento),
      (ColoresApp.tealClaro,   ColoresApp.teal),
      (ColoresApp.verdeClaro,  ColoresApp.verde),
      (ColoresApp.ambarClaro,  ColoresApp.ambar),
    ];
    return paleta[id.hashCode.abs() % paleta.length];
  }

  void _mostrarOpciones(BuildContext context) {
    PanelOpciones.mostrar(
      context,
      encabezado: _EncabezadoPanel(usuario: usuario),
      opciones:   _opciones(context),
    );
  }

  List<OpcionPanel> _opciones(BuildContext context) => [
    OpcionPanel(
      icono:       Icons.person_outline_rounded,
      colorFondo:  ColoresApp.acentoClaro,
      colorIcono:  ColoresApp.acento,
      titulo:      'Ver perfil',
      descripcion: 'Información completa del usuario',
      alPresionar: () {
        Navigator.of(context, rootNavigator: true).pop();
        context.push(Rutas.verPerfilUsuarioUrl(usuario.id));
      },
    ),
    OpcionPanel(
      icono:       Icons.people_outline_rounded,
      colorFondo:  ColoresApp.tealClaro,
      colorIcono:  ColoresApp.teal,
      titulo:      'Gestionar Roles',
      descripcion: 'Asignar o remover roles',
      alPresionar: () {
        Navigator.of(context, rootNavigator: true).pop();
        context.push(Rutas.gestionarRolesUsuarioUrl(usuario.id));
      },
    ),
    OpcionPanel(
      icono:       Icons.label_outline_rounded,
      colorFondo:  ColoresApp.ambarClaro,
      colorIcono:  ColoresApp.ambar,
      titulo:      'Gestionar Tags',
      descripcion: 'Etiquetas y categorías',
      alPresionar: () {
        Navigator.of(context, rootNavigator: true).pop();
        context.push(Rutas.gestionarTagsUsuarioUrl(usuario.id));
      },
    ),
    OpcionPanel(
      icono:       Icons.edit_outlined,
      colorFondo:  ColoresApp.superficieTerciar,
      colorIcono:  ColoresApp.textoSecundario,
      titulo:      'Editar información',
      descripcion: 'Datos personales y contacto',
      alPresionar: () {
        Navigator.of(context, rootNavigator: true).pop();
        context.push(Rutas.editarUsuarioUrl(usuario.id));
      },
    ),
    OpcionPanel(
      icono:        Icons.block_rounded,
      colorFondo:   ColoresApp.rojoClaro,
      colorIcono:   ColoresApp.rojo,
      colorTitulo:  ColoresApp.rojo,
      titulo:       'Suspender usuario',
      descripcion:  'Bloquear acceso temporalmente',
      alPresionar: () {
        Navigator.of(context, rootNavigator: true).pop();
        _mostrarDialogoSuspender(context);
      },
    ),
  ];

  void _mostrarDialogoSuspender(BuildContext context) {
    showDialog<void>(
      context:           context,
      barrierDismissible: false,
      builder: (_) => _DialogoSuspenderUsuario(
        usuario:    usuario,
        alConfirmar: () => context.read<UsuariosCubit>().suspender(usuario.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (colorFondo, colorTexto) = _colorAvatar(usuario.id);
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
          AvatarUsuario(
            iniciales:  usuario.iniciales,
            tamanio:    40,
            colorFondo: colorFondo,
            colorTexto: colorTexto,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  usuario.nombreCompleto,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color:      ColoresApp.textoPrimario,
                    fontSize:   15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  usuario.correo,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:    ColoresApp.textoSecundario,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _InsigniaEstatus(activo: usuario.estatus),
          const SizedBox(width: 6),
          _BotonOpciones(alPresionar: () => _mostrarOpciones(context)),
        ],
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
          iniciales:  usuario.iniciales,
          tamanio:    44,
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
                  color:      ColoresApp.textoPrimario,
                  fontSize:   16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                usuario.correo,
                style: const TextStyle(
                  color:    ColoresApp.textoSecundario,
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

// ─── Diálogo confirmar suspensión ────────────────────────────────────────────

class _DialogoSuspenderUsuario extends StatefulWidget {
  const _DialogoSuspenderUsuario({
    required this.usuario,
    required this.alConfirmar,
  });

  final UsuarioItem  usuario;
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
                const TextSpan(text: 'Para confirmar, escribe el nombre completo de '),
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
            controller:  _ctrl,
            onChanged:   _alCambiar,
            style: const TextStyle(
              color:    ColoresApp.textoPrimario,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText:    'Nombre completo',
              hintStyle:   const TextStyle(color: ColoresApp.textoTerciario),
              filled:      true,
              fillColor:   ColoresApp.fondo,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:   const BorderSide(color: ColoresApp.bordeMedio),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:   const BorderSide(color: ColoresApp.bordeMedio),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:   const BorderSide(color: ColoresApp.acento, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
