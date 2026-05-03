import 'package:equatable/equatable.dart';

import '../eventos/evento.dart';

sealed class EscanearQrEstado extends Equatable {
  const EscanearQrEstado();
  @override
  List<Object?> get props => [];
}

final class EscanearQrInicial extends EscanearQrEstado {
  const EscanearQrInicial();
}

final class EscanearQrCargando extends EscanearQrEstado {
  const EscanearQrCargando();
}

final class EscanearQrListo extends EscanearQrEstado {
  const EscanearQrListo({required this.evento, required this.presentes});
  final Evento evento;
  final int    presentes;
  @override
  List<Object?> get props => [evento, presentes];
}

final class EscanearQrProcesando extends EscanearQrEstado {
  const EscanearQrProcesando({required this.evento, required this.presentes});
  final Evento evento;
  final int    presentes;
  @override
  List<Object?> get props => [evento, presentes];
}

final class EscanearQrConfirmado extends EscanearQrEstado {
  const EscanearQrConfirmado({
    required this.evento,
    required this.presentes,
    required this.nombre,
    this.cedula,
    this.rol,
  });
  final Evento  evento;
  final int     presentes;
  final String  nombre;
  final String? cedula;
  final String? rol;
  @override
  List<Object?> get props => [evento, presentes, nombre, cedula, rol];
}

final class EscanearQrYaRegistrado extends EscanearQrEstado {
  const EscanearQrYaRegistrado({
    required this.evento,
    required this.presentes,
    required this.nombre,
    this.cedula,
  });
  final Evento  evento;
  final int     presentes;
  final String  nombre;
  final String? cedula;
  @override
  List<Object?> get props => [evento, presentes, nombre, cedula];
}

final class EscanearQrNoValido extends EscanearQrEstado {
  const EscanearQrNoValido({required this.evento, required this.presentes});
  final Evento evento;
  final int    presentes;
  @override
  List<Object?> get props => [evento, presentes];
}

final class EscanearQrErrorCarga extends EscanearQrEstado {
  const EscanearQrErrorCarga({required this.mensaje});
  final String mensaje;
  @override
  List<Object?> get props => [mensaje];
}
