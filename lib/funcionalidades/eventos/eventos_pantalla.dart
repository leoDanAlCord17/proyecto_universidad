import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../compartido/constantes.dart';
import '../../compartido/widgets/botones/boton_contorno_icono.dart';
import '../../compartido/widgets/navegacion/barra_navegacion_app.dart';
import '../../compartido/widgets/navegacion/barra_superior_app.dart';
import '../../configuracion/colores_app.dart';

class EventosPantalla extends StatelessWidget {
  const EventosPantalla({super.key});

  @override
  Widget build(BuildContext context) {
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
                izquierda: const _CabeceraTitulo(),
                derecha: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BotonContornoIcono(
                      icono:       Icons.description_outlined,
                      alPresionar: () => context.push(Rutas.borradores),
                    ),
                    const SizedBox(width: 18),
                    const _BotonCrearEvento(),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: BarraNavegacionApp(
          indiceActual:    1,
          alCambiarIndice: (indice) {
            if (indice == 0) context.go(Rutas.home);
            if (indice == 4) context.go(Rutas.perfil);
          },
        ),
      ),
    );
  }
}

// ─── Cabecera izquierda ───────────────────────────────────────────────────────

class _CabeceraTitulo extends StatelessWidget {
  const _CabeceraTitulo();

  String _obtenerFecha() {
    final ahora = DateTime.now();
    const dias  = ['Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','Domingo'];
    const meses = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
    return '${dias[ahora.weekday - 1]}, ${ahora.day} ${meses[ahora.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment:  MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mis eventos',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontSize:   20,
            fontWeight: FontWeight.w700,
            color:      ColoresApp.textoPrimario,
          ),
        ),
        Text(
          _obtenerFecha(),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: ColoresApp.textoSecundario,
          ),
        ),
      ],
    );
  }
}

// ─── Botón crear evento ───────────────────────────────────────────────────────

class _BotonCrearEvento extends StatelessWidget {
  const _BotonCrearEvento();

  @override
  Widget build(BuildContext context) {
    return Material(
      color:        Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap:        () => context.push(Rutas.crearEvento),
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width:  40,
          height: 40,
          decoration: BoxDecoration(
            gradient:     ColoresApp.degradadoPrincipal,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size:  22,
          ),
        ),
      ),
    );
  }
}
