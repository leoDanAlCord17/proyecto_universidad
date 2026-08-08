import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../compartido/constantes.dart';
import '../../compartido/widgets/avisos/aviso_app.dart';
import '../../compartido/widgets/botones/boton_app.dart';
import '../../compartido/widgets/formularios/campo_texto_app.dart';
import '../../configuracion/colores_app.dart';
import 'recuperar_contrasena_cubit.dart';
import 'recuperar_contrasena_estado.dart';

class RecuperarContrasenaPantalla extends StatefulWidget {
  const RecuperarContrasenaPantalla({super.key});

  @override
  State<RecuperarContrasenaPantalla> createState() =>
      _RecuperarContrasenaPantallaState();
}

class _RecuperarContrasenaPantallaState
    extends State<RecuperarContrasenaPantalla> {
  final _cedulaCtrl = TextEditingController();

  @override
  void dispose() {
    _cedulaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresApp.superficiePrimaria,
      body: BlocConsumer<RecuperarContrasenaCubit, RecuperarContrasenaEstado>(
        listener: (context, estado) {
          if (estado is RecuperarContrasenaError) {
            AvisoApp.mostrar(context,
                texto: estado.mensaje, estilo: EstiloAviso.error);
          }
        },
        builder: (context, estado) => switch (estado) {
          RecuperarContrasenaEnviado() => const _VistaConfirmacion(),
          RecuperarContrasenaInicial() ||
          RecuperarContrasenaEnviando() ||
          RecuperarContrasenaError() =>
            _VistaFormulario(
              cedulaCtrl: _cedulaCtrl,
              estaCargando: estado is RecuperarContrasenaEnviando,
            ),
        },
      ),
    );
  }
}

// ─── Vista formulario ─────────────────────────────────────────────────────────

class _VistaFormulario extends StatelessWidget {
  const _VistaFormulario(
      {required this.cedulaCtrl, required this.estaCargando});

  final TextEditingController cedulaCtrl;
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
            const _Cabecera(),
            const SizedBox(height: 40),
            CampoTextoApp(
              etiqueta: 'Cédula',
              hintText: 'Ej. 32727960',
              controller: cedulaCtrl,
            ),
            const SizedBox(height: 12),
            Text(
              'Enviaremos un enlace para restablecer tu contraseña al correo asociado a tu cuenta.',
              style: estiloTexto.bodySmall
                  ?.copyWith(color: ColoresApp.textoSecundario),
            ),
            const SizedBox(height: 32),
            BotonApp(
              texto: 'Enviar instrucciones',
              estaCargando: estaCargando,
              alPresionar: estaCargando
                  ? null
                  : () => context
                      .read<RecuperarContrasenaCubit>()
                      .enviar(cedulaCtrl.text),
            ),
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () => context.pop(),
                child: Text('Volver al inicio de sesión',
                    style: estiloTexto.labelLarge),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ─── Cabecera ─────────────────────────────────────────────────────────────────

class _Cabecera extends StatelessWidget {
  const _Cabecera();

  @override
  Widget build(BuildContext context) {
    final estiloTexto = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ColoresApp.acento,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.lock_reset_rounded,
              size: 45, color: ColoresApp.blanco),
        ),
        const SizedBox(height: 30),
        Text('Recuperar contraseña', style: estiloTexto.displaySmall),
        Text('Ingresa tu cédula y te enviaremos el enlace a tu correo',
            style: estiloTexto.bodyMedium),
      ],
    );
  }
}

// ─── Vista confirmación ───────────────────────────────────────────────────────

class _VistaConfirmacion extends StatelessWidget {
  const _VistaConfirmacion();

  @override
  Widget build(BuildContext context) {
    final estiloTexto = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ColoresApp.verdeClaro,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.mark_email_read_outlined,
                  size: 52, color: ColoresApp.verde),
            ),
            const SizedBox(height: 28),
            Text('Revisa tu correo', style: estiloTexto.displaySmall),
            const SizedBox(height: 12),
            Text(
              'Si la cédula ingresada está registrada, enviamos un enlace '
              'de recuperación al correo asociado a esa cuenta.',
              style: estiloTexto.bodyMedium
                  ?.copyWith(color: ColoresApp.textoSecundario),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Si no llega en unos minutos, revisa tu carpeta de spam.',
              style: estiloTexto.bodySmall
                  ?.copyWith(color: ColoresApp.textoTerciario),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            BotonApp(
              texto: 'Volver al inicio de sesión',
              alPresionar: () => context.go(Rutas.login),
            ),
          ],
        ),
      ),
    );
  }
}
