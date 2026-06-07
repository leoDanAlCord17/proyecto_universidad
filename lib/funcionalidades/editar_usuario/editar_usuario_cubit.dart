import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/errores.dart';
import '../../compartido/logger.dart';
import 'editar_usuario_estado.dart';
import 'editar_usuario_repositorio.dart';

class EditarUsuarioCubit extends Cubit<EditarUsuarioEstado> {
  EditarUsuarioCubit(this._repositorio) : super(const EditarUsuarioInicial());

  final EditarUsuarioRepositorio _repositorio;

  Future<void> cargar(String usuarioId) async {
    emit(const EditarUsuarioCargando());
    try {
      final data = await _repositorio.obtenerUsuario(usuarioId);
      emit(EditarUsuarioCargado(
        usuarioId:                   usuarioId,
        primerNombreInicial:         data['primer_nombre']         as String,
        primerApellidoInicial:       data['primer_apellido']       as String,
        segundoNombreInicial:        data['segundo_nombre']        as String?,
        segundoApellidoInicial:      data['segundo_apellido']      as String?,
        numeroIdentificacionInicial: data['numero_identificacion'] as String?,
        correoInicial:               data['correo']                as String,
        telefonoInicial:             data['telefono']              as String?,
      ),);
    } on FallaServidor catch (e) {
      reportarError(e);
      emit(EditarUsuarioError(mensaje: e.mensaje));
    } on FallaInesperada catch (e) {
      reportarError(e);
      emit(EditarUsuarioError(mensaje: e.mensaje));
    }
  }

  Future<void> guardar({
    required String primerNombre,
    String?         segundoNombre,
    required String primerApellido,
    String?         segundoApellido,
    String?         numeroIdentificacion,
    required String correo,
    String?         telefono,
  }) async {
    final estadoActual = state;
    if (estadoActual is! EditarUsuarioCargado) return;

    if (primerNombre.trim().isEmpty) {
      emit(estadoActual.copiarCon(errorValidacion: 'El primer nombre es requerido.'));
      return;
    }
    if (primerApellido.trim().isEmpty) {
      emit(estadoActual.copiarCon(errorValidacion: 'El primer apellido es requerido.'));
      return;
    }
    if (correo.trim().isEmpty) {
      emit(estadoActual.copiarCon(errorValidacion: 'El correo es requerido.'));
      return;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(correo.trim())) {
      emit(estadoActual.copiarCon(errorValidacion: 'El correo no tiene un formato válido.'));
      return;
    }

    emit(estadoActual.copiarCon(estaGuardando: true, errorValidacion: ''));
    try {
      await _repositorio.actualizarUsuario(
        usuarioId:           estadoActual.usuarioId,
        primerNombre:        primerNombre.trim(),
        segundoNombre:       segundoNombre?.trim(),
        primerApellido:      primerApellido.trim(),
        segundoApellido:     segundoApellido?.trim(),
        numeroIdentificacion: numeroIdentificacion?.trim(),
        correo:              correo.trim(),
        telefono:            telefono?.trim(),
      );
      emit(const EditarUsuarioGuardado());
    } on FallaServidor catch (e) {
      reportarError(e);
      emit(estadoActual.copiarCon(estaGuardando: false, errorValidacion: e.mensaje));
    } on FallaInesperada catch (e) {
      reportarError(e);
      emit(estadoActual.copiarCon(estaGuardando: false, errorValidacion: e.mensaje));
    }
  }
}
