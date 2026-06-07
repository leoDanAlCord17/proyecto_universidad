import 'auditoria_evento_modelo.dart';

sealed class AuditoriaEventoEstado {
  const AuditoriaEventoEstado();
}

final class AuditoriaEventoInicial extends AuditoriaEventoEstado {
  const AuditoriaEventoInicial();
}

final class AuditoriaEventoCargandoLista extends AuditoriaEventoEstado {
  const AuditoriaEventoCargandoLista();
}

final class AuditoriaEventoListaCargada extends AuditoriaEventoEstado {
  const AuditoriaEventoListaCargada();
}

final class AuditoriaEventoCargandoAuditoria extends AuditoriaEventoEstado {
  const AuditoriaEventoCargandoAuditoria({required this.eventoSeleccionado});

  final EventoParaAuditoria eventoSeleccionado;
}

final class AuditoriaEventoCargada extends AuditoriaEventoEstado {
  const AuditoriaEventoCargada({
    required this.eventoSeleccionado,
    required this.registros,
    required this.resumen,
    this.filtro = FiltroParticipantes.todos,
    this.busquedaParticipante = '',
  });

  final EventoParaAuditoria eventoSeleccionado;
  final List<RegistroAuditoria> registros;
  final ResumenAuditoria resumen;
  final FiltroParticipantes filtro;
  final String busquedaParticipante;

  List<RegistroAuditoria> get registrosFiltrados {
    var lista = registros;

    lista = switch (filtro) {
      FiltroParticipantes.todos => lista,
      FiltroParticipantes.entraron => lista.where((r) => r.haEntrado).toList(),
      FiltroParticipantes.ausentes =>
        lista.where((r) => r.estatus == 'ausente').toList(),
      FiltroParticipantes.salioAnticipado =>
        lista.where((r) => r.estatus == 'salio_anticipado').toList(),
      FiltroParticipantes.foraneos => lista.where((r) => r.esForaneo).toList(),
    };

    final q = busquedaParticipante.trim().toLowerCase();
    if (q.isNotEmpty) {
      lista = lista
          .where(
            (r) =>
                r.nombre.toLowerCase().contains(q) ||
                (r.numeroIdentificacion?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }

    return lista;
  }

  AuditoriaEventoCargada copiarCon({
    FiltroParticipantes? filtro,
    String? busquedaParticipante,
  }) =>
      AuditoriaEventoCargada(
        eventoSeleccionado: eventoSeleccionado,
        registros: registros,
        resumen: resumen,
        filtro: filtro ?? this.filtro,
        busquedaParticipante: busquedaParticipante ?? this.busquedaParticipante,
      );
}

final class AuditoriaEventoError extends AuditoriaEventoEstado {
  const AuditoriaEventoError(this.mensaje);

  final String mensaje;
}
