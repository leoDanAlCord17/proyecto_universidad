import 'package:equatable/equatable.dart';

import '../autenticacion/usuario.dart';

sealed class PerfilEstado extends Equatable {
  const PerfilEstado();
}

final class PerfilInicial extends PerfilEstado {
  const PerfilInicial();
  @override
  List<Object?> get props => [];
}

final class PerfilCargando extends PerfilEstado {
  const PerfilCargando();
  @override
  List<Object?> get props => [];
}

final class PerfilCargado extends PerfilEstado {
  const PerfilCargado({
    this.tagPrincipal,
    this.tagsSecundarios = const [],
    this.puedeEditarPerfil = false,
    this.estaGuardando = false,
    this.errorGuardado,
  });

  final String? tagPrincipal;
  final List<String> tagsSecundarios;
  final bool puedeEditarPerfil;
  final bool estaGuardando;
  final String? errorGuardado;

  PerfilCargado copiarCon({
    String? tagPrincipal,
    List<String>? tagsSecundarios,
    bool? puedeEditarPerfil,
    bool? estaGuardando,
    String? errorGuardado,
    bool limpiarError = false,
  }) =>
      PerfilCargado(
        tagPrincipal: tagPrincipal ?? this.tagPrincipal,
        tagsSecundarios: tagsSecundarios ?? this.tagsSecundarios,
        puedeEditarPerfil: puedeEditarPerfil ?? this.puedeEditarPerfil,
        estaGuardando: estaGuardando ?? this.estaGuardando,
        errorGuardado:
            limpiarError ? null : (errorGuardado ?? this.errorGuardado),
      );

  @override
  List<Object?> get props => [
        tagPrincipal,
        tagsSecundarios,
        puedeEditarPerfil,
        estaGuardando,
        errorGuardado,
      ];
}

final class PerfilError extends PerfilEstado {
  const PerfilError(this.mensaje);
  final String mensaje;
  @override
  List<Object?> get props => [mensaje];
}

/// La red falló pero hay tags cacheados disponibles.
/// Editar perfil no está disponible en este estado.
final class PerfilSinConexion extends PerfilEstado {
  const PerfilSinConexion({
    this.tagPrincipal,
    this.tagsSecundarios = const [],
  });

  final String? tagPrincipal;
  final List<String> tagsSecundarios;

  @override
  List<Object?> get props => [tagPrincipal, tagsSecundarios];
}

/// Estado transitorio emitido al guardar con éxito.
/// El BlocListener en la pantalla lo captura para actualizar el AuthCubit
/// y luego llama a [PerfilCubit.volverACargado].
final class PerfilGuardado extends PerfilEstado {
  const PerfilGuardado({
    required this.usuarioActualizado,
    required this.estadoAnterior,
  });

  final Usuario usuarioActualizado;
  final PerfilCargado estadoAnterior;

  @override
  List<Object?> get props => [usuarioActualizado, estadoAnterior];
}
