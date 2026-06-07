import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniasist/compartido/errores.dart';
import 'package:uniasist/funcionalidades/borradores/borrador_evento.dart';
import 'package:uniasist/funcionalidades/borradores/borradores_cubit.dart';
import 'package:uniasist/funcionalidades/borradores/borradores_estado.dart';

import '../helpers.dart';

const _borrador = BorradorEvento(
  id: 'borr-1',
  titulo: 'Feria de Ciencias',
  descripcion: 'Evento académico anual',
);

void main() {
  late MockBorradoresRepositorio repositorio;

  setUp(() {
    registrarFallbacks();
    repositorio = MockBorradoresRepositorio();
  });

  group('BorradoresCubit — integración con repositorio', () {
    test('cargar exitoso: emite BorradoresCargado con los borradores del repo',
        () async {
      when(() => repositorio.obtenerBorradores(any(),
          offset: any(named: 'offset'))).thenAnswer(
        (_) async => (
          borradores: [_borrador],
          hayMas: false,
        ),
      );

      final cubit = BorradoresCubit(repositorio);
      await cubit.cargarBorradores('user-1');

      expect(cubit.state, isA<BorradoresCargados>());
      final estado = cubit.state as BorradoresCargados;
      expect(estado.borradores.first.titulo, 'Feria de Ciencias');
      expect(estado.hayMas, false);
    });

    test('error del servidor: emite BorradoresError con el mensaje recibido',
        () async {
      when(() => repositorio.obtenerBorradores(any(),
              offset: any(named: 'offset')))
          .thenThrow(const FallaServidor('Sin conexión con el servidor.'));

      final cubit = BorradoresCubit(repositorio);
      await cubit.cargarBorradores('user-1');

      expect(cubit.state, isA<BorradoresError>());
      expect((cubit.state as BorradoresError).mensaje,
          'Sin conexión con el servidor.');
    });

    test('publicarEvento exitoso: elimina el borrador de la lista y recarga',
        () async {
      when(() => repositorio.obtenerBorradores(any(),
          offset: any(named: 'offset'))).thenAnswer(
        (_) async => (
          borradores: [_borrador],
          hayMas: false,
        ),
      );
      when(() => repositorio.publicarEvento(any())).thenAnswer((_) async {});

      final cubit = BorradoresCubit(repositorio);
      await cubit.cargarBorradores('user-1');
      await cubit.publicarEvento('borr-1');

      final estado = cubit.state as BorradoresCargados;
      expect(estado.borradores, isEmpty);
    });
  });
}
