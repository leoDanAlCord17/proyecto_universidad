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
  });

  final List<Tag> tags;
  final List<Tag> tagsFiltrados;

  TagsCargados copiarCon({List<Tag>? tagsFiltrados}) => TagsCargados(
    tags:          tags,
    tagsFiltrados: tagsFiltrados ?? this.tagsFiltrados,
  );

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
