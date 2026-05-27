import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../compartido/widgets/avatares/avatar_usuario.dart';
import '../../compartido/widgets/tarjetas/tarjeta_info_personal.dart';
import '../../configuracion/colores_app.dart';
import 'perfil_completo_usuario.dart';
import 'ver_perfil_usuario_cubit.dart';
import 'ver_perfil_usuario_estado.dart';

class VerPerfilUsuarioPantalla extends StatefulWidget {
  const VerPerfilUsuarioPantalla({super.key, required this.usuarioId});

  final String usuarioId;

  @override
  State<VerPerfilUsuarioPantalla> createState() => _VerPerfilUsuarioState();
}

class _VerPerfilUsuarioState extends State<VerPerfilUsuarioPantalla> {
  bool _estaIniciado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_estaIniciado) return;
    _estaIniciado = true;
    context.read<VerPerfilUsuarioCubit>().cargar(widget.usuarioId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VerPerfilUsuarioCubit, VerPerfilUsuarioEstado>(
      builder: _construirVista,
    );
  }

  Widget _construirVista(BuildContext context, VerPerfilUsuarioEstado estado) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor:          Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness:     Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: ColoresApp.fondo,
        body: switch (estado) {
          VerPerfilUsuarioInicial()  ||
          VerPerfilUsuarioCargando() => const _VistaEsqueleto(),
          VerPerfilUsuarioCargado()  => _VistaCompleta(perfil: estado.perfil),
          VerPerfilUsuarioError()    => _VistaError(mensaje: estado.mensaje),
        },
      ),
    );
  }
}

// ─── Vista esqueleto de carga ─────────────────────────────────────────────────

class _VistaEsqueleto extends StatelessWidget {
  const _VistaEsqueleto();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 260 + MediaQuery.paddingOf(context).top,
          decoration: const BoxDecoration(gradient: ColoresApp.degradadoPrincipal),
        ),
        const Expanded(
          child: Center(
            child: CircularProgressIndicator(color: ColoresApp.acento),
          ),
        ),
      ],
    );
  }
}

// ─── Vista completa ───────────────────────────────────────────────────────────

class _VistaCompleta extends StatelessWidget {
  const _VistaCompleta({required this.perfil});

  final PerfilCompletoUsuario perfil;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CabeceraGradiente(perfil: perfil),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            child: TarjetaInfoPersonal(
              cedula:          perfil.numeroIdentificacion,
              telefono:        perfil.telefono,
              tagPrincipal:    perfil.tagPrincipalNombre,
              tagsSecundarios: perfil.tagsSecundariosNombres,
              miembroDesde:    perfil.creadoEn,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Cabecera con degradado ───────────────────────────────────────────────────

class _CabeceraGradiente extends StatelessWidget {
  const _CabeceraGradiente({required this.perfil});

  final PerfilCompletoUsuario perfil;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: ColoresApp.degradadoPrincipal),
      child: Column(
        children: [
          SizedBox(height: topPad + 4),
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => context.pop(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
            child: Column(
              children: [
                AvatarUsuario(
                  iniciales:  perfil.iniciales,
                  tamanio:    72,
                  colorFondo: Colors.white.withValues(alpha: 0.2),
                  colorTexto: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  perfil.nombreCompleto,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white, fontSize: 22,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  perfil.correo,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (perfil.tagPrincipalNombre != null) ...[
                      _ChipHeader(texto: perfil.tagPrincipalNombre!),
                      const SizedBox(width: 8),
                    ],
                    _ChipEstatus(activo: perfil.estatus),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Chips de cabecera ────────────────────────────────────────────────────────

class _ChipHeader extends StatelessWidget {
  const _ChipHeader({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white, fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ChipEstatus extends StatelessWidget {
  const _ChipEstatus({required this.activo});

  final bool activo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: activo ? ColoresApp.verdeClaro : ColoresApp.rojoClaro,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        activo ? 'Activo' : 'Inactivo',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: activo ? ColoresApp.verde : ColoresApp.rojo,
          fontWeight: FontWeight.w600,
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
    return Column(
      children: [
        Container(
          height: 120 + MediaQuery.paddingOf(context).top,
          decoration: const BoxDecoration(gradient: ColoresApp.degradadoPrincipal),
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 4),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () => context.pop(),
              ),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: ColoresApp.rojo, size: 48),
                  const SizedBox(height: 16),
                  Text(mensaje, textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ColoresApp.textoSecundario,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => context.read<VerPerfilUsuarioCubit>().cargar(''),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
