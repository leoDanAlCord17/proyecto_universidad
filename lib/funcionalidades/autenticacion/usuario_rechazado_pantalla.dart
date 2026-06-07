import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/widgets/botones/boton_app.dart';
import '../../configuracion/colores_app.dart';
import 'auth_cubit.dart';

class UsuarioRechazadoPantalla extends StatelessWidget {
  const UsuarioRechazadoPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: ColoresApp.fondo,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Column(
              children: [
                const Spacer(),
                const _Icono(),
                const SizedBox(height: 32),
                Text(
                  'Solicitud rechazada',
                  textAlign: TextAlign.center,
                  style: estilos.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: ColoresApp.textoPrimario,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tu solicitud de acceso fue rechazada por el administrador. Puedes volver a intentarlo completando tu perfil de nuevo.',
                  textAlign: TextAlign.center,
                  style: estilos.bodyMedium?.copyWith(
                    color: ColoresApp.textoSecundario,
                    height: 1.5,
                  ),
                ),
                const Spacer(),
                BotonApp(
                  texto: 'Intentar de nuevo',
                  alPresionar: () =>
                      context.read<AuthCubit>().reiniciarParaReintento(),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.read<AuthCubit>().cerrarSesion(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColoresApp.textoSecundario,
                      side: const BorderSide(color: ColoresApp.bordeMedio),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cerrar sesión'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Icono extends StatelessWidget {
  const _Icono();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: ColoresApp.rojoClaro,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Icon(
        Icons.person_off_outlined,
        color: ColoresApp.rojo,
        size: 48,
      ),
    );
  }
}
