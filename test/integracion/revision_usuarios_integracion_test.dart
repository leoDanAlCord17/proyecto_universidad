import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniasist/compartido/errores.dart';
import 'package:uniasist/funcionalidades/revision_usuarios/revision_usuario_item.dart';
import 'package:uniasist/funcionalidades/revision_usuarios/revision_usuarios_cubit.dart';
import 'package:uniasist/funcionalidades/revision_usuarios/revision_usuarios_pantalla.dart';

import '../helpers.dart';

const _usuarioPendiente = RevisionUsuarioItem(
  id: 'rev-1',
  primerNombre: 'Ana',
  primerApellido: 'Pérez',
  correo: 'ana@uni.edu',
);

Widget _marco(RevisionUsuariosCubit cubit) => MaterialApp(
      home: BlocProvider<RevisionUsuariosCubit>.value(
        value: cubit,
        child: const RevisionUsuariosPantalla(),
      ),
    );

void main() {
  late MockRevisionUsuariosRepositorio repositorio;

  setUp(() {
    registrarFallbacks();
    repositorio = MockRevisionUsuariosRepositorio();
  });

  group('RevisionUsuarios — integración cubit + pantalla', () {
    testWidgets(
        'carga exitosa: pantalla muestra el nombre del usuario pendiente',
        (tester) async {
      when(() => repositorio.obtenerPendientes(offset: any(named: 'offset')))
          .thenAnswer(
        (_) async => (
          usuarios: [_usuarioPendiente],
          hayMas: false,
        ),
      );

      final cubit = RevisionUsuariosCubit(repositorio);

      await tester.pumpWidget(_marco(cubit));
      await tester.pump();
      await tester.pump();

      expect(find.text('Ana Pérez'), findsOneWidget);
      expect(find.text('ana@uni.edu'), findsOneWidget);
    });

    testWidgets('lista vacía: pantalla muestra mensaje de sin pendientes',
        (tester) async {
      when(() => repositorio.obtenerPendientes(offset: any(named: 'offset')))
          .thenAnswer(
        (_) async => (
          usuarios: <RevisionUsuarioItem>[],
          hayMas: false,
        ),
      );

      final cubit = RevisionUsuariosCubit(repositorio);

      await tester.pumpWidget(_marco(cubit));
      await tester.pump();
      await tester.pump();

      expect(
        find.text('No hay usuarios pendientes de aprobación'),
        findsOneWidget,
      );
    });

    testWidgets('error del servidor: pantalla muestra el mensaje de error',
        (tester) async {
      when(() => repositorio.obtenerPendientes(offset: any(named: 'offset')))
          .thenThrow(const FallaServidor('Error al cargar usuarios.'));

      final cubit = RevisionUsuariosCubit(repositorio);

      await tester.pumpWidget(_marco(cubit));
      await tester.pump();
      await tester.pump();

      expect(find.text('Error al cargar usuarios.'), findsOneWidget);
    });
  });
}
