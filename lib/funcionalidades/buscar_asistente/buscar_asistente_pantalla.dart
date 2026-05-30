import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/constantes.dart';
import '../../compartido/widgets/avisos/aviso_app.dart';
import '../../compartido/widgets/avisos/vista_error_app.dart';
import '../../compartido/widgets/botones/boton_app.dart';
import '../autenticacion/auth_cubit.dart';
import '../autenticacion/auth_estado.dart';
import '../../compartido/widgets/botones/boton_regresar.dart';
import '../../compartido/widgets/formularios/barra_busqueda_app.dart';
import '../../compartido/widgets/indicadores/insignia_estado.dart';
import '../../compartido/widgets/navegacion/barra_superior_app.dart';
import '../../compartido/widgets/tarjetas/tarjeta_asistente.dart';
import '../../configuracion/colores_app.dart';
import '../eventos/evento.dart';
import 'buscar_asistente_cubit.dart';
import 'buscar_asistente_estado.dart';
import 'resultado_busqueda.dart';

class BuscarAsistentePantalla extends StatefulWidget {
  const BuscarAsistentePantalla({super.key, required this.eventoId});

  final String eventoId;

  @override
  State<BuscarAsistentePantalla> createState() => _BuscarAsistentePantallaState();
}

class _BuscarAsistentePantallaState extends State<BuscarAsistentePantalla> {
  final _controladorBusqueda = TextEditingController();
  Timer? _debounce;
  bool   _estaCargado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_estaCargado) return;
    _estaCargado = true;
    final authEstado = context.read<AuthCubit>().state;
    final adminId    = authEstado is Autenticado ? authEstado.usuario.id : null;
    context.read<BuscarAsistenteCubit>().iniciar(widget.eventoId, adminId: adminId);
  }

  @override
  void dispose() {
    _controladorBusqueda.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onBusqueda(String valor) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => context.read<BuscarAsistenteCubit>().buscar(valor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BuscarAsistenteCubit, BuscarAsistenteEstado>(
      listener: _escucharEstado,
      builder:  _construirCuerpo,
    );
  }

  void _escucharEstado(BuildContext context, BuscarAsistenteEstado state) {
    if (state is BuscarAsistenteOperacionFallida) {
      AvisoApp.mostrar(context, texto: state.mensaje, estilo: EstiloAviso.error);
    }
  }

  Widget _construirCuerpo(BuildContext context, BuscarAsistenteEstado state) {
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
            const SafeArea(bottom: false, child: BarraSuperiorApp(izquierda: _CabeceraTitulo())),
            _construirBarra(),
            Expanded(child: _construirContenido(state)),
          ],
        ),
      ),
    );
  }

  Widget _construirBarra() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: BarraBusquedaApp(
        controlador: _controladorBusqueda,
        hintText:    'Buscar por nombre...',
        alCambiar:   _onBusqueda,
      ),
    );
  }

  Widget _construirContenido(BuscarAsistenteEstado state) => switch (state) {
    BuscarAsistenteInicial()          => const _EstadoInstruccion(),
    BuscarAsistenteCargando()         => const Center(child: CircularProgressIndicator(color: ColoresApp.acento)),
    BuscarAsistenteCargado()          => _ListaResultados(estado: state),
    BuscarAsistenteOperacionFallida() => _ListaResultados(estado: state.anterior),
    BuscarAsistenteError()            => VistaErrorApp(mensaje: state.mensaje),
  };

}

// ─── Encabezado ───────────────────────────────────────────────────────────────

class _CabeceraTitulo extends StatelessWidget {
  const _CabeceraTitulo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BotonRegresar(),
        const SizedBox(width: 12),
        Text(
          'Marcar asistencia',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontSize: 20, fontWeight: FontWeight.w700,
            color: ColoresApp.textoPrimario,
          ),
        ),
      ],
    );
  }
}

// ─── Lista de resultados ──────────────────────────────────────────────────────

class _ListaResultados extends StatelessWidget {
  const _ListaResultados({required this.estado});
  final BuscarAsistenteCargado estado;

  @override
  Widget build(BuildContext context) {
    if (estado.busqueda.trim().length < 2) return const _EstadoInstruccion();
    if (estado.resultados.isEmpty)         return const _EstadoSinResultados();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'RESULTADOS',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: ColoresApp.textoSecundario, fontWeight: FontWeight.w800,
              letterSpacing: 0.8, fontSize: 11,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding:     const EdgeInsets.fromLTRB(16, 0, 16, 32),
            itemCount:   estado.resultados.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TarjetaResultado(
                resultado:  estado.resultados[i],
                evento:     estado.evento,
                cargandoId: estado.usuarioIdRegistrando,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Tarjeta de resultado ─────────────────────────────────────────────────────

class _TarjetaResultado extends StatelessWidget {
  const _TarjetaResultado({
    required this.resultado,
    required this.evento,
    this.cargandoId,
  });
  final ResultadoBusqueda resultado;
  final Evento            evento;
  final String?           cargandoId;

  @override
  Widget build(BuildContext context) {
    final cubit      = context.read<BuscarAsistenteCubit>();
    final estaCargando = cargandoId == resultado.usuarioId;

    if (resultado.esForaneo) {
      return TarjetaAsistente(
        iniciales:      resultado.iniciales,
        nombre:         resultado.nombre,
        estatus:        resultado.estatus ?? EstatusAsistencia.presente,
        detalle:        resultado.horaEntrada != null ? 'Entrada ${resultado.horaEntrada}' : null,
        accionTrailing: _TrailingForaneo(estatus: resultado.estatus ?? EstatusAsistencia.presente),
      );
    }

    if (resultado.estaActivo) {
      return TarjetaAsistente(
        iniciales:        resultado.iniciales,
        nombre:           resultado.nombre,
        estatus:          resultado.estatus!,
        detalle:          resultado.horaEntrada != null
            ? 'Entrada ${resultado.horaEntrada}'
            : resultado.numeroIdentificacion,
        subtitulo:        resultado.registradoPorNombre != null
            ? 'Reg. por: ${resultado.registradoPorNombre}'
            : null,
        urlFoto:          resultado.urlFoto,
        textoBoton:       evento.permiteSalidaAnticipada ? 'MARCAR SALIDA' : null,
        varianteBoton:    VarianteBoton.rojo,
        alPresionarBoton: evento.permiteSalidaAnticipada
            ? () => _HojaMarcarSalida.mostrar(context,
                resultado: resultado, evento: evento, cubit: cubit,)
            : null,
      );
    }

    return TarjetaAsistente(
      iniciales:         resultado.iniciales,
      nombre:            resultado.nombre,
      estatus:           resultado.estatus ?? EstatusAsistencia.esperado,
      detalle:           resultado.numeroIdentificacion,
      urlFoto:           resultado.urlFoto,
      accionTrailing:    resultado.esNoEsperado ? const InsigniaEstado(estatus: 'no_esperado') : null,
      textoBoton:        'Registrar entrada',
      estaCargandoBoton: estaCargando,
      alPresionarBoton:  estaCargando ? null : () => cubit.registrarEntrada(resultado),
    );
  }
}

class _TrailingForaneo extends StatelessWidget {
  const _TrailingForaneo({required this.estatus});
  final String estatus;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize:       MainAxisSize.min,
      children: [
        InsigniaEstado(estatus: estatus),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: ColoresApp.tealClaro, borderRadius: BorderRadius.circular(30)),
          child: Text('Foráneo', style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: ColoresApp.teal, fontWeight: FontWeight.w700, fontSize: 11,
          ),),
        ),
      ],
    );
  }
}

// ─── Hoja de marcar salida ────────────────────────────────────────────────────

class _HojaMarcarSalida extends StatefulWidget {
  const _HojaMarcarSalida({required this.resultado, required this.evento});

  final ResultadoBusqueda resultado;
  final Evento            evento;

  static void mostrar(
    BuildContext context, {
    required ResultadoBusqueda    resultado,
    required Evento               evento,
    required BuscarAsistenteCubit cubit,
  }) {
    showModalBottomSheet<void>(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: _HojaMarcarSalida(resultado: resultado, evento: evento),
      ),
    );
  }

  @override
  State<_HojaMarcarSalida> createState() => _HojaMarcarSalidaState();
}

class _HojaMarcarSalidaState extends State<_HojaMarcarSalida> {
  bool  _esAnticipada = false;
  final _motivoCtrl   = TextEditingController();
  bool  _estaEnviado  = false;

  @override
  void dispose() {
    _motivoCtrl.dispose();
    super.dispose();
  }

  String _subtitulo() {
    final partes = <String>[widget.resultado.nombre];
    final hora   = widget.resultado.horaEntrada;
    if (hora != null) partes.add(hora);
    final mins = _minutosAntesCierre();
    if (mins != null) partes.add('$mins min antes del cierre');
    return partes.join(' · ');
  }

  int? _minutosAntesCierre() {
    final horaFin = widget.evento.horaFin;
    if (horaFin == null) return null;
    final p = horaFin.split(':');
    if (p.length < 2) return null;
    final h    = int.tryParse(p[0]) ?? 0;
    final m    = int.tryParse(p[1]) ?? 0;
    final base = widget.evento.fechaFin ?? widget.evento.fechaInicio ?? DateTime.now();
    final diff = DateTime(base.year, base.month, base.day, h, m)
        .difference(DateTime.now())
        .inMinutes;
    return diff > 0 ? diff : null;
  }

  void _confirmar(BuildContext ctx) {
    if (_esAnticipada && _motivoCtrl.text.trim().isEmpty) return;
    setState(() => _estaEnviado = true);
    ctx.read<BuscarAsistenteCubit>().marcarSalida(
      asistenciaId: widget.resultado.asistenciaId!,
      esAnticipada: _esAnticipada,
      motivo:       _esAnticipada ? _motivoCtrl.text.trim() : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BuscarAsistenteCubit, BuscarAsistenteEstado>(
      listener: (ctx, state) {
        if (!_estaEnviado) return;
        if (state is BuscarAsistenteCargado && !state.estaMarcandoSalida) Navigator.of(ctx).pop();
        if (state is BuscarAsistenteOperacionFallida) setState(() => _estaEnviado = false);
      },
      builder: (ctx, state) {
        final guardando = _estaEnviado && state is BuscarAsistenteCargado && state.estaMarcandoSalida;
        return _CuerpoHojaSalida(
          subtitulo:          _subtitulo(),
          esAnticipada:       _esAnticipada,
          motivoCtrl:         _motivoCtrl,
          guardando:          guardando,
          onToggleAnticipada: (val) => setState(() => _esAnticipada = val),
          onConfirmar:        () => _confirmar(ctx),
        );
      },
    );
  }
}

class _CuerpoHojaSalida extends StatelessWidget {
  const _CuerpoHojaSalida({
    required this.subtitulo,
    required this.esAnticipada,
    required this.motivoCtrl,
    required this.guardando,
    required this.onToggleAnticipada,
    required this.onConfirmar,
  });

  final String                subtitulo;
  final bool                  esAnticipada;
  final TextEditingController motivoCtrl;
  final bool                  guardando;
  final void Function(bool)   onToggleAnticipada;
  final VoidCallback          onConfirmar;

  Widget _construirEncabezadoSalida(TextTheme texto) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width:  44,
          height: 44,
          decoration: BoxDecoration(
            color:        ColoresApp.ambarClaro,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.warning_amber_rounded, color: ColoresApp.ambar, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                esAnticipada ? 'Salida anticipada' : 'Marcar salida',
                style: texto.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(subtitulo, style: texto.bodySmall?.copyWith(color: ColoresApp.textoSecundario)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: const BoxDecoration(
          color:        ColoresApp.superficiePrimaria,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize:       MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _construirEncabezadoSalida(texto),
            const SizedBox(height: 20),
            Text(
              '¿CÓMO REGISTRAR ESTA SALIDA?',
              style: texto.labelSmall?.copyWith(
                color:         ColoresApp.textoSecundario,
                fontWeight:    FontWeight.w800,
                letterSpacing: 0.8,
                fontSize:      11,
              ),
            ),
            const SizedBox(height: 10),
            _OpcionSalida(
              titulo:       'Salida anticipada — con motivo',
              descripcion:  "Se registra como 'Salió antes' con justificación obligatoria.",
              seleccionada: esAnticipada,
              onTap:        () => onToggleAnticipada(true),
              extra: esAnticipada
                  ? Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: TextFormField(
                        controller: motivoCtrl,
                        decoration: const InputDecoration(
                            hintText: 'Motivo de salida anticipada *',),
                        maxLines: 2,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 10),
            _OpcionSalida(
              titulo:       'Salida normal — sin motivo',
              descripcion:  'Se registra sin observación adicional.',
              seleccionada: !esAnticipada,
              onTap:        () => onToggleAnticipada(false),
            ),
            const SizedBox(height: 20),
            BotonApp(
              texto:        'Confirmar salida',
              alPresionar:  guardando ? null : onConfirmar,
              estaCargando: guardando,
            ),
            Center(
              child: TextButton(
                onPressed: guardando ? null : Navigator.of(context).pop,
                child: Text(
                  'Cancelar',
                  style: texto.bodyMedium
                      ?.copyWith(color: ColoresApp.textoSecundario),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpcionSalida extends StatelessWidget {
  const _OpcionSalida({
    required this.titulo,
    required this.descripcion,
    required this.seleccionada,
    required this.onTap,
    this.extra,
  });

  final String       titulo;
  final String       descripcion;
  final bool         seleccionada;
  final VoidCallback onTap;
  final Widget?      extra;

  @override
  Widget build(BuildContext context) {
    final borderColor = seleccionada ? ColoresApp.ambar : ColoresApp.bordeMedio;
    return Material(
      color:        Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap:        seleccionada ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor:  ColoresApp.ambarClaro,
        child: Ink(
          decoration: BoxDecoration(
            color:        ColoresApp.superficiePrimaria,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: seleccionada ? 1.5 : 1.0,
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width:  18,
                height: 18,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: seleccionada ? ColoresApp.ambar : Colors.transparent,
                  border: Border.all(color: borderColor, width: 2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize:   14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      descripcion,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ColoresApp.textoSecundario,
                      ),
                    ),
                    if (extra != null) extra!,
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

// ─── Estados vacíos / error ───────────────────────────────────────────────────

class _EstadoInstruccion extends StatelessWidget {
  const _EstadoInstruccion();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'Escribe al menos 2 caracteres\npara buscar.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: ColoresApp.textoTerciario),
        ),
      ),
    );
  }
}

class _EstadoSinResultados extends StatelessWidget {
  const _EstadoSinResultados();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Sin resultados.',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: ColoresApp.textoTerciario),
      ),
    );
  }
}

