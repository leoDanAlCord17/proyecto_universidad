import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../compartido/constantes.dart';
import '../../compartido/widgets/avisos/aviso_app.dart';
import '../../compartido/widgets/dialogo/dialogo_confirmacion.dart';
import '../../compartido/widgets/formularios/barra_busqueda_app.dart';
import '../../compartido/widgets/navegacion/barra_superior_app.dart';
import '../../compartido/widgets/botones/boton_regresar.dart';
import '../../configuracion/colores_app.dart';
import 'tipo_evento_item.dart';
import 'tipos_evento_cubit.dart';
import 'tipos_evento_estado.dart';

class TiposEventoPantalla extends StatefulWidget {
  const TiposEventoPantalla({super.key});

  @override
  State<TiposEventoPantalla> createState() => _TiposEventoPantallaState();
}

class _TiposEventoPantallaState extends State<TiposEventoPantalla> {
  bool _estaIniciado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_estaIniciado) return;
    _estaIniciado = true;
    context.read<TiposEventoCubit>().cargar();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TiposEventoCubit, TiposEventoEstado>(
      listenWhen: (_, curr) =>
          curr is TiposEventoCargados && curr.errorOperacion != null,
      listener: (context, estado) {
        if (estado is TiposEventoCargados && estado.errorOperacion != null) {
          AvisoApp.mostrar(context,
              texto: estado.errorOperacion!, estilo: EstiloAviso.error);
        }
      },
      builder: (context, estado) => _construirVista(context, estado),
    );
  }

  Widget _construirVista(BuildContext context, TiposEventoEstado estado) {
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
            const _BarraTitulo(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: BarraBusquedaApp(
                hintText:  'Buscar tipos de evento...',
                alCambiar: (texto) =>
                    context.read<TiposEventoCubit>().filtrar(texto),
              ),
            ),
            Expanded(child: _Cuerpo(estado: estado)),
          ],
        ),
      ),
    );
  }
}

// ─── Barra de título ──────────────────────────────────────────────────────────

class _BarraTitulo extends StatelessWidget {
  const _BarraTitulo();

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
              'Tipos de evento',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontSize:   20,
                fontWeight: FontWeight.w700,
                color:      ColoresApp.textoPrimario,
              ),
            ),
          ],
        ),
        derecha: const _BotonCrear(),
      ),
    );
  }
}

// ─── Botón crear ──────────────────────────────────────────────────────────────

class _BotonCrear extends StatelessWidget {
  const _BotonCrear();

  @override
  Widget build(BuildContext context) {
    return Material(
      color:        Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () async {
          await context.push(Rutas.crearTipoEvento);
          if (context.mounted) context.read<TiposEventoCubit>().cargar();
        },
        borderRadius:   BorderRadius.circular(12),
        splashColor:    Colors.white.withValues(alpha: 0.3),
        highlightColor: Colors.white.withValues(alpha: 0.15),
        child: Ink(
          width:  40,
          height: 40,
          decoration: BoxDecoration(
            gradient:     ColoresApp.degradadoPrincipal,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

// ─── Cuerpo según estado ──────────────────────────────────────────────────────

class _Cuerpo extends StatelessWidget {
  const _Cuerpo({required this.estado});

  final TiposEventoEstado estado;

  @override
  Widget build(BuildContext context) {
    return switch (estado) {
      TiposEventoInicial() || TiposEventoCargando() => const Center(
          child: CircularProgressIndicator(color: ColoresApp.acento),
        ),
      final TiposEventoCargados cargados => _Lista(estado: cargados),
      final TiposEventoError error       => _VistaError(mensaje: error.mensaje),
    };
  }
}

// ─── Lista ────────────────────────────────────────────────────────────────────

class _Lista extends StatelessWidget {
  const _Lista({required this.estado});

  final TiposEventoCargados estado;

  @override
  Widget build(BuildContext context) {
    final items = estado.filtrados;

    if (items.isEmpty) {
      return Center(
        child: Text(
          'No hay tipos de evento',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: ColoresApp.textoTerciario,
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text(
              'TIPOS DE EVENTO',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color:         ColoresApp.textoTerciario,
                letterSpacing: 0.8,
                fontSize:      13,
                fontWeight:    FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            ...items.map((tipo) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TarjetaTipoEvento(
                tipo: tipo,
                alEditar: () async {
                  await context.push(Rutas.editarTipoEventoUrl(tipo.id));
                  if (context.mounted) context.read<TiposEventoCubit>().cargar();
                },
                alDesactivar: () async {
                  final confirmo = await DialogoConfirmacion.mostrar(
                    context,
                    titulo:         'Desactivar tipo de evento',
                    descripcion:    '¿Deseas desactivar "${tipo.nombre}"? Dejará de estar disponible al crear eventos.',
                    textoConfirmar: 'Desactivar',
                    textoCancelar:  'Cancelar',
                  );
                  if (confirmo != true || !context.mounted) return;
                  context.read<TiposEventoCubit>().desactivar(tipo.id);
                },
              ),
            )),
          ],
        ),
        if (estado.estaDesactivando)
          const ColoredBox(
            color: Colors.black12,
            child: Center(
              child: CircularProgressIndicator(color: ColoresApp.acento),
            ),
          ),
      ],
    );
  }
}

// ─── Tarjeta de tipo de evento ────────────────────────────────────────────────

class _TarjetaTipoEvento extends StatelessWidget {
  const _TarjetaTipoEvento({
    required this.tipo,
    required this.alEditar,
    required this.alDesactivar,
  });

  final TipoEventoItem tipo;
  final VoidCallback   alEditar;
  final VoidCallback   alDesactivar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color:        ColoresApp.superficiePrimaria,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color:      ColoresApp.sombraTarjeta,
            blurRadius: 8,
            offset:     Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tipo.nombre,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color:      ColoresApp.textoPrimario,
                    fontSize:   16,
                  ),
                ),
                if (tipo.descripcion.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    tipo.descripcion,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:    ColoresApp.textoSecundario,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BotonEditar(alPresionar: alEditar),
              const SizedBox(width: 8),
              _BotonDesactivar(alPresionar: alDesactivar),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Botón editar ─────────────────────────────────────────────────────────────

class _BotonEditar extends StatelessWidget {
  const _BotonEditar({required this.alPresionar});

  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color:        Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap:          alPresionar,
        borderRadius:   BorderRadius.circular(10),
        splashColor:    Colors.white.withValues(alpha: 0.3),
        highlightColor: Colors.white.withValues(alpha: 0.15),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            gradient:     ColoresApp.degradadoPrincipal,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'Editar',
            style: TextStyle(
              color:      Colors.white,
              fontSize:   14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Botón desactivar ─────────────────────────────────────────────────────────

class _BotonDesactivar extends StatelessWidget {
  const _BotonDesactivar({required this.alPresionar});

  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color:        Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap:          alPresionar,
        borderRadius:   BorderRadius.circular(10),
        splashColor:    ColoresApp.rojo.withValues(alpha: 0.2),
        highlightColor: ColoresApp.rojo.withValues(alpha: 0.1),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color:        ColoresApp.rojoClaro,
            borderRadius: BorderRadius.circular(10),
            border:       Border.all(color: ColoresApp.bordeError),
          ),
          child: const Text(
            'Desactivar',
            style: TextStyle(
              color:      ColoresApp.rojo,
              fontSize:   14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
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
              onPressed: () => context.read<TiposEventoCubit>().cargar(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
