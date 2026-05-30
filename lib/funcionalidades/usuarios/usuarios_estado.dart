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
    this.seleccionados      = const {},
    this.modoSeleccion      = false,
    this.estaEjecutandoLote = false,
    this.errorLote,
  });

  final List<UsuarioItem> usuarios;
  final List<UsuarioItem> usuariosFiltrados;
  final Set<String>       seleccionados;
  final bool              modoSeleccion;
  final bool              estaEjecutandoLote;
  final String?           errorLote;

  UsuariosCargados copiarCon({
    List<UsuarioItem>? usuariosFiltrados,
    Set<String>?       seleccionados,
    bool?              modoSeleccion,
    bool?              estaEjecutandoLote,
    String?            errorLote,
    bool               limpiarError = false,
  }) =>
      UsuariosCargados(
        usuarios:            usuarios,
        usuariosFiltrados:   usuariosFiltrados  ?? this.usuariosFiltrados,
        seleccionados:       seleccionados      ?? this.seleccionados,
        modoSeleccion:       modoSeleccion      ?? this.modoSeleccion,
        estaEjecutandoLote:  estaEjecutandoLote ?? this.estaEjecutandoLote,
        errorLote:           limpiarError ? null : (errorLote ?? this.errorLote),
      );

  @override
  List<Object?> get props => [
    usuarios, usuariosFiltrados, seleccionados,
    modoSeleccion, estaEjecutandoLote, errorLote,
  ];
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
