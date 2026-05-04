import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../compartido/constantes.dart';
import '../../compartido/widgets/avisos/aviso_app.dart';
import '../../compartido/widgets/formularios/barra_busqueda_app.dart';
import '../../compartido/widgets/navegacion/barra_superior_app.dart';
import '../../compartido/widgets/botones/boton_regresar.dart';
import '../../compartido/widgets/tarjetas/tarjeta_borrador_evento.dart';
import '../../configuracion/colores_app.dart';
import '../../configuracion/dependencias.dart';
import '../autenticacion/auth_cubit.dart';
import '../autenticacion/auth_estado.dart';
import 'borrador_evento.dart';
import 'borradores_cubit.dart';
import 'borradores_estado.dart';

class BorradoresPantalla extends StatefulWidget {
  const BorradoresPantalla({super.key});

  @override
  State<BorradoresPantalla> createState() => _BorradoresPantallaState();
}

class _BorradoresPantallaState extends State<BorradoresPantalla> {
  bool           _estaIniciado = false;
  String         _textoBusqueda = '';
  DateTimeRange? _rango;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_estaIniciado) return;
    _estaIniciado = true;
    final authState = obtenerIt<AuthCubit>().state;
    if (authState is Autenticado) {
      final id = authState.usuario.id;
      if (id != null) context.read<BorradoresCubit>().cargarBorradores(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BorradoresCubit, BorradoresEstado>(
      listener: (context, estado) {
        if (estado is BorradoresCargados && estado.errorPublicacion != null) {
          AvisoApp.mostrar(
            context,
            texto:  estado.errorPublicacion!,
            estilo: EstiloAviso.error,
          );
          context.read<BorradoresCubit>().limpiarError();
        }
      },
      builder: (context, estado) => _construirVista(context, estado),
    );
  }

  Widget _construirVista(BuildContext context, BorradoresEstado estado) {
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
                    Text('Borradores',
                        style: Theme.of(context).textTheme.headlineSmall),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: BarraBusquedaApp(
                alCambiar: (texto) {
                  _textoBusqueda = texto;
                  context.read<BorradoresCubit>().filtrar(texto, _rango);
                },
                alSeleccionarRango: (rango) {
                  setState(() => _rango = rango);
                  context.read<BorradoresCubit>().filtrar(_textoBusqueda, rango);
                },
                alLimpiarRango: () {
                  setState(() => _rango = null);
                  context.read<BorradoresCubit>().filtrar(_textoBusqueda, null);
                },
                rangoSeleccionado: _rango,
              ),
            ),
            Expanded(child: _Cuerpo(estado: estado)),
          ],
        ),
      ),
    );
  }
}

// ─── Cuerpo según estado ──────────────────────────────────────────────────────

class _Cuerpo extends StatelessWidget {
  const _Cuerpo({required this.estado});

  final BorradoresEstado estado;

  @override
  Widget build(BuildContext context) {
    final e = estado;
    return switch (e) {
      BorradoresInicial() || BorradoresCargando() => const Center(
          child: CircularProgressIndicator(color: ColoresApp.acento),
        ),
      BorradoresCargados() => _Lista(estado: e),
      BorradoresError()    => _VistaError(mensaje: e.mensaje),
    };
  }
}

// ─── Lista de borradores ──────────────────────────────────────────────────────

class _Lista extends StatelessWidget {
  const _Lista({required this.estado});

  final BorradoresCargados estado;

  @override
  Widget build(BuildContext context) {
    final items = estado.borradoresFiltrados;

    if (items.isEmpty) {
      return Center(
        child: Text(
          'No hay borradores',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: ColoresApp.textoTerciario,
          ),
        ),
      );
    }

    return ListView.separated(
      padding:     const EdgeInsets.fromLTRB(20, 16, 20, 32),
      itemCount:   items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final borrador = items[i];
        return TarjetaBorradorEvento(
          titulo:         borrador.titulo,
          horario:        _formatearHorario(borrador),
          descripcion:    borrador.descripcion,
          estaPublicando: estado.publicandoId == borrador.id,
          alVerDetalles:  () => context.push(Rutas.editarEventoUrl(borrador.id)),
          alPublicar:     () => context
              .read<BorradoresCubit>()
              .publicarEvento(borrador.id),
        );
      },
    );
  }

  String _formatearHorario(BorradorEvento borrador) {
    final fecha = borrador.fechaInicio;
    if (fecha == null) return '—';
    const dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    final dia  = dias[fecha.weekday - 1];
    final d    = fecha.day.toString().padLeft(2, '0');
    final m    = fecha.month.toString().padLeft(2, '0');
    final base = '$dia $d/$m';
    final hi = borrador.horaInicio;
    if (hi == null) return base;
    final hf = borrador.horaFin;
    final hiStr = hi.length >= 5 ? _a12h(hi.substring(0, 5)) : hi;
    if (hf == null) return '$base . $hiStr';
    final hfStr = hf.length >= 5 ? _a12h(hf.substring(0, 5)) : hf;
    return '$base . $hiStr → $hfStr';
  }

  static String _a12h(String hhmm) {
    final p       = hhmm.split(':');
    if (p.length < 2) return hhmm;
    final h24     = int.tryParse(p[0]) ?? 0;
    final minutos = p[1].padLeft(2, '0');
    final h12     = h24 % 12 == 0 ? 12 : h24 % 12;
    final ampm    = h24 < 12 ? 'AM' : 'PM';
    return '$h12:$minutos $ampm';
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
          ],
        ),
      ),
    );
  }
}
