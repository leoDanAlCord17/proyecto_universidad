import 'package:flutter_bloc/flutter_bloc.dart';

import 'notificaciones_estado.dart';

class NotificacionesCubit extends Cubit<NotificacionesEstado> {
  NotificacionesCubit() : super(const NotificacionesCargadas());
}
