import 'package:equatable/equatable.dart';

sealed class CrearTagEstado extends Equatable {
  const CrearTagEstado();
}

final class CrearTagInicial extends CrearTagEstado {
  const CrearTagInicial();
  @override
  List<Object?> get props => [];
}

final class CrearTagCargando extends CrearTagEstado {
  const CrearTagCargando();
  @override
  List<Object?> get props => [];
}

final class CrearTagCargado extends CrearTagEstado {
  const CrearTagCargado({
    this.tagId,
    this.nombreInicial = '',
    this.descripcionInicial = '',
    this.tipoSeleccionado,
    this.estaGuardando = false,
    this.errorValidacion = '',
  });

  final String? tagId;
  final String nombreInicial;
  final String descripcionInicial;
  final String? tipoSeleccionado;
  final bool estaGuardando;
  final String errorValidacion;

  CrearTagCargado copiarCon({
    String? tipoSeleccionado,
    bool? estaGuardando,
    String? errorValidacion,
  }) =>
      CrearTagCargado(
        tagId: tagId,
        nombreInicial: nombreInicial,
        descripcionInicial: descripcionInicial,
        tipoSeleccionado: tipoSeleccionado ?? this.tipoSeleccionado,
        estaGuardando: estaGuardando ?? this.estaGuardando,
        errorValidacion: errorValidacion ?? this.errorValidacion,
      );

  @override
  List<Object?> get props => [
        tagId,
        nombreInicial,
        descripcionInicial,
        tipoSeleccionado,
        estaGuardando,
        errorValidacion,
      ];
}

final class CrearTagGuardado extends CrearTagEstado {
  const CrearTagGuardado();
  @override
  List<Object?> get props => [];
}

final class CrearTagError extends CrearTagEstado {
  const CrearTagError({required this.mensaje});
  final String mensaje;
  @override
  List<Object?> get props => [mensaje];
}
