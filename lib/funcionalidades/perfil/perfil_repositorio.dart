import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/traductor_errores.dart';

class PerfilRepositorio {
  final SupabaseClient _supabase;

  PerfilRepositorio(this._supabase);

  /// Obtiene el tag principal y los tags secundarios activos del usuario.
  Future<({String? tagPrincipal, List<String> tagsSecundarios})> obtenerTags(
    String usuarioId,
  ) async {
    try {
      final datos = await _supabase
          .from(TablasSupabase.usuariosTags)
          .select('tipo, tags(nombre)')
          .eq('usuario_id', usuarioId)
          .eq('estatus', true);

      String? tagPrincipal;
      final tagsSecundarios = <String>[];

      for (final fila in datos) {
        final nombre = (fila['tags'] as Map<String, dynamic>)['nombre'] as String;
        if (fila['tipo'] == 'principal') {
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
