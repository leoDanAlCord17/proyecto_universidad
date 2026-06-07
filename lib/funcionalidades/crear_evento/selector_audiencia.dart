import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/constantes.dart';
import '../../configuracion/colores_app.dart';
import 'crear_evento_cubit.dart';
import 'crear_evento_estado.dart';
import 'grupo_audiencia.dart';
import 'tag_opcion.dart';

// ─── Widget principal ─────────────────────────────────────────────────────────

class SelectorAudiencia extends StatelessWidget {
  const SelectorAudiencia({super.key, required this.estado});

  final CrearEventoCargado estado;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CrearEventoCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OpcionesAlcance(
          alcance: estado.alcance,
          alCambiar: (a) =>
              cubit.actualizarCampo((s) => s.copiarCon(alcance: a)),
        ),
        if (estado.alcance == AlcanceEvento.dirigido) ...[
          const SizedBox(height: 12),
          ...estado.grupos.map(
            (g) => _TarjetaGrupoAudiencia(
              grupo: g,
              onEliminar: () => cubit.eliminarGrupo(g.grupoIndex),
            ),
          ),
          const SizedBox(height: 4),
          _BotonAgregarGrupo(
            tagsPrincipales: estado.tagsPrincipales,
            tagsSecundarios: estado.tagsSecundarios,
            maxTagsSecundarios: estado.maxTagsSecundarios,
            siguienteIndice: _siguienteIndice(estado.grupos),
            onAgregar: cubit.agregarGrupo,
          ),
        ],
      ],
    );
  }

  static int _siguienteIndice(List<GrupoAudiencia> grupos) {
    if (grupos.isEmpty) return 0;
    return grupos.map((g) => g.grupoIndex).reduce((a, b) => a > b ? a : b) + 1;
  }
}

// ─── Opciones de alcance ──────────────────────────────────────────────────────

class _OpcionesAlcance extends StatelessWidget {
  const _OpcionesAlcance({required this.alcance, required this.alCambiar});

  final String alcance;
  final void Function(String) alCambiar;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Opcion(
            etiqueta: 'General',
            descripcion: 'Visible para todos',
            activo: alcance == AlcanceEvento.general,
            alPresionar: () => alCambiar(AlcanceEvento.general),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Opcion(
            etiqueta: 'Dirigido',
            descripcion: 'Grupos específicos',
            activo: alcance == AlcanceEvento.dirigido,
            alPresionar: () => alCambiar(AlcanceEvento.dirigido),
          ),
        ),
      ],
    );
  }
}

class _Opcion extends StatelessWidget {
  const _Opcion({
    required this.etiqueta,
    required this.descripcion,
    required this.activo,
    required this.alPresionar,
  });

  final String etiqueta;
  final String descripcion;
  final bool activo;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: alPresionar,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          decoration: BoxDecoration(
            color: activo
                ? ColoresApp.acento.withValues(alpha: 0.08)
                : ColoresApp.superficieSecund,
            border: Border.all(
              color: activo ? ColoresApp.acento : ColoresApp.bordeMedio,
              width: activo ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                activo
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 18,
                color: activo ? ColoresApp.acento : ColoresApp.textoTerciario,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      etiqueta,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: activo
                                ? ColoresApp.acento
                                : ColoresApp.textoPrimario,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                    ),
                    Text(
                      descripcion,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ColoresApp.textoTerciario,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tarjeta de grupo ─────────────────────────────────────────────────────────

class _TarjetaGrupoAudiencia extends StatelessWidget {
  const _TarjetaGrupoAudiencia({required this.grupo, required this.onEliminar});

  final GrupoAudiencia grupo;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: ColoresApp.superficieSecund,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ColoresApp.bordeMedio),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: ColoresApp.acento,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                grupo.etiqueta,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ColoresApp.textoPrimario,
                    ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onEliminar,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded,
                      size: 16, color: ColoresApp.textoTerciario),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Botón agregar grupo ──────────────────────────────────────────────────────

class _BotonAgregarGrupo extends StatelessWidget {
  const _BotonAgregarGrupo({
    required this.tagsPrincipales,
    required this.tagsSecundarios,
    required this.maxTagsSecundarios,
    required this.siguienteIndice,
    required this.onAgregar,
  });

  final List<TagOpcion> tagsPrincipales;
  final List<TagOpcion> tagsSecundarios;
  final int maxTagsSecundarios;
  final int siguienteIndice;
  final void Function(GrupoAudiencia) onAgregar;

  Future<void> _abrir(BuildContext context) async {
    final resultado = await showModalBottomSheet<GrupoAudiencia>(
      context: context,
      backgroundColor: ColoresApp.superficiePrimaria,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _HojaCrearGrupo(
        tagsPrincipales: tagsPrincipales,
        tagsSecundarios: tagsSecundarios,
        maxTagsSecundarios: maxTagsSecundarios,
        grupoIndex: siguienteIndice,
      ),
    );
    if (resultado != null) onAgregar(resultado);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => _abrir(context),
        borderRadius: BorderRadius.circular(10),
        highlightColor: ColoresApp.superficieTerciar,
        splashColor: ColoresApp.bordeMedio,
        child: Ink(
          decoration: BoxDecoration(
            border: Border.all(color: ColoresApp.acento),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_rounded, color: ColoresApp.acento, size: 18),
              const SizedBox(width: 6),
              Text(
                'Añadir grupo',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: ColoresApp.acento,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Hoja: crear grupo ────────────────────────────────────────────────────────

class _HojaCrearGrupo extends StatefulWidget {
  const _HojaCrearGrupo({
    required this.tagsPrincipales,
    required this.tagsSecundarios,
    required this.maxTagsSecundarios,
    required this.grupoIndex,
  });

  final List<TagOpcion> tagsPrincipales;
  final List<TagOpcion> tagsSecundarios;
  final int maxTagsSecundarios;
  final int grupoIndex;

  @override
  State<_HojaCrearGrupo> createState() => _HojaCrearGrupoState();
}

class _HojaCrearGrupoState extends State<_HojaCrearGrupo> {
  TagOpcion? _principal;
  List<TagOpcion> _secundarios = [];

  Future<void> _seleccionarPrincipal() async {
    final res = await showModalBottomSheet<TagOpcion>(
      context: context,
      backgroundColor: ColoresApp.superficiePrimaria,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _HojaSelectSingle<TagOpcion>(
        opciones: widget.tagsPrincipales,
        mostrarTexto: (t) => t.nombre,
        valorActual: _principal,
      ),
    );
    if (res != null) setState(() => _principal = res);
  }

  Future<void> _seleccionarSecundarios() async {
    final res = await showModalBottomSheet<List<TagOpcion>>(
      context: context,
      backgroundColor: ColoresApp.superficiePrimaria,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _HojaMultiSelect(
        opciones: widget.tagsSecundarios,
        seleccionados: _secundarios,
        max: widget.maxTagsSecundarios,
      ),
    );
    if (res != null) setState(() => _secundarios = res);
  }

  void _confirmar() {
    if (_principal == null) return;
    Navigator.of(context).pop(
      GrupoAudiencia(
        grupoIndex: widget.grupoIndex,
        tagPrincipal: _principal!,
        tagsSecundarios: _secundarios,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final puedeConfirmar = _principal != null;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ColoresApp.bordeMedio,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Nuevo grupo', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
            _CampoPickerHoja(
              etiqueta: 'Tag principal *',
              hintText: 'Selecciona',
              valor: _principal?.nombre,
              alPresionar: _seleccionarPrincipal,
            ),
            if (widget.tagsSecundarios.isNotEmpty) ...[
              const SizedBox(height: 16),
              _CampoPickerHoja(
                etiqueta: 'Tags secundarios',
                hintText: 'Ninguno',
                valor: _secundarios.isEmpty
                    ? null
                    : _secundarios.map((t) => t.nombre).join(', '),
                alPresionar: _seleccionarSecundarios,
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: Material(
                color:
                    puedeConfirmar ? ColoresApp.acento : ColoresApp.bordeMedio,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: puedeConfirmar ? _confirmar : null,
                  borderRadius: BorderRadius.circular(12),
                  splashColor: ColoresApp.blanco.withValues(alpha: 0.2),
                  highlightColor: ColoresApp.blanco.withValues(alpha: 0.1),
                  child: Center(
                    child: Text(
                      'Agregar',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: ColoresApp.blanco,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Campo picker dentro de la hoja ──────────────────────────────────────────

class _CampoPickerHoja extends StatelessWidget {
  const _CampoPickerHoja({
    required this.etiqueta,
    required this.hintText,
    required this.alPresionar,
    this.valor,
  });

  final String etiqueta;
  final String hintText;
  final String? valor;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: alPresionar,
            borderRadius: BorderRadius.circular(12),
            highlightColor: ColoresApp.superficieTerciar,
            splashColor: ColoresApp.bordeMedio,
            child: Ink(
              decoration: BoxDecoration(
                color: ColoresApp.superficieSecund,
                border: Border.all(color: ColoresApp.bordeMedio),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      valor ?? hintText,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: valor != null
                                ? ColoresApp.textoPrimario
                                : ColoresApp.textoTerciario,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: ColoresApp.textoTerciario,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Hoja selección simple ────────────────────────────────────────────────────

class _HojaSelectSingle<T> extends StatelessWidget {
  const _HojaSelectSingle({
    required this.opciones,
    required this.mostrarTexto,
    this.valorActual,
  });

  final List<T> opciones;
  final String Function(T) mostrarTexto;
  final T? valorActual;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: ColoresApp.bordeMedio,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: opciones.length,
              itemBuilder: (context, i) {
                final opcion = opciones[i];
                final activo = valorActual == opcion;
                return ListTile(
                  title: Text(
                    mostrarTexto(opcion),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: activo
                              ? ColoresApp.acento
                              : ColoresApp.textoPrimario,
                        ),
                  ),
                  trailing: activo
                      ? const Icon(Icons.check_rounded,
                          color: ColoresApp.acento)
                      : null,
                  onTap: () => Navigator.pop(context, opcion),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Hoja selección múltiple ──────────────────────────────────────────────────

class _HojaMultiSelect extends StatefulWidget {
  const _HojaMultiSelect({
    required this.opciones,
    required this.seleccionados,
    required this.max,
  });

  final List<TagOpcion> opciones;
  final List<TagOpcion> seleccionados;
  final int max;

  @override
  State<_HojaMultiSelect> createState() => _HojaMultiSelectState();
}

class _HojaMultiSelectState extends State<_HojaMultiSelect> {
  late List<TagOpcion> _seleccionados;

  @override
  void initState() {
    super.initState();
    _seleccionados = List.of(widget.seleccionados);
  }

  void _toggle(TagOpcion opcion) {
    setState(() {
      if (_seleccionados.contains(opcion)) {
        _seleccionados.remove(opcion);
      } else if (_seleccionados.length < widget.max) {
        _seleccionados.add(opcion);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: ColoresApp.bordeMedio,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (widget.max > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${_seleccionados.length}/${widget.max}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ColoresApp.textoTerciario,
                      ),
                ),
              ),
            ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.opciones.length,
              itemBuilder: (context, i) {
                final opcion = widget.opciones[i];
                final activo = _seleccionados.contains(opcion);
                final maxAlcanzado =
                    _seleccionados.length >= widget.max && !activo;
                return ListTile(
                  title: Text(
                    opcion.nombre,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: maxAlcanzado
                              ? ColoresApp.textoTerciario
                              : (activo
                                  ? ColoresApp.acento
                                  : ColoresApp.textoPrimario),
                        ),
                  ),
                  trailing: activo
                      ? const Icon(Icons.check_rounded,
                          color: ColoresApp.acento)
                      : null,
                  onTap: maxAlcanzado ? null : () => _toggle(opcion),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, _seleccionados),
                style:
                    FilledButton.styleFrom(backgroundColor: ColoresApp.acento),
                child: const Text('Confirmar'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
