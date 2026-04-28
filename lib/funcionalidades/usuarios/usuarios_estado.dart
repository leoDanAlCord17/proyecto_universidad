import 'package:equatable/equatable.dart';

import 'usuario_item.dart';

sealed class UsuariosEstado extends Equatable {
  const UsuariosEstado();
}

final class UsuariosInicial extends UsuariosEstado {
  const UsuariosInicial();
  @override
  List<Object?> get props => [];
}

final class UsuariosCargando extends UsuariosEstado {
  const UsuariosCargando();
  @override
  List<Object?> get props => [];
}

final class UsuariosCargados extends UsuariosEstado {
  const UsuariosCargados({
    required this.usuarios,
    required this.usuariosFiltrados,
  });

  final List<UsuarioItem> usuarios;
  final List<UsuarioItem> usuariosFiltrados;

  UsuariosCargados copiarCon({List<UsuarioItem>? usuariosFiltrados}) =>
      UsuariosCargados(
        usuarios:          usuarios,
        usuariosFiltrados: usuariosFiltrados ?? this.usuariosFiltrados,
      );

  @override
  List<Object?> get props => [usuarios, usuariosFiltrados];
}

final class UsuariosError extends UsuariosEstado {
  const UsuariosError({required this.mensaje});

  final String mensaje;

  @override
  List<Object?> get props => [mensaje];
}

final class UsuariosOperacionFallida extends UsuariosEstado {
  const UsuariosOperacionFallida({
    required this.anterior,
    required this.mensaje,
  });

  final UsuariosCargados anterior;
  final String           mensaje;

  @override
  List<Object?> get props => [anterior, mensaje];
}
