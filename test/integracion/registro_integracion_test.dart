import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:activiti/compartido/errores.dart';
import 'package:activiti/funcionalidades/autenticacion/auth_cubit.dart';
import 'package:activiti/funcionalidades/autenticacion/auth_estado.dart';
import 'package:activiti/funcionalidades/autenticacion/registro_cubit.dart';
import 'package:activiti/funcionalidades/autenticacion/registro_pantalla.dart';

import '../helpers.dart';

Widget _marco(RegistroCubit registro, MockAuthCubit auth) => MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<RegistroCubit>.value(value: registro),
          BlocProvider<AuthCubit>.value(value: auth),
        ],
        child: const RegistroPantalla(),
      ),
    );

void main() {
  late MockAutenticacionRepositorio repositorio;
  late MockAuthCubit authCubit;
  late MockAuthResponse authResponse;

  setUp(() {
    registrarFallbacks();
    repositorio = MockAutenticacionRepositorio();
    authCubit = MockAuthCubit();
    authResponse = MockAuthResponse();
    when(() => authCubit.verificarSesion()).thenAnswer((_) async {});
    when(() => authCubit.state).thenReturn(NoAutenticado());
  });

  group('Registro — integración cubit + pantalla', () {
    testWidgets(
        'campos vacíos: cubit emite RegistroError y aviso aparece en la UI',
        (tester) async {
      final cubit = RegistroCubit(repositorio);

      await tester.pumpWidget(_marco(cubit, authCubit));
      await tester.ensureVisible(find.text('Continuar'));
      await tester.tap(find.text('Continuar'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Por favor, llena todos los campos.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets(
        'contraseñas no coinciden: cubit emite RegistroError con mensaje correcto',
        (tester) async {
      final cubit = RegistroCubit(repositorio);

      await tester.pumpWidget(_marco(cubit, authCubit));
      final campos = find.byType(TextFormField);
      await tester.enterText(campos.at(0), 'leo@uni.edu');
      await tester.enterText(campos.at(1), 'clave1234');
      await tester.enterText(campos.at(2), 'diferente1');
      await tester.ensureVisible(find.text('Continuar'));
      await tester.tap(find.text('Continuar'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets(
        'registro exitoso: cubit emite RegistroExito y llama verificarSesion',
        (tester) async {
      when(() => repositorio.registrarse(any(), any()))
          .thenAnswer((_) async => authResponse);

      final cubit = RegistroCubit(repositorio);

      await tester.pumpWidget(_marco(cubit, authCubit));
      final campos = find.byType(TextFormField);
      await tester.enterText(campos.at(0), 'leo@uni.edu');
      await tester.enterText(campos.at(1), 'clave1234');
      await tester.enterText(campos.at(2), 'clave1234');
      await tester.ensureVisible(find.text('Continuar'));
      await tester.tap(find.text('Continuar'));
      await tester.pump();
      await tester.pump();

      verify(() => authCubit.verificarSesion()).called(1);
    });

    testWidgets(
        'error del servidor: cubit emite RegistroError con mensaje del repo',
        (tester) async {
      when(() => repositorio.registrarse(any(), any())).thenAnswer((_) async =>
          throw const FallaAutenticacion('Este correo ya está registrado.'));

      final cubit = RegistroCubit(repositorio);

      await tester.pumpWidget(_marco(cubit, authCubit));
      final campos = find.byType(TextFormField);
      await tester.enterText(campos.at(0), 'leo@uni.edu');
      await tester.enterText(campos.at(1), 'clave1234');
      await tester.enterText(campos.at(2), 'clave1234');
      await tester.ensureVisible(find.text('Continuar'));
      await tester.tap(find.text('Continuar'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Este correo ya está registrado.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });
  });
}
