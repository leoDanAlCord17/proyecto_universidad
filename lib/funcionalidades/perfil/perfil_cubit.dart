import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/errores.dart';
import '../autenticacion/usuario.dart';
import 'perfil_estado.dart';
import 'perfil_repositorio.dart';

class PerfilCubit extends Cubit<PerfilEstado> {
  PerfilCubit(this._repositorio) : super(const PerfilInicial());

  final PerfilRepositorio _repositorio;

  /// Carga los tags del usuario y la configuración de edición de perfil.
  Future<void> cargar(String usuarioId) async {
    emit(const PerfilCargando());
    try {
      final tags         = await _repositorio.obtenerTags(usuarioId);
      final puedeEditar  = await _repositorio.obtenerPuedeEditarPerfil();
      if (isClosed) return;
      emit(PerfilCargado(
        tagPrincipal:      tags.tagPrincipal,
        tagsSecundarios:   tags.tagsSecundarios,
        puedeEditarPerfil: puedeEditar,
      ),);
    } on FallaServidor catch (e) {
      if (isClosed) return;
      emit(PerfilError(e.mensaje));
    } on FallaInesperada catch (e) {
      if (isClosed) return;
      emit(PerfilError(e.mensaje));
    }
  }

  /// Guarda los cambios del perfil del usuario.
  /// Emite [PerfilGuardado] al tener éxito — el listener de la pantalla
  /// actualiza el AuthCubit y llama a [volverACargado].
  Future<void> guardarPerfil({
    required Usuario              usuarioActual,
    required Map<String, dynamic> campos,
  }) async {
    final estadoActual = state;
    if (estadoActual is! PerfilCargado) return;

    emit(estadoActual.copiarCon(estaGuardando: true, limpiarError: true));
    try {
      final datos = {
        ...campos,
        'actualizado_por': usuarioActual.id,
        'actualizado_en':  DateTime.now().toUtc().toIso8601String(),
      };
      await _repositorio.actualizarPerfil(
        usuarioId: usuarioActual.id!,
        datos:     datos,
      );

      final usuarioActualizado = Usuario(
        id:                   usuarioActual.id,
        authId:               usuarioActual.authId,
        primerNombre:         campos['primer_nombre']         as String? ?? usuarioActual.primerNombre,
        segundoNombre:        campos['segundo_nombre']        as String?,
        primerApellido:       campos['primer_apellido']       as String? ?? usuarioActual.primerApellido,
        segundoApellido:      campos['segundo_apellido']      as String?,
        numeroIdentificacion: campos['numero_identificacion'] as String?,
        correo:               campos['correo']                as String? ?? usuarioActual.correo,
        telefono:             campos['telefono']              as String?,
        urlAvatar:            usuarioActual.urlAvatar,
        estatus:              usuarioActual.estatus,
        estatusAprobacion:    usuarioActual.estatusAprobacion,
        creadoEn:             usuarioActual.creadoEn,
        roles:                usuarioActual.roles,
        permisos:             usuarioActual.permisos,
      );

      emit(PerfilGuardado(
        usuarioActualizado: usuarioActualizado,
        estadoAnterior:     estadoActual.copiarCon(estaGuardando: false),
      ),);
    } on FallaServidor catch (e) {
      emit(estadoActual.copiarCon(estaGuardando: false, limpiarError: true));
      emit((state as PerfilCargado).copiarCon(errorGuardado: e.mensaje));
    } on FallaInesperada catch (e) {
      emit(estadoActual.copiarCon(estaGuardando: false, limpiarError: true));
      emit((state as PerfilCargado).copiarCon(errorGuardado: e.mensaje));
    }
  }

  /// Regresa al estado cargado después de que [PerfilGuardado] fue procesado.
  void volverACargado(PerfilCargado estado) => emit(estado);
}
