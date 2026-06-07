import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/errores.dart';
import '../../compartido/logger.dart';
import 'auditoria_evento_estado.dart';
import 'auditoria_evento_modelo.dart';
import 'auditoria_evento_repositorio.dart';

class AuditoriaEventoCubit extends Cubit<AuditoriaEventoEstado> {
  AuditoriaEventoCubit(this._repositorio) : super(const AuditoriaEventoInicial());

  final AuditoriaEventoRepositorio _repositorio;

  List<EventoParaAuditoria> _todosEventos  = [];
  int                       _offsetEventos = 0;
  bool                      _hayMasEventos = false;

  List<EventoParaAuditoria> get todosEventos   => _todosEventos;
  bool                      get hayMasEventos  => _hayMasEventos;

  Future<void> iniciar() async {
    _offsetEventos = 0;
    _todosEventos  = [];
    emit(const AuditoriaEventoCargandoLista());
    try {
      final resultado = await _repositorio.obtenerEventos(offset: 0);
      if (isClosed) return;
      _todosEventos  = resultado.eventos;
      _offsetEventos = resultado.eventos.length;
      _hayMasEventos = resultado.hayMas;
      emit(const AuditoriaEventoListaCargada());
    } on FallaServidor catch (e) {
      if (isClosed) return;
      reportarError(e);
      emit(AuditoriaEventoError(e.mensaje));
    } on FallaRed catch (e) {
      if (isClosed) return;
      reportarError(e);
      emit(AuditoriaEventoError(e.mensaje));
    } on FallaInesperada catch (e) {
      if (isClosed) return;
      reportarError(e);
      emit(AuditoriaEventoError(e.mensaje));
    }
  }

  Future<void> cargarMasEventos() async {
    if (!_hayMasEventos) return;
    try {
      final resultado = await _repositorio.obtenerEventos(offset: _offsetEventos);
      if (isClosed) return;
      _todosEventos   = [..._todosEventos, ...resultado.eventos];
      _offsetEventos += resultado.eventos.length;
      _hayMasEventos  = resultado.hayMas;
    } on FallaServidor catch (_) {
      // La modal resetea el spinner; _hayMasEventos sigue true para reintentar.
    } on FallaRed catch (_) {
      // idem
    } on FallaInesperada catch (_) {
      // idem
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
      reportarError(e);
      emit(AuditoriaEventoError(e.mensaje));
    } on FallaInesperada catch (e) {
      reportarError(e);
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
