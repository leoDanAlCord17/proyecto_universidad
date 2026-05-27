import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/widgets/formularios/barra_busqueda_app.dart';
import '../../compartido/widgets/navegacion/barra_superior_app.dart';
import '../../compartido/widgets/botones/boton_regresar.dart';
import '../../configuracion/colores_app.dart';
import 'permiso.dart';
import 'permisos_cubit.dart';
import 'permisos_estado.dart';

class PermisosPantalla extends StatefulWidget {
  const PermisosPantalla({super.key});

  @override
  State<PermisosPantalla> createState() => _PermisosPantallaState();
}

class _PermisosPantallaState extends State<PermisosPantalla> {
  bool _estaIniciado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_estaIniciado) return;
    _estaIniciado = true;
    context.read<PermisosCubit>().cargarPermisos();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PermisosCubit, PermisosEstado>(
      builder: _construirVista,
    );
  }

  Widget _construirVista(BuildContext context, PermisosEstado estado) {
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
                      'Permisos',
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: BarraBusquedaApp(
                hintText:  'Buscar permisos...',
                alCambiar: (texto) =>
                    context.read<PermisosCubit>().filtrar(texto),
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

  final PermisosEstado estado;

  @override
  Widget build(BuildContext context) {
    final e = estado;
    return switch (e) {
      PermisosInicial() || PermisosCargando() => const Center(
          child: CircularProgressIndicator(color: ColoresApp.acento),
        ),
      PermisosCargados() => _Lista(estado: e),
      PermisosError()    => _VistaError(mensaje: e.mensaje),
    };
  }
}

// ─── Lista de permisos ────────────────────────────────────────────────────────

class _Lista extends StatelessWidget {
  const _Lista({required this.estado});

  final PermisosCargados estado;

  @override
  Widget build(BuildContext context) {
    final items = estado.permisosFiltrados;

    if (items.isEmpty) {
      return Center(
        child: Text(
          'No hay permisos',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: ColoresApp.textoTerciario,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Text(
          'PERMISOS DEL SISTEMA',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color:         ColoresApp.textoTerciario,
            letterSpacing: 0.8,
            fontSize:   13,
            fontWeight:    FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        ...items.map((p) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child:   _TarjetaPermiso(permiso: p),
        ),),
      ],
    );
  }
}

// ─── Tarjeta de permiso ───────────────────────────────────────────────────────

class _TarjetaPermiso extends StatelessWidget {
  const _TarjetaPermiso({required this.permiso});

  final Permiso permiso;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color:        ColoresApp.superficiePrimaria,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color:       ColoresApp.sombraTarjeta,
            blurRadius:  8,
            offset:      Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            permiso.nombre,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color:      ColoresApp.textoPrimario,
              fontSize:   16,
            ),
          ),
          if (permiso.descripcion.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              permiso.descripcion,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ColoresApp.textoSecundario,
                fontSize:   13,
              ),
            ),
          ],
        ],
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
          ],
        ),
      ),
    );
  }
}
