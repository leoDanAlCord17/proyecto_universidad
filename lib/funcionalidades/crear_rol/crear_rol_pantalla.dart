import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../compartido/widgets/avisos/aviso_app.dart';
import '../../compartido/widgets/botones/boton_app.dart';
import '../../compartido/widgets/botones/boton_regresar.dart';
import '../../compartido/widgets/dialogo/dialogo_confirmacion.dart';
import '../../compartido/widgets/formularios/barra_busqueda_app.dart';
import '../../compartido/widgets/formularios/campo_texto_app.dart';
import '../../compartido/widgets/navegacion/barra_superior_app.dart';
import '../../configuracion/colores_app.dart';
import 'crear_rol_cubit.dart';
import 'crear_rol_estado.dart';
import 'permiso_opcion.dart';

class CrearRolPantalla extends StatefulWidget {
  const CrearRolPantalla({super.key, this.rolId});

  final String? rolId;

  @override
  State<CrearRolPantalla> createState() => _CrearRolPantallaState();
}

class _CrearRolPantallaState extends State<CrearRolPantalla> {
  final _nombreCtrl      = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  bool _estaIniciado     = false;
  bool _estaPrelleno     = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_estaIniciado) return;
    _estaIniciado = true;
    if (widget.rolId != null) {
      context.read<CrearRolCubit>().cargarRolParaEditar(widget.rolId!);
    } else {
      context.read<CrearRolCubit>().cargarPermisos();
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  void _escucharEstado(BuildContext context, CrearRolEstado estado) {
    if (estado is CrearRolGuardado) {
      context.pop();
    } else if (estado is CrearRolError) {
      AvisoApp.mostrar(context, texto: estado.mensaje, estilo: EstiloAviso.error);
    } else if (estado is CrearRolCargado && estado.rolId != null && !_estaPrelleno) {
      _estaPrelleno          = true;
      _nombreCtrl.text       = estado.nombreInicial;
      _descripcionCtrl.text  = estado.descripcionInicial;
    }
  }

  Future<void> _alGuardar(BuildContext context, CrearRolCargado estado) async {
    if (estado.permisosSeleccionadosIds.isEmpty) {
      final confirmo = await DialogoConfirmacion.mostrar(
        context,
        titulo:         'Sin permisos',
        descripcion:    '¿Deseas guardar este rol sin permisos asignados?',
        textoConfirmar: 'Guardar así',
        textoCancelar:  'Cancelar',
      );
      if (confirmo != true || !context.mounted) return;
    }
    unawaited(
      context.read<CrearRolCubit>().guardar(
        nombre:      _nombreCtrl.text.trim(),
        descripcion: _descripcionCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CrearRolCubit, CrearRolEstado>(
      listener: _escucharEstado,
      builder:  _construirVista,
    );
  }

  Widget _construirVista(BuildContext context, CrearRolEstado estado) {
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
                    Text(widget.rolId != null ? 'Editar rol' : 'Crear rol',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: 20, fontWeight: FontWeight.w700,
                        color: ColoresApp.textoPrimario,
                      ),),
                  ],
                ),
              ),
            ),
            Expanded(child: _Cuerpo(estado: estado, nombreCtrl: _nombreCtrl, descripcionCtrl: _descripcionCtrl)),
            _BarraInferior(estado: estado, alGuardar: () {
              if (estado is CrearRolCargado) _alGuardar(context, estado);
            },),
          ],
        ),
      ),
    );
  }
}

// ─── Cuerpo ───────────────────────────────────────────────────────────────────

class _Cuerpo extends StatelessWidget {
  const _Cuerpo({required this.estado, required this.nombreCtrl, required this.descripcionCtrl});

  final CrearRolEstado          estado;
  final TextEditingController   nombreCtrl;
  final TextEditingController   descripcionCtrl;

  @override
  Widget build(BuildContext context) {
    final e = estado;
    return switch (e) {
      CrearRolInicial() || CrearRolCargando() => const Center(
          child: CircularProgressIndicator(color: ColoresApp.acento),
        ),
      CrearRolCargado() => _Formulario(estado: e, nombreCtrl: nombreCtrl, descripcionCtrl: descripcionCtrl),
      CrearRolGuardado() || CrearRolError()   => const SizedBox.shrink(),
    };
  }
}

// ─── Formulario ───────────────────────────────────────────────────────────────

class _Formulario extends StatelessWidget {
  const _Formulario({required this.estado, required this.nombreCtrl, required this.descripcionCtrl});

  final CrearRolCargado         estado;
  final TextEditingController   nombreCtrl;
  final TextEditingController   descripcionCtrl;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      children: [
        _SeccionInfo(nombreCtrl: nombreCtrl, descripcionCtrl: descripcionCtrl),
        const SizedBox(height: 20),
        BarraBusquedaApp(
          hintText:  'Buscar permisos...',
          alCambiar: (t) => context.read<CrearRolCubit>().filtrarPermisos(t),
        ),
        const SizedBox(height: 16),
        Text('PERMISOS DEL SISTEMA',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: ColoresApp.textoTerciario, letterSpacing: 0.8,
            fontSize: 13, fontWeight: FontWeight.w900,
          ),),
        const SizedBox(height: 12),
        ...estado.permisosVisibles.map((p) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _ItemPermiso(
            permiso:       p,
            estaAgregado:  estado.permisosSeleccionadosIds.contains(p.id),
            alToggle:      () => context.read<CrearRolCubit>().togglePermiso(p.id),
          ),
        ),),
      ],
    );
  }
}

// ─── Sección información ──────────────────────────────────────────────────────

class _SeccionInfo extends StatelessWidget {
  const _SeccionInfo({required this.nombreCtrl, required this.descripcionCtrl});

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
          Text('INFORMACIÓN DEL ROL',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ColoresApp.acento, letterSpacing: 0.8,
              fontSize: 14, fontWeight: FontWeight.w800,
            ),),
          const SizedBox(height: 16),
          CampoTextoApp(etiqueta: 'Nombre*',     hintText: 'Ej. Coordinador', controller: nombreCtrl),
          const SizedBox(height: 16),
          CampoTextoApp(etiqueta: 'Descripción*', hintText: 'Para usuarios estándar del sistema', controller: descripcionCtrl),
        ],
      ),
    );
  }
}

// ─── Item de permiso ──────────────────────────────────────────────────────────

class _ItemPermiso extends StatelessWidget {
  const _ItemPermiso({required this.permiso, required this.estaAgregado, required this.alToggle});

  final PermisoOpcion permiso;
  final bool          estaAgregado;
  final VoidCallback  alToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color:        ColoresApp.superficiePrimaria,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: ColoresApp.sombraTarjeta, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(permiso.nombre,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600, color: ColoresApp.textoPrimario, fontSize: 16,
                  ),),
                if (permiso.descripcion.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(permiso.descripcion,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ColoresApp.textoSecundario, fontSize: 13,
                    ),),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          estaAgregado ? _BotonQuitar(alPresionar: alToggle) : _BotonAgregar(alPresionar: alToggle),
        ],
      ),
    );
  }
}

// ─── Botón agregar ────────────────────────────────────────────────────────────

class _BotonAgregar extends StatelessWidget {
  const _BotonAgregar({required this.alPresionar});
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color:        Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap:          alPresionar,
        borderRadius:   BorderRadius.circular(10),
        splashColor:    ColoresApp.blanco.withValues(alpha: 0.3),
        highlightColor: ColoresApp.blanco.withValues(alpha: 0.15),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            gradient: ColoresApp.degradadoPrincipal,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text('Agregar',
            style: TextStyle(color: ColoresApp.blanco, fontSize: 14, fontWeight: FontWeight.w600),),
        ),
      ),
    );
  }
}

// ─── Botón quitar ─────────────────────────────────────────────────────────────

class _BotonQuitar extends StatelessWidget {
  const _BotonQuitar({required this.alPresionar});
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color:        Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap:          alPresionar,
        borderRadius:   BorderRadius.circular(10),
        splashColor:    ColoresApp.blanco.withValues(alpha: 0.3),
        highlightColor: ColoresApp.blanco.withValues(alpha: 0.15),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color:        ColoresApp.rojo,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text('Quitar',
            style: TextStyle(color: ColoresApp.blanco, fontSize: 14, fontWeight: FontWeight.w600),),
        ),
      ),
    );
  }
}

// ─── Barra inferior con botón guardar ────────────────────────────────────────

class _BarraInferior extends StatelessWidget {
  const _BarraInferior({required this.estado, required this.alGuardar});

  final CrearRolEstado estado;
  final VoidCallback   alGuardar;

  @override
  Widget build(BuildContext context) {
    final estaCargando = estado is CrearRolCargado && (estado as CrearRolCargado).estaGuardando;
    final puedeGuardar = estado is CrearRolCargado && !estaCargando;
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
