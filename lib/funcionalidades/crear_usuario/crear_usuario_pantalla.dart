import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/extensiones.dart';
import '../../compartido/widgets/avatares/selector_foto_perfil.dart';
import '../../compartido/widgets/botones/boton_app.dart';
import '../../compartido/widgets/botones/boton_regresar.dart';
import '../../compartido/widgets/formularios/campo_texto_app.dart';
import '../../configuracion/colores_app.dart';
import '../autenticacion/auth_cubit.dart';

import 'crear_usuario_cubit.dart';
import 'crear_usuario_estado.dart';

class CrearUsuarioPantalla extends StatefulWidget {
  const CrearUsuarioPantalla({super.key});

  @override
  State<CrearUsuarioPantalla> createState() => _CrearUsuarioPantallaState();
}

class _CrearUsuarioPantallaState extends State<CrearUsuarioPantalla> {
  final _primerNombreController = TextEditingController();
  final _segundoNombreController = TextEditingController();
  final _primerApellidoController = TextEditingController();
  final _segundoApellidoController = TextEditingController();
  final _numeroIdentificacionController = TextEditingController();
  final _correoController = TextEditingController();
  final _telefonoController = TextEditingController();
  String? _urlAvatar;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_correoController.text.isEmpty) {
      _correoController.text = context.read<CrearUsuarioCubit>().correoSesion;
    }
  }

  @override
  void dispose() {
    _primerNombreController.dispose();
    _segundoNombreController.dispose();
    _primerApellidoController.dispose();
    _segundoApellidoController.dispose();
    _numeroIdentificacionController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresApp.superficiePrimaria,
      body: BlocConsumer<CrearUsuarioCubit, CrearUsuarioEstado>(
        listener: (context, estado) {
          if (estado is CrearUsuarioError) context.mostrarError(estado.mensaje);
          if (estado is CrearUsuarioExito)
            context.read<AuthCubit>().verificarSesion();
        },
        builder: (context, estado) => _CuerpoCrearUsuario(
          primerNombreController: _primerNombreController,
          segundoNombreController: _segundoNombreController,
          primerApellidoController: _primerApellidoController,
          segundoApellidoController: _segundoApellidoController,
          numeroIdentificacionController: _numeroIdentificacionController,
          correoController: _correoController,
          telefonoController: _telefonoController,
          estaCargando: estado is CrearUsuarioCargando,
          authId: context.read<CrearUsuarioCubit>().authIdSesion,
          urlAvatar: _urlAvatar,
          alCambiarFoto: (url) => setState(() => _urlAvatar = url),
        ),
      ),
    );
  }
}

class _CuerpoCrearUsuario extends StatelessWidget {
  const _CuerpoCrearUsuario({
    required this.primerNombreController,
    required this.segundoNombreController,
    required this.primerApellidoController,
    required this.segundoApellidoController,
    required this.numeroIdentificacionController,
    required this.correoController,
    required this.telefonoController,
    required this.estaCargando,
    required this.authId,
    required this.urlAvatar,
    required this.alCambiarFoto,
  });

  final TextEditingController primerNombreController;
  final TextEditingController segundoNombreController;
  final TextEditingController primerApellidoController;
  final TextEditingController segundoApellidoController;
  final TextEditingController numeroIdentificacionController;
  final TextEditingController correoController;
  final TextEditingController telefonoController;
  final bool estaCargando;
  final String authId;
  final String? urlAvatar;
  final ValueChanged<String?> alCambiarFoto;

  String get _iniciales {
    final n = primerNombreController.text.trim();
    final a = primerApellidoController.text.trim();
    return '${n.isNotEmpty ? n[0] : ''}${a.isNotEmpty ? a[0] : ''}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _EncabezadoCrearUsuario(
              alRetroceder: () => context.read<AuthCubit>().cerrarSesion(),
            ),
            const SizedBox(height: 24),
            Center(
              child: SelectorFotoPerfil(
                authId: authId,
                iniciales: _iniciales,
                urlActual: urlAvatar,
                alCambiar: alCambiarFoto,
              ),
            ),
            const SizedBox(height: 24),
            _FilaNombres(
              primerNombreController: primerNombreController,
              segundoNombreController: segundoNombreController,
            ),
            const SizedBox(height: 20),
            _FilaApellidos(
              primerApellidoController: primerApellidoController,
              segundoApellidoController: segundoApellidoController,
            ),
            const SizedBox(height: 20),
            CampoTextoApp(
              etiqueta: 'Cédula* (la usarás para iniciar sesión)',
              hintText: 'DNI / Cédula / Pasaporte',
              controller: numeroIdentificacionController,
            ),
            const SizedBox(height: 20),
            CampoTextoApp(
              etiqueta: 'Correo Electrónico',
              hintText: 'usuario@gmail.com',
              controller: correoController,
              soloLectura: true,
            ),
            const SizedBox(height: 20),
            CampoTextoApp(
              etiqueta: 'Teléfono',
              hintText: '+58 000 000 0000',
              controller: telefonoController,
            ),
            const SizedBox(height: 40),
            BotonApp(
              texto: 'Finalizar Registro',
              estaCargando: estaCargando,
              alPresionar: () => context
                  .read<CrearUsuarioCubit>()
                  .guardarPerfil(
                    primerNombre: primerNombreController.text,
                    primerApellido: primerApellidoController.text,
                    segundoNombre: segundoNombreController.text,
                    segundoApellido: segundoApellidoController.text,
                    numeroIdentificacion: numeroIdentificacionController.text,
                    telefono: telefonoController.text,
                    urlAvatar: urlAvatar,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EncabezadoCrearUsuario extends StatelessWidget {
  const _EncabezadoCrearUsuario({required this.alRetroceder});

  final VoidCallback alRetroceder;

  @override
  Widget build(BuildContext context) {
    final estiloTexto = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BotonRegresar(alPresionar: alRetroceder),
        const SizedBox(height: 30),
        Text('Registro de Datos', style: estiloTexto.displaySmall),
        const SizedBox(height: 6),
        Text(
          'Paso 2 de 2 · Completa tu perfil para acceder a Activiti',
          style: estiloTexto.bodyMedium,
        ),
      ],
    );
  }
}

class _FilaNombres extends StatelessWidget {
  const _FilaNombres({
    required this.primerNombreController,
    required this.segundoNombreController,
  });

  final TextEditingController primerNombreController;
  final TextEditingController segundoNombreController;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CampoTextoApp(
            etiqueta: 'Primer Nombre',
            hintText: 'Ej. Leo',
            controller: primerNombreController,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CampoTextoApp(
            etiqueta: 'Segundo Nombre',
            hintText: 'Ej. Daniel',
            controller: segundoNombreController,
          ),
        ),
      ],
    );
  }
}

class _FilaApellidos extends StatelessWidget {
  const _FilaApellidos({
    required this.primerApellidoController,
    required this.segundoApellidoController,
  });

  final TextEditingController primerApellidoController;
  final TextEditingController segundoApellidoController;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CampoTextoApp(
            etiqueta: 'Primer Apellido',
            hintText: 'Ej. Alvarez',
            controller: primerApellidoController,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CampoTextoApp(
            etiqueta: 'Segundo Apellido',
            hintText: 'Ej. Cordero',
            controller: segundoApellidoController,
          ),
        ),
      ],
    );
  }
}
