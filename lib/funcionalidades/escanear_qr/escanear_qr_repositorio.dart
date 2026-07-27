import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/asistencia_registro_base.dart';
import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/reintento.dart';
import '../../compartido/traductor_errores.dart';
import '../../compartido/utilidades/normalizador_qr.dart';
import '../eventos/evento.dart';

class EscanearQrRepositorio extends AsistenciaRegistroBase {
  const EscanearQrRepositorio(super.supabase);

  /// Obtiene los datos del evento por su UUID.
  Future<Evento> obtenerEvento(String eventoId) => conReintentos(() async {
        try {
          final fila = await supabase
              .from(TablasSupabase.eventos)
              .select()
              .eq('id', eventoId)
              .single()
              .timeout(kTimeoutSolicitud);
          return Evento.desdeJson(fila);
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Cuenta asistentes con estatus activo en el evento.
  Future<int> contarPresentes(String eventoId) => conReintentos(() async {
        try {
          final result = await supabase
              .from(TablasSupabase.asistencia)
              .select('id')
              .eq('evento_id', eventoId)
              .inFilter('estatus', [
            EstatusAsistencia.presente,
            EstatusAsistencia.completado,
            EstatusAsistencia.salioAnticipado,
          ]).timeout(kTimeoutSolicitud);
          return result.length;
        } on PostgrestException catch (_) {
          return 0;
        } catch (_) {
          return 0;
        }
      });

  /// Busca un usuario activo a partir del valor crudo leído del QR — admite
  /// tanto el QR nativo de la app (UUID de `usuarios.id`) como el QR del
  /// carnet físico universitario (número de identificación/cédula, con o
  /// sin prefijos propios del carnet). Ver [NormalizadorQR].
  ///
  /// Retorna null si no existe, no está activo, o el QR no trae ningún
  /// identificador reconocible.
  Future<Map<String, dynamic>?> buscarUsuario(String rawQr) =>
      conReintentos(() async {
        final valor = NormalizadorQR.extraerIdentificador(rawQr);
        if (valor.isEmpty) return null;
        try {
          const columnas = 'id, primer_nombre, primer_apellido, '
              'numero_identificacion, '
              'usuarios_roles!usuarios_roles_usuario_id_fkey(roles(nombre))';

          // `id` es una columna `uuid` en Postgres: comparar esa columna con
          // `.eq()` contra un valor que no tiene forma de UUID (ej. una
          // cédula) hace que Postgres lance un error de tipo en vez de
          // simplemente no encontrar coincidencias. Por eso el OR contra
          // `id` solo se arma cuando el valor normalizado ya es un UUID
          // válido; si no, se busca únicamente por `numero_identificacion`
          // (columna de texto, sin ese riesgo).
          final query = supabase.from(TablasSupabase.usuarios).select(columnas);
          final filtrada = esUuidValido(valor)
              ? query.or('id.eq.$valor,numero_identificacion.eq.$valor')
              : query.eq('numero_identificacion', valor);

          final fila = await filtrada
              .eq('estatus', true)
              .maybeSingle()
              .timeout(kTimeoutSolicitud);
          return fila;
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Registra la entrada del usuario para el evento.
  /// Retorna true si fue registrado, false si ya estaba registrado.
  Future<bool> registrarEntrada({
    required String eventoId,
    required String usuarioId,
    String? registradoPorId,
  }) =>
      registrarEntradaBase(
        eventoId: eventoId,
        usuarioId: usuarioId,
        camposExtra: {'entrada_registrada_por': registradoPorId},
      );
}
