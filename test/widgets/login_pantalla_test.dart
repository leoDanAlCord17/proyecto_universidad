import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniasist/funcionalidades/autenticacion/auth_cubit.dart';
import 'package:uniasist/funcionalidades/autenticacion/login_cubit.dart';
import 'package:uniasist/funcionalidades/autenticacion/login_estado.dart';
import 'package:uniasist/funcionalidades/autenticacion/login_pantalla.dart';

import '../helpers.dart';

Widget _marco(LoginCubit login, AuthCubit auth) => enMarcoPantalla(
      providers: [
        BlocProvider<LoginCubit>.value(value: login),
        BlocProvider<AuthCubit>.value(value: auth),
      ],
      child: const LoginPantalla(),
    );

void main() {
  late MockLoginCubit loginCubit;
  late MockAuthCubit authCubit;

  setUp(() {
    registrarFallbacks();
    loginCubit = MockLoginCubit();
    authCubit = MockAuthCubit();
    when(() => authCubit.verificarSesion()).thenAnswer((_) async {});
  });

  group('LoginPantalla', () {
    testWidgets('renderiza campos y botón en estado inicial', (tester) async {
      when(() => loginCubit.state).thenReturn(LoginInicial());

      await tester.pumpWidget(_marco(loginCubit, authCubit));

      expect(find.text('Correo institucional'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);
      expect(find.text('Iniciar sesión'), findsOneWidget);
    });

    testWidgets('muestra CircularProgressIndicator cuando LoginCargando',
        (tester) async {
      when(() => loginCubit.state).thenReturn(LoginCargando());

      await tester.pumpWidget(_marco(loginCubit, authCubit));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Iniciar sesión'), findsNothing);
    });

    testWidgets('muestra SnackBar con el mensaje cuando LoginError',
        (tester) async {
      whenListen(
        loginCubit,
        Stream.fromIterable([LoginError('Correo o contraseña incorrectos.')]),
        initialState: LoginInicial(),
      );

      await tester.pumpWidget(_marco(loginCubit, authCubit));
      await tester.pump(); // BlocConsumer listener fires → Overlay.insert
      await tester.pump(); // Overlay rebuilds con la nueva entrada

      expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3)); // drena timers de AvisoApp
    });

    testWidgets('llama ingresar con los valores escritos al presionar el botón',
        (tester) async {
      when(() => loginCubit.state).thenReturn(LoginInicial());
      when(() => loginCubit.ingresar(any(), any())).thenAnswer((_) async {});

      await tester.pumpWidget(_marco(loginCubit, authCubit));

      final campos = find.byType(TextFormField);
      await tester.enterText(campos.at(0), 'leo@uni.edu');
      await tester.enterText(campos.at(1), 'clave123');
      await tester.tap(find.text('Iniciar sesión'));

      verify(() => loginCubit.ingresar('leo@uni.edu', 'clave123')).called(1);
    });

    testWidgets('llama verificarSesion en AuthCubit cuando LoginExito',
        (tester) async {
      whenListen(
        loginCubit,
        Stream.fromIterable([LoginExito()]),
        initialState: LoginInicial(),
      );

      await tester.pumpWidget(_marco(loginCubit, authCubit));
      await tester.pump();

      verify(() => authCubit.verificarSesion()).called(1);
    });
  });
}
