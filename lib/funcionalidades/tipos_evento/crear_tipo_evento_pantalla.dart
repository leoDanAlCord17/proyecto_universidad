import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../compartido/widgets/avisos/aviso_app.dart';
import '../../compartido/widgets/botones/boton_app.dart';
import '../../compartido/widgets/botones/boton_regresar.dart';
import '../../compartido/widgets/formularios/campo_texto_app.dart';
import '../../compartido/widgets/navegacion/barra_superior_app.dart';
import '../../configuracion/colores_app.dart';
import 'crear_tipo_evento_cubit.dart';
import 'crear_tipo_evento_estado.dart';

class CrearTipoEventoPantalla extends StatefulWidget {
  const CrearTipoEventoPantalla({super.key, this.tipoEventoId});

  final String? tipoEventoId;

  @override
  State<CrearTipoEventoPantalla> createState() =>
      _CrearTipoEventoPantallaState();
}

class _CrearTipoEventoPantallaState extends State<CrearTipoEventoPantalla> {
  final _nombreCtrl      = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  bool _estaIniciado = false;
  bool _estaPrelleno = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_estaIniciado) return;
    _estaIniciado = true;
    if (widget.tipoEventoId != null) {
      context.read<CrearTipoEventoCubit>().cargarParaEditar(widget.tipoEventoId!);
    } else {
      context.read<CrearTipoEventoCubit>().iniciarCreacion();
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  void _escucharEstado(BuildContext context, CrearTipoEventoEstado estado) {
    if (estado is CrearTipoEventoGuardado) {
      context.pop();
    } else if (estado is CrearTipoEventoError) {
      AvisoApp.mostrar(context, texto: estado.mensaje, estilo: EstiloAviso.error);
    } else if (estado is CrearTipoEventoCargado &&
        estado.tipoEventoId != null &&
        !_estaPrelleno) {
      _estaPrelleno         = true;
      _nombreCtrl.text      = estado.nombreInicial;
      _descripcionCtrl.text = estado.descripcionInicial;
    }
  }

  void _alGuardar(BuildContext context, CrearTipoEventoEstado estado) {
    if (estado is! CrearTipoEventoCargado) return;
    context.read<CrearTipoEventoCubit>().guardar(
      nombre:      _nombreCtrl.text.trim(),
      descripcion: _descripcionCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CrearTipoEventoCubit, CrearTipoEventoEstado>(
      listener: _escucharEstado,
      builder:  _construirVista,
    );
  }

  Widget _construirVista(BuildContext context, CrearTipoEventoEstado estado) {
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
            _BarraTitulo(esEdicion: widget.tipoEventoId != null),
            Expanded(
              child: _Cuerpo(
                estado:          estado,
                nombreCtrl:      _nombreCtrl,
                descripcionCtrl: _descripcionCtrl,
              ),
            ),
            _BarraInferior(
              estado:    estado,
              alGuardar: () => _alGuardar(context, estado),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Barra de título ──────────────────────────────────────────────────────────

class _BarraTitulo extends StatelessWidget {
  const _BarraTitulo({required this.esEdicion});

  final bool esEdicion;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: BarraSuperiorApp(
        izquierda: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BotonRegresar(),
            const SizedBox(width: 12),
            Text(
              esEdicion ? 'Editar tipo de evento' : 'Crear tipo de evento',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontSize:   20,
                fontWeight: FontWeight.w700,
                color:      ColoresApp.textoPrimario,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Cuerpo ───────────────────────────────────────────────────────────────────

class _Cuerpo extends StatelessWidget {
  const _Cuerpo({
    required this.estado,
    required this.nombreCtrl,
    required this.descripcionCtrl,
  });

  final CrearTipoEventoEstado   estado;
  final TextEditingController   nombreCtrl;
  final TextEditingController   descripcionCtrl;

  @override
  Widget build(BuildContext context) {
    return switch (estado) {
      CrearTipoEventoInicial() || CrearTipoEventoCargando() => const Center(
          child: CircularProgressIndicator(color: ColoresApp.acento),
        ),
      CrearTipoEventoCargado() => _Formulario(
          nombreCtrl:      nombreCtrl,
          descripcionCtrl: descripcionCtrl,
        ),
      CrearTipoEventoGuardado() || CrearTipoEventoError() =>
        const SizedBox.shrink(),
    };
  }
}

// ─── Formulario ───────────────────────────────────────────────────────────────

class _Formulario extends StatelessWidget {
  const _Formulario({
    required this.nombreCtrl,
    required this.descripcionCtrl,
  });

  final TextEditingController nombreCtrl;
  final TextEditingController descripcionCtrl;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:        ColoresApp.superficiePrimaria,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color:      ColoresApp.sombraTarjeta,
                blurRadius: 8,
                offset:     Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'INFORMACIÓN DEL TIPO DE EVENTO',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:         ColoresApp.acento,
                  letterSpacing: 0.8,
                  fontSize:      14,
                  fontWeight:    FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              CampoTextoApp(
                etiqueta:   'Nombre*',
                hintText:   'Ej. Conferencia',
                controller: nombreCtrl,
              ),
              const SizedBox(height: 16),
              CampoTextoApp(
                etiqueta:   'Descripción',
                hintText:   'Descripción breve del tipo de evento',
                controller: descripcionCtrl,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Barra inferior ───────────────────────────────────────────────────────────

class _BarraInferior extends StatelessWidget {
  const _BarraInferior({required this.estado, required this.alGuardar});

  final CrearTipoEventoEstado estado;
  final VoidCallback          alGuardar;

  @override
  Widget build(BuildContext context) {
    final estaCargando =
        estado is CrearTipoEventoCargado &&
        (estado as CrearTipoEventoCargado).estaGuardando;
    final puedeGuardar = estado is CrearTipoEventoCargado && !estaCargando;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: BotonApp(
          texto:        'Guardar',
          estaCargando: estaCargando,
          alPresionar:  puedeGuardar ? alGuardar : null,
        ),
      ),
    );
  }
}
