import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/widgets/avisos/aviso_app.dart';
import '../../compartido/widgets/avisos/vista_error_app.dart';
import '../../compartido/widgets/listas/fila_togle.dart';
import '../../compartido/widgets/navegacion/barra_superior_app.dart';
import '../../compartido/widgets/botones/boton_regresar.dart';
import '../../configuracion/colores_app.dart';
import 'configuracion_item.dart';
import 'configuracion_general_cubit.dart';
import 'configuracion_general_estado.dart';

class ConfiguracionGeneralPantalla extends StatefulWidget {
  const ConfiguracionGeneralPantalla({super.key});

  @override
  State<ConfiguracionGeneralPantalla> createState() =>
      _ConfiguracionGeneralPantallaState();
}

class _ConfiguracionGeneralPantallaState
    extends State<ConfiguracionGeneralPantalla> {
  bool _estaIniciado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_estaIniciado) return;
    _estaIniciado = true;
    context.read<ConfiguracionGeneralCubit>().cargar();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ConfiguracionGeneralCubit, ConfiguracionGeneralEstado>(
      listenWhen: (_, curr) =>
          curr is ConfiguracionGeneralCargado && curr.errorPuntual != null,
      listener: (context, estado) {
        if (estado is ConfiguracionGeneralCargado &&
            estado.errorPuntual != null) {
          AvisoApp.mostrar(
            context,
            texto: estado.errorPuntual!,
            estilo: EstiloAviso.error,
          );
        }
      },
      builder: _construirVista,
    );
  }

  Widget _construirVista(
      BuildContext context, ConfiguracionGeneralEstado estado) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
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
                      'Configuraciones generales',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: ColoresApp.textoPrimario,
                          ),
                    ),
                  ],
                ),
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

  final ConfiguracionGeneralEstado estado;

  @override
  Widget build(BuildContext context) {
    final e = estado;
    return switch (e) {
      ConfiguracionGeneralInicial() ||
      ConfiguracionGeneralCargando() =>
        const Center(
            child: CircularProgressIndicator(color: ColoresApp.acento)),
      ConfiguracionGeneralCargado() => _Lista(estado: e),
      ConfiguracionGeneralError() => VistaErrorApp(
          mensaje: e.mensaje,
          alReintentar: () =>
              context.read<ConfiguracionGeneralCubit>().cargar(),
        ),
    };
  }
}

// ─── Lista agrupada por módulo ─────────────────────────────────────────────────

class _Lista extends StatelessWidget {
  const _Lista({required this.estado});

  final ConfiguracionGeneralCargado estado;

  @override
  Widget build(BuildContext context) {
    if (estado.items.isEmpty) {
      return Center(
        child: Text(
          'No hay configuraciones registradas',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ColoresApp.textoTerciario,
              ),
        ),
      );
    }

    final porModulo = <String, List<ConfiguracionItem>>{};
    for (final item in estado.items) {
      porModulo.putIfAbsent(item.modulo, () => []).add(item);
    }
    final modulos = porModulo.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      itemCount: modulos.length,
      itemBuilder: (context, i) {
        final modulo = modulos[i];
        final items = porModulo[modulo]!;
        return Padding(
          padding: EdgeInsets.only(bottom: 24, top: i == 0 ? 0 : 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  modulo.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: ColoresApp.textoTerciario,
                        letterSpacing: 0.8,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              for (final item in items) ...[
                _Fila(
                    item: item, guardando: estado.guardando.contains(item.id)),
                const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─── Una fila: un solo control por configuración ───────────────────────────────
//
// Booleana → sí/no (FilaTogle, el mismo interruptor que usa el resto de la
// app). Numérica → cuántos (stepper). Nunca ambos a la vez — mostrar un
// interruptor de "valor" y otro de "activar" por separado resultaba confuso.

class _Fila extends StatelessWidget {
  const _Fila({required this.item, required this.guardando});

  final ConfiguracionItem item;
  final bool guardando;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ConfiguracionGeneralCubit>();

    if (item.esBooleano) {
      return FilaTogle(
        titulo: item.tituloLegible,
        descripcion: item.descripcion,
        valor: item.valorBooleano,
        alCambiar:
            guardando ? null : (v) => cubit.actualizarValor(item.id, v ? 1 : 0),
      );
    }

    return _FilaNumero(
      titulo: item.tituloLegible,
      descripcion: item.descripcion,
      valor: item.valor,
      alCambiar: guardando ? null : (v) => cubit.actualizarValor(item.id, v),
    );
  }
}

// ─── Fila numérica — mismo estilo visual que FilaTogle, con un stepper ────────

class _FilaNumero extends StatelessWidget {
  const _FilaNumero({
    required this.titulo,
    required this.descripcion,
    required this.valor,
    required this.alCambiar,
  });

  final String titulo;
  final String descripcion;
  final int valor;
  final ValueChanged<int>? alCambiar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: ColoresApp.superficieSecund,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: ColoresApp.sombraTarjeta,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 3),
                Text(descripcion, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline_rounded),
            color: ColoresApp.acento,
            visualDensity: VisualDensity.compact,
            onPressed: (alCambiar != null && valor > 0)
                ? () => alCambiar!(valor - 1)
                : null,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$valor',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            color: ColoresApp.acento,
            visualDensity: VisualDensity.compact,
            onPressed: alCambiar != null ? () => alCambiar!(valor + 1) : null,
          ),
        ],
      ),
    );
  }
}
