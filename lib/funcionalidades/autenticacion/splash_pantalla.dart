import 'dart:async';

import 'package:flutter/material.dart';

import '../../configuracion/colores_app.dart';

/// Pantalla mostrada en [Rutas.splash] mientras `AuthCubit.verificarSesion()`
/// resuelve (hasta `kTimeoutSolicitud`, 15s). En redes lentas, un spinner
/// sin contexto durante varios segundos puede sentirse como que la app se
/// congeló — a partir de los 4s se añade un texto secundario para dejar
/// claro que sigue respondiendo, solo que la red está tardando.
class SplashPantalla extends StatefulWidget {
  const SplashPantalla({super.key});

  @override
  State<SplashPantalla> createState() => _SplashPantallaState();
}

class _SplashPantallaState extends State<SplashPantalla> {
  static const _umbralConexionLenta = Duration(seconds: 4);

  bool _conexionLenta = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_umbralConexionLenta, () {
      if (mounted) setState(() => _conexionLenta = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresApp.fondo,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: ColoresApp.acento),
            if (_conexionLenta) ...[
              const SizedBox(height: 20),
              Text(
                'Conexión lenta, verificando sesión...',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ColoresApp.textoSecundario,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
