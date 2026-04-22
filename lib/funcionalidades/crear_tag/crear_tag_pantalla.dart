import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../compartido/widgets/avisos/aviso_app.dart';
import '../../compartido/widgets/botones/boton_app.dart';
import '../../compartido/widgets/botones/boton_regresar.dart';
import '../../compartido/widgets/formularios/campo_select_app.dart';
import '../../compartido/widgets/formularios/campo_texto_app.dart';
import '../../compartido/widgets/navegacion/barra_superior_app.dart';
import '../../configuracion/colores_app.dart';
import '../autenticacion/auth_cubit.dart';
import '../autenticacion/auth_estado.dart';
import 'crear_tag_cubit.dart';
import 'crear_tag_estado.dart';

class CrearTagPantalla extends StatefulWidget {
  const CrearTagPantalla({super.key, this.tagId});

  final String? tagId;

  @override
  State<CrearTagPantalla> createState() => _CrearTagPantallaState();
}

class _CrearTagPantallaState extends State<CrearTagPantalla> {
  final _nombreCtrl      = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  bool  _estaIniciado    = false;
  bool  _estaPrelleno    = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_estaIniciado) return;
    _estaIniciado = true;
    if (widget.tagId != null) {
      context.read<CrearTagCubit>().cargarTagParaEditar(widget.tagId!);
    } else {
      context.read<CrearTagCubit>().cargarFormulario();
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  void _escucharEstado(BuildContext context, CrearTagEstado estado) {
    if (estado is CrearTagGuardado) {
      context.pop();
    } else if (estado is CrearTagError) {
      AvisoApp.mostrar(context, texto: estado.mensaje, estilo: EstiloAviso.error);
    } else if (estado is CrearTagCargado && estado.tagId != null && !_estaPrelleno) {
      _estaPrelleno         = true;
      _nombreCtrl.text      = estado.nombreInicial;
      _descripcionCtrl.text = estado.descripcionInicial;
    }
  }

  Future<void> _alGuardar(BuildContext context, CrearTagCargado estado) async {
    final authEstado = context.read<AuthCubit>().state;
    if (authEstado is! Autenticado || authEstado.usuario.id == null) return;
    await context.read<CrearTagCubit>().guardar(
      nombre:      _nombreCtrl.text.trim(),
      descripcion: _descripcionCtrl.text.trim(),
      tipo:        estado.tipoSeleccionado,
      creadorId:   authEstado.usuario.id!,
    );
    if (!context.mounted) return;
    final nuevoEstado = context.read<CrearTagCubit>().state;
    if (nuevoEstado is CrearTagCargado && nuevoEstado.errorValidacion.isNotEmpty) {
      AvisoApp.mostrar(context, texto: nuevoEstado.errorValidacion, estilo: EstiloAviso.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CrearTagCubit, CrearTagEstado>(
      listener: _escucharEstado,
      builder:  (context, estado) => _construirVista(context, estado),
    );
  }

  Widget _construirVista(BuildContext context, CrearTagEstado estado) {
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
                    const BotonRegresar(),
                    const SizedBox(width: 12),
                    Text(
                      widget.tagId != null ? 'Editar tag' : 'Crear tag',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize:   20,
                        fontWeight: FontWeight.w700,
                        color:      ColoresApp.textoPrimario,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _Cuerpo(
                estado:         estado,
                nombreCtrl:     _nombreCtrl,
                descripcionCtrl: _descripcionCtrl,
              ),
            ),
            _BarraInferior(
              estado:    estado,
              alGuardar: () {
                if (estado is CrearTagCargado) _alGuardar(context, estado);
              },
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

  final CrearTagEstado        estado;
  final TextEditingController nombreCtrl;
  final TextEditingController descripcionCtrl;

  @override
  Widget build(BuildContext context) {
    final e = estado;
    return switch (e) {
      CrearTagInicial() || CrearTagCargando() => const Center(
          child: CircularProgressIndicator(color: ColoresApp.acento),
        ),
      CrearTagCargado() => _Formulario(
          estado:         e,
          nombreCtrl:     nombreCtrl,
          descripcionCtrl: descripcionCtrl,
        ),
      CrearTagGuardado() || CrearTagError() => const SizedBox.shrink(),
    };
  }
}

// ─── Formulario ───────────────────────────────────────────────────────────────

class _Formulario extends StatelessWidget {
  const _Formulario({
    required this.estado,
    required this.nombreCtrl,
    required this.descripcionCtrl,
  });

  final CrearTagCargado       estado;
  final TextEditingController nombreCtrl;
  final TextEditingController descripcionCtrl;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      children: [
        _SeccionInfo(
          estado:         estado,
          nombreCtrl:     nombreCtrl,
          descripcionCtrl: descripcionCtrl,
        ),
      ],
    );
  }
}

// ─── Sección información ──────────────────────────────────────────────────────

class _SeccionInfo extends StatelessWidget {
  const _SeccionInfo({
    required this.estado,
    required this.nombreCtrl,
    required this.descripcionCtrl,
  });

  final CrearTagCargado       estado;
  final TextEditingController nombreCtrl;
  final TextEditingController descripcionCtrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        ColoresApp.superficiePrimaria,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: ColoresApp.sombraTarjeta, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INFORMACIÓN DEL TAG',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color:         ColoresApp.acento,
              letterSpacing: 0.8,
              fontSize:      14,
              fontWeight:    FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          CampoTextoApp(
            etiqueta: 'Nombre*',
            hintText: 'Ej. Estudiante',
            controller: nombreCtrl,
          ),
          const SizedBox(height: 16),
          CampoTextoApp(
            etiqueta: 'Descripción*',
            hintText: 'Describe el tag',
            controller: descripcionCtrl,
          ),
          const SizedBox(height: 16),
          CampoSelectApp<String>(
            etiqueta:     'Tipo*',
            hintText:     'Selecciona el tipo',
            opciones:     const ['principal', 'secundario'],
            mostrarTexto: (t) => t == 'principal' ? 'Principal' : 'Secundario',
            valorActual:  estado.tipoSeleccionado,
            alSeleccionar: (t) => context.read<CrearTagCubit>().seleccionarTipo(t),
          ),
        ],
      ),
    );
  }
}

// ─── Barra inferior ───────────────────────────────────────────────────────────

class _BarraInferior extends StatelessWidget {
  const _BarraInferior({required this.estado, required this.alGuardar});

  final CrearTagEstado estado;
  final VoidCallback   alGuardar;

  @override
  Widget build(BuildContext context) {
    final estaCargando = estado is CrearTagCargado && (estado as CrearTagCargado).estaGuardando;
    final puedeGuardar = estado is CrearTagCargado && !estaCargando;
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
