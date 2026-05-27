import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/errores.dart';
import 'auditoria_evento_estado.dart';
import 'auditoria_evento_modelo.dart';
import 'auditoria_evento_repositorio.dart';

class AuditoriaEventoCubit extends Cubit<AuditoriaEventoEstado> {
  AuditoriaEventoCubit(this._repositorio) : super(const AuditoriaEventoInicial());

  final AuditoriaEventoRepositorio _repositorio;

  List<EventoParaAuditoria> _todosEventos = [];
  List<EventoParaAuditoria> get todosEventos => _todosEventos;

  Future<void> iniciar() async {
    emit(const AuditoriaEventoCargandoLista());
    try {
      _todosEventos = await _repositorio.obtenerEventos();
      emit(const AuditoriaEventoListaCargada());
    } on FallaServidor catch (e) {
      emit(AuditoriaEventoError(e.mensaje));
    } on FallaInesperada catch (e) {
      emit(AuditoriaEventoError(e.mensaje));
    }
  }

  Future<void> seleccionarEvento(EventoParaAuditoria evento) async {
    emit(AuditoriaEventoCargandoAuditoria(eventoSeleccionado: evento));
    try {
      final registros = await _repositorio.obtenerRegistros(evento.id);
      final resumen   = ResumenAuditoria.calcular(registros);
      emit(AuditoriaEventoCargada(
        eventoSeleccionado: evento,
        registros:          registros,
        resumen:            resumen,
      ),);
    } on FallaServidor catch (e) {
      emit(AuditoriaEventoError(e.mensaje));
    } on FallaInesperada catch (e) {
      emit(AuditoriaEventoError(e.mensaje));
    }
  }

  void cambiarFiltro(FiltroParticipantes filtro) {
    final actual = state;
    if (actual is AuditoriaEventoCargada) {
      emit(actual.copiarCon(filtro: filtro));
    }
  }

  void buscarParticipante(String query) {
    final actual = state;
    if (actual is AuditoriaEventoCargada) {
      emit(actual.copiarCon(busquedaParticipante: query));
    }
  }
}
