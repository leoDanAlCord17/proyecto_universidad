import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/widgets/botones/boton_regresar.dart';
import '../../compartido/widgets/formularios/barra_busqueda_app.dart';
import '../../compartido/widgets/navegacion/barra_superior_app.dart';
import '../../configuracion/colores_app.dart';
import '../autenticacion/auth_cubit.dart';
import '../autenticacion/auth_estado.dart';
import 'colaborador_item.dart';
import 'colaboradores_evento_cubit.dart';
import 'colaboradores_evento_estado.dart';

class ColaboradoresEventoPantalla extends StatefulWidget {
  const ColaboradoresEventoPantalla({super.key, required this.eventoId});

  final String eventoId;

  @override
  State<ColaboradoresEventoPantalla> createState() => _ColaboradoresEventoPantallaState();
}

class _ColaboradoresEventoPantallaState extends State<ColaboradoresEventoPantalla> {
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
    context.read<ColaboradoresEventoCubit>().iniciar(widget.eventoId, adminId: adminId);
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
      () => context.read<ColaboradoresEventoCubit>().buscar(valor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ColaboradoresEventoCubit, ColaboradoresEventoEstado>(
      listener: _escucharEstado,
      builder:  _construirCuerpo,
    );
  }

  void _escucharEstado(BuildContext context, ColaboradoresEventoEstado estado) {
    if (estado is ColaboradoresEventoOperacionFallida) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(estado.mensaje)));
    }
  }

  Widget _construirCuerpo(BuildContext context, ColaboradoresEventoEstado estado) {
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
            const SafeArea(
              bottom: false,
              child: BarraSuperiorApp(izquierda: _CabeceraTitulo()),
            ),
            _construirBarra(),
            Expanded(child: _construirContenido(estado)),
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
        hintText:    'Buscar usuario para agregar...',
        alCambiar:   _onBusqueda,
      ),
    );
  }

  Widget _construirContenido(ColaboradoresEventoEstado estado) => switch (estado) {
    ColaboradoresEventoInicial()          => const SizedBox.shrink(),
    ColaboradoresEventoCargando()         => const Center(
        child: CircularProgressIndicator(color: ColoresApp.acento),
      ),
    ColaboradoresEventoCargado()          => _Contenido(estado: estado),
    ColaboradoresEventoOperacionFallida() => _Contenido(estado: estado.anterior),
    ColaboradoresEventoError()            => _VistaError(mensaje: estado.mensaje),
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
          'Colaboradores',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontSize:   20,
            fontWeight: FontWeight.w700,
            color:      ColoresApp.textoPrimario,
          ),
        ),
      ],
    );
  }
}

// ─── Contenido principal ─────────────────────────────────────────────────────

class _Contenido extends StatelessWidget {
  const _Contenido({required this.estado});
  final ColaboradoresEventoCargado estado;

  @override
  Widget build(BuildContext context) {
    final tieneResultados = estado.busqueda.trim().length >= 2;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        const _EncabezadoSeccion(titulo: 'COLABORADORES ACTUALES'),
        const SizedBox(height: 12),
        if (estado.colaboradores.isEmpty)
          const _EstadoSinColaboradores()
        else
          ...estado.colaboradores.map(
            (colaborador) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ItemColaborador(item: colaborador, estado: estado),
            ),
          ),
        if (tieneResultados) ...[
          const SizedBox(height: 28),
          const _EncabezadoSeccion(titulo: 'AGREGAR COLABORADOR'),
          const SizedBox(height: 12),
          if (estado.resultadosBusqueda.isEmpty)
            const _EstadoSinResultados()
          else
            ...estado.resultadosBusqueda.map(
              (usuario) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ItemBusqueda(usuario: usuario, estado: estado),
              ),
            ),
        ],
      ],
    );
  }
}

// ─── Ítem de colaborador asignado ────────────────────────────────────────────

class _ItemColaborador extends StatelessWidget {
  const _ItemColaborador({required this.item, required this.estado});

  final ColaboradorItem            item;
  final ColaboradoresEventoCargado estado;

  @override
  Widget build(BuildContext context) {
    final cubit      = context.read<ColaboradoresEventoCubit>();
    final esCargando = estado.idOperando == item.asignacionId;
    return Container(
      decoration: BoxDecoration(
        color:        ColoresApp.superficiePrimaria,
        border:       Border.all(color: ColoresApp.bordeMedio),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          _Avatar(iniciales: item.iniciales, urlFoto: item.urlFoto),
          const SizedBox(width: 12),
          Expanded(
            child: _InfoUsuario(
              nombre: item.nombre,
              detalle: item.numeroIdentificacion,
              asignadoPor: item.asignadoPorNombre,
            ),
          ),
          const SizedBox(width: 8),
          _BotonAccion(
            texto:       'Quitar',
            colorFondo:  ColoresApp.rojoClaro,
            colorTexto:  ColoresApp.rojo,
            colorRipple: ColoresApp.rojo,
            esCargando:  esCargando,
            alPresionar: esCargando ? null : () => cubit.quitar(item),
          ),
        ],
      ),
    );
  }
}

// ─── Ítem de resultado de búsqueda ───────────────────────────────────────────

class _ItemBusqueda extends StatelessWidget {
  const _ItemBusqueda({required this.usuario, required this.estado});

  final UsuarioParaAsignar         usuario;
  final ColaboradoresEventoCargado estado;

  @override
  Widget build(BuildContext context) {
    final cubit      = context.read<ColaboradoresEventoCubit>();
    final esCargando = estado.idOperando == usuario.id;
    return Container(
      decoration: BoxDecoration(
        color:        ColoresApp.superficiePrimaria,
        border:       Border.all(color: ColoresApp.bordeMedio),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          _Avatar(iniciales: usuario.iniciales, urlFoto: usuario.urlFoto),
          const SizedBox(width: 12),
          Expanded(
            child: _InfoUsuario(
              nombre: usuario.nombre,
              detalle: usuario.numeroIdentificacion,
            ),
          ),
          const SizedBox(width: 8),
          _BotonAccion(
            texto:       'Agregar',
            colorFondo:  ColoresApp.acentoClaro,
            colorTexto:  ColoresApp.acento,
            colorRipple: ColoresApp.acento,
            esCargando:  esCargando,
            alPresionar: esCargando ? null : () => cubit.asignar(usuario),
          ),
        ],
      ),
    );
  }
}

// ─── Componentes compartidos ─────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({required this.iniciales, this.urlFoto});
  final String  iniciales;
  final String? urlFoto;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius:          20,
      backgroundColor: ColoresApp.acentoClaro,
      backgroundImage: urlFoto != null ? NetworkImage(urlFoto!) : null,
      child: urlFoto == null
          ? Text(
              iniciales,
              style: const TextStyle(
                fontSize:   13,
                fontWeight: FontWeight.w700,
                color:      ColoresApp.acento,
              ),
            )
          : null,
    );
  }
}

class _InfoUsuario extends StatelessWidget {
  const _InfoUsuario({required this.nombre, this.detalle, this.asignadoPor});
  final String  nombre;
  final String? detalle;
  final String? asignadoPor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize:       MainAxisSize.min,
      children: [
        Text(
          nombre,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        if (detalle != null)
          Text(
            detalle!,
            style: const TextStyle(
              fontSize: 12,
              color:    ColoresApp.textoSecundario,
            ),
          ),
        if (asignadoPor != null)
          Text(
            'Registrado por: $asignadoPor',
            style: const TextStyle(
              fontSize: 11,
              color:    ColoresApp.textoTerciario,
            ),
          ),
      ],
    );
  }
}

class _BotonAccion extends StatelessWidget {
  const _BotonAccion({
    required this.texto,
    required this.colorFondo,
    required this.colorTexto,
    required this.colorRipple,
    required this.esCargando,
    this.alPresionar,
  });

  final String        texto;
  final Color         colorFondo;
  final Color         colorTexto;
  final Color         colorRipple;
  final bool          esCargando;
  final VoidCallback? alPresionar;

  @override
  Widget build(BuildContext context) {
    if (esCargando) {
      return SizedBox(
        width:  20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: colorTexto),
      );
    }
    return Material(
      color:        colorFondo,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap:        alPresionar,
        borderRadius: BorderRadius.circular(8),
        splashColor:  colorRipple.withValues(alpha: 0.2),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            texto,
            style: TextStyle(
              fontSize:   12,
              fontWeight: FontWeight.w600,
              color:      colorTexto,
            ),
          ),
        ),
      ),
    );
  }
}

class _EncabezadoSeccion extends StatelessWidget {
  const _EncabezadoSeccion({required this.titulo});
  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Text(
      titulo,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color:         ColoresApp.textoSecundario,
        fontWeight:    FontWeight.w800,
        fontSize:      12,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ─── Estados vacíos / error ───────────────────────────────────────────────────

class _EstadoSinColaboradores extends StatelessWidget {
  const _EstadoSinColaboradores();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        'Este evento aún no tiene colaboradores asignados.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: ColoresApp.textoTerciario,
        ),
      ),
    );
  }
}

class _EstadoSinResultados extends StatelessWidget {
  const _EstadoSinResultados();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        'Sin resultados.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: ColoresApp.textoTerciario,
        ),
      ),
    );
  }
}

class _VistaError extends StatelessWidget {
  const _VistaError({required this.mensaje});
  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          mensaje,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: ColoresApp.rojo,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
