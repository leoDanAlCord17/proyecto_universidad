import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../compartido/constantes.dart';
import '../../compartido/widgets/avatares/avatar_usuario.dart';
import '../../compartido/widgets/utilidades/banner_sin_conexion.dart';
import '../../compartido/widgets/dialogo/dialogo_confirmacion.dart';
import '../../compartido/widgets/navegacion/barra_navegacion_app.dart';
import '../../compartido/widgets/qr/tarjeta_qr_usuario.dart';
import '../../compartido/widgets/tarjetas/tarjeta_app.dart';
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
  bool _editando = false;

  Future<void> _confirmarCerrarSesion(BuildContext context) async {
    final resultado = await DialogoConfirmacion.mostrar(
      context,
      titulo: '¿Cerrar sesión?',
      descripcion:
          'Se cerrará tu sesión actual y tendrás que volver a iniciar sesión.',
      textoConfirmar: 'Quedarme',
      textoCancelar: 'Cerrar sesión',
    );
    if (resultado == false && context.mounted) {
      unawaited(context.read<AuthCubit>().cerrarSesion());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_tagsCargados) return;
    _tagsCargados = true;

    final estado = context.read<AuthCubit>().state;
    if (estado is Autenticado && estado.usuario.id != null) {
      context.read<PerfilCubit>().cargar(estado.usuario.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AuthCubit, AuthEstado, Usuario?>(
      selector: (estado) => estado is Autenticado ? estado.usuario : null,
      builder: (context, usuario) {
        return BlocConsumer<PerfilCubit, PerfilEstado>(
          listener: (context, estado) {
            if (estado is PerfilGuardado) {
              context
                  .read<AuthCubit>()
                  .actualizarUsuario(estado.usuarioActualizado);
              context.read<PerfilCubit>().volverACargado(estado.estadoAnterior);
              setState(() => _editando = false);
            }
          },
          builder: (context, perfilEstado) {
            final puedeEditar =
                perfilEstado is PerfilCargado && perfilEstado.puedeEditarPerfil;
            final estaGuardando =
                perfilEstado is PerfilCargado && perfilEstado.estaGuardando;
            final errorGuardado = perfilEstado is PerfilCargado
                ? perfilEstado.errorGuardado
                : null;

            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
                statusBarBrightness: Brightness.dark,
              ),
              child: Scaffold(
                backgroundColor: ColoresApp.fondo,
                body: Column(
                  children: [
                    Container(
                      height: MediaQuery.paddingOf(context).top,
                      color: ColoresApp.acento,
                    ),
                    _Cabecera(usuario: usuario),
                    if (perfilEstado is PerfilSinConexion)
                      BannerSinConexion(
                        onReintentar: () {
                          final auth = context.read<AuthCubit>().state;
                          if (auth is Autenticado && auth.usuario.id != null) {
                            context
                                .read<PerfilCubit>()
                                .cargar(auth.usuario.id!);
                          }
                        },
                      ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                          child: Column(
                            children: [
                              if (usuario?.id != null)
                                TarjetaQrUsuario(usuarioId: usuario!.id!),
                              const SizedBox(height: 16),
                              if (!_editando)
                                TarjetaInfoPersonal(
                                  cedula: usuario?.numeroIdentificacion,
                                  telefono: usuario?.telefono,
                                  roles: usuario?.roles ?? [],
                                  tagPrincipal: _tagPrincipal(),
                                  tagsSecundarios: _tagsSecundarios(),
                                  miembroDesde: usuario?.creadoEn,
                                  alEditarTap: puedeEditar && usuario != null
                                      ? () => setState(() => _editando = true)
                                      : null,
                                )
                              else if (usuario != null)
                                _FormularioEditar(
                                  usuario: usuario,
                                  estaGuardando: estaGuardando,
                                  errorGuardado: errorGuardado,
                                  alGuardar: (campos) =>
                                      context.read<PerfilCubit>().guardarPerfil(
                                            usuarioActual: usuario,
                                            campos: campos,
                                          ),
                                  alCancelar: () =>
                                      setState(() => _editando = false),
                                ),
                              const SizedBox(height: 32),
                              if (!_editando)
                                TextButton(
                                  onPressed: () =>
                                      _confirmarCerrarSesion(context),
                                  child: Text(
                                    'Cerrar sesión',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: ColoresApp.rojo,
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
                  indiceActual: 4,
                  alCambiarIndice: (indice) {
                    if (indice == 0) context.go(Rutas.home);
                    if (indice == 1) context.go(Rutas.eventos);
                    if (indice == 3) context.go(Rutas.historial);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  String? _tagPrincipal() => switch (context.watch<PerfilCubit>().state) {
        PerfilCargado(:final tagPrincipal) => tagPrincipal,
        PerfilSinConexion(:final tagPrincipal) => tagPrincipal,
        _ => null,
      };

  List<String> _tagsSecundarios() =>
      switch (context.watch<PerfilCubit>().state) {
        PerfilCargado(:final tagsSecundarios) => tagsSecundarios,
        PerfilSinConexion(:final tagsSecundarios) => tagsSecundarios,
        _ => [],
      };
}

// ─── Formulario de edición de perfil ─────────────────────────────────────────

class _FormularioEditar extends StatefulWidget {
  const _FormularioEditar({
    required this.usuario,
    required this.estaGuardando,
    required this.alGuardar,
    required this.alCancelar,
    this.errorGuardado,
  });

  final Usuario usuario;
  final bool estaGuardando;
  final String? errorGuardado;
  final void Function(Map<String, dynamic>) alGuardar;
  final VoidCallback alCancelar;

  @override
  State<_FormularioEditar> createState() => _FormularioEditarState();
}

class _FormularioEditarState extends State<_FormularioEditar> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _primerNombre;
  late final TextEditingController _segundoNombre;
  late final TextEditingController _primerApellido;
  late final TextEditingController _segundoApellido;
  late final TextEditingController _cedula;
  late final TextEditingController _correo;
  late final TextEditingController _telefono;

  @override
  void initState() {
    super.initState();
    final u = widget.usuario;
    _primerNombre = TextEditingController(text: u.primerNombre);
    _segundoNombre = TextEditingController(text: u.segundoNombre ?? '');
    _primerApellido = TextEditingController(text: u.primerApellido);
    _segundoApellido = TextEditingController(text: u.segundoApellido ?? '');
    _cedula = TextEditingController(text: u.numeroIdentificacion ?? '');
    _correo = TextEditingController(text: u.correo);
    _telefono = TextEditingController(text: u.telefono ?? '');
  }

  @override
  void dispose() {
    _primerNombre.dispose();
    _segundoNombre.dispose();
    _primerApellido.dispose();
    _segundoApellido.dispose();
    _cedula.dispose();
    _correo.dispose();
    _telefono.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    widget.alGuardar({
      'primer_nombre': _primerNombre.text.trim(),
      'segundo_nombre': _nullIfEmpty(_segundoNombre.text),
      'primer_apellido': _primerApellido.text.trim(),
      'segundo_apellido': _nullIfEmpty(_segundoApellido.text),
      'numero_identificacion': _nullIfEmpty(_cedula.text),
      'correo': _correo.text.trim(),
      'telefono': _nullIfEmpty(_telefono.text),
    });
  }

  String? _nullIfEmpty(String value) {
    final v = value.trim();
    return v.isEmpty ? null : v;
  }

  @override
  Widget build(BuildContext context) {
    return TarjetaApp(
      relleno: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Encabezado ──────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    'EDITAR INFORMACIÓN PERSONAL',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: ColoresApp.textoTerciario,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Campos ──────────────────────────────────────────────────────
            _Campo(
              controlador: _primerNombre,
              etiqueta: 'Primer nombre',
              obligatorio: true,
            ),
            const SizedBox(height: 12),
            _Campo(
              controlador: _segundoNombre,
              etiqueta: 'Segundo nombre',
            ),
            const SizedBox(height: 12),
            _Campo(
              controlador: _primerApellido,
              etiqueta: 'Primer apellido',
              obligatorio: true,
            ),
            const SizedBox(height: 12),
            _Campo(
              controlador: _segundoApellido,
              etiqueta: 'Segundo apellido',
            ),
            const SizedBox(height: 12),
            _Campo(
              controlador: _cedula,
              etiqueta: 'Número de identificación',
              teclado: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _Campo(
              controlador: _correo,
              etiqueta: 'Correo electrónico',
              obligatorio: true,
              teclado: TextInputType.emailAddress,
              validador: (v) {
                if (v == null || v.trim().isEmpty)
                  return 'El correo es obligatorio';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                  return 'Ingresa un correo válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _Campo(
              controlador: _telefono,
              etiqueta: 'Teléfono',
              teclado: TextInputType.phone,
            ),

            // ── Error del servidor ───────────────────────────────────────────
            if (widget.errorGuardado != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: ColoresApp.rojoClaro,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  widget.errorGuardado!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ColoresApp.rojo,
                      ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ── Botones ──────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: widget.estaGuardando ? null : _guardar,
                style: FilledButton.styleFrom(
                  backgroundColor: ColoresApp.acento,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: widget.estaGuardando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ColoresApp.blanco,
                        ),
                      )
                    : const Text(
                        'Guardar',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: widget.estaGuardando ? null : widget.alCancelar,
                child: Text(
                  'Cancelar',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ColoresApp.textoSecundario,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Campo de texto reutilizable ─────────────────────────────────────────────

class _Campo extends StatelessWidget {
  const _Campo({
    required this.controlador,
    required this.etiqueta,
    this.obligatorio = false,
    this.teclado = TextInputType.text,
    this.validador,
  });

  final TextEditingController controlador;
  final String etiqueta;
  final bool obligatorio;
  final TextInputType teclado;
  final String? Function(String?)? validador;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controlador,
      keyboardType: teclado,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: ColoresApp.textoPrimario,
          ),
      decoration: InputDecoration(
        labelText: etiqueta,
        labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ColoresApp.textoSecundario,
            ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        filled: true,
        fillColor: ColoresApp.fondo,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ColoresApp.superficieTerciar),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ColoresApp.superficieTerciar),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ColoresApp.acento, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ColoresApp.rojo),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ColoresApp.rojo, width: 1.5),
        ),
      ),
      validator: validador ??
          (obligatorio
              ? (v) => (v == null || v.trim().isEmpty)
                  ? 'El campo "$etiqueta" es obligatorio'
                  : null
              : null),
    );
  }
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
              iniciales: usuario?.iniciales ?? '',
              urlFoto: usuario?.urlAvatar,
              tamanio: 80,
              colorFondo: ColoresApp.blanco.withValues(alpha: 0.2),
              colorTexto: ColoresApp.blanco,
            ),
            const SizedBox(height: 12),
            Text(
              usuario?.nombreCompleto ?? '',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: ColoresApp.blanco,
                    fontSize: 25,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              usuario?.correo ?? '',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: ColoresApp.blanco.withValues(alpha: 0.8),
                  ),
            ),
            const SizedBox(height: 16),
            BlocBuilder<PerfilCubit, PerfilEstado>(
              builder: (context, estado) {
                final tagPrincipal = switch (estado) {
                  PerfilCargado(:final tagPrincipal) => tagPrincipal,
                  PerfilSinConexion(:final tagPrincipal) => tagPrincipal,
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
        color: ColoresApp.blanco.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: ColoresApp.blanco,
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
