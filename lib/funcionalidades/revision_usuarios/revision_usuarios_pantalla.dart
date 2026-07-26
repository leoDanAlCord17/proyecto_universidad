import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../compartido/constantes.dart';
import '../../compartido/widgets/avisos/aviso_app.dart';
import '../../compartido/widgets/avisos/vista_error_app.dart';
import '../../compartido/widgets/botones/boton_app.dart';
import '../../compartido/widgets/botones/boton_regresar.dart';
import '../../compartido/widgets/dialogo/dialogo_confirmacion.dart';
import '../../compartido/widgets/formularios/barra_busqueda_app.dart';
import '../../compartido/widgets/navegacion/barra_superior_app.dart';
import '../../configuracion/colores_app.dart';
import 'revision_usuario_item.dart';
import 'revision_usuarios_cubit.dart';
import 'revision_usuarios_estado.dart';

class RevisionUsuariosPantalla extends StatefulWidget {
  const RevisionUsuariosPantalla({super.key});

  @override
  State<RevisionUsuariosPantalla> createState() =>
      _RevisionUsuariosPantallaState();
}

class _RevisionUsuariosPantallaState extends State<RevisionUsuariosPantalla> {
  bool _estaIniciado = false;
  String _busqueda = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_estaIniciado) return;
    _estaIniciado = true;
    context.read<RevisionUsuariosCubit>().cargar();
  }

  List<RevisionUsuarioItem> _aplicarFiltro(List<RevisionUsuarioItem> usuarios) {
    if (_busqueda.trim().isEmpty) return usuarios;
    final q = _busqueda.toLowerCase().trim();
    return usuarios
        .where(
          (u) =>
              u.nombreCompleto.toLowerCase().contains(q) ||
              u.correo.toLowerCase().contains(q) ||
              (u.numeroIdentificacion?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RevisionUsuariosCubit, RevisionUsuariosEstado>(
      listenWhen: (_, curr) =>
          curr is RevisionUsuariosCargados && curr.errorOperacion != null,
      listener: (context, estado) {
        if (estado is RevisionUsuariosCargados &&
            estado.errorOperacion != null) {
          AvisoApp.mostrar(
            context,
            texto: estado.errorOperacion!,
            estilo: EstiloAviso.error,
          );
        }
      },
      builder: _construirVista,
    );
  }

  Widget _construirVista(
    BuildContext context,
    RevisionUsuariosEstado estado,
  ) {
    final (estadoMostrar, cargandoMas) = switch (estado) {
      RevisionUsuariosCargados() => (
          estado.copiarCon(usuarios: _aplicarFiltro(estado.usuarios)),
          false,
        ),
      RevisionUsuariosCargandoMas() => (
          RevisionUsuariosCargados(
            usuarios: _aplicarFiltro(estado.usuarios),
            hayMas: true,
          ),
          true,
        ),
      _ => (estado, false),
    };

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
            const _BarraTitulo(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: BarraBusquedaApp(
                hintText: 'Buscar nombre, correo o cédula...',
                alCambiar: (v) => setState(() => _busqueda = v),
              ),
            ),
            Expanded(
              child: _Cuerpo(
                estado: estadoMostrar,
                busqueda: _busqueda,
                cargandoMas: cargandoMas,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Barra de título ──────────────────────────────────────────────────────────

class _BarraTitulo extends StatelessWidget {
  const _BarraTitulo();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: BarraSuperiorApp(
        izquierda: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BotonRegresar(),
            const SizedBox(width: 12),
            Text(
              'Revisión de usuarios',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: ColoresApp.textoPrimario,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Cuerpo según estado ──────────────────────────────────────────────────────

class _Cuerpo extends StatelessWidget {
  const _Cuerpo({
    required this.estado,
    required this.busqueda,
    this.cargandoMas = false,
  });

  final RevisionUsuariosEstado estado;
  final String busqueda;
  final bool cargandoMas;

  @override
  Widget build(BuildContext context) {
    return switch (estado) {
      RevisionUsuariosInicial() ||
      RevisionUsuariosCargando() ||
      RevisionUsuariosCargandoMas() =>
        const Center(
          child: CircularProgressIndicator(color: ColoresApp.acento),
        ),
      final RevisionUsuariosCargados cargados =>
        _Lista(estado: cargados, busqueda: busqueda, cargandoMas: cargandoMas),
      final RevisionUsuariosError error => VistaErrorApp(
          mensaje: error.mensaje,
          alReintentar: () => context.read<RevisionUsuariosCubit>().cargar()),
    };
  }
}

// ─── Lista de usuarios pendientes ─────────────────────────────────────────────

class _Lista extends StatelessWidget {
  const _Lista({
    required this.estado,
    required this.busqueda,
    this.cargandoMas = false,
  });

  final RevisionUsuariosCargados estado;
  final String busqueda;
  final bool cargandoMas;

  @override
  Widget build(BuildContext context) {
    if (estado.usuarios.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            busqueda.trim().isNotEmpty
                ? 'Sin resultados para "$busqueda"'
                : 'No hay usuarios pendientes de aprobación',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ColoresApp.textoTerciario,
                ),
          ),
        ),
      );
    }

    final mostrarPie = cargandoMas || estado.hayMas;
    final itemCount = 1 + estado.usuarios.length + (mostrarPie ? 1 : 0);

    return Stack(
      fit: StackFit.expand,
      children: [
        ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'USUARIOS PENDIENTES',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: ColoresApp.textoTerciario,
                        letterSpacing: 0.8,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              );
            }

            if (index - 1 < estado.usuarios.length) {
              final usuario = estado.usuarios[index - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _TarjetaUsuarioPendiente(
                  usuario: usuario,
                  estaProcessando: estado.usuarioIdProcessando == usuario.id,
                  alAceptar: () =>
                      context.read<RevisionUsuariosCubit>().aprobar(usuario.id),
                  alRechazar: () async {
                    final confirmo = await DialogoConfirmacion.mostrar(
                      context,
                      titulo: 'Rechazar usuario',
                      descripcion:
                          '¿Deseas rechazar la solicitud de ${usuario.primerNombre} ${usuario.primerApellido}? El usuario podrá volver a intentarlo.',
                      textoConfirmar: 'Rechazar',
                      textoCancelar: 'Cancelar',
                    );
                    if (confirmo != true || !context.mounted) return;
                    unawaited(context
                        .read<RevisionUsuariosCubit>()
                        .rechazar(usuario.id));
                  },
                ),
              );
            }

            if (cargandoMas) {
              return const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Center(
                  child: CircularProgressIndicator(color: ColoresApp.acento),
                ),
              );
            }
            return TextButton.icon(
              onPressed: () =>
                  context.read<RevisionUsuariosCubit>().cargarMas(),
              icon: const Icon(Icons.expand_more_rounded),
              label: const Text('Cargar más'),
            );
          },
        ),
        if (estado.usuarioIdProcessando != null)
          const ColoredBox(
            color: ColoresApp.sombraGeneral,
            child: Center(
              child: CircularProgressIndicator(color: ColoresApp.acento),
            ),
          ),
      ],
    );
  }
}

// ─── Tarjeta de usuario pendiente ─────────────────────────────────────────────

class _TarjetaUsuarioPendiente extends StatelessWidget {
  const _TarjetaUsuarioPendiente({
    required this.usuario,
    required this.estaProcessando,
    required this.alAceptar,
    required this.alRechazar,
  });

  final RevisionUsuarioItem usuario;
  final bool estaProcessando;
  final VoidCallback alAceptar;
  final VoidCallback alRechazar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColoresApp.superficiePrimaria,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: ColoresApp.sombraTarjeta,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoUsuario(usuario: usuario),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          _BotonesNavegacion(usuarioId: usuario.id),
          const SizedBox(height: 10),
          _BotonesAccion(
            estaProcessando: estaProcessando,
            alAceptar: alAceptar,
            alRechazar: alRechazar,
          ),
        ],
      ),
    );
  }
}

// ─── Info del usuario ─────────────────────────────────────────────────────────

class _InfoUsuario extends StatelessWidget {
  const _InfoUsuario({required this.usuario});

  final RevisionUsuarioItem usuario;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          usuario.nombreCompleto,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: ColoresApp.textoPrimario,
                fontSize: 16,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          usuario.correo,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ColoresApp.textoSecundario,
                fontSize: 13,
              ),
        ),
        if (usuario.numeroIdentificacion != null) ...[
          const SizedBox(height: 2),
          Text(
            'ID: ${usuario.numeroIdentificacion}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ColoresApp.textoTerciario,
                  fontSize: 12,
                ),
          ),
        ],
        if (usuario.telefono != null) ...[
          const SizedBox(height: 2),
          Text(
            'Tel: ${usuario.telefono}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ColoresApp.textoTerciario,
                  fontSize: 12,
                ),
          ),
        ],
      ],
    );
  }
}

// ─── Botones de navegación a pantallas de roles y tags ────────────────────────

class _BotonesNavegacion extends StatelessWidget {
  const _BotonesNavegacion({required this.usuarioId});

  final String usuarioId;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () =>
                context.push(Rutas.gestionarRolesUsuarioUrl(usuarioId)),
            icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
            label: const Text('Agregar roles'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ColoresApp.teal,
              side: const BorderSide(color: ColoresApp.teal),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () =>
                context.push(Rutas.gestionarTagsUsuarioUrl(usuarioId)),
            icon: const Icon(Icons.label_outline_rounded, size: 18),
            label: const Text('Agregar tags'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ColoresApp.ambar,
              side: const BorderSide(color: ColoresApp.ambar),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Botones de acción ────────────────────────────────────────────────────────

class _BotonesAccion extends StatelessWidget {
  const _BotonesAccion({
    required this.estaProcessando,
    required this.alAceptar,
    required this.alRechazar,
  });

  final bool estaProcessando;
  final VoidCallback alAceptar;
  final VoidCallback alRechazar;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: estaProcessando ? null : alRechazar,
            style: OutlinedButton.styleFrom(
              foregroundColor: ColoresApp.rojo,
              side: BorderSide(
                color: estaProcessando
                    ? ColoresApp.textoTerciario
                    : ColoresApp.rojo,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Rechazar'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: BotonApp(
            texto: 'Aceptar',
            estaCargando: estaProcessando,
            alPresionar: estaProcessando ? null : alAceptar,
          ),
        ),
      ],
    );
  }
}
