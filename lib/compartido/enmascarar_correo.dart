/// Censura un correo conservando su largo real (para que se note que es el
/// correo verdadero), mostrando los primeros 2 caracteres y el último del
/// nombre de usuario, y los primeros 2 del dominio.
///
/// Ej. "leodanielalvarezcordero@gmail.com" → "le*********************o@gm***.com".
///
/// Retorna [correo] tal cual si no tiene el formato esperado (sin "@").
String enmascararCorreo(String correo) {
  final arroba = correo.indexOf('@');
  if (arroba <= 0) return correo;
  final local = correo.substring(0, arroba);
  final dominio = correo.substring(arroba + 1);
  final punto = dominio.lastIndexOf('.');
  final nombreDominio = punto > 0 ? dominio.substring(0, punto) : dominio;
  final extension = punto > 0 ? dominio.substring(punto) : '';
  final localOculto = _enmascararParte(local, prefijo: 2, sufijo: 1);
  final dominioOculto = _enmascararParte(nombreDominio, prefijo: 2, sufijo: 0);
  return '$localOculto@$dominioOculto$extension';
}

/// Censura [texto] conservando su largo real, mostrando [prefijo] caracteres
/// al inicio y [sufijo] al final sin censurar. Si [texto] es muy corto para
/// eso, muestra solo el primer carácter.
String _enmascararParte(String texto,
    {required int prefijo, required int sufijo}) {
  if (texto.isEmpty) return texto;
  if (texto.length <= prefijo + sufijo) {
    return '${texto[0]}${'*' * (texto.length - 1)}';
  }
  final inicio = texto.substring(0, prefijo);
  final fin = sufijo > 0 ? texto.substring(texto.length - sufijo) : '';
  final ocultos = texto.length - prefijo - sufijo;
  return '$inicio${'*' * ocultos}$fin';
}
