import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/logger.dart';
import 'eventos_en_curso_estado.dart';
import 'eventos_en_curso_repositorio.dart';

class EventosEnCursoCubit extends Cubit<EventosEnCursoEstado> {
  EventosEnCursoCubit(this._repositorio) : super(const EventosEnCursoInicial());

  final EventosEnCursoRepositorio _repositorio;
  final Map<String, StreamSubscription<List<Map<String, dynamic>>>> _subs = {};

  /// Carga los eventos en curso del usuario y activa un stream por cada uno.
  Future<void> registrarForaneo({
    required String eventoId,
    required String primerNombre,
    required String primerApellido,
    required String cedula,
    String? contacto,
  }) =>
      _repositorio.registrarForaneo(
        eventoId: eventoId,
        primerNombre: primerNombre,
        primerApellido: primerApellido,
        cedula: cedula,
        contacto: contacto,
      );

  Future<void> cargar(String usuarioId) async {
    emit(const EventosEnCursoCargando());
    try {
      final eventos = await _repositorio.obtenerEventosEnCurso(usuarioId);
      if (isClosed) return;
      emit(EventosEnCursoCargado(eventos: eventos));
      for (final e in eventos) {
        _suscribir(e.id);
      }
    } on FallaServidor catch (f) {
      reportarError(f);
      if (!isClosed) emit(EventosEnCursoError(f.mensaje));
    } on FallaInesperada catch (f) {
      reportarError(f);
      if (!isClosed) emit(EventosEnCursoError(f.mensaje));
    }
  }

  void _suscribir(String eventoId) {
    _subs[eventoId]?.cancel();
    _subs[eventoId] = _repositorio
        .streamAsistencia(eventoId)
        .listen((rows) => _actualizarContador(eventoId, rows));
  }

  void _actualizarContador(
    String eventoId,
    List<Map<String, dynamic>> rows,
  ) {
    final estado = state;
    if (estado is! EventosEnCursoCargado) return;
    final indice = estado.eventos.indexWhere((e) => e.id == eventoId);
    if (indice == -1) return;
    final presentes = rows.where((r) {
      final s = r['estatus'] as String? ?? '';
      return s == EstatusAsistencia.presente ||
          s == EstatusAsistencia.completado;
    }).length;
    final esGeneral = estado.eventos[indice].esGeneral;
    final total = esGeneral
        ? 0
        : rows.where((r) => r['estatus'] != EstatusAsistencia.anulado).length;
    final actualizados = estado.eventos.map((e) {
      if (e.id != eventoId) return e;
      return e.copyWith(totalPresentes: presentes, totalRegistrados: total);
    }).toList();
    emit(EventosEnCursoCargado(eventos: actualizados));
  }

  @override
  Future<void> close() {
    for (final sub in _subs.values) {
      sub.cancel();
    }
    _subs.clear();
    return super.close();
  }
}
