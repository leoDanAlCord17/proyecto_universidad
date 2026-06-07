import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniasist/funcionalidades/autenticacion/auth_cubit.dart';
import 'package:uniasist/funcionalidades/crear_usuario/crear_usuario_cubit.dart';
import 'package:uniasist/funcionalidades/crear_usuario/crear_usuario_estado.dart';
import 'package:uniasist/funcionalidades/crear_usuario/crear_usuario_pantalla.dart';

import '../helpers.dart';

Widget _marco(CrearUsuarioCubit cubit, AuthCubit auth) => enMarcoPantalla(
      providers: [
        BlocProvider<CrearUsuarioCubit>.value(value: cubit),
        BlocProvider<AuthCubit>.value(value: auth),
      ],
      child: const CrearUsuarioPantalla(),
    );

void main() {
  late MockCrearUsuarioCubit crearCubit;
  late MockAuthCubit authCubit;

  setUp(() {
    registrarFallbacks();
    crearCubit = MockCrearUsuarioCubit();
    authCubit = MockAuthCubit();
    when(() => crearCubit.correoSesion).thenReturn('leo@uni.edu');
    when(() => authCubit.verificarSesion()).thenAnswer((_) async {});
    when(() => authCubit.cerrarSesion()).thenAnswer((_) async {});
  });

  group('CrearUsuarioPantalla', () {
    testWidgets('pre-llena el campo de correo con correoSesion',
        (tester) async {
      when(() => crearCubit.state).thenReturn(const CrearUsuarioInicial());

      await tester.pumpWidget(_marco(crearCubit, authCubit));

      expect(find.text('leo@uni.edu'), findsOneWidget);
    });

    testWidgets('renderiza los campos de nombre, apellido y botón',
        (tester) async {
      when(() => crearCubit.state).thenReturn(const CrearUsuarioInicial());

      await tester.pumpWidget(_marco(crearCubit, authCubit));

      expect(find.text('Primer Nombre'), findsOneWidget);
      expect(find.text('Primer Apellido'), findsOneWidget);
      expect(find.text('Finalizar Registro'), findsOneWidget);
    });

    testWidgets('muestra CircularProgressIndicator cuando CrearUsuarioCargando',
        (tester) async {
      when(() => crearCubit.state).thenReturn(const CrearUsuarioCargando());

      await tester.pumpWidget(_marco(crearCubit, authCubit));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Finalizar Registro'), findsNothing);
    });

    testWidgets('muestra SnackBar con el mensaje cuando CrearUsuarioError',
        (tester) async {
      whenListen(
        crearCubit,
        Stream.fromIterable([
          const CrearUsuarioError('El nombre y apellido son obligatorios.'),
        ]),
        initialState: const CrearUsuarioInicial(),
      );

      await tester.pumpWidget(_marco(crearCubit, authCubit));
      await tester.pump(); // BlocConsumer listener fires → Overlay.insert
      await tester.pump(); // Overlay rebuilds con la nueva entrada

      expect(
        find.text('El nombre y apellido son obligatorios.'),
        findsOneWidget,
      );

      await tester.pump(const Duration(seconds: 3)); // drena timers de AvisoApp
    });

    testWidgets('llama guardarPerfil con los valores escritos', (tester) async {
      when(() => crearCubit.state).thenReturn(const CrearUsuarioInicial());
      when(
        () => crearCubit.guardarPerfil(
          primerNombre: any(named: 'primerNombre'),
          primerApellido: any(named: 'primerApellido'),
          segundoNombre: any(named: 'segundoNombre'),
          segundoApellido: any(named: 'segundoApellido'),
          numeroIdentificacion: any(named: 'numeroIdentificacion'),
          telefono: any(named: 'telefono'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(_marco(crearCubit, authCubit));

      // Primer Nombre es el primer campo editable (índice 0)
      // Segundo Nombre (1), Primer Apellido (2), Segundo Apellido (3)
      // Correo es readonly (4), Teléfono (5)
      final campos = find.byType(TextFormField);
      await tester.enterText(campos.at(0), 'Leo');
      await tester.enterText(campos.at(2), 'Alvarez');

      await tester.ensureVisible(find.text('Finalizar Registro'));
      await tester.tap(find.text('Finalizar Registro'));

      verify(
        () => crearCubit.guardarPerfil(
          primerNombre: 'Leo',
          primerApellido: 'Alvarez',
          segundoNombre: '',
          segundoApellido: '',
          numeroIdentificacion: '',
          telefono: '',
        ),
      ).called(1);
    });

    testWidgets('llama verificarSesion en AuthCubit cuando CrearUsuarioExito',
        (tester) async {
      whenListen(
        crearCubit,
        Stream.fromIterable([const CrearUsuarioExito()]),
        initialState: const CrearUsuarioInicial(),
      );

      await tester.pumpWidget(_marco(crearCubit, authCubit));
      await tester.pump();

      verify(() => authCubit.verificarSesion()).called(1);
    });
  });
}
