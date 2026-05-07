import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/widgets/botones/boton_app.dart';
import '../../configuracion/colores_app.dart';
import 'auth_cubit.dart';

class PendienteAprobacionPantalla extends StatefulWidget {
  const PendienteAprobacionPantalla({super.key});

  @override
  State<PendienteAprobacionPantalla> createState() =>
      _PendienteAprobacionPantallaState();
}

class _PendienteAprobacionPantallaState
    extends State<PendienteAprobacionPantalla> {
  bool _verificando = false;

  Future<void> _verificarEstado() async {
    setState(() => _verificando = true);
    await context.read<AuthCubit>().verificarSesion();
    if (mounted) setState(() => _verificando = false);
  }

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor:          Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness:     Brightness.light,
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
                  'Tu cuenta está en revisión',
                  textAlign: TextAlign.center,
                  style: estilos.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color:      ColoresApp.textoPrimario,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Un administrador revisará tu solicitud y recibirás una respuesta pronto. Por ahora no puedes acceder a la app.',
                  textAlign: TextAlign.center,
                  style: estilos.bodyMedium?.copyWith(
                    color:  ColoresApp.textoSecundario,
                    height: 1.5,
                  ),
                ),
                const Spacer(),
                BotonApp(
                  texto:        'Verificar estado',
                  estaCargando: _verificando,
                  alPresionar:  _verificando ? null : _verificarEstado,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.read<AuthCubit>().cerrarSesion(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColoresApp.textoSecundario,
                      side:    const BorderSide(color: ColoresApp.bordeMedio),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape:   RoundedRectangleBorder(
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
      width:       96,
      height:      96,
      decoration:  BoxDecoration(
        color:        ColoresApp.ambarClaro,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Icon(
        Icons.hourglass_top_rounded,
        color: ColoresApp.ambar,
        size:  48,
      ),
    );
  }
}
