import 'package:flutter/material.dart';

import '../../../configuracion/colores_app.dart';
import '../estadisticas_modelo.dart';
import '../filtros_estadisticas.dart';

class PanelFiltros extends StatefulWidget {
  const PanelFiltros({
    required this.filtrosActuales,
    required this.opciones,
    required this.alAplicar,
  });

  final FiltrosEstadisticas filtrosActuales;
  final OpcionesFiltros opciones;
  final ValueChanged<FiltrosEstadisticas> alAplicar;

  @override
  State<PanelFiltros> createState() => _PanelFiltrosState();
}

class _PanelFiltrosState extends State<PanelFiltros>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DateTimeRange _rango;
  late List<OpcionFiltro> _tiposSeleccionados;
  late List<OpcionFiltro> _creadoresSeleccionados;
  late List<OpcionFiltro> _tagsSeleccionados;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _rango = widget.filtrosActuales.rango;
    _tiposSeleccionados = List.from(widget.filtrosActuales.tiposSeleccionados);
    _creadoresSeleccionados =
        List.from(widget.filtrosActuales.creadoresSeleccionados);
    _tagsSeleccionados = List.from(widget.filtrosActuales.tagsSeleccionados);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _seleccionarRango(int dias) {
    final ahora = DateTime.now();
    setState(
      () => _rango = DateTimeRange(
        start: ahora.subtract(Duration(days: dias)),
        end: ahora,
      ),
    );
  }

  void _seleccionarAnio() {
    final ahora = DateTime.now();
    setState(
      () => _rango = DateTimeRange(
        start: DateTime(ahora.year, 1, 1),
        end: ahora,
      ),
    );
  }

  Future<void> _seleccionarPersonalizado() async {
    final resultado = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _rango,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: ColoresApp.acento),
        ),
        child: child!,
      ),
    );
    if (resultado != null) setState(() => _rango = resultado);
  }

  void _toggleTipo(OpcionFiltro o) => setState(() {
        _tiposSeleccionados.any((e) => e.id == o.id)
            ? _tiposSeleccionados.removeWhere((e) => e.id == o.id)
            : _tiposSeleccionados.add(o);
      });

  void _toggleCreador(OpcionFiltro o) => setState(() {
        _creadoresSeleccionados.any((e) => e.id == o.id)
            ? _creadoresSeleccionados.removeWhere((e) => e.id == o.id)
            : _creadoresSeleccionados.add(o);
      });

  void _toggleTag(OpcionFiltro o) => setState(() {
        _tagsSeleccionados.any((e) => e.id == o.id)
            ? _tagsSeleccionados.removeWhere((e) => e.id == o.id)
            : _tagsSeleccionados.add(o);
      });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final totalActivos = _tiposSeleccionados.length +
        _creadoresSeleccionados.length +
        _tagsSeleccionados.length;

    return ConstrainedBox(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.88),
      child: Container(
        decoration: const BoxDecoration(
          color: ColoresApp.superficiePrimaria,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 14),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: ColoresApp.bordeMedio,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('Filtros',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const Spacer(),
                  if (totalActivos > 0)
                    TextButton(
                      onPressed: () => setState(() {
                        _tiposSeleccionados.clear();
                        _creadoresSeleccionados.clear();
                        _tagsSeleccionados.clear();
                      }),
                      child: const Text(
                        'Limpiar todo',
                        style: TextStyle(color: ColoresApp.rojo, fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _TabsFiltros(
                controller: _tabController, totalActivos: totalActivos),
            const SizedBox(height: 4),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _TabPeriodo(
                    rango: _rango,
                    alSeleccionar7: () => _seleccionarRango(7),
                    alSeleccionar30: () => _seleccionarRango(30),
                    alSeleccionar90: () => _seleccionarRango(90),
                    alSeleccionarAnio: _seleccionarAnio,
                    alPersonalizado: _seleccionarPersonalizado,
                  ),
                  _TabMultiselect(
                    opciones: widget.opciones.tipos,
                    seleccionados: _tiposSeleccionados,
                    onToggle: _toggleTipo,
                    etiquetaVacia:
                        'No hay tipos de evento disponibles para el período',
                  ),
                  _TabMultiselect(
                    opciones: widget.opciones.creadores,
                    seleccionados: _creadoresSeleccionados,
                    onToggle: _toggleCreador,
                    etiquetaVacia:
                        'No hay organizadores disponibles para el período',
                  ),
                  _TabMultiselect(
                    opciones: widget.opciones.tags,
                    seleccionados: _tagsSeleccionados,
                    onToggle: _toggleTag,
                    etiquetaVacia: 'No hay tags disponibles para el período',
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding + 16),
              child: FilledButton(
                onPressed: () => widget.alAplicar(
                  FiltrosEstadisticas(
                    rango: _rango,
                    tiposSeleccionados: _tiposSeleccionados,
                    creadoresSeleccionados: _creadoresSeleccionados,
                    tagsSeleccionados: _tagsSeleccionados,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: ColoresApp.acento,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Aplicar filtros',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tabs del panel ───────────────────────────────────────────────────────────

class _TabsFiltros extends StatelessWidget {
  const _TabsFiltros({required this.controller, required this.totalActivos});
  final TabController controller;
  final int totalActivos;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: ColoresApp.superficieSecund,
        borderRadius: BorderRadius.circular(12),
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
        labelColor: ColoresApp.blanco,
        unselectedLabelColor: ColoresApp.textoSecundario,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.all(4),
        tabs: const [
          Tab(text: 'Período'),
          Tab(text: 'Tipo'),
          Tab(text: 'Creador'),
          Tab(text: 'Tag'),
        ],
      ),
    );
  }
}

// ─── Tab Período ──────────────────────────────────────────────────────────────

class _TabPeriodo extends StatelessWidget {
  const _TabPeriodo({
    required this.rango,
    required this.alSeleccionar7,
    required this.alSeleccionar30,
    required this.alSeleccionar90,
    required this.alSeleccionarAnio,
    required this.alPersonalizado,
  });

  final DateTimeRange rango;
  final VoidCallback alSeleccionar7;
  final VoidCallback alSeleccionar30;
  final VoidCallback alSeleccionar90;
  final VoidCallback alSeleccionarAnio;
  final VoidCallback alPersonalizado;

  @override
  Widget build(BuildContext context) {
    final dias = rango.end.difference(rango.start).inDays;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rango activo',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.1,
                  color: ColoresApp.textoTerciario,
                ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: ColoresApp.acentoClaro,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ColoresApp.acentoBorde),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    color: ColoresApp.acento, size: 16),
                const SizedBox(width: 8),
                Text(
                  '${rango.start.day}/${rango.start.month}/${rango.start.year}'
                  '  →  '
                  '${rango.end.day}/${rango.end.month}/${rango.end.year}',
                  style: const TextStyle(
                    color: ColoresApp.acento,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Presets',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.1,
                  color: ColoresApp.textoTerciario,
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ChipPreset(
                  label: '7 días', activo: dias <= 8, alTap: alSeleccionar7),
              _ChipPreset(
                  label: '30 días',
                  activo: dias > 8 && dias <= 31,
                  alTap: alSeleccionar30),
              _ChipPreset(
                  label: '90 días',
                  activo: dias > 31 && dias <= 92,
                  alTap: alSeleccionar90),
              _ChipPreset(
                label: 'Este año',
                activo: rango.start.month == 1 && rango.start.day == 1,
                alTap: alSeleccionarAnio,
              ),
              _ChipPreset(
                label: 'Personalizado',
                icono: Icons.edit_calendar_outlined,
                activo: false,
                alTap: alPersonalizado,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChipPreset extends StatelessWidget {
  const _ChipPreset(
      {required this.label,
      required this.activo,
      required this.alTap,
      this.icono});
  final String label;
  final bool activo;
  final VoidCallback alTap;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: activo ? ColoresApp.acento : ColoresApp.superficieSecund,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: alTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            border: Border.all(
                color: activo ? ColoresApp.acento : ColoresApp.bordeMedio),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icono != null) ...[
                Icon(
                  icono,
                  size: 14,
                  color:
                      activo ? ColoresApp.blanco : ColoresApp.textoSecundario,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color:
                      activo ? ColoresApp.blanco : ColoresApp.textoSecundario,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tab multi-selección ──────────────────────────────────────────────────────

class _TabMultiselect extends StatelessWidget {
  const _TabMultiselect({
    required this.opciones,
    required this.seleccionados,
    required this.onToggle,
    required this.etiquetaVacia,
  });

  final List<OpcionFiltro> opciones;
  final List<OpcionFiltro> seleccionados;
  final ValueChanged<OpcionFiltro> onToggle;
  final String etiquetaVacia;

  @override
  Widget build(BuildContext context) {
    if (opciones.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            etiquetaVacia,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: ColoresApp.textoTerciario),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      itemCount: opciones.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: ColoresApp.bordesuave),
      itemBuilder: (_, i) {
        final opcion = opciones[i];
        final activo = seleccionados.any((e) => e.id == opcion.id);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onToggle(opcion),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      opcion.nombre,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight:
                                activo ? FontWeight.w700 : FontWeight.w500,
                            color: activo
                                ? ColoresApp.acento
                                : ColoresApp.textoPrimario,
                          ),
                    ),
                  ),
                  if (activo)
                    const Icon(Icons.check_circle_rounded,
                        color: ColoresApp.acento, size: 22)
                  else
                    const Icon(Icons.radio_button_unchecked_rounded,
                        color: ColoresApp.bordeMedio, size: 22),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
