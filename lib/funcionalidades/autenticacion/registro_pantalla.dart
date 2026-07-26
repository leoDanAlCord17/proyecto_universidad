import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../compartido/extensiones.dart';
import '../../configuracion/colores_app.dart';
import '../autenticacion/auth_cubit.dart';
import '../../compartido/widgets/botones/boton_app.dart';
import '../../compartido/widgets/botones/boton_regresar.dart';
import '../../compartido/widgets/formularios/campo_texto_app.dart';

import 'registro_cubit.dart';
import 'registro_estado.dart';

class RegistroPantalla extends StatefulWidget {
  const RegistroPantalla({super.key});

  @override
  State<RegistroPantalla> createState() => _RegistroPantallaState();
}

class _RegistroPantallaState extends State<RegistroPantalla> {
  final _correoController = TextEditingController();
  final _claveController = TextEditingController();
  final _confirmarClaveController = TextEditingController();

  @override
  void dispose() {
    _correoController.dispose();
    _claveController.dispose();
    _confirmarClaveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresApp.superficiePrimaria,
      body: BlocConsumer<RegistroCubit, RegistroEstado>(
        listener: (context, estado) {
          if (estado is RegistroError) context.mostrarError(estado.mensaje);
          if (estado is RegistroExito)
            context.read<AuthCubit>().verificarSesion();
        },
        builder: (context, estado) => _CuerpoRegistro(
          correoController: _correoController,
          claveController: _claveController,
          confirmarClaveController: _confirmarClaveController,
          estaCargando: estado is RegistroCargando,
        ),
      ),
    );
  }
}

class _CuerpoRegistro extends StatelessWidget {
  const _CuerpoRegistro({
    required this.correoController,
    required this.claveController,
    required this.confirmarClaveController,
    required this.estaCargando,
  });

  final TextEditingController correoController;
  final TextEditingController claveController;
  final TextEditingController confirmarClaveController;
  final bool estaCargando;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            const _CabeceraRegistro(),
            const SizedBox(height: 45),
            CampoTextoApp(
              etiqueta: 'Correo institucional',
              hintText: 'maria.gonzalez@uni.edu',
              controller: correoController,
            ),
            const SizedBox(height: 20),
            CampoTextoApp(
              etiqueta: 'Contraseña',
              hintText: '••••••••',
              controller: claveController,
              esContrasena: true,
            ),
            const SizedBox(height: 20),
            CampoTextoApp(
              etiqueta: 'Confirmar contraseña',
              hintText: '••••••••',
              controller: confirmarClaveController,
              esContrasena: true,
            ),
            const SizedBox(height: 40),
            BotonApp(
              texto: 'Continuar',
              estaCargando: estaCargando,
              alPresionar: () => context.read<RegistroCubit>().registrarse(
                    correoController.text.trim(),
                    claveController.text,
                    confirmarClaveController.text,
                  ),
            ),
            const SizedBox(height: 30),
            const _PieRegistro(),
          ],
        ),
      ),
    );
  }
}

class _CabeceraRegistro extends StatelessWidget {
  const _CabeceraRegistro();

  @override
  Widget build(BuildContext context) {
    final estiloTexto = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BotonRegresar(),
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ColoresApp.acento,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.person_add_outlined,
              size: 45, color: ColoresApp.blanco),
        ),
        const SizedBox(height: 30),
        Text('Crear cuenta', style: estiloTexto.displaySmall),
        Text('Paso 1 de 2 · Credenciales de acceso',
            style: estiloTexto.bodyMedium),
      ],
    );
  }
}

class _PieRegistro extends StatelessWidget {
  const _PieRegistro();

  @override
  Widget build(BuildContext context) {
    final estiloTexto = Theme.of(context).textTheme;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('¿Ya tienes cuenta? ', style: estiloTexto.bodyMedium),
            TextButton(
              onPressed: () => context.pop(),
              child: Text('Inicia sesión', style: estiloTexto.labelLarge),
            ),
          ],
        ),
        const SizedBox(height: 40),
        Center(child: Text('v3.0 • Activiti', style: estiloTexto.bodySmall)),
      ],
    );
  }
}
