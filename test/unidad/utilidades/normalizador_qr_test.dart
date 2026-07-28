import 'package:flutter_test/flutter_test.dart';
import 'package:activiti/compartido/normalizador_qr.dart';

void main() {
  group('NormalizadorQR.extraerIdentificador', () {
    test('retorna cadena vacía si el valor es null', () {
      expect(NormalizadorQR.extraerIdentificador(null), '');
    });

    test('retorna cadena vacía si el valor está vacío', () {
      expect(NormalizadorQR.extraerIdentificador(''), '');
    });

    test('retorna cadena vacía si el valor son solo espacios', () {
      expect(NormalizadorQR.extraerIdentificador('   '), '');
    });

    test('preserva un UUID v4 nativo de la app sin modificaciones', () {
      const uuid = 'a1b2c3d4-e5f6-4789-9abc-1234567890ab';
      expect(NormalizadorQR.extraerIdentificador(uuid), uuid);
    });

    test('preserva un UUID v4 en mayúsculas', () {
      const uuid = 'A1B2C3D4-E5F6-4789-9ABC-1234567890AB';
      expect(NormalizadorQR.extraerIdentificador(uuid), uuid);
    });

    test('recorta espacios alrededor de un UUID antes de compararlo', () {
      const uuid = 'a1b2c3d4-e5f6-4789-9abc-1234567890ab';
      expect(NormalizadorQR.extraerIdentificador(' $uuid '), uuid);
    });

    test('cédula numérica limpia se retorna igual', () {
      expect(NormalizadorQR.extraerIdentificador('32727962'), '32727962');
    });

    test('cédula con prefijo "V-" elimina el prefijo y el guion', () {
      expect(NormalizadorQR.extraerIdentificador('V-32727962'), '32727962');
    });

    test('cédula con prefijo "CI: " elimina el prefijo y el espacio', () {
      expect(
        NormalizadorQR.extraerIdentificador('CI: 32727962'),
        '32727962',
      );
    });

    test(
        'cédula con prefijo "CED-" y espacios alrededor preserva ceros a la '
        'izquierda', () {
      expect(
        NormalizadorQR.extraerIdentificador(' CED-032727962 '),
        '032727962',
      );
    });

    test('valor sin ningún dígito retorna cadena vacía', () {
      expect(NormalizadorQR.extraerIdentificador('abc-sin-numeros'), '');
    });
  });
}
