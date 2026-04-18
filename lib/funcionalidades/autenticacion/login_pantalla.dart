import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../compartido/constantes.dart';
import '../../compartido/extensiones.dart';
import '../../configuracion/colores_app.dart';
import 'auth_cubit.dart';
import '../../compartido/widgets/botones/boton_app.dart';
import '../../compartido/widgets/formularios/campo_texto_app.dart';

import 'login_cubit.dart';
import 'login_estado.dart';

class LoginPantalla extends StatefulWidget {
  const LoginPantalla({super.key});

  @override
  State<LoginPantalla> createState() => _LoginPantallaState();
}

class _LoginPantallaState extends State<LoginPantalla> {
  final _correoController    = TextEditingController();
  final _contrasenaController = TextEditingController();

  @override
  void dispose() {
    _correoController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresApp.superficiePrimaria,
      body: BlocConsumer<LoginCubit, LoginEstado>(
        listener: (context, estado) {
          if (estado is LoginError) context.mostrarError(estado.mensaje);
          if (estado is LoginExito) context.read<AuthCubit>().verificarSesion();
        },
        builder: (context, estado) => _CuerpoLogin(
          correoController:    _correoController,
          contrasenaController: _contrasenaController,
          estaCargando:        estado is LoginCargando,
        ),
      ),
    );
  }
}

class _CuerpoLogin extends StatelessWidget {
  const _CuerpoLogin({
    required this.correoController,
    required this.contrasenaController,
    required this.estaCargando,
  });

  final TextEditingController correoController;
  final TextEditingController contrasenaController;
  final bool estaCargando;

  @override
  Widget build(BuildContext context) {
    final estiloTexto = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            const _CabeceraLogin(),
            const SizedBox(height: 45),
            CampoTextoApp(
              etiqueta:   'Correo institucional',
              hintText:   'maria.gonzalez@uni.edu',
              controller: correoController,
            ),
            const SizedBox(height: 20),
            CampoTextoApp(
              etiqueta:     'Contraseña',
              hintText:     '••••••••',
              controller:   contrasenaController,
              esContrasena: true,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: Text('¿Olvidaste tu contraseña?', style: estiloTexto.labelLarge),
              ),
            ),
            const SizedBox(height: 35),
            BotonApp(
              texto:        'Iniciar sesión',
              estaCargando: estaCargando,
              alPresionar:  () => context.read<LoginCubit>().ingresar(
                correoController.text,
                contrasenaController.text,
              ),
            ),
            const SizedBox(height: 30),
            const _PieLogin(),
          ],
        ),
      ),
    );
  }
}

class _CabeceraLogin extends StatelessWidget {
  const _CabeceraLogin();

  @override
  Widget build(BuildContext context) {
    final estiloTexto = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding:    const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:        ColoresApp.acento,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.people_alt_outlined, size: 45, color: ColoresApp.blanco),
        ),
        const SizedBox(height: 30),
        Text('Bienvenido', style: estiloTexto.displaySmall),
        Text('Sistema de asistencia universitaria', style: estiloTexto.bodyMedium),
      ],
    );
  }
}

class _PieLogin extends StatelessWidget {
  const _PieLogin();

  @override
  Widget build(BuildContext context) {
    final estiloTexto = Theme.of(context).textTheme;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('¿No tienes cuenta? ', style: estiloTexto.bodyMedium),
            TextButton(
              onPressed: () => context.push(Rutas.registro),
              child: Text('Regístrate', style: estiloTexto.labelLarge),
            ),
          ],
        ),
        const SizedBox(height: 40),
        Center(child: Text('v3.0 • UniAsist', style: estiloTexto.bodySmall)),
      ],
    );
  }
}
