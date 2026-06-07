import 'package:equatable/equatable.dart';

import 'tag_item.dart';

sealed class GestionarTagsUsuarioEstado extends Equatable {
  const GestionarTagsUsuarioEstado();
}

final class GestionarTagsUsuarioInicial extends GestionarTagsUsuarioEstado {
  const GestionarTagsUsuarioInicial();
  @override
  List<Object?> get props => [];
}

final class GestionarTagsUsuarioCargando extends GestionarTagsUsuarioEstado {
  const GestionarTagsUsuarioCargando();
  @override
  List<Object?> get props => [];
}

final class GestionarTagsUsuarioCargado extends GestionarTagsUsuarioEstado {
  const GestionarTagsUsuarioCargado({
    required this.nombreUsuario,
    required this.correoUsuario,
    required this.tagPrincipal,
    required this.tagsSecundarios,
    required this.principalesDisponibles,
    required this.secundariosDisponibles,
    required this.maxSecundarios,
  });

  final String nombreUsuario;
  final String correoUsuario;
  final TagItem? tagPrincipal;
  final List<TagItem> tagsSecundarios;
  final List<TagItem> principalesDisponibles;
  final List<TagItem> secundariosDisponibles;
  final int maxSecundarios;

  bool get estaEnLimite => tagsSecundarios.length >= maxSecundarios;

  @override
  List<Object?> get props => [
        nombreUsuario,
        correoUsuario,
        tagPrincipal,
        tagsSecundarios,
        principalesDisponibles,
        secundariosDisponibles,
        maxSecundarios,
      ];
}

final class GestionarTagsUsuarioError extends GestionarTagsUsuarioEstado {
  const GestionarTagsUsuarioError({required this.mensaje});

  final String mensaje;

  @override
  List<Object?> get props => [mensaje];
}

final class GestionarTagsUsuarioOperacionFallida
    extends GestionarTagsUsuarioEstado {
  const GestionarTagsUsuarioOperacionFallida({
    required this.anterior,
    required this.mensaje,
  });

  final GestionarTagsUsuarioCargado anterior;
  final String mensaje;

  @override
  List<Object?> get props => [anterior, mensaje];
}
