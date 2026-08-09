import 'package:flutter_test/flutter_test.dart';
import 'package:activiti/compartido/enmascarar_correo.dart';

void main() {
  group('enmascararCorreo', () {
    test('conserva el largo real del nombre de usuario y del dominio', () {
      final resultado = enmascararCorreo('leodanielalvarezcordero@gmail.com');
      expect(resultado, 'le********************o@gm***.com');
    });

    test('muestra los primeros 2 caracteres del dominio', () {
      final resultado = enmascararCorreo('anagomez@uni.edu');
      expect(resultado, 'an*****z@un*.edu');
    });

    test(
        'usuario de 3 caracteres: no alcanza para mostrar ambos extremos sin '
        'exponerlo completo, usa el fallback de un solo carácter visible', () {
      // prefijo(2) + sufijo(1) == largo del texto (3): mostrar ambos
      // extremos dejaría 0 caracteres ocultos, o sea el correo sin censurar.
      final resultado = enmascararCorreo('leo@x.co');
      expect(resultado, 'l**@x.co');
    });

    test('usuario y dominio de 1 solo carácter no tienen nada que ocultar', () {
      final resultado = enmascararCorreo('a@x.co');
      expect(resultado, 'a@x.co');
    });

    test('dominio sin extensión reconocible se censura completo', () {
      final resultado = enmascararCorreo('leo@localhost');
      expect(resultado, 'l**@lo*******');
    });

    test('retorna el texto tal cual si no tiene formato de correo', () {
      expect(enmascararCorreo('no-es-un-correo'), 'no-es-un-correo');
    });
  });
}
