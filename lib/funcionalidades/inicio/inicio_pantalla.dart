import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../compartido/widgets/avatares/avatar_usuario.dart';
import '../../compartido/widgets/botones/boton_contorno_icono.dart';
import '../../compartido/widgets/navegacion/barra_superior_app.dart';
import '../../compartido/widgets/panel/panel_opciones.dart';
import '../../compartido/widgets/qr/tarjeta_qr_perfil.dart';
import '../../compartido/constantes.dart';
import '../../compartido/navegacion.dart';
import '../../compartido/reanudar_app.dart';
import '../../configuracion/colores_app.dart';
import '../autenticacion/auth_cubit.dart';
import '../autenticacion/auth_estado.dart';
import '../autenticacion/usuario.dart';
import '../notificaciones/notificaciones_cubit.dart';
import '../notificaciones/notificaciones_estado.dart';
import 'eventos_en_curso_cubit.dart';
import 'eventos_en_curso_estado.dart';
import 'inicio_cubit.dart';
import 'inicio_estado.dart';
import '../../compartido/widgets/tarjetas/tarjeta_evento_en_curso.dart';

class InicioPantalla extends StatefulWidget {
  const InicioPantalla({super.key});

  @override
  State<InicioPantalla> createState() => _InicioPantallaState();
}

class _InicioPantallaState extends State<InicioPantalla>
    with WidgetsBindingObserver {
  bool _tagsCargados = false;
  VoidCallback? _cancelarReanudacion;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cancelarReanudacion = escucharReanudacion(_alReanudar);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_tagsCargados) return;
    _tagsCargados = true;

    final authEstado = context.read<AuthCubit>().state;
    if (authEstado is Autenticado && authEstado.usuario.id != null) {
      final id = authEstado.usuario.id!;
      context.read<InicioCubit>().cargarTags(id);
      context.read<EventosEnCursoCubit>().cargar(id);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // El refresco periódico del cubit (cada 5 min, red de seguridad) ya
    // cubre la mayoría de los casos, pero si la app estuvo minimizada un
    // rato, esto evita esperar hasta el próximo tick del timer al volver a
    // primer plano.
    if (state == AppLifecycleState.resumed) _alReanudar();
  }

  // AppLifecycleState.resumed no siempre se dispara de forma confiable en
  // Flutter Web (depende del navegador) — escucharReanudacion complementa
  // con el evento nativo visibilitychange. En plataformas no-web es un
  // no-op (retorna null), así que esto solo agrega, nunca duplica sin razón.
  void _alReanudar() {
    if (!mounted) return;
    context.read<EventosEnCursoCubit>().refrescarAlReanudar();
  }

  @override
  void dispose() {
    _cancelarReanudacion?.call();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AuthCubit, AuthEstado, Usuario?>(
      selector: (estado) => estado is Autenticado ? estado.usuario : null,
      builder: (context, usuario) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          child: Scaffold(
            backgroundColor: ColoresApp.fondo,
            body: Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: BarraSuperiorApp(
                    izquierda: Row(
                      children: [
                        if (usuario != null) ...[
                          AvatarUsuario(
                            iniciales: usuario.iniciales,
                            urlFoto: usuario.urlAvatar,
                            tamanio: 42,
                          ),
                          const SizedBox(width: 12),
                        ],
                        // Flexible (no un tamaño fijo) para que el saludo se
                        // achique en pantallas angostas en vez de invadir el
                        // espacio de los botones de notificaciones/ajustes.
                        Flexible(
                          child: _CabeceraTexto(
                              nombre: usuario?.nombreCompleto ?? ''),
                        ),
                      ],
                    ),
                    derecha: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BlocSelector<NotificacionesCubit, NotificacionesEstado,
                            int>(
                          selector: (estado) => estado is NotificacionesCargadas
                              ? estado.cantidad
                              : 0,
                          builder: (_, cantidad) =>
                              _BotonNotificaciones(cantidad: cantidad),
                        ),
                        // Mismo ancho que el espacio entre el avatar y el
                        // saludo (izquierda), para que ambos lados de la
                        // barra guarden la misma separación y se vean
                        // simétricos.
                        const SizedBox(width: 12),
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
                              usuarioId: usuario!.id!,
                              roles: usuario.roles,
                              tagPrincipal: estado is InicioTagsCargados
                                  ? estado.tagPrincipal
                                  : null,
                              tagsSecundarios: estado is InicioTagsCargados
                                  ? estado.tagsSecundarios
                                  : [],
                            ),
                          ),
                        BlocBuilder<EventosEnCursoCubit, EventosEnCursoEstado>(
                          builder: (context, estado) =>
                              _SeccionEventosEnCurso(estado: estado),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlocSelector<EventosEnCursoCubit, EventosEnCursoEstado, int>(
          selector: (estado) =>
              estado is EventosEnCursoCargado ? estado.eventos.length : 0,
          builder: (context, cantidad) {
            if (cantidad == 0) return const SizedBox.shrink();
            final texto = cantidad == 1
                ? '1 evento activo ahora'
                : '$cantidad eventos activos ahora';
            return _TextoAjustable(
              texto: texto,
              style: estilos.titleSmall?.copyWith(
                color: ColoresApp.verde,
                fontWeight: FontWeight.w600,
              ),
            );
          },
        ),
        _TextoAjustable(
          texto: 'Hola, $nombre 👋',
          style: estilos.titleSmall?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: ColoresApp.textoPrimario,
          ),
        ),
      ],
    );
  }
}

/// Texto de una sola línea que se achica (no se corta ni se envuelve) para
/// caber en el espacio disponible — usado por el saludo "Hola, {nombre} 👋",
/// cuyo largo depende del nombre real del usuario y podía invadir los
/// botones de la barra superior en pantallas angostas.
class _TextoAjustable extends StatelessWidget {
  const _TextoAjustable({required this.texto, required this.style});

  final String texto;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(texto, style: style, maxLines: 1, softWrap: false),
    );
  }
}

// ─── Sección eventos en curso ─────────────────────────────────────────────────

class _SeccionEventosEnCurso extends StatelessWidget {
  const _SeccionEventosEnCurso({required this.estado});

  final EventosEnCursoEstado estado;

  @override
  Widget build(BuildContext context) {
    return switch (estado) {
      EventosEnCursoInicial() ||
      EventosEnCursoCargando() =>
        const _CargandoEventosEnCurso(),
      EventosEnCursoError(:final mensaje) =>
        _ErrorEventosEnCurso(mensaje: mensaje),
      EventosEnCursoCargado(:final eventos) => eventos.isEmpty
          ? const _EstadoVacioEventos()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                for (final evento in eventos) ...[
                  TarjetaEventoEnCurso(eventoEnCurso: evento),
                  const SizedBox(height: 12),
                ],
              ],
            ),
    };
  }
}

// ─── Estado de carga: eventos en curso ───────────────────────────────────────

class _CargandoEventosEnCurso extends StatelessWidget {
  const _CargandoEventosEnCurso();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 24),
      child: Center(
        child: CircularProgressIndicator(color: ColoresApp.acento),
      ),
    );
  }
}

// ─── Estado de error: eventos en curso ───────────────────────────────────────

class _ErrorEventosEnCurso extends StatelessWidget {
  const _ErrorEventosEnCurso({required this.mensaje});

  final String mensaje;

  void _reintentar(BuildContext context) {
    final authEstado = context.read<AuthCubit>().state;
    if (authEstado is Autenticado && authEstado.usuario.id != null) {
      context.read<EventosEnCursoCubit>().cargar(authEstado.usuario.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: ColoresApp.superficieTerciar,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 36,
              color: ColoresApp.textoSecundario,
            ),
            const SizedBox(height: 12),
            Text(
              'No se pudieron cargar los eventos activos',
              textAlign: TextAlign.center,
              style: estilos.bodyMedium?.copyWith(
                color: ColoresApp.textoSecundario,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => _reintentar(context),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Estado vacío: sin eventos en curso ──────────────────────────────────────

class _EstadoVacioEventos extends StatelessWidget {
  const _EstadoVacioEventos();

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: ColoresApp.superficieTerciar,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.event_busy_outlined,
              size: 40,
              color: ColoresApp.textoSecundario,
            ),
            const SizedBox(height: 12),
            Text(
              'No hay eventos activos en este momento',
              textAlign: TextAlign.center,
              style: estilos.bodyMedium
                  ?.copyWith(color: ColoresApp.textoSecundario),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => pestanaActiva.value = 1,
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text('Ver próximos eventos'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Botón de ajustes con panel de opciones ──────────────────────────────────

class _BotonAjustes extends StatelessWidget {
  const _BotonAjustes();

  @override
  Widget build(BuildContext context) {
    final usuario = context.select<AuthCubit, Usuario?>(
      (c) => c.state is Autenticado ? (c.state as Autenticado).usuario : null,
    );

    if (usuario == null || !usuario.tienePermiso('ajustes')) {
      return const SizedBox.shrink();
    }

    final revisionHabilitada = context.select<InicioCubit, bool>(
      (cubit) => cubit.state is InicioTagsCargados
          ? (cubit.state as InicioTagsCargados).revisionHabilitada
          : false,
    );

    return BotonContornoIcono(
      icono: Icons.settings_outlined,
      alPresionar: () => PanelOpciones.mostrar(
        context,
        opciones: [
          if (usuario.tienePermiso('ajustes.usuarios'))
            OpcionPanel(
              icono: Icons.people_outline_rounded,
              colorFondo: ColoresApp.acentoClaro,
              colorIcono: ColoresApp.acento,
              titulo: 'Usuarios',
              descripcion: 'Gestionar usuarios',
              alPresionar: () {
                Navigator.of(context, rootNavigator: true).pop();
                context.push(Rutas.gestionUsuarios);
              },
            ),
          if (revisionHabilitada &&
              usuario.tienePermiso('ajustes.revision_usuarios'))
            OpcionPanel(
              icono: Icons.how_to_reg_outlined,
              colorFondo: ColoresApp.ambarClaro,
              colorIcono: ColoresApp.ambar,
              titulo: 'Revisión de usuarios',
              descripcion: 'Aprobar o rechazar solicitudes',
              alPresionar: () {
                Navigator.of(context, rootNavigator: true).pop();
                context.push(Rutas.revisionUsuarios);
              },
            ),
          if (usuario.tienePermiso('ajustes.gestionar_roles'))
            OpcionPanel(
              icono: Icons.admin_panel_settings_outlined,
              colorFondo: ColoresApp.tealClaro,
              colorIcono: ColoresApp.teal,
              titulo: 'Gestionar Roles',
              descripcion: 'Asignar o remover roles',
              alPresionar: () {
                Navigator.of(context, rootNavigator: true).pop();
                context.push(Rutas.gestionRoles);
              },
            ),
          if (usuario.tienePermiso('ajustes.permisos'))
            OpcionPanel(
              icono: Icons.shield_outlined,
              colorFondo: ColoresApp.verdeClaro,
              colorIcono: ColoresApp.verde,
              titulo: 'Permisos',
              descripcion: 'Permisos de la app',
              alPresionar: () {
                Navigator.of(context, rootNavigator: true).pop();
                context.push(Rutas.permisosSistema);
              },
            ),
          if (usuario.tienePermiso('ajustes.gestionar_tags'))
            OpcionPanel(
              icono: Icons.label_outline_rounded,
              colorFondo: ColoresApp.ambarClaro,
              colorIcono: ColoresApp.ambar,
              titulo: 'Gestionar Tags',
              descripcion: 'Etiquetas',
              alPresionar: () {
                Navigator.of(context, rootNavigator: true).pop();
                context.push(Rutas.gestionTags);
              },
            ),
          if (usuario.tienePermiso('ajustes.tipos_eventos'))
            OpcionPanel(
              icono: Icons.category_outlined,
              colorFondo: ColoresApp.tealClaro,
              colorIcono: ColoresApp.teal,
              titulo: 'Tipos de evento',
              descripcion: 'Gestionar tipos de evento',
              alPresionar: () {
                Navigator.of(context, rootNavigator: true).pop();
                context.push(Rutas.gestionTiposEvento);
              },
            ),
          if (usuario.tienePermiso('ajustes.estadisticas'))
            OpcionPanel(
              icono: Icons.bar_chart_rounded,
              colorFondo: ColoresApp.verdeClaro,
              colorIcono: ColoresApp.verde,
              titulo: 'Estadísticas',
              descripcion: 'Métricas y análisis de eventos',
              alPresionar: () {
                Navigator.of(context, rootNavigator: true).pop();
                context.push(Rutas.estadisticas);
              },
            ),
          if (usuario.tienePermiso('ajustes.configuraciones'))
            OpcionPanel(
              icono: Icons.tune_rounded,
              colorFondo: ColoresApp.superficieTerciar,
              colorIcono: ColoresApp.textoSecundario,
              titulo: 'Configuraciones generales',
              descripcion: 'Preferencias y ajustes',
              alPresionar: () {
                Navigator.of(context, rootNavigator: true).pop();
                context.push(Rutas.configuracionGeneral);
              },
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
          icono: Icons.notifications_outlined,
          alPresionar: () => context.push(Rutas.notificaciones),
        ),
        if (cantidad > 0)
          Positioned(
            top: -5,
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: ColoresApp.rojo,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Center(
        child: Text(
          cantidad > 9 ? '+9' : '$cantidad',
          style: const TextStyle(
            color: ColoresApp.blanco,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
