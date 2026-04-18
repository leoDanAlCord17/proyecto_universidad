import 'package:flutter_bloc/flutter_bloc.dart';
import 'inicio_estado.dart';

class InicioCubit extends Cubit<InicioEstado> {
  InicioCubit() : super(InicioInicial());
}
