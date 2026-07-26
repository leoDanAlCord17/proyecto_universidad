/// Validadores de formulario reutilizables en toda la app.
///
/// Antes había 4 expresiones regulares de correo distintas e inconsistentes
/// dispersas en `login_cubit.dart`, `registro_cubit.dart`,
/// `editar_usuario_cubit.dart`, `recuperar_contrasena_cubit.dart` y
/// `perfil_pantalla.dart` — algunas sin `$` final, otras sin soporte para
/// dominios con subniveles (`usuario@alumnos.uni.edu.mx`). Esta es ahora la
/// única fuente de verdad.
class Validadores {
  Validadores._();

  static final RegExp _regexCorreo = RegExp(
    r'^[\w.+\-]+@[a-zA-Z0-9\-]+(\.[a-zA-Z0-9\-]+)*\.[a-zA-Z]{2,}$',
  );

  /// true si [correo] tiene un formato de correo válido.
  /// Recorta espacios antes de validar.
  static bool esCorreoValido(String correo) =>
      _regexCorreo.hasMatch(correo.trim());

  /// Validador listo para `TextFormField.validator` u otros campos de
  /// formulario: devuelve el mensaje de error o `null` si es válido.
  static String? validarCorreo(
    String? valor, {
    String mensajeVacio = 'El correo es obligatorio.',
    String mensajeInvalido = 'Ingresa un correo con formato válido.',
  }) {
    final v = valor?.trim() ?? '';
    if (v.isEmpty) return mensajeVacio;
    if (!esCorreoValido(v)) return mensajeInvalido;
    return null;
  }
}
