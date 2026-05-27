import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../compartido/widgets/avisos/aviso_app.dart';
import '../../compartido/widgets/botones/boton_app.dart';
import '../../compartido/widgets/botones/boton_regresar.dart';
import '../../compartido/widgets/formularios/campo_texto_app.dart';
import '../../compartido/widgets/navegacion/barra_superior_app.dart';
import '../../configuracion/colores_app.dart';
import 'editar_usuario_cubit.dart';
import 'editar_usuario_estado.dart';

class EditarUsuarioPantalla extends StatefulWidget {
  const EditarUsuarioPantalla({super.key, required this.usuarioId});

  final String usuarioId;

  @override
  State<EditarUsuarioPantalla> createState() => _EditarUsuarioPantallaState();
}

class _EditarUsuarioPantallaState extends State<EditarUsuarioPantalla> {
  final _primerNombreCtrl        = TextEditingController();
  final _segundoNombreCtrl       = TextEditingController();
  final _primerApellidoCtrl      = TextEditingController();
  final _segundoApellidoCtrl     = TextEditingController();
  final _numeroIdentificacionCtrl = TextEditingController();
  final _correoCtrl              = TextEditingController();
  final _telefonoCtrl            = TextEditingController();

  bool _estaIniciado  = false;
  bool _estaPrelleno  = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_estaIniciado) return;
    _estaIniciado = true;
    context.read<EditarUsuarioCubit>().cargar(widget.usuarioId);
  }

  @override
  void dispose() {
    _primerNombreCtrl.dispose();
    _segundoNombreCtrl.dispose();
    _primerApellidoCtrl.dispose();
    _segundoApellidoCtrl.dispose();
    _numeroIdentificacionCtrl.dispose();
    _correoCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  void _escucharEstado(BuildContext context, EditarUsuarioEstado estado) {
    if (estado is EditarUsuarioGuardado) {
      AvisoApp.mostrar(context, texto: 'Información actualizada.', estilo: EstiloAviso.exito);
      context.pop();
    } else if (estado is EditarUsuarioCargado && estado.errorValidacion.isNotEmpty) {
      AvisoApp.mostrar(context, texto: estado.errorValidacion, estilo: EstiloAviso.error);
    } else if (estado is EditarUsuarioCargado && !_estaPrelleno) {
      _estaPrelleno = true;
      _primerNombreCtrl.text         = estado.primerNombreInicial;
      _segundoNombreCtrl.text        = estado.segundoNombreInicial         ?? '';
      _primerApellidoCtrl.text       = estado.primerApellidoInicial;
      _segundoApellidoCtrl.text      = estado.segundoApellidoInicial       ?? '';
      _numeroIdentificacionCtrl.text = estado.numeroIdentificacionInicial  ?? '';
      _correoCtrl.text               = estado.correoInicial;
      _telefonoCtrl.text             = estado.telefonoInicial              ?? '';
    }
  }

  Future<void> _alGuardar(BuildContext context) async {
    await context.read<EditarUsuarioCubit>().guardar(
      primerNombre:        _primerNombreCtrl.text,
      segundoNombre:       _segundoNombreCtrl.text,
      primerApellido:      _primerApellidoCtrl.text,
      segundoApellido:     _segundoApellidoCtrl.text,
      numeroIdentificacion: _numeroIdentificacionCtrl.text,
      correo:              _correoCtrl.text,
      telefono:            _telefonoCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EditarUsuarioCubit, EditarUsuarioEstado>(
      listener: _escucharEstado,
      builder:  _construirVista,
    );
  }

  Widget _construirVista(BuildContext context, EditarUsuarioEstado estado) {
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
                      'Editar información',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize:   20,
                        fontWeight: FontWeight.w700,
                        color:      ColoresApp.textoPrimario,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(child: _Cuerpo(
              estado:                   estado,
              primerNombreCtrl:         _primerNombreCtrl,
              segundoNombreCtrl:        _segundoNombreCtrl,
              primerApellidoCtrl:       _primerApellidoCtrl,
              segundoApellidoCtrl:      _segundoApellidoCtrl,
              numeroIdentificacionCtrl: _numeroIdentificacionCtrl,
              correoCtrl:               _correoCtrl,
              telefonoCtrl:             _telefonoCtrl,
            ),),
            _BarraInferior(
              estado:    estado,
              alGuardar: () => _alGuardar(context),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Cuerpo ───────────────────────────────────────────────────────────────────

class _Cuerpo extends StatelessWidget {
  const _Cuerpo({
    required this.estado,
    required this.primerNombreCtrl,
    required this.segundoNombreCtrl,
    required this.primerApellidoCtrl,
    required this.segundoApellidoCtrl,
    required this.numeroIdentificacionCtrl,
    required this.correoCtrl,
    required this.telefonoCtrl,
  });

  final EditarUsuarioEstado   estado;
  final TextEditingController primerNombreCtrl;
  final TextEditingController segundoNombreCtrl;
  final TextEditingController primerApellidoCtrl;
  final TextEditingController segundoApellidoCtrl;
  final TextEditingController numeroIdentificacionCtrl;
  final TextEditingController correoCtrl;
  final TextEditingController telefonoCtrl;

  @override
  Widget build(BuildContext context) {
    final e = estado;
    return switch (e) {
      EditarUsuarioInicial() || EditarUsuarioCargando() => const Center(
        child: CircularProgressIndicator(color: ColoresApp.acento),
      ),
      EditarUsuarioCargado() => _Formulario(
        primerNombreCtrl:         primerNombreCtrl,
        segundoNombreCtrl:        segundoNombreCtrl,
        primerApellidoCtrl:       primerApellidoCtrl,
        segundoApellidoCtrl:      segundoApellidoCtrl,
        numeroIdentificacionCtrl: numeroIdentificacionCtrl,
        correoCtrl:               correoCtrl,
        telefonoCtrl:             telefonoCtrl,
      ),
      EditarUsuarioGuardado() || EditarUsuarioError() => const SizedBox.shrink(),
    };
  }
}

// ─── Formulario ───────────────────────────────────────────────────────────────

class _Formulario extends StatelessWidget {
  const _Formulario({
    required this.primerNombreCtrl,
    required this.segundoNombreCtrl,
    required this.primerApellidoCtrl,
    required this.segundoApellidoCtrl,
    required this.numeroIdentificacionCtrl,
    required this.correoCtrl,
    required this.telefonoCtrl,
  });

  final TextEditingController primerNombreCtrl;
  final TextEditingController segundoNombreCtrl;
  final TextEditingController primerApellidoCtrl;
  final TextEditingController segundoApellidoCtrl;
  final TextEditingController numeroIdentificacionCtrl;
  final TextEditingController correoCtrl;
  final TextEditingController telefonoCtrl;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:        ColoresApp.superficiePrimaria,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color:      ColoresApp.sombraTarjeta,
                blurRadius: 8,
                offset:     Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'INFORMACIÓN PERSONAL',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:         ColoresApp.acento,
                  letterSpacing: 0.8,
                  fontSize:      14,
                  fontWeight:    FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              CampoTextoApp(
                etiqueta:   'Primer nombre*',
                hintText:   'Ej. Juan',
                controller: primerNombreCtrl,
              ),
              const SizedBox(height: 16),
              CampoTextoApp(
                etiqueta:   'Segundo nombre',
                hintText:   'Opcional',
                controller: segundoNombreCtrl,
              ),
              const SizedBox(height: 16),
              CampoTextoApp(
                etiqueta:   'Primer apellido*',
                hintText:   'Ej. Pérez',
                controller: primerApellidoCtrl,
              ),
              const SizedBox(height: 16),
              CampoTextoApp(
                etiqueta:   'Segundo apellido',
                hintText:   'Opcional',
                controller: segundoApellidoCtrl,
              ),
              const SizedBox(height: 16),
              CampoTextoApp(
                etiqueta:   'Número de identificación',
                hintText:   'Ej. V-12345678',
                controller: numeroIdentificacionCtrl,
              ),
              const SizedBox(height: 16),
              CampoTextoApp(
                etiqueta:   'Correo electrónico*',
                hintText:   'Ej. correo@email.com',
                controller: correoCtrl,
              ),
              const SizedBox(height: 16),
              CampoTextoApp(
                etiqueta:   'Teléfono',
                hintText:   'Opcional',
                controller: telefonoCtrl,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Barra inferior ───────────────────────────────────────────────────────────

class _BarraInferior extends StatelessWidget {
  const _BarraInferior({required this.estado, required this.alGuardar});

  final EditarUsuarioEstado estado;
  final VoidCallback        alGuardar;

  @override
  Widget build(BuildContext context) {
    final estaCargando = estado is EditarUsuarioCargado &&
        (estado as EditarUsuarioCargado).estaGuardando;
    final puedeGuardar = estado is EditarUsuarioCargado && !estaCargando;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: BotonApp(
          texto:        'Guardar cambios',
          estaCargando: estaCargando,
          alPresionar:  puedeGuardar ? alGuardar : null,
        ),
      ),
    );
  }
}
