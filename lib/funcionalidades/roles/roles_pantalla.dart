import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../compartido/constantes.dart';
import '../../compartido/widgets/formularios/barra_busqueda_app.dart';
import '../../compartido/widgets/navegacion/barra_superior_app.dart';
import '../../compartido/widgets/botones/boton_regresar.dart';
import '../../configuracion/colores_app.dart';
import 'rol.dart';
import 'roles_cubit.dart';
import 'roles_estado.dart';

class RolesPantalla extends StatefulWidget {
  const RolesPantalla({super.key});

  @override
  State<RolesPantalla> createState() => _RolesPantallaState();
}

class _RolesPantallaState extends State<RolesPantalla> {
  bool _estaIniciado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_estaIniciado) return;
    _estaIniciado = true;
    context.read<RolesCubit>().cargarRoles();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RolesCubit, RolesEstado>(
      builder: _construirVista,
    );
  }

  Widget _construirVista(BuildContext context, RolesEstado estado) {
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
                      'Gestión de roles',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: ColoresApp.textoPrimario,
                          ),
                    ),
                  ],
                ),
                derecha: const _BotonCrearRol(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: BarraBusquedaApp(
                hintText: 'Buscar roles...',
                alCambiar: (texto) => context.read<RolesCubit>().filtrar(texto),
              ),
            ),
            Expanded(child: _Cuerpo(estado: estado)),
          ],
        ),
      ),
    );
  }
}

// ─── Botón crear rol ──────────────────────────────────────────────────────────

class _BotonCrearRol extends StatelessWidget {
  const _BotonCrearRol();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () async {
          await context.push(Rutas.crearRol);
          if (context.mounted)
            unawaited(context.read<RolesCubit>().cargarRoles());
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: ColoresApp.blanco.withValues(alpha: 0.3),
        highlightColor: ColoresApp.blanco.withValues(alpha: 0.15),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: ColoresApp.degradadoPrincipal,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.add_rounded,
            color: ColoresApp.blanco,
            size: 22,
          ),
        ),
      ),
    );
  }
}

// ─── Cuerpo según estado ──────────────────────────────────────────────────────

class _Cuerpo extends StatelessWidget {
  const _Cuerpo({required this.estado});

  final RolesEstado estado;

  @override
  Widget build(BuildContext context) {
    final e = estado;
    return switch (e) {
      RolesInicial() || RolesCargando() => const Center(
          child: CircularProgressIndicator(color: ColoresApp.acento),
        ),
      RolesCargados() => _Lista(estado: e),
      RolesCargandoMas() => _Lista(
          estado: RolesCargados(
            roles: e.roles,
            rolesFiltrados: e.rolesFiltrados,
            hayMas: true,
            conteoUsuarios: e.conteoUsuarios,
          ),
          cargandoMas: true,
        ),
      RolesError() => _VistaError(mensaje: e.mensaje),
    };
  }
}

// ─── Lista de roles ───────────────────────────────────────────────────────────

class _Lista extends StatelessWidget {
  const _Lista({required this.estado, this.cargandoMas = false});

  final RolesCargados estado;
  final bool cargandoMas;

  @override
  Widget build(BuildContext context) {
    final items = estado.rolesFiltrados;

    if (items.isEmpty) {
      return Center(
        child: Text(
          'No hay roles',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ColoresApp.textoTerciario,
              ),
        ),
      );
    }

    Widget pieDeLista() {
      if (cargandoMas) {
        return const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Center(
            child: CircularProgressIndicator(color: ColoresApp.acento),
          ),
        );
      }
      if (estado.hayMas) {
        return TextButton.icon(
          onPressed: () => context.read<RolesCubit>().cargarMas(),
          icon: const Icon(Icons.expand_more_rounded),
          label: const Text('Cargar más'),
        );
      }
      return const SizedBox.shrink();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Text(
          'ROLES DEL SISTEMA',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: ColoresApp.textoTerciario,
                letterSpacing: 0.8,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 12),
        ...items.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _TarjetaRol(
              rol: r,
              cantidadUsuarios: estado.conteoUsuarios[r.id] ?? 0,
            ),
          ),
        ),
        pieDeLista(),
      ],
    );
  }
}

// ─── Tarjeta de rol ───────────────────────────────────────────────────────────

class _TarjetaRol extends StatelessWidget {
  const _TarjetaRol({required this.rol, required this.cantidadUsuarios});

  final Rol rol;
  final int cantidadUsuarios;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: ColoresApp.superficiePrimaria,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: ColoresApp.sombraTarjeta,
            blurRadius: 8,
            offset: Offset(0, 2),
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
                  rol.nombre,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ColoresApp.textoPrimario,
                        fontSize: 16,
                      ),
                ),
                if (rol.descripcion.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    rol.descripcion,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ColoresApp.textoSecundario,
                          fontSize: 13,
                        ),
                  ),
                ],
                const SizedBox(height: 6),
                _ContadorUsuarios(cantidad: cantidadUsuarios),
              ],
            ),
          ),
          const SizedBox(width: 12),
          rol.esSistema
              ? const _InsigniaSistema()
              : _BotonEditar(
                  alPresionar: () async {
                    await context.push(Rutas.editarRolUrl(rol.id));
                    if (context.mounted)
                      unawaited(context.read<RolesCubit>().cargarRoles());
                  },
                ),
        ],
      ),
    );
  }
}

// ─── Insignia "Sistema" ───────────────────────────────────────────────────────

class _InsigniaSistema extends StatelessWidget {
  const _InsigniaSistema();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: ColoresApp.rojoClaro,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: ColoresApp.bordeError),
      ),
      child: const Text(
        'Sistema',
        style: TextStyle(
          color: ColoresApp.rojo,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
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
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: alPresionar,
        borderRadius: BorderRadius.circular(10),
        splashColor: ColoresApp.blanco.withValues(alpha: 0.3),
        highlightColor: ColoresApp.blanco.withValues(alpha: 0.15),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            gradient: ColoresApp.degradadoPrincipal,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'Editar',
            style: TextStyle(
              color: ColoresApp.blanco,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Contador de usuarios asignados ──────────────────────────────────────────

class _ContadorUsuarios extends StatelessWidget {
  const _ContadorUsuarios({required this.cantidad});

  final int cantidad;

  @override
  Widget build(BuildContext context) {
    final texto = cantidad == 0
        ? 'Sin usuarios asignados'
        : 'Asignado a $cantidad ${cantidad == 1 ? "usuario" : "usuarios"}';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.people_outline_rounded,
          size: 13,
          color: ColoresApp.textoTerciario,
        ),
        const SizedBox(width: 4),
        Text(
          texto,
          style: const TextStyle(
            color: ColoresApp.textoTerciario,
            fontSize: 12,
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
              onPressed: () => context.read<RolesCubit>().cargarRoles(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
