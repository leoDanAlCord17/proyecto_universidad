import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/widgets/avisos/aviso_app.dart';
import '../../compartido/widgets/botones/boton_app.dart';
import '../../compartido/widgets/formularios/campo_texto_app.dart';
import '../../configuracion/colores_app.dart';
import '../autenticacion/auth_cubit.dart';
import 'nueva_contrasena_cubit.dart';
import 'nueva_contrasena_estado.dart';

class NuevaContrasenaPantalla extends StatefulWidget {
  const NuevaContrasenaPantalla({super.key});

  @override
  State<NuevaContrasenaPantalla> createState() =>
      _NuevaContrasenaPantallaState();
}

class _NuevaContrasenaPantallaState extends State<NuevaContrasenaPantalla> {
  final _claveCtrl = TextEditingController();
  final _confirmacionCtrl = TextEditingController();

  @override
  void dispose() {
    _claveCtrl.dispose();
    _confirmacionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresApp.superficiePrimaria,
      body: BlocConsumer<NuevaContrasenaCubit, NuevaContrasenaEstado>(
        listener: (context, estado) {
          if (estado is NuevaContrasenaError) {
            AvisoApp.mostrar(context,
                texto: estado.mensaje, estilo: EstiloAviso.error);
          }
          if (estado is NuevaContrasenaGuardada) {
            context.read<AuthCubit>().verificarSesion();
          }
        },
        builder: (context, estado) => switch (estado) {
          NuevaContrasenaGuardada() => const SizedBox.shrink(),
          NuevaContrasenaInicial() ||
          NuevaContrasenaGuardando() ||
          NuevaContrasenaError() =>
            _CuerpoFormulario(
              claveCtrl: _claveCtrl,
              confirmacionCtrl: _confirmacionCtrl,
              estaCargando: estado is NuevaContrasenaGuardando,
            ),
        },
      ),
    );
  }
}

// ─── Cuerpo ───────────────────────────────────────────────────────────────────

class _CuerpoFormulario extends StatelessWidget {
  const _CuerpoFormulario({
    required this.claveCtrl,
    required this.confirmacionCtrl,
    required this.estaCargando,
  });

  final TextEditingController claveCtrl;
  final TextEditingController confirmacionCtrl;
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
              etiqueta: 'Nueva contraseña',
              hintText: '••••••••',
              controller: claveCtrl,
              esContrasena: true,
            ),
            const SizedBox(height: 20),
            CampoTextoApp(
              etiqueta: 'Confirmar contraseña',
              hintText: '••••••••',
              controller: confirmacionCtrl,
              esContrasena: true,
            ),
            const SizedBox(height: 8),
            Text(
              'Mínimo 6 caracteres.',
              style: estiloTexto.bodySmall
                  ?.copyWith(color: ColoresApp.textoSecundario),
            ),
            const SizedBox(height: 32),
            BotonApp(
              texto: 'Guardar contraseña',
              estaCargando: estaCargando,
              alPresionar: estaCargando
                  ? null
                  : () => context.read<NuevaContrasenaCubit>().cambiar(
                        nuevaClave: claveCtrl.text,
                        confirmacion: confirmacionCtrl.text,
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
          child: const Icon(Icons.lock_outline_rounded,
              size: 45, color: ColoresApp.blanco),
        ),
        const SizedBox(height: 30),
        Text('Nueva contraseña', style: estiloTexto.displaySmall),
        Text('Elige una contraseña segura para tu cuenta',
            style: estiloTexto.bodyMedium),
      ],
    );
  }
}
