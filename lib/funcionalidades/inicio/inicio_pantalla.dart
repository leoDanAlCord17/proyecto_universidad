import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../compartido/widgets/avatares/avatar_usuario.dart';
import '../../compartido/widgets/botones/boton_contorno_icono.dart';
import '../../compartido/widgets/navegacion/barra_navegacion_app.dart';
import '../../compartido/widgets/navegacion/barra_superior_app.dart';
import '../../compartido/widgets/panel/panel_opciones.dart';
import '../../compartido/widgets/qr/tarjeta_qr_perfil.dart';
import '../../compartido/constantes.dart';
import '../../configuracion/colores_app.dart';
import '../autenticacion/auth_cubit.dart';
import '../autenticacion/auth_estado.dart';
import '../autenticacion/usuario.dart';
import '../notificaciones/notificaciones_cubit.dart';
import '../notificaciones/notificaciones_estado.dart';
import 'inicio_cubit.dart';
import 'inicio_estado.dart';

class InicioPantalla extends StatefulWidget {
  const InicioPantalla({super.key});

  @override
  State<InicioPantalla> createState() => _InicioPantallaState();
}

class _InicioPantallaState extends State<InicioPantalla> {
  bool _tagsCargados = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_tagsCargados) return;
    _tagsCargados = true;

    final authEstado = context.read<AuthCubit>().state;
    if (authEstado is Autenticado && authEstado.usuario.id != null) {
      context.read<InicioCubit>().cargarTags(authEstado.usuario.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AuthCubit, AuthEstado, Usuario?>(
      selector: (estado) => estado is Autenticado ? estado.usuario : null,
      builder: (context, usuario) {
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
                    derecha: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BlocSelector<NotificacionesCubit, NotificacionesEstado, int>(
                          selector: (estado) =>
                              estado is NotificacionesCargadas ? estado.cantidad : 0,
                          builder: (_, cantidad) =>
                              _BotonNotificaciones(cantidad: cantidad),
                        ),
                        const SizedBox(width: 8),
                        const _BotonAjustes(),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Column(
                      children: [
                        if (usuario?.id != null)
                          BlocBuilder<InicioCubit, InicioEstado>(
                            builder: (context, estado) => TarjetaQrPerfil(
                              usuarioId:       usuario!.id!,
                              roles:           usuario.roles,
                              tagPrincipal:    estado is InicioTagsCargados ? estado.tagPrincipal    : null,
                              tagsSecundarios: estado is InicioTagsCargados ? estado.tagsSecundarios : [],
                            ),
                          ),
                        if (kDebugMode) ...[
                          const SizedBox(height: 12),
                          const _TarjetaDevWidgets(),
                          const SizedBox(height: 12),
                          const _TarjetaDevFuentes(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: BarraNavegacionApp(
              indiceActual:    0,
              alCambiarIndice: (indice) {
                if (indice == 1) context.go(Rutas.eventos);
                if (indice == 4) context.go(Rutas.perfil);
              },
            ),
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
class _TarjetaDevFuentes extends StatelessWidget {
  const _TarjetaDevFuentes();

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
          const Icon(Icons.text_fields_outlined, color: ColoresApp.acento, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Vista de fuentes',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          TextButton(
            onPressed: () => context.push(Rutas.vistaFuentes),
            child: const Text('Ver'),
          ),
        ],
      ),
    );
  }
}

// ─── Botón de ajustes con panel de opciones ──────────────────────────────────

class _BotonAjustes extends StatelessWidget {
  const _BotonAjustes();

  @override
  Widget build(BuildContext context) {
    return BotonContornoIcono(
      icono:       Icons.settings_outlined,
      alPresionar: () => PanelOpciones.mostrar(
        context,
        opciones: [
          OpcionPanel(
            icono:       Icons.people_outline_rounded,
            colorFondo:  ColoresApp.acentoClaro,
            colorIcono:  ColoresApp.acento,
            titulo:      'Usuarios',
            descripcion: 'Gestionar usuarios',
            alPresionar: () {
              Navigator.of(context, rootNavigator: true).pop();
              context.push(Rutas.gestionUsuarios);
            },
          ),
          OpcionPanel(
            icono:       Icons.admin_panel_settings_outlined,
            colorFondo:  ColoresApp.tealClaro,
            colorIcono:  ColoresApp.teal,
            titulo:      'Gestionar Roles',
            descripcion: 'Asignar o remover roles',
            alPresionar: () {
              Navigator.of(context, rootNavigator: true).pop();
              context.push(Rutas.gestionRoles);
            },
          ),
          OpcionPanel(
            icono:       Icons.shield_outlined,
            colorFondo:  ColoresApp.verdeClaro,
            colorIcono:  ColoresApp.verde,
            titulo:      'Permisos',
            descripcion: 'Permisos de la app',
            alPresionar: () {
              Navigator.of(context, rootNavigator: true).pop();
              context.push(Rutas.permisosSistema);
            },
          ),
          OpcionPanel(
            icono:       Icons.label_outline_rounded,
            colorFondo:  ColoresApp.ambarClaro,
            colorIcono:  ColoresApp.ambar,
            titulo:      'Gestionar Tags',
            descripcion: 'Etiquetas',
            alPresionar: () {
              Navigator.of(context, rootNavigator: true).pop();
              context.push(Rutas.gestionTags);
            },
          ),
          const OpcionPanel(
            icono:       Icons.tune_rounded,
            colorFondo:  ColoresApp.superficieTerciar,
            colorIcono:  ColoresApp.textoSecundario,
            titulo:      'Configuraciones generales',
            descripcion: 'Preferencias y ajustes',
          ),
        ],
      ),
    );
  }
}

// ─── Botón de notificaciones con insignia ─────────────────────────────────────

class _BotonNotificaciones extends StatelessWidget {
  const _BotonNotificaciones({required this.cantidad});

  final int cantidad;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        BotonContornoIcono(
          icono:       Icons.notifications_outlined,
          alPresionar: () => context.push(Rutas.notificaciones),
        ),
        if (cantidad > 0)
          Positioned(
            top:   -5,
            right: -5,
            child: _Insignia(cantidad: cantidad),
          ),
      ],
    );
  }
}

class _Insignia extends StatelessWidget {
  const _Insignia({required this.cantidad});

  final int cantidad;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding:     const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration:  BoxDecoration(
        color:        ColoresApp.rojo,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Center(
        child: Text(
          cantidad > 9 ? '+9' : '$cantidad',
          style: const TextStyle(
            color:      Colors.white,
            fontSize:   10,
            fontWeight: FontWeight.w700,
            height:     1.0,
          ),
        ),
      ),
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
