import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/traductor_errores.dart';

class InicioRepositorio {
  const InicioRepositorio(this._cliente);

  final SupabaseClient _cliente;

  /// Retorna el tag principal y los tags secundarios activos del usuario.
  Future<({String? tagPrincipal, List<String> tagsSecundarios})> obtenerTags(
    String usuarioId,
  ) async {
    try {
      final datos = await _cliente
          .from(TablasSupabase.usuariosTags)
          .select('tags(nombre, tipo)')
          .eq('usuario_id', usuarioId)
          .eq('estatus', true);

      String? tagPrincipal;
      final tagsSecundarios = <String>[];

      for (final fila in datos) {
        final tag    = fila['tags'] as Map<String, dynamic>;
        final nombre = tag['nombre'] as String;
        final tipo   = tag['tipo']   as String;
        if (tipo == 'principal') {
          tagPrincipal = nombre;
        } else {
          tagsSecundarios.add(nombre);
        }
      }

      return (tagPrincipal: tagPrincipal, tagsSecundarios: tagsSecundarios);
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }
}
