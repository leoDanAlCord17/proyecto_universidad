import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uniasist/funcionalidades/autenticacion/auth_cubit.dart';
import 'package:uniasist/funcionalidades/autenticacion/auth_estado.dart';
import 'package:uniasist/funcionalidades/autenticacion/autenticacion_repositorio.dart';
import 'package:uniasist/funcionalidades/autenticacion/login_cubit.dart';
import 'package:uniasist/funcionalidades/autenticacion/login_estado.dart';
import 'package:uniasist/funcionalidades/autenticacion/registro_cubit.dart';
import 'package:uniasist/funcionalidades/autenticacion/registro_estado.dart';
import 'package:uniasist/funcionalidades/autenticacion/usuario.dart';
import 'package:uniasist/funcionalidades/auditoria_evento/auditoria_evento_repositorio.dart';
import 'package:uniasist/funcionalidades/crear_usuario/crear_usuario_cubit.dart';
import 'package:uniasist/funcionalidades/crear_usuario/crear_usuario_estado.dart';
import 'package:uniasist/funcionalidades/escanear_qr/escanear_qr_repositorio.dart';
import 'package:uniasist/funcionalidades/eventos/evento.dart';
import 'package:uniasist/funcionalidades/historial/historial_item.dart';
import 'package:uniasist/funcionalidades/historial/historial_repositorio.dart';
import 'package:uniasist/funcionalidades/notificaciones/notificaciones_repositorio.dart';
import 'package:uniasist/funcionalidades/panel_control_evento/asistente_item.dart';
import 'package:uniasist/funcionalidades/panel_control_evento/panel_control_repositorio.dart';

// ─── Mocks de repositorio ────────────────────────────────────────────────────

class MockAutenticacionRepositorio extends Mock
    implements AutenticacionRepositorio {}

class MockAuditoriaEventoRepositorio extends Mock
    implements AuditoriaEventoRepositorio {}

class MockNotificacionesRepositorio extends Mock
    implements NotificacionesRepositorio {}

class MockHistorialRepositorio extends Mock
    implements HistorialRepositorio {}

class MockEscanearQrRepositorio extends Mock
    implements EscanearQrRepositorio {}

class MockPanelControlRepositorio extends Mock
    implements PanelControlRepositorio {}

class MockSession extends Mock implements Session {}

class MockUser extends Mock implements User {}

class MockAuthResponse extends Mock implements AuthResponse {}

// ─── Mocks de cubits (para tests de widget) ──────────────────────────────────

class MockLoginCubit extends MockCubit<LoginEstado> implements LoginCubit {}

class MockRegistroCubit extends MockCubit<RegistroEstado>
    implements RegistroCubit {}

class MockCrearUsuarioCubit extends MockCubit<CrearUsuarioEstado>
    implements CrearUsuarioCubit {}

class MockAuthCubit extends MockCubit<AuthEstado> implements AuthCubit {}

// ─── Fixtures ────────────────────────────────────────────────────────────────

const usuarioEjemplo = Usuario(
  id:             'user-id-1',
  authId:         'auth-id-1',
  primerNombre:   'Leo',
  primerApellido: 'Alvarez',
  correo:         'leo@uni.edu',
);

final _fechaBase = DateTime.utc(2025, 1, 1);

final eventoEjemplo = Evento(
  id:                      'evento-id-1',
  titulo:                  'Evento de prueba',
  modoRegistro:            'auto',
  estatus:                 'en_curso',
  creadoEn:                _fechaBase,
  actualizadoEn:           _fechaBase,
  permiteQrEvento:         true,
  permiteQrUsuario:        true,
  permiteManualAdmin:      true,
  requiereCicloCompleto:   false,
  permiteSalidaAnticipada: false,
  marcarAusentesAuto:      false,
  permiteForaneos:         false,
);

const historialItemEjemplo = HistorialItem(
  id:           'historial-id-1',
  eventoId:     'evento-id-1',
  eventoTitulo: 'Charla de Flutter',
  estatus:      'presente',
);

const asistenteEjemplo = AsistenteItem(
  id:          'asistencia-id-1',
  usuarioId:   'user-id-1',
  nombre:      'Leo Alvarez',
  iniciales:   'LA',
  estatus:     'presente',
  esForaneo:   false,
  eraEsperado: false,
);

/// Registra los tipos personalizados necesarios para que any() funcione
/// con argumentos de esos tipos en mocktail.
void registrarFallbacks() {
  registerFallbackValue(usuarioEjemplo);
}

// ─── Helpers de widget ───────────────────────────────────────────────────────

/// Envuelve un widget aislado en un MaterialApp + Scaffold.
Widget enMarcoApp(Widget child) =>
    MaterialApp(home: Scaffold(body: child));

/// Envuelve una pantalla que provee sus propios BlocProviders.
/// Recibe la lista de providers y el widget hijo.
Widget enMarcoPantalla({
  required List<BlocProvider> providers,
  required Widget child,
}) =>
    MaterialApp(
      home: MultiBlocProvider(providers: providers, child: child),
    );
