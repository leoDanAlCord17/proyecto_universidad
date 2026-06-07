import 'package:equatable/equatable.dart';

sealed class CrearTipoEventoEstado extends Equatable {
  const CrearTipoEventoEstado();
}

final class CrearTipoEventoInicial extends CrearTipoEventoEstado {
  const CrearTipoEventoInicial();
  @override
  List<Object?> get props => [];
}

final class CrearTipoEventoCargando extends CrearTipoEventoEstado {
  const CrearTipoEventoCargando();
  @override
  List<Object?> get props => [];
}

final class CrearTipoEventoCargado extends CrearTipoEventoEstado {
  const CrearTipoEventoCargado({
    this.tipoEventoId,
    this.nombreInicial = '',
    this.descripcionInicial = '',
    this.estaGuardando = false,
  });

  final String? tipoEventoId;
  final String nombreInicial;
  final String descripcionInicial;
  final bool estaGuardando;

  CrearTipoEventoCargado copiarCon({bool? estaGuardando}) =>
      CrearTipoEventoCargado(
        tipoEventoId: tipoEventoId,
        nombreInicial: nombreInicial,
        descripcionInicial: descripcionInicial,
        estaGuardando: estaGuardando ?? this.estaGuardando,
      );

  @override
  List<Object?> get props => [
        tipoEventoId,
        nombreInicial,
        descripcionInicial,
        estaGuardando,
      ];
}

final class CrearTipoEventoGuardado extends CrearTipoEventoEstado {
  const CrearTipoEventoGuardado();
  @override
  List<Object?> get props => [];
}

final class CrearTipoEventoError extends CrearTipoEventoEstado {
  const CrearTipoEventoError({required this.mensaje});

  final String mensaje;

  @override
  List<Object?> get props => [mensaje];
}
