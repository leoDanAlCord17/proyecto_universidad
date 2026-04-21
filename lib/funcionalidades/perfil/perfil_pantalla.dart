import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../compartido/constantes.dart';

import '../../compartido/widgets/avatares/avatar_usuario.dart';
import '../../compartido/widgets/navegacion/barra_navegacion_app.dart';
import '../../compartido/widgets/qr/tarjeta_qr_usuario.dart';
import '../../compartido/widgets/tarjetas/tarjeta_info_personal.dart';
import '../../configuracion/colores_app.dart';
import '../autenticacion/auth_cubit.dart';
import '../autenticacion/auth_estado.dart';
import '../autenticacion/usuario.dart';
import 'perfil_cubit.dart';
import 'perfil_estado.dart';

class PerfilPantalla extends StatefulWidget {
  const PerfilPantalla({super.key});

  @override
  State<PerfilPantalla> createState() => _PerfilPantallaState();
}

class _PerfilPantallaState extends State<PerfilPantalla> {
  bool _tagsCargados = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_tagsCargados) return;
    _tagsCargados = true;

    final estado = context.read<AuthCubit>().state;
    if (estado is Autenticado && estado.usuario.id != null) {
      context.read<PerfilCubit>().cargarTags(estado.usuario.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AuthCubit, AuthEstado, Usuario?>(
      selector: (estado) => estado is Autenticado ? estado.usuario : null,
      builder: (context, usuario) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor:          Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness:     Brightness.dark,
          ),
          child: Scaffold(
            backgroundColor: ColoresApp.fondo,
            body: Column(
              children: [
                Container(
                  height: MediaQuery.paddingOf(context).top,
                  color:  ColoresApp.acento,
                ),
                _Cabecera(usuario: usuario),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                      child: Column(
                        children: [
                          if (usuario?.id != null)
                            TarjetaQrUsuario(usuarioId: usuario!.id!),
                          const SizedBox(height: 16),
                          TarjetaInfoPersonal(
                            cedula:          usuario?.numeroIdentificacion,
                            telefono:        usuario?.telefono,
                            roles:           usuario?.roles ?? [],
                            tagPrincipal:    _tagPrincipal(),
                            tagsSecundarios: _tagsSecundarios(),
                            miembroDesde:    usuario?.creadoEn,
                          ),
                          const SizedBox(height: 32),
                          TextButton(
                            onPressed: () =>
                                context.read<AuthCubit>().cerrarSesion(),
                            child: Text(
                              'Cerrar sesión',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: ColoresApp.rojo,  
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17,
                                ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: BarraNavegacionApp(
              indiceActual:    4,
              alCambiarIndice: (indice) {
                if (indice == 0) context.go(Rutas.home);
                if (indice == 1) context.go(Rutas.eventos);
              },
            ),
          ),
        );
      },
    );
  }

  String? _tagPrincipal() => switch (context.watch<PerfilCubit>().state) {
    PerfilCargado(:final tagPrincipal) => tagPrincipal,
    _ => null,
  };

  List<String> _tagsSecundarios() => switch (context.watch<PerfilCubit>().state) {
    PerfilCargado(:final tagsSecundarios) => tagsSecundarios,
    _ => [],
  };
}

// ─── Cabecera con degradado ──────────────────────────────────────────────────

class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.usuario});

  final Usuario? usuario;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: ColoresApp.degradadoPrincipal,
      ),
      child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            children: [
              AvatarUsuario(
                iniciales:  usuario?.iniciales ?? '',
                urlFoto:    usuario?.urlAvatar,
                tamanio:    80,
                colorFondo: Colors.white.withValues(alpha: 0.2),
                colorTexto: Colors.white,
              ),
              const SizedBox(height: 12),
              Text(
                usuario?.nombreCompleto ?? '',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontSize: 25,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                usuario?.correo ?? '',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 16),
              BlocBuilder<PerfilCubit, PerfilEstado>(
                builder: (context, estado) {
                  final tagPrincipal = switch (estado) {
                    PerfilCargado(:final tagPrincipal) => tagPrincipal,
                    _ => null,
                  };
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (tagPrincipal != null) ...[
                        _ChipCabecera(texto: tagPrincipal),
                        const SizedBox(width: 8),
                      ],
                      _ChipEstatus(activo: usuario?.estatus ?? true),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
    );
  }
}

// ─── Chip para la cabecera (tag principal) ───────────────────────────────────

class _ChipCabecera extends StatelessWidget {
  const _ChipCabecera({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color:        Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color:      Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Chip de estatus (Activo / Inactivo) ─────────────────────────────────────

class _ChipEstatus extends StatelessWidget {
  const _ChipEstatus({required this.activo});

  final bool activo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color:        activo ? ColoresApp.verdeClaro : ColoresApp.rojoClaro,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        activo ? 'Activo' : 'Inactivo',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color:      activo ? ColoresApp.verde : ColoresApp.rojo,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
