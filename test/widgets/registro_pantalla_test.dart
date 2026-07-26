import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:activiti/funcionalidades/autenticacion/auth_cubit.dart';
import 'package:activiti/funcionalidades/autenticacion/registro_cubit.dart';
import 'package:activiti/funcionalidades/autenticacion/registro_estado.dart';
import 'package:activiti/funcionalidades/autenticacion/registro_pantalla.dart';

import '../helpers.dart';

Widget _marco(RegistroCubit registro, AuthCubit auth) => enMarcoPantalla(
      providers: [
        BlocProvider<RegistroCubit>.value(value: registro),
        BlocProvider<AuthCubit>.value(value: auth),
      ],
      child: const RegistroPantalla(),
    );

void main() {
  late MockRegistroCubit registroCubit;
  late MockAuthCubit authCubit;

  setUp(() {
    registrarFallbacks();
    registroCubit = MockRegistroCubit();
    authCubit = MockAuthCubit();
    when(() => authCubit.verificarSesion()).thenAnswer((_) async {});
  });

  group('RegistroPantalla', () {
    testWidgets('renderiza 3 campos y botón en estado inicial', (tester) async {
      when(() => registroCubit.state).thenReturn(RegistroInicial());

      await tester.pumpWidget(_marco(registroCubit, authCubit));

      expect(find.text('Correo institucional'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);
      expect(find.text('Confirmar contraseña'), findsOneWidget);
      expect(find.text('Continuar'), findsOneWidget);
    });

    testWidgets('muestra CircularProgressIndicator cuando RegistroCargando',
        (tester) async {
      when(() => registroCubit.state).thenReturn(RegistroCargando());

      await tester.pumpWidget(_marco(registroCubit, authCubit));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Continuar'), findsNothing);
    });

    testWidgets('muestra SnackBar con el mensaje cuando RegistroError',
        (tester) async {
      whenListen(
        registroCubit,
        Stream.fromIterable([RegistroError('Las contraseñas no coinciden.')]),
        initialState: RegistroInicial(),
      );

      await tester.pumpWidget(_marco(registroCubit, authCubit));
      await tester.pump(); // BlocConsumer listener fires → Overlay.insert
      await tester.pump(); // Overlay rebuilds con la nueva entrada

      expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);

      // AvisoApp tiene timers de hasta 2900 ms; hay que drenarlos para que
      // el test framework no falle con "Timer is still pending".
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets(
        'llama registrarse con los valores escritos al presionar Continuar',
        (tester) async {
      when(() => registroCubit.state).thenReturn(RegistroInicial());
      when(() => registroCubit.registrarse(any(), any(), any()))
          .thenAnswer((_) async {});

      await tester.pumpWidget(_marco(registroCubit, authCubit));

      final campos = find.byType(TextFormField);
      await tester.enterText(campos.at(0), 'leo@uni.edu');
      await tester.enterText(campos.at(1), 'clave123');
      await tester.enterText(campos.at(2), 'clave123');

      await tester.ensureVisible(find.text('Continuar'));
      await tester.tap(find.text('Continuar'));

      verify(() =>
              registroCubit.registrarse('leo@uni.edu', 'clave123', 'clave123'))
          .called(1);
    });

    testWidgets('llama verificarSesion en AuthCubit cuando RegistroExito',
        (tester) async {
      whenListen(
        registroCubit,
        Stream.fromIterable([RegistroExito()]),
        initialState: RegistroInicial(),
      );

      await tester.pumpWidget(_marco(registroCubit, authCubit));
      await tester.pump();

      verify(() => authCubit.verificarSesion()).called(1);
    });
  });
}
