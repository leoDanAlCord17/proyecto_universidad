import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../constantes.dart';
import '../../../configuracion/colores_app.dart';
import '../../../funcionalidades/inicio/evento_en_curso.dart';
import '../../../funcionalidades/inicio/eventos_en_curso_cubit.dart';
import '../dialogo/modal_foraneo.dart';
import '../dialogo/modal_qr_evento.dart';

class TarjetaEventoEnCurso extends StatelessWidget {
  const TarjetaEventoEnCurso({super.key, required this.eventoEnCurso});

  final EventoEnCurso eventoEnCurso;

  @override
  Widget build(BuildContext context) {
    final e      = eventoEnCurso;
    final titulo = e.lugar != null ? '${e.titulo} · ${e.lugar}' : e.titulo;

    return Container(
      decoration: BoxDecoration(
        color:        ColoresApp.acentoClaro,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColoresApp.acentoBorde, width: 1),
        boxShadow: const [
          BoxShadow(
            color:      Color(0x1A5B3FD4),
            blurRadius: 16,
            offset:     Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _ChipEnCurso(),
                      if (e.rangoHorario.isNotEmpty)
                        Text(
                          e.rangoHorario,
                          style: const TextStyle(
                            fontSize:   13,
                            fontWeight: FontWeight.w500,
                            color:      ColoresApp.textoTerciario,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize:   20,
                      fontWeight: FontWeight.w800,
                 
                      height:     1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ContadorPresentes(
                    presentes:   e.totalPresentes,
                    registrados: e.totalRegistrados,
                  ),
                ],
              ),
            ),
            _BarraProgreso(valor: e.progreso),
            const SizedBox(height: 14),
            _FilaBotones(eventoEnCurso: e),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Chip "En curso" ──────────────────────────────────────────────────────────

class _ChipEnCurso extends StatelessWidget {
  const _ChipEnCurso();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color:        ColoresApp.verdeClaro,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'En curso',
        style: TextStyle(
          fontSize:   12,
          fontWeight: FontWeight.w700,
          color:      ColoresApp.verde,
        ),
      ),
    );
  }
}

// ─── Contador de presentes ────────────────────────────────────────────────────

class _ContadorPresentes extends StatelessWidget {
  const _ContadorPresentes({
    required this.presentes,
    required this.registrados,
  });

  final int presentes;
  final int registrados;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width:  9,
          height: 9,
          decoration: const BoxDecoration(
            color: ColoresApp.verde,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 7),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$presentes / $registrados ',
                style: const TextStyle(
                  fontSize:   14,
                  fontWeight: FontWeight.w700,
                  color:      ColoresApp.verde,
                ),
              ),
              const TextSpan(
                text: 'presentes',
                style: TextStyle(
                  fontSize:   14,
                  fontWeight: FontWeight.w500,
                  color:      ColoresApp.textoSecundario,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Barra de progreso ────────────────────────────────────────────────────────

class _BarraProgreso extends StatelessWidget {
  const _BarraProgreso({required this.valor});

  final double valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          height: 6,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: ColoresApp.superficieTerciar),
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: valor.clamp(0.0, 1.0),
                child: const ColoredBox(color: ColoresApp.verde),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Fila de botones scrollable ───────────────────────────────────────────────

class _FilaBotones extends StatelessWidget {
  const _FilaBotones({required this.eventoEnCurso});

  final EventoEnCurso eventoEnCurso;

  List<_DatoBoton> _botones(BuildContext context) {
    final id = eventoEnCurso.id;
    final e  = eventoEnCurso;
    return [
      if (e.permiteQrUsuario)
        _DatoBoton('Escanear\n QR', () => context.push(Rutas.escanear)),
      if (e.permiteQrEvento)
        _DatoBoton('QR \nevento', () => ModalQrEvento.mostrar(context, eventoId: id, horaFin: e.horaFin)),
      if (e.permiteForaneos)
        _DatoBoton('Usuario\nforáneo', () => ModalForaneo.mostrar(
          context,
          onRegistrar: ({required primerNombre, required primerApellido, required cedula, contacto}) =>
              context.read<EventosEnCursoCubit>().registrarForaneo(
                eventoId:       id,
                primerNombre:   primerNombre,
                primerApellido: primerApellido,
                cedula:         cedula,
                contacto:       contacto,
              ),
        )),
      _DatoBoton('Buscar\nusuario', () => context.push(Rutas.buscarAsistenteUrl(id))),
      _DatoBoton('Detalles', () => context.push(Rutas.panelControlUrl(id))),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final botones = _botones(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (int i = 0; i < botones.length; i++) ...[
              _BotonAccion(dato: botones[i]),
              if (i < botones.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _DatoBoton {
  const _DatoBoton(this.texto, this.accion);
  final String       texto;
  final VoidCallback accion;
}

class _BotonAccion extends StatelessWidget {
  const _BotonAccion({required this.dato});

  final _DatoBoton dato;

  @override
  Widget build(BuildContext context) {
    return Material(
      color:        ColoresApp.acento,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap:          dato.accion,
        borderRadius:   BorderRadius.circular(12),
        splashColor:    Colors.white.withValues(alpha: 0.25),
        highlightColor: Colors.white.withValues(alpha: 0.1),
        child: SizedBox(
          width:  88,
          height: 58,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                dato.texto,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color:      Colors.white,
                  fontSize:   12,
                  fontWeight: FontWeight.w600,
                  height:     1.35,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
