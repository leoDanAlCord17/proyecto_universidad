import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'errores.dart';
import 'traductor_errores.dart';

enum OrigenFoto { camara, galeria }

/// Selecciona, redimensiona/comprime y sube fotos de perfil al bucket
/// `avatars` de Supabase Storage.
class AvatarRepositorio {
  const AvatarRepositorio(this._supabase);

  final SupabaseClient _supabase;

  static const _bucket = 'avatars';
  static const _ladoMaximo = 500;
  static const _calidadJpeg = 80;

  /// Abre la cámara o la galería del dispositivo. Retorna `null` si el
  /// usuario cancela la selección sin elegir ninguna imagen.
  Future<XFile?> seleccionar(OrigenFoto origen) => ImagePicker().pickImage(
        source: origen == OrigenFoto.camara
            ? ImageSource.camera
            : ImageSource.gallery,
        // Límite de decodificación previo, generoso — evita cargar en
        // memoria fotos de 12+ MP de cámaras modernas antes de nuestro
        // propio resize a 500x500, sin recortar calidad de forma perceptible.
        maxWidth: 2000,
        maxHeight: 2000,
      );

  /// Redimensiona [archivo] a un máximo de 500x500px (conservando la
  /// proporción) y lo comprime a JPEG calidad 80% — deja cada foto entre
  /// ~50KB y 150KB sin pérdida perceptible de calidad en pantalla de
  /// teléfono.
  Future<Uint8List> procesar(XFile archivo) async {
    final bytesOriginales = await archivo.readAsBytes();
    final decodificada = img.decodeImage(bytesOriginales);
    if (decodificada == null) {
      throw const FallaInesperada('No se pudo leer la imagen seleccionada.');
    }

    final necesitaRedimensionar =
        decodificada.width > _ladoMaximo || decodificada.height > _ladoMaximo;
    final procesada = necesitaRedimensionar
        ? img.copyResize(
            decodificada,
            width:
                decodificada.width >= decodificada.height ? _ladoMaximo : null,
            height:
                decodificada.height > decodificada.width ? _ladoMaximo : null,
          )
        : decodificada;

    return Uint8List.fromList(img.encodeJpg(procesada, quality: _calidadJpeg));
  }

  /// Sube [bytes] al bucket `avatars` usando siempre el mismo nombre de
  /// archivo por usuario (`<authId>.jpg`, con `upsert: true`) — así cada
  /// cambio de foto sobrescribe la anterior en vez de acumular archivos
  /// huérfanos. Retorna la URL pública, con un parámetro de caché nuevo
  /// para que las imágenes ya cacheadas en el dispositivo se refresquen.
  Future<String> subir(
      {required String authId, required Uint8List bytes}) async {
    final ruta = '$authId.jpg';
    try {
      await _supabase.storage.from(_bucket).uploadBinary(
            ruta,
            bytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );
      final urlBase = _supabase.storage.from(_bucket).getPublicUrl(ruta);
      return '$urlBase?v=${DateTime.now().millisecondsSinceEpoch}';
    } on StorageException catch (e) {
      throw FallaServidor(e.message);
    } catch (e) {
      TraductorErrores.lanzarInesperado(e);
    }
  }

  /// Selecciona, procesa y sube en un solo paso. Retorna `null` si el
  /// usuario canceló la selección (no es un error).
  Future<String?> seleccionarProcesarYSubir({
    required OrigenFoto origen,
    required String authId,
  }) async {
    final archivo = await seleccionar(origen);
    if (archivo == null) return null;
    final bytes = await procesar(archivo);
    return subir(authId: authId, bytes: bytes);
  }

  /// Elimina la foto de perfil del usuario del bucket, si existe.
  Future<void> eliminar(String authId) async {
    try {
      await _supabase.storage.from(_bucket).remove(['$authId.jpg']);
    } on StorageException catch (e) {
      throw FallaServidor(e.message);
    } catch (e) {
      TraductorErrores.lanzarInesperado(e);
    }
  }
}
