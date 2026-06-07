import 'package:equatable/equatable.dart';

import 'tag_opcion.dart';

class GrupoAudiencia extends Equatable {
  const GrupoAudiencia({
    required this.grupoIndex,
    required this.tagPrincipal,
    this.tagsSecundarios = const [],
  });

  final int grupoIndex;
  final TagOpcion tagPrincipal;
  final List<TagOpcion> tagsSecundarios;

  String get etiqueta {
    final partes = [
      tagPrincipal.nombre,
      ...tagsSecundarios.map((t) => t.nombre)
    ];
    return partes.join(' + ');
  }

  @override
  List<Object?> get props => [grupoIndex, tagPrincipal, tagsSecundarios];
}
