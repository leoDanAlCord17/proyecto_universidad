/// Extrae un identificador de usuario limpio a partir del valor crudo
/// leído de un código QR.
///
/// La app reconoce dos formatos de QR distintos para identificar a un
/// usuario al escanear asistencia:
///  - El QR nativo de la app (pantalla "Mi QR"), que codifica directamente
///    el UUID de `usuarios.id`.
///  - El QR impreso en el carnet físico universitario, que codifica el
///    número de identificación/cédula — a veces con prefijos o separadores
///    propios del formato del carnet (ej. "V-32727962", "CI: 32727962").
///
/// Aislar esta normalización aquí, en vez de repartirla en cada
/// repositorio que busca usuarios por QR, deja un único punto de extensión
/// si en el futuro aparecen más formatos de carnet externos con otros
/// prefijos o máscaras.
class NormalizadorQR {
  NormalizadorQR._();

  static final RegExp _regexUuidV4 = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static final RegExp _regexNoNumerico = RegExp(r'[^0-9]');

  /// Retorna el identificador listo para consultar contra `usuarios.id`
  /// (UUID) o `usuarios.numero_identificacion` (cédula).
  ///
  /// - Cadena vacía si [rawQr] es nulo o vacío (incluye solo espacios).
  /// - El valor tal cual (recortado) si ya es un UUID v4 válido — QR nativo
  ///   de la app.
  /// - Solo los dígitos si no es UUID — QR de carnet físico: elimina
  ///   prefijos, espacios, guiones y cualquier otro carácter no numérico.
  static String extraerIdentificador(String? rawQr) {
    if (rawQr == null) return '';

    final valor = rawQr.trim();
    if (valor.isEmpty) return '';

    if (_regexUuidV4.hasMatch(valor)) return valor;

    return valor.replaceAll(_regexNoNumerico, '');
  }
}
