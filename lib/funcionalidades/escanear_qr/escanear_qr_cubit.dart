import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/logger.dart';
import '../../compartido/notificaciones_push_servicio.dart';
import 'escanear_qr_estado.dart';
import 'escanear_qr_repositorio.dart';

class EscanearQrCubit extends Cubit<EscanearQrEstado> {
  EscanearQrCubit(this._repositorio) : super(const EscanearQrInicial());

  final EscanearQrRepositorio _repositorio;

  String? _eventoId;
  String? _adminId;
  bool _estaProcesando = false;
  Timer? _timerReset;

  Future<void> iniciar(String eventoId, {String? adminId}) async {
    _eventoId = eventoId;
    _adminId = adminId;
    emit(const EscanearQrCargando());
    try {
      final (evento, presentes) = await (
        _repositorio.obtenerEvento(eventoId),
        _repositorio.contarPresentes(eventoId),
      ).wait;
      if (!evento.permiteQrEvento) {
        emit(const EscanearQrErrorCarga(
            mensaje: 'Este evento no permite el escaneo de QR.'));
        return;
      }
      emit(EscanearQrListo(evento: evento, presentes: presentes));
    } on FallaServidor catch (e) {
      reportarError(e);
      emit(EscanearQrErrorCarga(mensaje: e.mensaje));
    } on FallaInesperada catch (e) {
      reportarError(e);
      emit(EscanearQrErrorCarga(mensaje: e.mensaje));
    }
  }

  Future<void> procesarQr(String rawValue) async {
    if (_estaProcesando) return;
    final listo = _extraerListo(state);
    if (listo == null || _eventoId == null) return;

    _estaProcesando = true;
    emit(
        EscanearQrProcesando(evento: listo.evento, presentes: listo.presentes));

    try {
      final usuario = await _repositorio.buscarUsuario(rawValue);
      if (usuario == null) {
        emit(EscanearQrNoValido(
            evento: listo.evento, presentes: listo.presentes));
        _programarReset(listo);
        return;
      }

      final datos = _extraerDatosUsuario(usuario);
      // El QR escaneado puede traer la cédula del carnet físico en vez del
      // UUID nativo (ver NormalizadorQR) — usar siempre el `id` que
      // resolvió el repositorio, nunca el valor crudo del QR, para que
      // asistencia.usuario_id y la notificación push queden con el UUID
      // real del usuario.
      final usuarioId = usuario['id'] as String;
      final registrado = await _repositorio.registrarEntrada(
        eventoId: _eventoId!,
        usuarioId: usuarioId,
        registradoPorId: _adminId,
      );
      _emitirResultado(listo, registrado,
          nombre: datos.nombre, cedula: datos.cedula, rol: datos.rol);

      // N12 — notifica al usuario que su entrada fue registrada
      if (registrado) {
        await NotificacionesPushServicio.enviar(
          usuarioIds: [usuarioId],
          titulo: 'Asistencia registrada',
          cuerpo: 'Tu entrada a "${listo.evento.titulo}" fue registrada.',
          tipo: TiposNotificacion.asistencia,
          entidadId: _eventoId,
          entidadTipo: 'evento',
        );
      }
    } on FallaServidor catch (e) {
      reportarError(e);
      _programarReset(listo);
    } on FallaInesperada catch (e) {
      reportarError(e);
      _programarReset(listo);
    }
  }

  ({String nombre, String? cedula, String? rol}) _extraerDatosUsuario(
    Map<String, dynamic> usuario,
  ) {
    final nombre =
        '${usuario['primer_nombre'] ?? ''} ${usuario['primer_apellido'] ?? ''}'
            .trim();
    final cedula = usuario['numero_identificacion'] as String?;
    final roles = usuario['usuarios_roles'] as List?;
    String? rol;
    if (roles != null && roles.isNotEmpty) {
      final entrada = (roles.first as Map<String, dynamic>)['roles'];
      if (entrada is Map<String, dynamic>) rol = entrada['nombre'] as String?;
    }
    return (nombre: nombre, cedula: cedula, rol: rol);
  }

  void _emitirResultado(
    EscanearQrListo listo,
    bool registrado, {
    required String nombre,
    required String? cedula,
    required String? rol,
  }) {
    if (registrado) {
      emit(
        EscanearQrConfirmado(
          evento: listo.evento,
          presentes: listo.presentes + 1,
          nombre: nombre,
          cedula: cedula,
          rol: rol,
        ),
      );
      _programarReset(listo, nuevosPresentes: listo.presentes + 1);
    } else {
      emit(
        EscanearQrYaRegistrado(
          evento: listo.evento,
          presentes: listo.presentes,
          nombre: nombre,
          cedula: cedula,
        ),
      );
      _programarReset(listo);
    }
  }

  void _programarReset(EscanearQrListo base, {int? nuevosPresentes}) {
    _timerReset?.cancel();
    _timerReset = Timer(const Duration(seconds: 2, milliseconds: 500), () {
      _estaProcesando = false;
      if (!isClosed) {
        emit(
          EscanearQrListo(
            evento: base.evento,
            presentes: nuevosPresentes ?? base.presentes,
          ),
        );
      }
    });
  }

  @override
  Future<void> close() {
    _timerReset?.cancel();
    return super.close();
  }

  EscanearQrListo? _extraerListo(EscanearQrEstado estado) =>
      estado is EscanearQrListo ? estado : null;
}
