import 'package:equatable/equatable.dart';

sealed class EscanearEventoQrEstado extends Equatable {
  const EscanearEventoQrEstado();
  @override
  List<Object?> get props => [];
}

final class EscanearEventoQrListo extends EscanearEventoQrEstado {
  const EscanearEventoQrListo();
}

final class EscanearEventoQrProcesando extends EscanearEventoQrEstado {
  const EscanearEventoQrProcesando();
}

final class EscanearEventoQrConfirmado extends EscanearEventoQrEstado {
  const EscanearEventoQrConfirmado({required this.eventoNombre});
  final String eventoNombre;
  @override
  List<Object?> get props => [eventoNombre];
}

final class EscanearEventoQrYaRegistrado extends EscanearEventoQrEstado {
  const EscanearEventoQrYaRegistrado({required this.eventoNombre});
  final String eventoNombre;
  @override
  List<Object?> get props => [eventoNombre];
}

final class EscanearEventoQrNoDisponible extends EscanearEventoQrEstado {
  const EscanearEventoQrNoDisponible({required this.eventoNombre});
  final String eventoNombre;
  @override
  List<Object?> get props => [eventoNombre];
}

final class EscanearEventoQrDirigidoNoPermitido extends EscanearEventoQrEstado {
  const EscanearEventoQrDirigidoNoPermitido({required this.eventoNombre});
  final String eventoNombre;
  @override
  List<Object?> get props => [eventoNombre];
}

final class EscanearEventoQrNoValido extends EscanearEventoQrEstado {
  const EscanearEventoQrNoValido();
}
