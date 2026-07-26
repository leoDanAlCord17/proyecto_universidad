import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../compartido/constantes.dart';
import '../../compartido/widgets/avisos/aviso_app.dart';
import '../../compartido/widgets/avisos/vista_error_app.dart';
import '../../compartido/widgets/dialogo/dialogo_confirmacion_texto.dart';
import '../../compartido/widgets/dialogo/modal_foraneo.dart';
import 'asistente_item.dart';
import '../../compartido/widgets/dialogo/modal_qr_evento.dart';
import '../../compartido/widgets/panel/panel_opciones.dart';
import '../../compartido/widgets/indicadores/barra_estadistica.dart';
import '../../compartido/widgets/tarjetas/tarjeta_app.dart';
import '../../compartido/widgets/tarjetas/tarjeta_asistente.dart';
import '../../configuracion/colores_app.dart';
import '../autenticacion/auth_cubit.dart';
import '../autenticacion/auth_estado.dart';
import '../eventos/evento.dart';
import 'panel_control_cubit.dart';
import 'panel_control_estado.dart';

class PanelControlPantalla extends StatefulWidget {
  const PanelControlPantalla({super.key, required this.eventoId});

  final String eventoId;

  @override
  State<PanelControlPantalla> createState() => _PanelControlPantallaState();
}

class _PanelControlPantallaState extends State<PanelControlPantalla> {
  bool _estaCargado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_estaCargado) return;
    _estaCargado = true;
    final authEstado = context.read<AuthCubit>().state;
    final adminId = authEstado is Autenticado ? authEstado.usuario.id : null;
    context.read<PanelControlCubit>().cargar(widget.eventoId, adminId: adminId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PanelControlCubit, PanelControlEstado>(
      listener: _escucharEstado,
      builder: _construirCuerpo,
    );
  }

  void _escucharEstado(BuildContext context, PanelControlEstado state) {
    if (state is PanelControlOperacionFallida) {
      AvisoApp.mostrar(context,
          texto: state.mensaje, estilo: EstiloAviso.error);
    } else if (state is PanelControlEventoCerrado) {
      AvisoApp.mostrar(context,
          texto: 'Evento cerrado exitosamente.', estilo: EstiloAviso.exito);
      context.pop();
    }
  }

  Widget _construirCuerpo(BuildContext context, PanelControlEstado state) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: ColoresApp.fondo,
        body: Column(
          children: [
            Container(
                height: MediaQuery.paddingOf(context).top,
                color: ColoresApp.acento),
            Expanded(child: _construirContenido(state)),
          ],
        ),
      ),
    );
  }

  Widget _construirContenido(PanelControlEstado state) => switch (state) {
        PanelControlInicial() => const SizedBox.shrink(),
        PanelControlCargando() => const Center(
            child: CircularProgressIndicator(color: ColoresApp.acento),
          ),
        PanelControlCargado() => _ContenidoCargado(estado: state),
        PanelControlOperacionFallida() =>
          _ContenidoCargado(estado: state.anterior),
        PanelControlError() => VistaErrorApp(mensaje: state.mensaje),
        PanelControlEventoCerrado() => const SizedBox.shrink(),
      };
}

// ─── Contenido principal cargado ─────────────────────────────────────────────

class _ContenidoCargado extends StatelessWidget {
  const _ContenidoCargado({required this.estado});
  final PanelControlCargado estado;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _EncabezadoEvento(estado: estado),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FilaEstadisticas(estado: estado),
                if (estado.tasaConvocatoria != null) ...[
                  const SizedBox(height: 14),
                  _SeccionTasas(estado: estado),
                ],
                const SizedBox(height: 24),
                _SeccionMarcarAsistencia(evento: estado.evento),
                const SizedBox(height: 24),
                _SeccionAlertaPendientes(estado: estado),
                _SeccionUsuarios(estado: estado),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Encabezado con degradado (fijo) ─────────────────────────────────────────

class _EncabezadoEvento extends StatelessWidget {
  const _EncabezadoEvento({required this.estado});
  final PanelControlCargado estado;

  @override
  Widget build(BuildContext context) {
    final evento = estado.evento;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: ColoresApp.degradadoPrincipal),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _BotonRegresar(),
              _BotonConfiguracion(estado: estado),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            evento.titulo,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: ColoresApp.blanco,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
          ),
          if (evento.lugar != null) ...[
            const SizedBox(height: 4),
            Text(
              evento.lugar!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: ColoresApp.blanco.withValues(alpha: 0.7),
                  ),
            ),
          ],
          const SizedBox(height: 18),
          _ChipsInfoEvento(estado: estado),
        ],
      ),
    );
  }
}

class _BotonRegresar extends StatelessWidget {
  const _BotonRegresar();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColoresApp.blanco.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => context.pop(),
        borderRadius: BorderRadius.circular(12),
        splashColor: ColoresApp.blanco.withValues(alpha: 0.3),
        highlightColor: ColoresApp.blanco.withValues(alpha: 0.1),
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: ColoresApp.blanco,
            size: 18,
          ),
        ),
      ),
    );
  }
}

// ─── Chips de información distribuidos en la fila ────────────────────────────

class _ChipsInfoEvento extends StatelessWidget {
  const _ChipsInfoEvento({required this.estado});
  final PanelControlCargado estado;

  String _formatearHora(String? hora) {
    if (hora == null) return '--:--';
    final p = hora.split(':');
    if (p.length < 2) return hora;
    final h24 = int.tryParse(p[0]) ?? 0;
    final min = p[1].padLeft(2, '0');
    final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
    final ampm = h24 < 12 ? 'AM' : 'PM';
    return '$h12:$min $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final e = estado.evento;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ChipInfo(etiqueta: 'INICIO', valor: _formatearHora(e.horaInicio)),
        _ChipInfo(etiqueta: 'CIERRE', valor: _formatearHora(e.horaFin)),
        _ChipInfo(
          etiqueta: 'PRESENTES',
          valor: estado.esEventoDirigido
              ? '${estado.presentesEsperados}/${estado.totalAudiencia}'
              : '${estado.totalPresentes}',
        ),
        _ChipInfo(etiqueta: 'MODOS', valor: '${estado.cantidadModos}'),
      ],
    );
  }
}

class _ChipInfo extends StatelessWidget {
  const _ChipInfo({required this.etiqueta, required this.valor});
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: ColoresApp.blanco.withValues(alpha: 0.6),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
        ),
        const SizedBox(height: 3),
        Text(
          valor,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: ColoresApp.blanco,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

// ─── Botón configuración (cabecera) ──────────────────────────────────────────

class _BotonConfiguracion extends StatelessWidget {
  const _BotonConfiguracion({required this.estado});

  final PanelControlCargado estado;

  void _abrirOpciones(BuildContext context) {
    PanelOpciones.mostrar(context, opciones: _opciones(context));
  }

  List<OpcionPanel> _opciones(BuildContext context) => [
        OpcionPanel(
          icono: Icons.group_add_rounded,
          colorFondo: ColoresApp.acentoClaro,
          colorIcono: ColoresApp.acento,
          titulo: 'Colaboradores',
          descripcion: 'Asigna usuarios para ayudar a gestionar este evento',
          alPresionar: () {
            Navigator.of(context, rootNavigator: true).pop();
            context.push(Rutas.colaboradoresEventoUrl(estado.evento.id));
          },
        ),
        OpcionPanel(
          icono: Icons.event_busy_rounded,
          colorFondo: ColoresApp.rojoClaro,
          colorIcono: ColoresApp.rojo,
          titulo: 'Cerrar evento',
          descripcion: 'Finaliza y cierra el evento en curso',
          alPresionar: () {
            Navigator.of(context, rootNavigator: true).pop();
            DialogoConfirmacionTexto.mostrar(
              context,
              titulo: 'Cerrar evento',
              descripcionPrefijo: 'Escribe el nombre ',
              descripcionSufijo: ' para confirmar el cierre.',
              valorEsperado: estado.evento.titulo,
              distingueMayusculas: true,
              etiquetaCampo: 'Nombre del evento',
              textoBotonConfirmar: 'Confirmar cierre',
              alConfirmar: context.read<PanelControlCubit>().cerrarEvento,
            );
          },
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColoresApp.blanco.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _abrirOpciones(context),
        borderRadius: BorderRadius.circular(12),
        splashColor: ColoresApp.blanco.withValues(alpha: 0.3),
        highlightColor: ColoresApp.blanco.withValues(alpha: 0.1),
        child: const Padding(
          padding: EdgeInsets.all(8),
          child:
              Icon(Icons.settings_outlined, color: ColoresApp.blanco, size: 20),
        ),
      ),
    );
  }
}

// ─── Estadísticas ─────────────────────────────────────────────────────────────

class _FilaEstadisticas extends StatelessWidget {
  const _FilaEstadisticas({required this.estado});
  final PanelControlCargado estado;

  @override
  Widget build(BuildContext context) {
    return estado.esEventoDirigido
        ? _EstadisticasDirigido(estado: estado)
        : _EstadisticasGeneral(estado: estado);
  }
}

class _EstadisticasDirigido extends StatelessWidget {
  const _EstadisticasDirigido({required this.estado});
  final PanelControlCargado estado;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _TarjetaEstadistica(
                    valor: estado.presentesEsperados,
                    etiqueta: 'Llegaron',
                    color: ColoresApp.verde)),
            const SizedBox(width: 10),
            Expanded(
                child: _TarjetaEstadistica(
                    valor: estado.pendientes,
                    etiqueta: 'Pendientes',
                    color: ColoresApp.ambar)),
            const SizedBox(width: 10),
            Expanded(
                child: _TarjetaEstadistica(
                    valor: estado.ausentes,
                    etiqueta: 'Ausentes',
                    color: ColoresApp.rojo)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: _TarjetaEstadistica(
                    valor: estado.presentesNoEsperados,
                    etiqueta: 'No esperados',
                    color: ColoresApp.teal)),
            const SizedBox(width: 10),
            Expanded(
                child: _TarjetaEstadistica(
                    valor: estado.presentesForaneos,
                    etiqueta: 'Foráneos',
                    color: ColoresApp.teal)),
            const SizedBox(width: 10),
            Expanded(
                child: _TarjetaEstadistica(
                    valor: estado.totalPresentes,
                    etiqueta: 'Total en sala',
                    color: ColoresApp.textoPrimario)),
          ],
        ),
      ],
    );
  }
}

class _EstadisticasGeneral extends StatelessWidget {
  const _EstadisticasGeneral({required this.estado});
  final PanelControlCargado estado;

  @override
  Widget build(BuildContext context) {
    final delSistema = estado.totalPresentes - estado.presentesForaneos;
    return Row(
      children: [
        Expanded(
            child: _TarjetaEstadistica(
                valor: delSistema,
                etiqueta: 'Del sistema',
                color: ColoresApp.verde)),
        const SizedBox(width: 10),
        Expanded(
            child: _TarjetaEstadistica(
                valor: estado.presentesForaneos,
                etiqueta: 'Foráneos',
                color: ColoresApp.teal)),
        const SizedBox(width: 10),
        Expanded(
            child: _TarjetaEstadistica(
                valor: estado.totalPresentes,
                etiqueta: 'Total',
                color: ColoresApp.textoPrimario)),
      ],
    );
  }
}

// ─── Gráficas de tasas (solo eventos dirigidos) ───────────────────────────────

class _SeccionTasas extends StatelessWidget {
  const _SeccionTasas({required this.estado});
  final PanelControlCargado estado;

  @override
  Widget build(BuildContext context) {
    final convocatoria = estado.tasaConvocatoria!;
    final ocupacion = estado.tasaOcupacion!;
    return TarjetaApp(
      variante: VarianteTarjeta.normal,
      child: Column(
        children: [
          BarraEstadistica(
            etiqueta: 'Tasa convocatoria',
            porcentaje: convocatoria,
          ),
          const SizedBox(height: 16),
          BarraEstadistica(
            etiqueta: 'Tasa ocupación',
            porcentaje: ocupacion,
            colorBarra: ColoresApp.acento,
            colorPorcentaje: ColoresApp.acento,
          ),
        ],
      ),
    );
  }
}

class _TarjetaEstadistica extends StatelessWidget {
  const _TarjetaEstadistica({
    required this.valor,
    required this.etiqueta,
    required this.color,
  });

  final int valor;
  final String etiqueta;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TarjetaApp(
      variante: VarianteTarjeta.normal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale:
                  CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: Text(
              '$valor',
              key: ValueKey(valor),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: color,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            etiqueta,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

// ─── Sección Marcar Asistencia ────────────────────────────────────────────────

class _SeccionMarcarAsistencia extends StatelessWidget {
  const _SeccionMarcarAsistencia({required this.evento});
  final Evento evento;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _EncabezadoSeccion(titulo: 'MARCAR ASISTENCIA'),
        const SizedBox(height: 12),
        _BotonesAccion(evento: evento),
      ],
    );
  }
}

class _BotonesAccion extends StatelessWidget {
  const _BotonesAccion({required this.evento});
  final Evento evento;

  @override
  Widget build(BuildContext context) {
    final botones = <_BotonAccion>[
      if (evento.permiteQrEvento)
        _BotonAccion(
          icono: Icons.qr_code_scanner_rounded,
          etiqueta: 'QR\nEvento',
          alPresionar: () => ModalQrEvento.mostrar(context,
              eventoId: evento.id, horaFin: evento.horaFin),
        ),
      if (evento.permiteQrUsuario)
        _BotonAccion(
          icono: Icons.qr_code_rounded,
          etiqueta: 'QR\nUsuario',
          alPresionar: () async {
            await context.push(Rutas.escanearQrUsuarioUrl(evento.id));
            if (context.mounted) {
              unawaited(context.read<PanelControlCubit>().recargarSilencioso());
            }
          },
        ),
      if (evento.permiteManualAdmin)
        _BotonAccion(
          icono: Icons.person_search_rounded,
          etiqueta: 'Buscar\nusuario',
          alPresionar: () async {
            await context.push(Rutas.buscarAsistenteUrl(evento.id));
            if (context.mounted) {
              unawaited(context.read<PanelControlCubit>().recargarSilencioso());
            }
          },
        ),
      if (evento.permiteForaneos)
        _BotonAccion(
          icono: Icons.person_add_rounded,
          etiqueta: 'Foráneo',
          alPresionar: () => ModalForaneo.mostrar(
            context,
            onRegistrar: (
                    {required primerNombre,
                    required primerApellido,
                    required cedula,
                    contacto}) =>
                context.read<PanelControlCubit>().registrarForaneo(
                      primerNombre: primerNombre,
                      primerApellido: primerApellido,
                      cedula: cedula,
                      contacto: contacto,
                    ),
          ),
        ),
    ];

    if (botones.isEmpty) return const SizedBox.shrink();

    final items = <Widget>[];
    for (int i = 0; i < botones.length; i++) {
      items.add(Expanded(child: botones[i]));
      if (i < botones.length - 1) items.add(const SizedBox(width: 8));
    }
    return IntrinsicHeight(
      child:
          Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: items),
    );
  }
}

class _BotonAccion extends StatelessWidget {
  const _BotonAccion({
    required this.icono,
    required this.etiqueta,
    this.alPresionar,
  });
  final IconData icono;
  final String etiqueta;
  final VoidCallback? alPresionar;

  @override
  Widget build(BuildContext context) {
    const radio = BorderRadius.all(Radius.circular(18));
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: radio,
        boxShadow: [
          BoxShadow(
            color: ColoresApp.sombraTarjeta,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: ColoresApp.blanco,
        borderRadius: radio,
        child: InkWell(
          onTap: alPresionar,
          borderRadius: radio,
          splashColor: ColoresApp.acentoClaro,
          highlightColor: ColoresApp.acentoClaro.withValues(alpha: 0.6),
          child: Ink(
            decoration: const BoxDecoration(
              color: ColoresApp.blanco,
              borderRadius: radio,
              border: Border.fromBorderSide(
                BorderSide(color: ColoresApp.bordesuave),
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icono, size: 26, color: ColoresApp.acento),
                const SizedBox(height: 6),
                Text(
                  etiqueta,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Sección Usuarios ─────────────────────────────────────────────────────────

class _SeccionUsuarios extends StatelessWidget {
  const _SeccionUsuarios({required this.estado});
  final PanelControlCargado estado;

  @override
  Widget build(BuildContext context) {
    final filtrados = estado.asistentesFiltrados;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _EncabezadoSeccion(titulo: 'USUARIOS REGISTRADOS'),
        const SizedBox(height: 12),
        _FiltrosTabs(
          estado: estado,
          onFiltrar: context.read<PanelControlCubit>().cambiarFiltro,
        ),
        const SizedBox(height: 12),
        if (estado.filtroActivo == FiltroAsistentes.pendientes &&
            filtrados.isNotEmpty) ...[
          _BotonCopiarLista(asistentes: filtrados),
          const SizedBox(height: 8),
        ],
        if (filtrados.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'Sin registros para este filtro.',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          )
        else
          ...filtrados.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TarjetaAsistente(
                iniciales: a.iniciales,
                nombre: a.nombre,
                estatus: a.estatus,
                detalle: a.etiquetaDetalle,
                subtitulo: a.registradoPorNombre != null
                    ? 'Reg. por: ${a.registradoPorNombre}'
                    : null,
                urlFoto: a.urlFoto,
                accionTrailing: a.estatus == EstatusAsistencia.esperado
                    ? _BotonRegistrar(eventoId: estado.evento.id)
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Botón Registrar (inline en TarjetaAsistente) ────────────────────────────

class _BotonRegistrar extends StatelessWidget {
  const _BotonRegistrar({required this.eventoId});
  final String eventoId;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => context.push(Rutas.buscarAsistenteUrl(eventoId)),
        borderRadius: BorderRadius.circular(20),
        splashColor: ColoresApp.blanco.withValues(alpha: 0.3),
        child: Ink(
          decoration: BoxDecoration(
            gradient: ColoresApp.degradadoPrincipal,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Text(
            'Registrar',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: ColoresApp.blanco,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}

// ─── Filtros en pills ─────────────────────────────────────────────────────────

class _FiltrosTabs extends StatelessWidget {
  const _FiltrosTabs({
    required this.estado,
    required this.onFiltrar,
  });

  final PanelControlCargado estado;
  final void Function(FiltroAsistentes) onFiltrar;

  static const _etiquetas = {
    FiltroAsistentes.todos: 'Todos',
    FiltroAsistentes.esperados: 'Esperados',
    FiltroAsistentes.pendientes: 'Sin llegar',
    FiltroAsistentes.noEsperados: 'No esperados',
    FiltroAsistentes.registrados: 'Llegaron',
    FiltroAsistentes.abandono: 'Abandono',
    FiltroAsistentes.foraneos: 'Foráneos',
  };

  List<FiltroAsistentes> _filtrosVisibles() {
    if (!estado.esEventoDirigido) {
      return FiltroAsistentes.values
          .where(
            (f) =>
                f != FiltroAsistentes.esperados &&
                f != FiltroAsistentes.pendientes &&
                f != FiltroAsistentes.noEsperados,
          )
          .toList();
    }
    return FiltroAsistentes.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filtrosVisibles().map((filtro) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _ChipFiltro(
              etiqueta: _etiquetas[filtro]!,
              activo: filtro == estado.filtroActivo,
              onTap: () => onFiltrar(filtro),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ChipFiltro extends StatelessWidget {
  const _ChipFiltro({
    required this.etiqueta,
    required this.activo,
    required this.onTap,
  });

  final String etiqueta;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: activo
            ? Ink(
                decoration: BoxDecoration(
                  gradient: ColoresApp.degradadoPrincipal,
                  borderRadius: BorderRadius.circular(30),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                child: Text(
                  etiqueta,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: ColoresApp.blanco,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  border: Border.all(color: ColoresApp.bordeMedio),
                  borderRadius: BorderRadius.circular(30),
                  color: ColoresApp.superficiePrimaria,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                child: Text(
                  etiqueta,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: ColoresApp.textoSecundario,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
      ),
    );
  }
}

// ─── Alerta de pendientes (sin llegar) ───────────────────────────────────────

class _SeccionAlertaPendientes extends StatelessWidget {
  const _SeccionAlertaPendientes({required this.estado});
  final PanelControlCargado estado;

  @override
  Widget build(BuildContext context) {
    if (!estado.esEventoDirigido || estado.pendientes == 0) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: TarjetaApp(
        variante: VarianteTarjeta.normal,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: ColoresApp.ambarClaro,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.person_off_rounded,
                color: ColoresApp.ambar,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${estado.pendientes} sin llegar',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: ColoresApp.textoPrimario,
                        ),
                  ),
                  Text(
                    'Audiencia que aún no ha llegado al evento',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ColoresApp.textoSecundario,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => context
                  .read<PanelControlCubit>()
                  .cambiarFiltro(FiltroAsistentes.pendientes),
              style: TextButton.styleFrom(
                foregroundColor: ColoresApp.acento,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text(
                'Ver lista',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Botón copiar lista de pendientes ────────────────────────────────────────

class _BotonCopiarLista extends StatelessWidget {
  const _BotonCopiarLista({required this.asistentes});
  final List<AsistenteItem> asistentes;

  Future<void> _copiar(BuildContext context) async {
    final nombres = asistentes.map((a) => '• ${a.nombre}').join('\n');
    await Clipboard.setData(ClipboardData(text: nombres));
    if (!context.mounted) return;
    AvisoApp.mostrar(
      context,
      texto: 'Lista copiada al portapapeles',
      estilo: EstiloAviso.exito,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: () => _copiar(context),
        icon: const Icon(Icons.copy_all_rounded, size: 15),
        label: const Text('Copiar lista'),
        style: TextButton.styleFrom(
          foregroundColor: ColoresApp.textoSecundario,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

// ─── Encabezado de sección ────────────────────────────────────────────────────

class _EncabezadoSeccion extends StatelessWidget {
  const _EncabezadoSeccion({required this.titulo});
  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Text(
      titulo,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: ColoresApp.textoSecundario,
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: 0.8,
          ),
    );
  }
}
