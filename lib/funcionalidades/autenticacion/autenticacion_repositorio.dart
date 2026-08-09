import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/reintento.dart';
import '../../compartido/traductor_errores.dart';
import 'usuario.dart';

class AutenticacionRepositorio {
  AutenticacionRepositorio(this._supabase);
  final SupabaseClient _supabase;

  /// Inicia sesión con cédula (número de identificación) y contraseña.
  /// Supabase Auth solo autentica por correo, así que primero resuelve la
  /// cédula al correo real registrado vía la función de base de datos
  /// `obtener_correo_por_cedula` (SECURITY DEFINER — no expone el resto del
  /// perfil, solo el correo, y es la única forma de hacer esa búsqueda sin
  /// sesión activa dado que la tabla `usuarios` no permite SELECT anónimo).
  ///
  /// Lanza [FallaAutenticacion] con el mismo mensaje genérico tanto si la
  /// cédula no existe como si la contraseña es incorrecta, para no revelar
  /// si una cédula está registrada en el sistema.
  ///
  /// Un 429 (demasiados intentos) o 500 de Supabase Auth es transitorio —
  /// se relanza como [FallaRed] para que [conReintentos] lo reintente una
  /// vez con backoff, en vez de fallarle al usuario en un pico momentáneo
  /// del servicio. Credenciales inválidas (400/422) no se reintentan: con
  /// la misma cédula/clave el resultado sería idéntico.
  Future<AuthResponse> iniciarSesion(String cedula, String clave) =>
      conReintentos(() async {
        try {
          final correo = await _resolverCorreoPorCedula(cedula);

          if (correo == null) {
            throw const FallaAutenticacion('Cédula o contraseña incorrectos.');
          }

          return await _supabase.auth
              .signInWithPassword(
                email: correo,
                password: clave,
              )
              .timeout(kTimeoutSolicitud);
        } on AuthException catch (e) {
          if (e.statusCode == '429' || e.statusCode == '500') {
            throw FallaRed(TraductorErrores.deAuth(e));
          }
          throw FallaAutenticacion(TraductorErrores.deAuth(e));
        } on FallaAutenticacion {
          rethrow;
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Resuelve una cédula (número de identificación) al correo real
  /// registrado en Supabase Auth, vía la función `obtener_correo_por_cedula`
  /// (SECURITY DEFINER — solo devuelve el correo, nada más del perfil, y es
  /// la única forma de hacer esta búsqueda sin sesión activa dado que la
  /// tabla `usuarios` no permite SELECT anónimo). Retorna `null` si la
  /// cédula no está registrada.
  Future<String?> _resolverCorreoPorCedula(String cedula) async {
    final resultado = await _supabase.rpc('obtener_correo_por_cedula',
        params: {'p_cedula': cedula}).timeout(kTimeoutSolicitud);
    return resultado as String?;
  }

  /// Resuelve una cédula al correo registrado y lo retorna parcialmente
  /// censurado (ej. "l***z@g***.com"), para mostrarlo como vista previa en
  /// la pantalla de recuperar contraseña antes de enviar. Retorna `null` si
  /// la cédula no existe.
  ///
  /// Nota de seguridad: a diferencia de [iniciarSesion] y
  /// [enviarCorreoRecuperacion], que deliberadamente no revelan si una
  /// cédula existe, este método SÍ lo hace — es una decisión de producto
  /// explícita (mismo trade-off que usan Google/GitHub al mostrar un hint
  /// del correo antes de confirmar el envío).
  Future<String?> obtenerCorreoEnmascarado(String cedula) async {
    final correo = await _resolverCorreoPorCedula(cedula);
    if (correo == null) return null;
    return _enmascararCorreo(correo);
  }

  String _enmascararCorreo(String correo) {
    final arroba = correo.indexOf('@');
    if (arroba <= 0) return correo;
    final local = correo.substring(0, arroba);
    final dominio = correo.substring(arroba + 1);
    final punto = dominio.lastIndexOf('.');
    final nombreDominio = punto > 0 ? dominio.substring(0, punto) : dominio;
    final extension = punto > 0 ? dominio.substring(punto) : '';
    final localOculto = '${local[0]}***';
    final dominioOculto =
        nombreDominio.isEmpty ? '***' : '${nombreDominio[0]}***';
    return '$localOculto@$dominioOculto$extension';
  }

  /// Registra un nuevo usuario en Supabase Auth.
  /// Lanza [FallaAutenticacion] si el correo ya está en uso o la clave es inválida.
  Future<AuthResponse> registrarse(String correo, String clave) async {
    try {
      return await _supabase.auth
          .signUp(
            email: correo,
            password: clave,
          )
          .timeout(kTimeoutSolicitud);
    } on AuthException catch (e) {
      throw FallaAutenticacion(TraductorErrores.deAuth(e));
    } catch (e) {
      TraductorErrores.lanzarInesperado(e);
    }
  }

  /// Retorna la sesión activa actual, o null si no hay sesión.
  Session? obtenerSesionActual() => _supabase.auth.currentSession;

  /// Cierra la sesión del usuario actual.
  /// Lanza [FallaInesperada] si ocurre un error al cerrar sesión.
  Future<void> cerrarSesion() async {
    try {
      await _supabase.auth.signOut().timeout(kTimeoutSolicitud);
    } catch (e) {
      TraductorErrores.lanzarInesperado(e);
    }
  }

  /// Obtiene el perfil del usuario junto con sus roles y permisos activos.
  /// Retorna [null] si el usuario aún no tiene perfil creado (registro incompleto).
  /// Lanza [FallaServidor] para cualquier otro error de base de datos.
  Future<Usuario?> obtenerPerfil(String idAuth) => conReintentos(() async {
        try {
          final datos = await _supabase
              .from(TablasSupabase.usuarios)
              .select(
                '*, usuarios_roles!usuarios_roles_usuario_id_fkey(estatus, roles(nombre, estatus, roles_permisos(estatus, permisos(nombre))))',
              )
              .eq('auth_id', idAuth)
              .single()
              .timeout(kTimeoutSolicitud);

          return Usuario.desdeJson(datos);
        } on PostgrestException catch (e) {
          if (e.code == 'PGRST116') return null; // perfil no creado aún
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Envía un correo con enlace para restablecer la contraseña, a partir de
  /// la cédula del usuario (resuelta internamente al correo real — ver
  /// [_resolverCorreoPorCedula]). Siempre retorna éxito aunque la cédula no
  /// exista, por el mismo motivo de seguridad por el que Supabase tampoco
  /// revela si un correo existe: no da pistas de qué cédulas están
  /// registradas.
  Future<void> enviarCorreoRecuperacion(String cedula) async {
    try {
      final correo = await _resolverCorreoPorCedula(cedula);
      if (correo == null) return;

      // Uri.base.origin resuelve al origen real desde el que corre la PWA
      // (localhost en desarrollo, el dominio de Vercel en producción) — así
      // el enlace del correo siempre apunta a donde el usuario realmente
      // está, sin hardcodear un dominio. El esquema móvil anterior
      // ('com.activiti.activiti://...') no aplica: esta app corre como PWA
      // web, no hay un app nativo registrado que lo intercepte.
      await _supabase.auth
          .resetPasswordForEmail(
            correo,
            redirectTo: Uri.base.origin,
          )
          .timeout(kTimeoutSolicitud);
    } on AuthException catch (e) {
      throw FallaAutenticacion(TraductorErrores.deAuth(e));
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      TraductorErrores.lanzarInesperado(e);
    }
  }

  /// Actualiza la contraseña del usuario autenticado con sesión de recuperación.
  /// Lanza [FallaAutenticacion] si la sesión expiró o la clave es inválida.
  Future<void> actualizarContrasena(String nuevaClave) async {
    try {
      await _supabase.auth
          .updateUser(UserAttributes(password: nuevaClave))
          .timeout(kTimeoutSolicitud);
    } on AuthException catch (e) {
      throw FallaAutenticacion(TraductorErrores.deAuth(e));
    } catch (e) {
      TraductorErrores.lanzarInesperado(e);
    }
  }

  /// Stream que emite un evento cuando Supabase detecta una sesión de recuperación de contraseña.
  Stream<bool> flujoRecuperacionContrasena() => _supabase.auth.onAuthStateChange
      .where((data) => data.event == AuthChangeEvent.passwordRecovery)
      .map((_) => true);

  /// Registra o actualiza el token de sesión activa del usuario.
  Future<void> actualizarTokenSesion(String usuarioId, String token) async {
    try {
      await _supabase.from(TablasSupabase.sesionesActivas).upsert(
          {'usuario_id': usuarioId, 'token': token},
          onConflict: 'usuario_id');
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      TraductorErrores.lanzarInesperado(e);
    }
  }

  /// Stream que emite el token de sesión activo. Detecta inicio de sesión en otro dispositivo.
  Stream<String?> flujoTokenSesion(String usuarioId) => _supabase
      .from(TablasSupabase.sesionesActivas)
      .stream(primaryKey: ['usuario_id'])
      .eq('usuario_id', usuarioId)
      .map((filas) => filas.isEmpty ? null : filas.first['token'] as String?);

  /// Crea o actualiza el perfil del usuario en la tabla 'usuarios'.
  /// Usa upsert con conflicto en auth_id para soportar el reintento de usuarios rechazados.
  Future<void> crearPerfilUsuario(Usuario usuario) async {
    try {
      await _supabase
          .from(TablasSupabase.usuarios)
          .upsert(usuario.aJson(), onConflict: 'auth_id');
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      TraductorErrores.lanzarInesperado(e);
    }
  }

  /// Retorna true si la revisión de usuarios al crear cuenta está habilitada.
  /// Devuelve false ante cualquier error (comportamiento seguro por defecto).
  Future<bool> verificarRevisionCreacionHabilitada() => conReintentos(() async {
        try {
          final datos = await _supabase
              .from(TablasSupabase.configuracion)
              .select('valor')
              .eq('clave', 'revision_usuario_creacion')
              .eq('estatus', true)
              .single()
              .timeout(kTimeoutSolicitud);
          return (datos['valor'] as int?) == 1;
        } on PostgrestException catch (_) {
          return false;
        } catch (_) {
          return false;
        }
      });
}
