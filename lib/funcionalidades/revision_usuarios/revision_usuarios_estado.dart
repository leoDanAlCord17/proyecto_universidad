import 'package:equatable/equatable.dart';

import 'revision_usuario_item.dart';

sealed class RevisionUsuariosEstado extends Equatable {
  const RevisionUsuariosEstado();
}

final class RevisionUsuariosInicial extends RevisionUsuariosEstado {
  const RevisionUsuariosInicial();
  @override
  List<Object?> get props => [];
}

final class RevisionUsuariosCargando extends RevisionUsuariosEstado {
  const RevisionUsuariosCargando();
  @override
  List<Object?> get props => [];
}

final class RevisionUsuariosCargados extends RevisionUsuariosEstado {
  const RevisionUsuariosCargados({
    required this.usuarios,
    this.usuarioIdProcessando,
    this.errorOperacion,
  });

  final List<RevisionUsuarioItem> usuarios;
  final String?                   usuarioIdProcessando;
  final String?                   errorOperacion;

  RevisionUsuariosCargados copiarCon({
    List<RevisionUsuarioItem>? usuarios,
    String?                    usuarioIdProcessando,
    bool                       limpiarProcessando = false,
    String?                    errorOperacion,
    bool                       limpiarError       = false,
  }) =>
      RevisionUsuariosCargados(
        usuarios:             usuarios ?? this.usuarios,
        usuarioIdProcessando: limpiarProcessando
            ? null
            : (usuarioIdProcessando ?? this.usuarioIdProcessando),
        errorOperacion: limpiarError
            ? null
            : (errorOperacion ?? this.errorOperacion),
      );

  @override
  List<Object?> get props => [usuarios, usuarioIdProcessando, errorOperacion];
}

final class RevisionUsuariosError extends RevisionUsuariosEstado {
  const RevisionUsuariosError(this.mensaje);

  final String mensaje;

  @override
  List<Object?> get props => [mensaje];
}
