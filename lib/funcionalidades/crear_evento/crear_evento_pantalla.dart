import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../compartido/constantes.dart';
import '../../compartido/widgets/botones/boton_regresar.dart';
import '../../compartido/widgets/formularios/campo_fecha_app.dart';
import '../../compartido/widgets/formularios/campo_hora_app.dart';
import '../../compartido/widgets/formularios/campo_multiselect_app.dart';
import '../../compartido/widgets/formularios/campo_select_app.dart';
import '../../compartido/widgets/formularios/campo_texto_app.dart';
import '../../compartido/widgets/listas/fila_togle.dart';
import '../../compartido/widgets/navegacion/barra_superior_app.dart';
import '../../configuracion/colores_app.dart';
import 'crear_evento_cubit.dart';
import 'crear_evento_estado.dart';
import 'tag_opcion.dart';
import 'tipo_evento.dart';

const _decorTarjeta = BoxDecoration(
  color:        ColoresApp.superficiePrimaria,
  borderRadius: BorderRadius.all(Radius.circular(16)),
  boxShadow:    [BoxShadow(color: ColoresApp.sombraTarjeta, blurRadius: 4, offset: Offset(0, 1))],
);

// ─── Pantalla ─────────────────────────────────────────────────────────────────

class CrearEventoPantalla extends StatefulWidget {
  const CrearEventoPantalla({super.key, this.eventoId});

  final String? eventoId;

  @override
  State<CrearEventoPantalla> createState() => _CrearEventoPantallaState();
}

class _CrearEventoPantallaState extends State<CrearEventoPantalla> {
  final _tituloCtrl      = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _lugarCtrl       = TextEditingController();
  bool _estaPrelleno = false;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<CrearEventoCubit>();
    if (widget.eventoId != null) {
      cubit.cargarEventoParaEditar(widget.eventoId!);
    } else {
      cubit.cargarOpciones();
    }
    _tituloCtrl.addListener(
      () => _actualizar((s) => s.copiarCon(titulo: _tituloCtrl.text)),
    );
    _descripcionCtrl.addListener(
      () => _actualizar((s) => s.copiarCon(descripcion: _descripcionCtrl.text)),
    );
    _lugarCtrl.addListener(
      () => _actualizar((s) => s.copiarCon(lugar: _lugarCtrl.text)),
    );
  }

  void _actualizar(CrearEventoCargado Function(CrearEventoCargado) fn) =>
      context.read<CrearEventoCubit>().actualizarCampo(fn);

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _lugarCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CrearEventoCubit, CrearEventoEstado>(
      listener: (context, estado) {
        if (!_estaPrelleno &&
            estado is CrearEventoCargado &&
            widget.eventoId != null) {
          _estaPrelleno = true;
          _tituloCtrl.text      = estado.titulo;
          _descripcionCtrl.text = estado.descripcion;
          _lugarCtrl.text       = estado.lugar;
        }
        if (estado is CrearEventoGuardado) context.go(Rutas.eventos);
        if (estado is CrearEventoError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:         Text(estado.mensaje),
            backgroundColor: ColoresApp.rojo,
          ));
        }
      },
      builder: (context, estado) => _construirVista(context, estado),
    );
  }

  Widget _construirVista(BuildContext context, CrearEventoEstado estado) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor:          Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness:     Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: ColoresApp.fondo,
        body: switch (estado) {
          CrearEventoInicial() || CrearEventoCargando() => const Center(
              child: CircularProgressIndicator(color: ColoresApp.acento),
            ),
          CrearEventoCargado() => _CuerpoFormulario(
              estado:          estado,
              tituloCtrl:      _tituloCtrl,
              descripcionCtrl: _descripcionCtrl,
              lugarCtrl:       _lugarCtrl,
              modoEdicion:     widget.eventoId != null,
            ),
          CrearEventoGuardado() => const SizedBox.shrink(),
          CrearEventoError()    => _VistaError(mensaje: estado.mensaje),
        },
      ),
    );
  }
}

// ─── Cuerpo ───────────────────────────────────────────────────────────────────

class _CuerpoFormulario extends StatelessWidget {
  const _CuerpoFormulario({
    required this.estado,
    required this.tituloCtrl,
    required this.descripcionCtrl,
    required this.lugarCtrl,
    required this.modoEdicion,
  });

  final CrearEventoCargado    estado;
  final TextEditingController tituloCtrl;
  final TextEditingController descripcionCtrl;
  final TextEditingController lugarCtrl;
  final bool                  modoEdicion;

  @override
  Widget build(BuildContext context) {
    return Column(
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
                  modoEdicion ? 'Editar evento' : 'Nuevo evento',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              children: [
                _TarjetaInfoBasica(
                  estado:          estado,
                  tituloCtrl:      tituloCtrl,
                  descripcionCtrl: descripcionCtrl,
                  lugarCtrl:       lugarCtrl,
                ),
                const SizedBox(height: 16),
                _TarjetaFechaDuracion(estado: estado),
                const SizedBox(height: 16),
                _TarjetaTagsUsuarios(estado: estado),
                const SizedBox(height: 16),
                _TarjetaModosRegistro(estado: estado),
                const SizedBox(height: 16),
                _TarjetaControlSalida(estado: estado),
                const SizedBox(height: 28),
                _BotonesAccion(estado: estado),
                SizedBox(height: MediaQuery.paddingOf(context).bottom + 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Tarjeta: información básica ──────────────────────────────────────────────

class _TarjetaInfoBasica extends StatelessWidget {
  const _TarjetaInfoBasica({
    required this.estado,
    required this.tituloCtrl,
    required this.descripcionCtrl,
    required this.lugarCtrl,
  });

  final CrearEventoCargado    estado;
  final TextEditingController tituloCtrl;
  final TextEditingController descripcionCtrl;
  final TextEditingController lugarCtrl;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CrearEventoCubit>();
    return Container(
      decoration: _decorTarjeta,
      padding:    const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tituloSeccion('INFORMACIÓN BÁSICA', context),
          const SizedBox(height: 16),
          CampoTextoApp(
            etiqueta:   'Título *',
            hintText:   'Ej. Cálculo III – Parcial 2',
            controller: tituloCtrl,
          ),
          const SizedBox(height: 16),
          CampoTextoApp(
            etiqueta:   'Descripción',
            hintText:   'Instrucciones o detalles del evento',
            controller: descripcionCtrl,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CampoSelectApp<TipoEvento>(
                  etiqueta:      'Tipo de evento',
                  hintText:      'Selecciona',
                  opciones:      estado.tiposEvento,
                  mostrarTexto:  (t) => t.nombre,
                  valorActual:   estado.tipoEventoSeleccionado,
                  alSeleccionar: (t) => cubit.actualizarCampo(
                    (s) => s.copiarCon(tipoEventoSeleccionado: t),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CampoTextoApp(
                  etiqueta:   'Lugar',
                  hintText:   'Aula 304',
                  controller: lugarCtrl,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Tarjeta: fecha y duración ────────────────────────────────────────────────

class _TarjetaFechaDuracion extends StatelessWidget {
  const _TarjetaFechaDuracion({required this.estado});

  final CrearEventoCargado estado;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CrearEventoCubit>();
    return Container(
      decoration: _decorTarjeta,
      padding:    const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tituloSeccion('FECHA Y DURACIÓN', context),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CampoFechaApp(
                  etiqueta:      'Fecha inicio',
                  hintText:      'dd/mm/aaaa',
                  fechaActual:   estado.fechaInicio,
                  alSeleccionar: (f) => cubit.actualizarCampo(
                    (s) => s.copiarCon(fechaInicio: f),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CampoHoraApp(
                  etiqueta:      'Hora inicio',
                  hintText:      '08:00',
                  horaActual:    estado.horaInicio,
                  alSeleccionar: (h) => cubit.actualizarCampo(
                    (s) => s.copiarCon(horaInicio: h),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilaTogle(
            titulo:      'Tiene hora de cierre',
            descripcion: 'Define cuándo finaliza el evento',
            valor:       estado.tieneFechaFin,
            alCambiar:   (v) => cubit.actualizarCampo(
              (s) => s.copiarCon(tieneFechaFin: v),
            ),
          ),
          if (estado.tieneFechaFin) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CampoFechaApp(
                    etiqueta:      'Fecha fin',
                    hintText:      'dd/mm/aaaa',
                    fechaActual:   estado.fechaFin,
                    fechaMinima:   estado.fechaInicio,
                    alSeleccionar: (f) => cubit.actualizarCampo(
                      (s) => s.copiarCon(fechaFin: f),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CampoHoraApp(
                    etiqueta:      'Hora fin',
                    hintText:      '10:00',
                    horaActual:    estado.horaFin,
                    alSeleccionar: (h) => cubit.actualizarCampo(
                      (s) => s.copiarCon(horaFin: h),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Tarjeta: tags usuarios ───────────────────────────────────────────────────

class _TarjetaTagsUsuarios extends StatelessWidget {
  const _TarjetaTagsUsuarios({required this.estado});

  final CrearEventoCargado estado;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CrearEventoCubit>();
    return Container(
      decoration: _decorTarjeta,
      padding:    const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tituloSeccion('TAGS USUARIOS', context),
          const SizedBox(height: 16),
          FilaTogle(
            titulo:      'Usar tags?',
            descripcion: 'Defina grupos para el evento',
            valor:       estado.usarTags,
            alCambiar:   (v) => cubit.actualizarCampo(
              (s) => s.copiarCon(usarTags: v),
            ),
          ),
          if (estado.usarTags) ...[
            const SizedBox(height: 16),
            CampoMultiselectApp<TagOpcion>(
              etiqueta:         'Tags Principales',
              hintText:         'Selecciona categorías...',
              opciones:         estado.tagsPrincipales,
              mostrarTexto:     (t) => t.nombre,
              obtenerId:        (t) => t.id,
              idsSeleccionados: estado.tagsPrincipalesIds,
              alSeleccionar:    (ids) => cubit.actualizarCampo(
                (s) => s.copiarCon(tagsPrincipalesIds: ids),
              ),
            ),
            const SizedBox(height: 16),
            CampoMultiselectApp<TagOpcion>(
              etiqueta:         'Tags secundarios',
              hintText:         'Selecciona categorías...',
              opciones:         estado.tagsSecundarios,
              mostrarTexto:     (t) => t.nombre,
              obtenerId:        (t) => t.id,
              idsSeleccionados: estado.tagsSecundariosIds,
              alSeleccionar:    (ids) => cubit.actualizarCampo(
                (s) => s.copiarCon(tagsSecundariosIds: ids),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Tarjeta: modos de registro ───────────────────────────────────────────────

class _TarjetaModosRegistro extends StatelessWidget {
  const _TarjetaModosRegistro({required this.estado});

  final CrearEventoCargado estado;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CrearEventoCubit>();
    return Container(
      decoration: _decorTarjeta,
      padding:    const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tituloSeccion('MODOS DE REGISTRO', context),
          const SizedBox(height: 16),
          FilaTogle(
            titulo:      'Marcado manual',
            descripcion: 'Admin busca por nombre o cédula',
            icono:       Icons.manage_search_rounded,
            valor:       estado.permiteManualAdmin,
            alCambiar:   (v) => cubit.actualizarCampo(
              (s) => s.copiarCon(permiteManualAdmin: v),
            ),
          ),
          const SizedBox(height: 12),
          FilaTogle(
            titulo:      'Auto-registro (QR evento)',
            descripcion: 'Asistente escanea el QR proyectado',
            icono:       Icons.qr_code_rounded,
            valor:       estado.permiteQrEvento,
            alCambiar:   (v) => cubit.actualizarCampo(
              (s) => s.copiarCon(permiteQrEvento: v),
            ),
          ),
          const SizedBox(height: 12),
          FilaTogle(
            titulo:      'Escanear carnet QR',
            descripcion: 'Admin escanea el QR del estudiante',
            icono:       Icons.qr_code_scanner_rounded,
            valor:       estado.permiteQrUsuario,
            alCambiar:   (v) => cubit.actualizarCampo(
              (s) => s.copiarCon(permiteQrUsuario: v),
            ),
          ),
          const SizedBox(height: 12),
          FilaTogle(
            titulo:      'Registrar invitados foráneos',
            descripcion: 'Sin cuenta en el sistema',
            icono:       Icons.person_add_alt_1_outlined,
            valor:       estado.permiteForaneos,
            alCambiar:   (v) => cubit.actualizarCampo(
              (s) => s.copiarCon(permiteForaneos: v),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tarjeta: control de salida ───────────────────────────────────────────────

class _TarjetaControlSalida extends StatelessWidget {
  const _TarjetaControlSalida({required this.estado});

  final CrearEventoCargado estado;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CrearEventoCubit>();
    return Container(
      decoration: _decorTarjeta,
      padding:    const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tituloSeccion('CONTROL DE SALIDA', context),
          const SizedBox(height: 16),
          FilaTogle(
            titulo:      'Registrar salida (ciclo completo)',
            descripcion: 'Asistente debe marcar entrada Y salida',
            valor:       estado.requiereCicloCompleto,
            alCambiar:   (v) => cubit.actualizarCampo(
              (s) => s.copiarCon(requiereCicloCompleto: v),
            ),
          ),
          const SizedBox(height: 12),
          FilaTogle(
            titulo:      'Permitir salida anticipada',
            descripcion: 'Admin justifica caso por caso',
            valor:       estado.permiteSalidaAnticipada,
            alCambiar:   (v) => cubit.actualizarCampo(
              (s) => s.copiarCon(permiteSalidaAnticipada: v),
            ),
          ),
          const SizedBox(height: 12),
          FilaTogle(
            titulo:      'Marcar ausentes automáticamente',
            descripcion: 'Al llegar la hora de cierre',
            valor:       estado.marcarAusentesAuto,
            alCambiar:   (v) => cubit.actualizarCampo(
              (s) => s.copiarCon(marcarAusentesAuto: v),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Botones de acción ────────────────────────────────────────────────────────

class _BotonesAccion extends StatelessWidget {
  const _BotonesAccion({required this.estado});

  final CrearEventoCargado estado;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CrearEventoCubit>();
    return Column(
      children: [
        SizedBox(
          width:  double.infinity,
          height: 52,
          child: Material(
            color:        Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap:          estado.estaGuardando ? null : cubit.publicarEvento,
              borderRadius:   BorderRadius.circular(14),
              splashColor:    Colors.white.withValues(alpha: 0.3),
              highlightColor: Colors.white.withValues(alpha: 0.15),
              child: Ink(
                decoration: BoxDecoration(
                  gradient:     ColoresApp.degradadoPrincipal,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: estado.estaGuardando
                      ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)
                      : const Text(
                          'Publicar evento',
                          style: TextStyle(
                            color:      Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize:   15,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width:  double.infinity,
          height: 52,
          child: Material(
            color:        Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap:          estado.estaGuardando ? null : cubit.guardarBorrador,
              borderRadius:   BorderRadius.circular(14),
              highlightColor: ColoresApp.superficieTerciar,
              splashColor:    ColoresApp.bordeMedio,
              child: Ink(
                decoration: BoxDecoration(
                  border:       Border.all(color: ColoresApp.bordeMedio),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    'Guardar como borrador',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: ColoresApp.textoSecundario,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Vista de error ───────────────────────────────────────────────────────────

class _VistaError extends StatelessWidget {
  const _VistaError({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: ColoresApp.rojo, size: 48),
            const SizedBox(height: 16),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ColoresApp.textoSecundario,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.read<CrearEventoCubit>().cargarOpciones(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Utilidades ───────────────────────────────────────────────────────────────

Widget _tituloSeccion(String texto, BuildContext context) {
  return Text(
    texto,
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      color:         ColoresApp.acento,
      fontWeight:    FontWeight.w800,
      letterSpacing: 1.5,
    ),
  );
}
