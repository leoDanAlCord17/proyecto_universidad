import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../compartido/widgets/avatares/avatar_usuario.dart';
import '../../compartido/widgets/navegacion/barra_navegacion_app.dart';
import '../../compartido/widgets/navegacion/barra_superior_app.dart';
import '../../compartido/constantes.dart';
import '../../configuracion/colores_app.dart';
import '../autenticacion/auth_cubit.dart';
import '../autenticacion/auth_estado.dart';
import '../autenticacion/usuario.dart';

class InicioPantalla extends StatelessWidget {
  const InicioPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AuthCubit, AuthEstado, Usuario?>(
      selector: (estado) => estado is Autenticado ? estado.usuario : null,
      builder: (context, usuario) {
        return Scaffold(
          backgroundColor: ColoresApp.fondo,
          body: Column(
            children: [
              SafeArea(
                bottom: false,
                child: BarraSuperiorApp(
                  izquierda: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (usuario != null) ...[
                        AvatarUsuario(iniciales: usuario.iniciales, tamanio: 42),
                        const SizedBox(width: 12),
                      ],
                      _CabeceraTexto(nombre: usuario?.nombreCompleto ?? ''),
                    ],
                  ),
                  derecha: IconButton(
                    icon:      const Icon(Icons.settings_outlined),
                    color:     ColoresApp.textoSecundario,
                    iconSize:  24,
                    tooltip:   'Configuración',
                    onPressed: null,
                  ),
                ),
              ),
              if (kDebugMode)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: _TarjetaDevWidgets(),
                ),
            ],
          ),
          bottomNavigationBar: BarraNavegacionApp(
            indiceActual:    0,
            alCambiarIndice: (_) {},
          ),
        );
      },
    );
  }
}

class _CabeceraTexto extends StatelessWidget {
  const _CabeceraTexto({required this.nombre});

  final String nombre;

  String _obtenerFecha() {
    final ahora = DateTime.now();
    const dias  = ['Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','Domingo'];
    const meses = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
    return '${dias[ahora.weekday - 1]}, ${ahora.day} ${meses[ahora.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return Column(
      mainAxisAlignment:  MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _obtenerFecha(),
          style: estilos.titleSmall?.copyWith(color: ColoresApp.textoSecundario),
        ),
        Text(
          'Hola, $nombre 👋',
          style: estilos.titleSmall?.copyWith(
            fontSize:   20,
            fontWeight: FontWeight.w700,
            color:      ColoresApp.textoPrimario,
          ),
        ),
      ],
    );
  }
}

// TODO: borrar cuando ya no se necesite
class _TarjetaDevWidgets extends StatelessWidget {
  const _TarjetaDevWidgets();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        ColoresApp.superficiePrimaria,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: ColoresApp.bordeMedio),
      ),
      child: Row(
        children: [
          const Icon(Icons.widgets_outlined, color: ColoresApp.acento, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Vista de widgets',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          TextButton(
            onPressed: () => context.push(Rutas.vistaWidgets),
            child: const Text('Ver'),
          ),
        ],
      ),
    );
  }
}
