import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../compartido/constantes.dart';
import '../../compartido/navegacion.dart';
import '../../compartido/widgets/avisos/vista_error_app.dart';
import '../../compartido/widgets/formularios/barra_busqueda_app.dart';
import '../../compartido/widgets/navegacion/barra_navegacion_app.dart';
import '../../compartido/widgets/navegacion/barra_superior_app.dart';
import '../../configuracion/colores_app.dart';
import '../autenticacion/auth_cubit.dart';
import '../autenticacion/auth_estado.dart';
import 'historial_cubit.dart';
import 'historial_estado.dart';
import 'historial_exportador.dart';
import 'historial_item.dart';

class HistorialPantalla extends StatefulWidget {
  const HistorialPantalla({super.key});

  @override
  State<HistorialPantalla> createState() => _HistorialPantallaState();
}

class _HistorialPantallaState extends State<HistorialPantalla>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _busquedaCtrl = TextEditingController();
  DateTimeRange? _rango;
  bool _estaIniciado = false;
  bool _exportando = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _busquedaCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_estaIniciado) return;
    _estaIniciado = true;
    final authEstado = context.read<AuthCubit>().state;
    if (authEstado is Autenticado) {
      context.read<HistorialCubit>().cargar(authEstado.usuario.id!);
    }
  }

  Future<void> _exportar(List<HistorialItem> items, String nombre) async {
    setState(() => _exportando = true);
    try {
      await HistorialExportador.generarYCompartirPdf(
        nombreUsuario: nombre,
        items: items,
      );
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  List<HistorialItem> _filtrar(List<HistorialItem> items) {
    final q = _busquedaCtrl.text.toLowerCase().trim();
    return items.where((item) {
      final coincideTexto = q.isEmpty ||
          item.eventoTitulo.toLowerCase().contains(q) ||
          (item.eventoLugar?.toLowerCase().contains(q) ?? false);

      final coincideFecha = _rango == null ||
          (item.eventoFechaInicio != null &&
              !item.eventoFechaInicio!.isBefore(_rango!.start) &&
              !item.eventoFechaInicio!.isAfter(_rango!.end));

      return coincideTexto && coincideFecha;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistorialCubit, HistorialEstado>(
      builder: _construirVista,
    );
  }

  Widget _construirVista(BuildContext context, HistorialEstado estado) {
    // Tanto HistorialCargado como HistorialCargandoMas tienen items visibles
    final itemsActuales = switch (estado) {
      HistorialCargado(:final items) => items,
      HistorialCargandoMas(:final items) => items,
      _ => null,
    };
    final hayMas = estado is HistorialCargado && estado.hayMas;
    final cargandoMas = estado is HistorialCargandoMas;

    final filtrados =
        itemsActuales != null ? _filtrar(itemsActuales) : <HistorialItem>[];
    final asistidosFiltrados = filtrados.where((i) => i.esAsistido).toList();
    final salieronFiltrados =
        filtrados.where((i) => i.esSalidaAnticipada).toList();
    final ausentesFiltrados = filtrados.where((i) => i.esAusente).toList();
    final hayBusquedaActiva =
        _busquedaCtrl.text.trim().isNotEmpty || _rango != null;

    final authEstado = context.read<AuthCubit>().state;
    final nombre =
        authEstado is Autenticado ? authEstado.usuario.nombreCompleto : '';
    final todosItems = itemsActuales ?? [];

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
            _BarraTitulo(
              estaExportando: _exportando,
              alCompartir: (todosItems.isNotEmpty && !_exportando)
                  ? () => _exportar(todosItems, nombre)
                  : null,
            ),
            if (itemsActuales != null) ..._construirControles(filtrados),
            Expanded(
              child: _Cuerpo(
                estado: estado,
                tabController: _tabController,
                todos: filtrados,
                asistidos: asistidosFiltrados,
                salieron: salieronFiltrados,
                ausentes: ausentesFiltrados,
                hayBusquedaActiva: hayBusquedaActiva,
                hayMas: hayMas,
                cargandoMas: cargandoMas,
              ),
            ),
          ],
        ),
        bottomNavigationBar: BarraNavegacionApp(
          indiceActual: 3,
          alCambiarIndice: (indice) {
            if (indice == 0) irAPestana(context, Rutas.home);
            if (indice == 1) irAPestana(context, Rutas.eventos);
            if (indice == 4) irAPestana(context, Rutas.perfil);
          },
        ),
      ),
    );
  }

  List<Widget> _construirControles(List<HistorialItem> filtrados) => [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: BarraBusquedaApp(
            controlador: _busquedaCtrl,
            hintText: 'Buscar evento o lugar...',
            alCambiar: (_) => setState(() {}),
            alSeleccionarRango: (r) => setState(() => _rango = r),
            alLimpiarRango: () => setState(() => _rango = null),
            rangoSeleccionado: _rango,
          ),
        ),
        _BloqueTotales(items: filtrados),
        _BarraTabs(controller: _tabController),
      ];
}

// ─── Barra de título ──────────────────────────────────────────────────────────

class _BarraTitulo extends StatelessWidget {
  const _BarraTitulo({
    this.alCompartir,
    this.estaExportando = false,
  });

  final VoidCallback? alCompartir;
  final bool estaExportando;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: BarraSuperiorApp(
        izquierda: Text(
          'Mi historial',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: ColoresApp.textoPrimario,
              ),
        ),
        derecha: alCompartir != null || estaExportando
            ? Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(50),
                child: InkWell(
                  borderRadius: BorderRadius.circular(50),
                  onTap: estaExportando ? null : alCompartir,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: estaExportando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ColoresApp.acento,
                            ),
                          )
                        : const Icon(
                            Icons.ios_share_rounded,
                            color: ColoresApp.acento,
                            size: 22,
                          ),
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

// ─── Bloque de totales ────────────────────────────────────────────────────────

class _BloqueTotales extends StatelessWidget {
  const _BloqueTotales({required this.items});

  final List<HistorialItem> items;

  @override
  Widget build(BuildContext context) {
    final totalAsistio = items.where((i) => i.esAsistido).length;
    final totalSalioAntes = items.where((i) => i.esSalidaAnticipada).length;
    final totalAusente = items.where((i) => i.esAusente).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: ColoresApp.superficiePrimaria,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: ColoresApp.sombraTarjeta,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _CeldaTotales(
            valor: items.length,
            label: 'Total',
            color: ColoresApp.acento,
          ),
          const _Divisor(),
          _CeldaTotales(
            valor: totalAsistio,
            label: 'Asistí',
            color: ColoresApp.verde,
          ),
          const _Divisor(),
          _CeldaTotales(
            valor: totalSalioAntes,
            label: 'Salió antes',
            color: ColoresApp.ambar,
          ),
          const _Divisor(),
          _CeldaTotales(
            valor: totalAusente,
            label: 'Ausente',
            color: ColoresApp.rojo,
          ),
        ],
      ),
    );
  }
}

class _CeldaTotales extends StatelessWidget {
  const _CeldaTotales({
    required this.valor,
    required this.label,
    required this.color,
  });

  final int valor;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$valor',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                  fontSize: 22,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: ColoresApp.textoTerciario,
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }
}

class _Divisor extends StatelessWidget {
  const _Divisor();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: ColoresApp.superficieTerciar,
    );
  }
}

// ─── Barra de tabs ────────────────────────────────────────────────────────────

class _BarraTabs extends StatelessWidget {
  const _BarraTabs({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        color: ColoresApp.superficiePrimaria,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: ColoresApp.sombraTarjeta,
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: TabBar(
        controller: controller,
        isScrollable: false,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: ColoresApp.acento,
          borderRadius: BorderRadius.circular(10),
        ),
        labelColor: ColoresApp.superficiePrimaria,
        unselectedLabelColor: ColoresApp.textoSecundario,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.all(4),
        tabs: const [
          Tab(text: 'Todos'),
          Tab(text: 'Asistí'),
          Tab(text: 'Salió antes'),
          Tab(text: 'Ausente'),
        ],
      ),
    );
  }
}

// ─── Cuerpo según estado ──────────────────────────────────────────────────────

class _Cuerpo extends StatelessWidget {
  const _Cuerpo({
    required this.estado,
    required this.tabController,
    required this.todos,
    required this.asistidos,
    required this.salieron,
    required this.ausentes,
    required this.hayBusquedaActiva,
    required this.hayMas,
    required this.cargandoMas,
  });

  // ── Configuraciones de estado vacío ─────────────────────────────────────────
  static const _vaciaResultados = _VaciaConfig(
    icono: Icons.search_off_rounded,
    titulo: 'Sin resultados',
    subtitulo: 'Intenta con otro término o ajusta el rango de fechas',
  );
  static const _vaciaTodos = _VaciaConfig(
    icono: Icons.calendar_today_outlined,
    titulo: 'Sin eventos aún',
    subtitulo: 'Los eventos a los que asistas aparecerán aquí',
  );
  static const _vaciaAsistidos = _VaciaConfig(
    icono: Icons.check_circle_outline,
    titulo: 'Sin asistencias aún',
    subtitulo: 'Los eventos donde asististe aparecerán aquí',
    colorIcono: ColoresApp.verde,
  );
  static const _vaciaSalieron = _VaciaConfig(
    icono: Icons.logout_outlined,
    titulo: 'Sin salidas anticipadas',
    subtitulo: 'Aquí verás los eventos donde saliste antes del cierre',
    colorIcono: ColoresApp.ambar,
  );
  static const _vaciaAusentes = _VaciaConfig(
    icono: Icons.emoji_events_rounded,
    titulo: '¡Sin ausencias!',
    subtitulo: 'Mantén este récord asistiendo a todos tus eventos',
    colorIcono: ColoresApp.verde,
  );

  final HistorialEstado estado;
  final TabController tabController;
  final List<HistorialItem> todos;
  final List<HistorialItem> asistidos;
  final List<HistorialItem> salieron;
  final List<HistorialItem> ausentes;
  final bool hayBusquedaActiva;
  final bool hayMas;
  final bool cargandoMas;

  @override
  Widget build(BuildContext context) {
    return switch (estado) {
      HistorialInicial() || HistorialCargando() => const Center(
          child: CircularProgressIndicator(color: ColoresApp.acento),
        ),
      HistorialCargado() || HistorialCargandoMas() => TabBarView(
          controller: tabController,
          children: [
            _ListaHistorial(
              items: todos,
              vaciaConfig: hayBusquedaActiva ? _vaciaResultados : _vaciaTodos,
              hayMas: hayMas,
              cargandoMas: cargandoMas,
            ),
            _ListaHistorial(
              items: asistidos,
              vaciaConfig:
                  hayBusquedaActiva ? _vaciaResultados : _vaciaAsistidos,
            ),
            _ListaHistorial(
              items: salieron,
              vaciaConfig:
                  hayBusquedaActiva ? _vaciaResultados : _vaciaSalieron,
            ),
            _ListaHistorial(
              items: ausentes,
              vaciaConfig:
                  hayBusquedaActiva ? _vaciaResultados : _vaciaAusentes,
            ),
          ],
        ),
      final HistorialError error => VistaErrorApp(
          mensaje: error.mensaje,
          alReintentar: () {
            final authEstado = context.read<AuthCubit>().state;
            if (authEstado is Autenticado) {
              context.read<HistorialCubit>().cargar(authEstado.usuario.id!);
            }
          },
        ),
    };
  }
}

// ─── Lista de eventos ─────────────────────────────────────────────────────────

class _ListaHistorial extends StatelessWidget {
  const _ListaHistorial({
    required this.items,
    required this.vaciaConfig,
    this.hayMas = false,
    this.cargandoMas = false,
  });

  final List<HistorialItem> items;
  final _VaciaConfig vaciaConfig;
  final bool hayMas;
  final bool cargandoMas;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && !cargandoMas) {
      return _VistaVacia(config: vaciaConfig);
    }

    // El item extra al final es el indicador de "Cargar más"
    final totalItems = items.length + (hayMas || cargandoMas ? 1 : 0);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      itemCount: totalItems,
      itemBuilder: (context, i) {
        if (i == items.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: cargandoMas
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ColoresApp.acento,
                      ),
                    ),
                  )
                : Center(
                    child: TextButton.icon(
                      onPressed: () =>
                          context.read<HistorialCubit>().cargarMas(),
                      icon: const Icon(
                        Icons.expand_more_rounded,
                        color: ColoresApp.acento,
                      ),
                      label: const Text(
                        'Cargar más',
                        style: TextStyle(color: ColoresApp.acento),
                      ),
                    ),
                  ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _TarjetaHistorial(item: items[i]),
        );
      },
    );
  }
}

// ─── Tarjeta de evento ────────────────────────────────────────────────────────

class _TarjetaHistorial extends StatelessWidget {
  const _TarjetaHistorial({required this.item});

  final HistorialItem item;

  @override
  Widget build(BuildContext context) {
    final config = _configEstatus(item.estatus);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColoresApp.superficiePrimaria,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: ColoresApp.sombraTarjeta,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _Insignia(icono: config.icono, color: config.color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.eventoTitulo,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ColoresApp.textoPrimario,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.eventoLugar != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: ColoresApp.textoTerciario,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          item.eventoLugar!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: ColoresApp.textoTerciario,
                                    fontSize: 11,
                                  ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (item.etiquetaFecha.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.etiquetaFecha,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ColoresApp.textoSecundario,
                          fontSize: 11,
                        ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          _EtiquetaEstatus(
              label: config.label, color: config.color, fondo: config.fondo),
        ],
      ),
    );
  }

  _ConfigEstatus _configEstatus(String estatus) => switch (estatus) {
        EstatusAsistencia.presente => const _ConfigEstatus(
            icono: Icons.check_circle_outline,
            color: ColoresApp.verde,
            fondo: ColoresApp.verdeClaro,
            label: 'Presente',
          ),
        EstatusAsistencia.completado => const _ConfigEstatus(
            icono: Icons.verified_outlined,
            color: ColoresApp.verde,
            fondo: ColoresApp.verdeClaro,
            label: 'Completado',
          ),
        EstatusAsistencia.salioAnticipado => const _ConfigEstatus(
            icono: Icons.logout_outlined,
            color: ColoresApp.ambar,
            fondo: ColoresApp.ambarClaro,
            label: 'Salió antes',
          ),
        EstatusAsistencia.ausente => const _ConfigEstatus(
            icono: Icons.cancel_outlined,
            color: ColoresApp.rojo,
            fondo: ColoresApp.rojoClaro,
            label: 'Ausente',
          ),
        _ => _ConfigEstatus(
            icono: Icons.help_outline,
            color: ColoresApp.textoTerciario,
            fondo: ColoresApp.superficieSecund,
            label: estatus,
          ),
      };
}

class _ConfigEstatus {
  const _ConfigEstatus({
    required this.icono,
    required this.color,
    required this.fondo,
    required this.label,
  });

  final IconData icono;
  final Color color;
  final Color fondo;
  final String label;
}

class _Insignia extends StatelessWidget {
  const _Insignia({required this.icono, required this.color});

  final IconData icono;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icono, color: color, size: 22),
    );
  }
}

class _EtiquetaEstatus extends StatelessWidget {
  const _EtiquetaEstatus({
    required this.label,
    required this.color,
    required this.fondo,
  });

  final String label;
  final Color color;
  final Color fondo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
      ),
    );
  }
}

// ─── Configuración de estado vacío ───────────────────────────────────────────

class _VaciaConfig {
  const _VaciaConfig({
    required this.icono,
    required this.titulo,
    this.subtitulo,
    this.colorIcono,
  });

  final IconData icono;
  final String titulo;
  final String? subtitulo;
  final Color? colorIcono;
}

// ─── Vista estado vacío ───────────────────────────────────────────────────────

class _VistaVacia extends StatelessWidget {
  const _VistaVacia({required this.config});

  final _VaciaConfig config;

  @override
  Widget build(BuildContext context) {
    final color = config.colorIcono ?? ColoresApp.textoTerciario;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(config.icono, color: color, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              config.titulo,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: ColoresApp.textoPrimario,
                  ),
            ),
            if (config.subtitulo != null) ...[
              const SizedBox(height: 6),
              Text(
                config.subtitulo!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ColoresApp.textoTerciario,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
