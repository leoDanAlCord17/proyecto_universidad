import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/logger.dart';
import '../eventos/evento.dart';
import 'escanear_evento_qr_estado.dart';
import 'escanear_evento_qr_repositorio.dart';

class EscanearEventoQrCubit extends Cubit<EscanearEventoQrEstado> {
  EscanearEventoQrCubit(this._repositorio) : super(const EscanearEventoQrListo());

  final EscanearEventoQrRepositorio _repositorio;

  String? _usuarioId;
  bool    _estaProcesando = false;
  Timer?  _timerReset;

  void iniciar({required String usuarioId}) {
    _usuarioId = usuarioId;
  }

  Future<void> procesarQr(String rawValue) async {
    if (_estaProcesando || _usuarioId == null) return;
    if (state is! EscanearEventoQrListo) return;

    _estaProcesando = true;
    emit(const EscanearEventoQrProcesando());
    try {
      await _validarYRegistrar(rawValue);
    } on FallaServidor catch (e) {
      reportarError(e);
      _programarReset();
    } on FallaInesperada catch (e) {
      reportarError(e);
      _programarReset();
    }
  }

  @override
  Future<void> close() {
    _timerReset?.cancel();
    return super.close();
  }

  // ─── Helpers privados ────────────────────────────────────────────────────────

  Future<void> _validarYRegistrar(String rawValue) async {
    final evento = await _obtenerEventoOEmitirNoValido(rawValue);
    if (evento == null) return;

    if (evento.estatus != EstatusEvento.enCurso || !evento.permiteQrUsuario) {
      emit(EscanearEventoQrNoDisponible(eventoNombre: evento.titulo));
      _programarReset();
      return;
    }

    if (evento.alcance == AlcanceEvento.dirigido) {
      final pertenece = await _repositorio.verificarPerteneceAudiencia(rawValue, _usuarioId!);
      if (!pertenece) {
        emit(EscanearEventoQrDirigidoNoPermitido(eventoNombre: evento.titulo));
        _programarReset();
        return;
      }
    }

    final registrado = await _repositorio.registrarEntrada(
      eventoId:  rawValue,
      usuarioId: _usuarioId!,
    );
    if (registrado) {
      emit(EscanearEventoQrConfirmado(eventoNombre: evento.titulo));
    } else {
      emit(EscanearEventoQrYaRegistrado(eventoNombre: evento.titulo));
    }
    _programarReset();
  }

  Future<Evento?> _obtenerEventoOEmitirNoValido(String rawValue) async {
    if (!_repositorio.esUuidValido(rawValue)) {
      emit(const EscanearEventoQrNoValido());
      _programarReset();
      return null;
    }
    final evento = await _repositorio.obtenerEvento(rawValue);
    if (evento == null) {
      emit(const EscanearEventoQrNoValido());
      _programarReset();
      return null;
    }
    return evento;
  }

  void _programarReset() {
    _timerReset?.cancel();
    _timerReset = Timer(const Duration(seconds: 2, milliseconds: 500), () {
      _estaProcesando = false;
      if (!isClosed) emit(const EscanearEventoQrListo());
    });
  }
}
