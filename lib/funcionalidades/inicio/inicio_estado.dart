import 'package:equatable/equatable.dart';

sealed class InicioEstado extends Equatable {}

final class InicioInicial extends InicioEstado {
  @override
  List<Object?> get props => [];
}
