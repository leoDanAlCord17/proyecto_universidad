import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/traductor_errores.dart';
import 'usuario.dart';

class AutenticacionRepositorio {
  final SupabaseClient _supabase;

  AutenticacionRepositorio(this._supabase);

  /// Inicia sesión con correo y contraseña.
  /// Lanza [FallaAutenticacion] si las credenciales son incorrectas.
  Future<AuthResponse> iniciarSesion(String correo, String clave) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: correo,
        password: clave,
      );
    } on AuthException catch (e) {
      throw FallaAutenticacion(TraductorErrores.deAuth(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }

  /// Registra un nuevo usuario en Supabase Auth.
  /// Lanza [FallaAutenticacion] si el correo ya está en uso o la clave es inválida.
  Future<AuthResponse> registrarse(String correo, String clave) async {
    try {
      return await _supabase.auth.signUp(
        email: correo,
        password: clave,
      );
    } on AuthException catch (e) {
      throw FallaAutenticacion(TraductorErrores.deAuth(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }

  /// Retorna la sesión activa actual, o null si no hay sesión.
  Session? obtenerSesionActual() => _supabase.auth.currentSession;

  /// Cierra la sesión del usuario actual.
  /// Lanza [FallaInesperada] si ocurre un error al cerrar sesión.
  Future<void> cerrarSesion() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }

  /// Obtiene el perfil del usuario junto con sus roles y permisos activos.
  /// Retorna [null] si el usuario aún no tiene perfil creado (registro incompleto).
  /// Lanza [FallaServidor] para cualquier otro error de base de datos.
  Future<Usuario?> obtenerPerfil(String idAuth) async {
    try {
      final datos = await _supabase
          .from(TablasSupabase.usuarios)
          .select(
            '*, usuarios_roles!usuarios_roles_usuario_id_fkey(estatus, roles(nombre, estatus, roles_permisos(estatus, permisos(nombre))))',
          )
          .eq('auth_id', idAuth)
          .single();

      return Usuario.desdeJson(datos);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') return null; // perfil no creado aún
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }

  /// Envía un correo con enlace para restablecer la contraseña.
  /// Siempre retorna éxito aunque el correo no exista (por seguridad Supabase no lo revela).
  Future<void> enviarCorreoRecuperacion(String correo) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        correo,
        redirectTo: 'com.uniasist.uniasist://reset-password',
      );
    } on AuthException catch (e) {
      throw FallaAutenticacion(TraductorErrores.deAuth(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }

  /// Actualiza la contraseña del usuario autenticado con sesión de recuperación.
  /// Lanza [FallaAutenticacion] si la sesión expiró o la clave es inválida.
  Future<void> actualizarContrasena(String nuevaClave) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: nuevaClave));
    } on AuthException catch (e) {
      throw FallaAutenticacion(TraductorErrores.deAuth(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }

  /// Stream que emite un evento cuando Supabase detecta una sesión de recuperación de contraseña.
  Stream<bool> flujoRecuperacionContrasena() => _supabase.auth.onAuthStateChange
      .where((data) => data.event == AuthChangeEvent.passwordRecovery)
      .map((_) => true);

  /// Actualiza el token de sesión activa del usuario en la base de datos.
  Future<void> actualizarTokenSesion(String usuarioId, String token) async {
    try {
      await _supabase
          .from(TablasSupabase.usuarios)
          .update({'sesion_token': token})
          .eq('id', usuarioId);
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }

  /// Stream que emite el token de sesión activo. Detecta inicio de sesión en otro dispositivo.
  Stream<String?> flujoTokenSesion(String usuarioId) =>
      _supabase
          .from(TablasSupabase.usuarios)
          .stream(primaryKey: ['id'])
          .eq('id', usuarioId)
          .map((filas) => filas.isEmpty ? null : filas.first['sesion_token'] as String?);

  /// Crea el perfil de un nuevo usuario en la tabla 'usuarios'.
  /// Lanza [FallaServidor] si hay un error al insertar.
  Future<void> crearPerfilUsuario(Usuario usuario) async {
    try {
      await _supabase
          .from(TablasSupabase.usuarios)
          .insert(usuario.aJson());
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }
}
