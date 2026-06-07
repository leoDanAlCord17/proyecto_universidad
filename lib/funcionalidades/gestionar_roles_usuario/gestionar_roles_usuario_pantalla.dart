import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/widgets/avisos/aviso_app.dart';
import '../../compartido/widgets/avisos/vista_error_app.dart';
import '../../compartido/widgets/botones/boton_regresar.dart';
import '../../compartido/widgets/navegacion/barra_superior_app.dart';
import '../../configuracion/colores_app.dart';
import '../autenticacion/auth_cubit.dart';
import '../autenticacion/auth_estado.dart';
import 'gestionar_roles_usuario_cubit.dart';
import 'gestionar_roles_usuario_estado.dart';
import 'rol_item.dart';

class GestionarRolesUsuarioPantalla extends StatefulWidget {
  const GestionarRolesUsuarioPantalla({super.key, required this.usuarioId});

  final String usuarioId;

  @override
  State<GestionarRolesUsuarioPantalla> createState() =>
      _GestionarRolesUsuarioState();
}

class _GestionarRolesUsuarioState extends State<GestionarRolesUsuarioPantalla> {
  bool _estaIniciado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_estaIniciado) return;
    _estaIniciado = true;
    final authEstado = context.read<AuthCubit>().state;
    final adminId = authEstado is Autenticado ? authEstado.usuario.id : null;
    context
        .read<GestionarRolesUsuarioCubit>()
        .cargar(widget.usuarioId, adminId: adminId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GestionarRolesUsuarioCubit,
        GestionarRolesUsuarioEstado>(
      listenWhen: (_, curr) => curr is GestionarRolesUsuarioOperacionFallida,
      listener: (context, estado) {
        if (estado is GestionarRolesUsuarioOperacionFallida) {
          AvisoApp.mostrar(context,
              texto: estado.mensaje, estilo: EstiloAviso.error);
        }
      },
      builder: _construirVista,
    );
  }

  Widget _construirVista(
      BuildContext context, GestionarRolesUsuarioEstado estado) {
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

// ─── Cabecera ─────────────────────────────────────────────────────────────────

class _CabeceraTitulo extends StatelessWidget {
  const _CabeceraTitulo({required this.estado});

  final GestionarRolesUsuarioEstado estado;

  @override
  Widget build(BuildContext context) {
    final nombre = estado is GestionarRolesUsuarioCargado
        ? (estado as GestionarRolesUsuarioCargado).nombreUsuario
        : estado is GestionarRolesUsuarioOperacionFallida
            ? (estado as GestionarRolesUsuarioOperacionFallida)
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
              'Gestionar Roles',
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

// ─── Cuerpo ───────────────────────────────────────────────────────────────────

class _Cuerpo extends StatelessWidget {
  const _Cuerpo({required this.estado});

  final GestionarRolesUsuarioEstado estado;

  @override
  Widget build(BuildContext context) {
    final e = estado;
    return switch (e) {
      GestionarRolesUsuarioInicial() ||
      GestionarRolesUsuarioCargando() =>
        const Center(
          child: CircularProgressIndicator(color: ColoresApp.acento),
        ),
      GestionarRolesUsuarioCargado() => _VistaContenido(estado: e),
      GestionarRolesUsuarioOperacionFallida() =>
        _VistaContenido(estado: e.anterior),
      GestionarRolesUsuarioError() => VistaErrorApp(mensaje: e.mensaje),
    };
  }
}

// ─── Vista de contenido ───────────────────────────────────────────────────────

class _VistaContenido extends StatelessWidget {
  const _VistaContenido({required this.estado});

  final GestionarRolesUsuarioCargado estado;

  void _abrirPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: ColoresApp.sombraBarrera,
      builder: (_) => _HojaPickerRol(
        opciones: estado.rolesDisponibles,
        alSeleccionar: (rol) {
          Navigator.of(context, rootNavigator: true).pop();
          context.read<GestionarRolesUsuarioCubit>().asignarRol(rol.id);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LabelSeccion('ROLES ASIGNADOS · ${estado.rolesActivos.length}'),
          const SizedBox(height: 12),
          if (estado.rolesActivos.isEmpty)
            const _PlaceholderVacio(texto: 'Sin roles asignados')
          else
            ...estado.rolesActivos.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _FilaRolAsignado(
                  rol: r,
                  alQuitar: () => context
                      .read<GestionarRolesUsuarioCubit>()
                      .quitarRol(r.id),
                ),
              ),
            ),
          if (estado.rolesDisponibles.isNotEmpty) ...[
            const SizedBox(height: 10),
            _BotonAgregar(alPresionar: () => _abrirPicker(context)),
          ],
        ],
      ),
    );
  }
}

// ─── Fila de rol asignado ─────────────────────────────────────────────────────

class _FilaRolAsignado extends StatelessWidget {
  const _FilaRolAsignado({required this.rol, required this.alQuitar});

  final RolItem rol;
  final VoidCallback alQuitar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: ColoresApp.superficiePrimaria,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: ColoresApp.sombraTarjeta,
              blurRadius: 8,
              offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
                color: ColoresApp.teal, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rol.nombre,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ColoresApp.textoPrimario,
                        fontSize: 15,
                      ),
                ),
                if (rol.descripcion.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    rol.descripcion,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ColoresApp.textoSecundario,
                          fontSize: 13,
                        ),
                  ),
                ],
              ],
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
                child: Icon(Icons.close_rounded,
                    size: 18, color: ColoresApp.textoTerciario),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Botón agregar ────────────────────────────────────────────────────────────

class _BotonAgregar extends StatelessWidget {
  const _BotonAgregar({required this.alPresionar});

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
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, color: ColoresApp.acento, size: 18),
              SizedBox(width: 8),
              Text(
                'Agregar rol',
                style: TextStyle(
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

// ─── Placeholder ──────────────────────────────────────────────────────────────

class _PlaceholderVacio extends StatelessWidget {
  const _PlaceholderVacio({required this.texto});

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

// ─── Hoja picker de rol ───────────────────────────────────────────────────────

class _HojaPickerRol extends StatefulWidget {
  const _HojaPickerRol({required this.opciones, required this.alSeleccionar});

  final List<RolItem> opciones;
  final ValueChanged<RolItem> alSeleccionar;

  @override
  State<_HojaPickerRol> createState() => _HojaPickerRolState();
}

class _HojaPickerRolState extends State<_HojaPickerRol> {
  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    return ConstrainedBox(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
      child: Container(
        decoration: const BoxDecoration(
          color: ColoresApp.superficiePrimaria,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 14),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: ColoresApp.bordeMedio,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Asignar rol',
                  style: TextStyle(
                    color: ColoresApp.textoPrimario,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: ColoresApp.bordesuave),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding + 20),
                itemCount: widget.opciones.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  indent: 16,
                  color: ColoresApp.bordesuave,
                ),
                itemBuilder: (_, i) {
                  final rol = widget.opciones[i];
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => widget.alSeleccionar(rol),
                      borderRadius: BorderRadius.circular(10),
                      highlightColor: ColoresApp.superficieSecund,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: ColoresApp.teal,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rol.nombre,
                                    style: const TextStyle(
                                      color: ColoresApp.textoPrimario,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (rol.descripcion.isNotEmpty)
                                    Text(
                                      rol.descripcion,
                                      style: const TextStyle(
                                        color: ColoresApp.textoTerciario,
                                        fontSize: 13,
                                      ),
                                    ),
                                ],
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
