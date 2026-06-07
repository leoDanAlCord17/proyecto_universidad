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
    required this.hayMas,
    this.usuarioIdProcessando,
    this.errorOperacion,
  });

  final List<RevisionUsuarioItem> usuarios;
  final bool                      hayMas;
  final String?                   usuarioIdProcessando;
  final String?                   errorOperacion;

  RevisionUsuariosCargados copiarCon({
    List<RevisionUsuarioItem>? usuarios,
    bool?                      hayMas,
    String?                    usuarioIdProcessando,
    bool                       limpiarProcessando = false,
    String?                    errorOperacion,
    bool                       limpiarError       = false,
  }) =>
      RevisionUsuariosCargados(
        usuarios:             usuarios ?? this.usuarios,
        hayMas:               hayMas   ?? this.hayMas,
        usuarioIdProcessando: limpiarProcessando
            ? null
            : (usuarioIdProcessando ?? this.usuarioIdProcessando),
        errorOperacion: limpiarError
            ? null
            : (errorOperacion ?? this.errorOperacion),
      );

  @override
  List<Object?> get props => [usuarios, hayMas, usuarioIdProcessando, errorOperacion];
}

/// La lista ya muestra resultados y se está cargando la siguiente página.
final class RevisionUsuariosCargandoMas extends RevisionUsuariosEstado {
  const RevisionUsuariosCargandoMas({required this.usuarios});

  final List<RevisionUsuarioItem> usuarios;

  @override
  List<Object?> get props => [usuarios];
}

final class RevisionUsuariosError extends RevisionUsuariosEstado {
  const RevisionUsuariosError(this.mensaje);

  final String mensaje;

  @override
  List<Object?> get props => [mensaje];
}
