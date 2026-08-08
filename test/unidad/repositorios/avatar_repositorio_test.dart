import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:activiti/compartido/avatar_repositorio.dart';
import 'package:activiti/compartido/errores.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

/// Genera una imagen JPEG de prueba en memoria de [ancho]x[alto], sin tocar
/// el sistema de archivos ni ningún canal de plataforma — AvatarRepositorio
/// no depende de Supabase para redimensionar/comprimir, así que esta parte
/// sí es puramente unitaria.
XFile _imagenDePrueba(int ancho, int alto) {
  final imagen = img.Image(width: ancho, height: alto);
  img.fill(imagen, color: img.ColorRgb8(120, 90, 200));
  final bytes = Uint8List.fromList(img.encodeJpg(imagen, quality: 95));
  return XFile.fromData(
    bytes,
    name: 'prueba.jpg',
    mimeType: 'image/jpeg',
  );
}

void main() {
  late AvatarRepositorio repositorio;

  setUp(() {
    // AvatarRepositorio solo necesita el SupabaseClient para subir/eliminar
    // — procesar() nunca lo toca, así que un mock sin ningún stub configurado
    // es suficiente para estas pruebas.
    repositorio = AvatarRepositorio(_MockSupabaseClient());
  });

  group('AvatarRepositorio.procesar', () {
    test('redimensiona una imagen grande a un máximo de 500x500', () async {
      final archivo = _imagenDePrueba(1600, 1200);
      final resultado = await repositorio.procesar(archivo);

      final decodificada = img.decodeImage(resultado);
      expect(decodificada, isNotNull);
      expect(decodificada!.width, lessThanOrEqualTo(500));
      expect(decodificada.height, lessThanOrEqualTo(500));
      // Conserva la proporción original (4:3) dentro de un margen de
      // redondeo de 1px.
      expect(decodificada.width, 500);
      expect(decodificada.height, closeTo(375, 1));
    });

    test('conserva las dimensiones si ya son 500x500 o menores', () async {
      final archivo = _imagenDePrueba(300, 200);
      final resultado = await repositorio.procesar(archivo);

      final decodificada = img.decodeImage(resultado);
      expect(decodificada!.width, 300);
      expect(decodificada.height, 200);
    });

    test('redimensiona una imagen alta (retrato) respetando la proporción',
        () async {
      final archivo = _imagenDePrueba(1200, 1600);
      final resultado = await repositorio.procesar(archivo);

      final decodificada = img.decodeImage(resultado);
      expect(decodificada!.height, 500);
      expect(decodificada.width, closeTo(375, 1));
    });

    test('el resultado es un JPEG válido', () async {
      final archivo = _imagenDePrueba(800, 800);
      final resultado = await repositorio.procesar(archivo);

      // Firma de archivo JPEG: FF D8 FF
      expect(resultado[0], 0xFF);
      expect(resultado[1], 0xD8);
      expect(resultado[2], 0xFF);
    });

    test('lanza FallaInesperada si el archivo no es una imagen válida',
        () async {
      // Suficientemente largo para que los decodificadores de formato no
      // truenen por buffer corto (RangeError) y en su lugar respondan
      // limpiamente que no reconocen el formato — el caso real que se
      // busca cubrir: alguien selecciona un archivo que no es una imagen.
      final archivoInvalido = XFile.fromData(
        Uint8List.fromList(List.filled(200, 0x41)),
        name: 'no_es_imagen.jpg',
      );

      expect(
        () => repositorio.procesar(archivoInvalido),
        throwsA(isA<FallaInesperada>()),
      );
    });
  });
}
