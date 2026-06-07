import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniasist/compartido/errores.dart';
import 'package:uniasist/funcionalidades/autenticacion/auth_cubit.dart';
import 'package:uniasist/funcionalidades/autenticacion/auth_estado.dart';
import 'package:uniasist/funcionalidades/autenticacion/login_cubit.dart';
import 'package:uniasist/funcionalidades/autenticacion/login_pantalla.dart';

import '../helpers.dart';

Widget _marco(LoginCubit login, MockAuthCubit auth) => MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<LoginCubit>.value(value: login),
          BlocProvider<AuthCubit>.value(value: auth),
        ],
        child: const LoginPantalla(),
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

  group('Login — integración cubit + pantalla', () {
    testWidgets(
        'campos vacíos: cubit real emite LoginError y aviso aparece en la UI',
        (tester) async {
      final cubit = LoginCubit(repositorio);

      await tester.pumpWidget(_marco(cubit, authCubit));
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Por favor, llena todos los campos.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets(
        'credenciales correctas: cubit real emite LoginExito y llama verificarSesion',
        (tester) async {
      when(() => repositorio.iniciarSesion(any(), any()))
          .thenAnswer((_) async => authResponse);

      final cubit = LoginCubit(repositorio);

      await tester.pumpWidget(_marco(cubit, authCubit));

      final campos = find.byType(TextFormField);
      await tester.enterText(campos.at(0), 'leo@uni.edu');
      await tester.enterText(campos.at(1), 'clave123');
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pump(); // future del mock resuelve → cubit emite LoginExito
      await tester.pump(); // BlocListener reacciona → llama verificarSesion

      verify(() => authCubit.verificarSesion()).called(1);
    });

    testWidgets(
        'error del servidor: cubit real emite LoginError con mensaje del repo',
        (tester) async {
      when(() => repositorio.iniciarSesion(any(), any())).thenThrow(
          const FallaAutenticacion('Correo o contraseña incorrectos.'));

      final cubit = LoginCubit(repositorio);

      await tester.pumpWidget(_marco(cubit, authCubit));

      final campos = find.byType(TextFormField);
      await tester.enterText(campos.at(0), 'leo@uni.edu');
      await tester.enterText(campos.at(1), 'clave_mala');
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });
  });
}
