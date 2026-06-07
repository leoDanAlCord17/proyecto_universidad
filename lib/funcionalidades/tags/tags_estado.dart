import 'package:equatable/equatable.dart';

import 'tag.dart';

sealed class TagsEstado extends Equatable {
  const TagsEstado();
}

final class TagsInicial extends TagsEstado {
  const TagsInicial();
  @override
  List<Object?> get props => [];
}

final class TagsCargando extends TagsEstado {
  const TagsCargando();
  @override
  List<Object?> get props => [];
}

final class TagsCargados extends TagsEstado {
  const TagsCargados({
    required this.tags,
    required this.tagsFiltrados,
    required this.hayMas,
  });

  final List<Tag> tags;
  final List<Tag> tagsFiltrados;
  final bool      hayMas;

  TagsCargados copiarCon({List<Tag>? tagsFiltrados, bool? hayMas}) => TagsCargados(
    tags:          tags,
    tagsFiltrados: tagsFiltrados ?? this.tagsFiltrados,
    hayMas:        hayMas        ?? this.hayMas,
  );

  @override
  List<Object?> get props => [tags, tagsFiltrados, hayMas];
}

/// La lista ya muestra resultados y se está cargando la siguiente página.
final class TagsCargandoMas extends TagsEstado {
  const TagsCargandoMas({required this.tags, required this.tagsFiltrados});

  final List<Tag> tags;
  final List<Tag> tagsFiltrados;

  @override
  List<Object?> get props => [tags, tagsFiltrados];
}

final class TagsError extends TagsEstado {
  const TagsError({required this.mensaje});

  final String mensaje;

  @override
  List<Object?> get props => [mensaje];
}

final class TagsOperacionFallida extends TagsEstado {
  const TagsOperacionFallida({required this.anterior, required this.mensaje});

  final TagsCargados anterior;
  final String       mensaje;

  @override
  List<Object?> get props => [anterior, mensaje];
}
