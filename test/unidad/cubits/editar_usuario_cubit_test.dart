import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:activiti/compartido/errores.dart';
import 'package:activiti/funcionalidades/editar_usuario/editar_usuario_cubit.dart';
import 'package:activiti/funcionalidades/editar_usuario/editar_usuario_estado.dart';

import '../../helpers.dart';

void main() {
  late MockEditarUsuarioRepositorio repositorio;

  setUp(() {
    registrarFallbacks();
    repositorio = MockEditarUsuarioRepositorio();
  });

  EditarUsuarioCubit build() => EditarUsuarioCubit(repositorio);

  Map<String, dynamic> datosUsuario({String? urlAvatar}) => {
        'id': 'user-1',
        'auth_id': 'auth-1',
        'primer_nombre': 'Leo',
        'primer_apellido': 'Alvarez',
        'segundo_nombre': null,
        'segundo_apellido': null,
        'numero_identificacion': null,
        'correo': 'leo@uni.edu',
        'telefono': null,
        'url_avatar': urlAvatar,
      };

  group('EditarUsuarioCubit.cargar', () {
    blocTest<EditarUsuarioCubit, EditarUsuarioEstado>(
      'emite [Cargando, Cargado] con authId y urlAvatarInicial del repositorio',
      build: build,
      setUp: () => when(() => repositorio.obtenerUsuario('user-1')).thenAnswer(
        (_) async =>
            datosUsuario(urlAvatar: 'https://ejemplo.com/avatars/auth-1.jpg'),
      ),
      act: (c) => c.cargar('user-1'),
      expect: () => [
        isA<EditarUsuarioCargando>(),
        isA<EditarUsuarioCargado>()
            .having((e) => e.authId, 'authId', 'auth-1')
            .having(
              (e) => e.urlAvatarInicial,
              'urlAvatarInicial',
              'https://ejemplo.com/avatars/auth-1.jpg',
            ),
      ],
    );

    blocTest<EditarUsuarioCubit, EditarUsuarioEstado>(
      'emite Error cuando falla el repositorio',
      build: build,
      setUp: () => when(() => repositorio.obtenerUsuario('user-1'))
          .thenThrow(const FallaServidor('Sin conexión')),
      act: (c) => c.cargar('user-1'),
      expect: () => [
        isA<EditarUsuarioCargando>(),
        isA<EditarUsuarioError>()
            .having((e) => e.mensaje, 'mensaje', 'Sin conexión'),
      ],
    );
  });

  group('EditarUsuarioCubit.guardar', () {
    blocTest<EditarUsuarioCubit, EditarUsuarioEstado>(
      'no envía url_avatar cuando no hubo cambio de foto',
      build: build,
      seed: () => const EditarUsuarioCargado(
        usuarioId: 'user-1',
        authId: 'auth-1',
        primerNombreInicial: 'Leo',
        primerApellidoInicial: 'Alvarez',
        correoInicial: 'leo@uni.edu',
      ),
      setUp: () => when(() => repositorio.actualizarUsuario(
            usuarioId: any(named: 'usuarioId'),
            primerNombre: any(named: 'primerNombre'),
            segundoNombre: any(named: 'segundoNombre'),
            primerApellido: any(named: 'primerApellido'),
            segundoApellido: any(named: 'segundoApellido'),
            numeroIdentificacion: any(named: 'numeroIdentificacion'),
            correo: any(named: 'correo'),
            telefono: any(named: 'telefono'),
            huboCambioFoto: any(named: 'huboCambioFoto'),
            urlAvatar: any(named: 'urlAvatar'),
          )).thenAnswer((_) async {}),
      act: (c) => c.guardar(
        primerNombre: 'Leo',
        primerApellido: 'Alvarez',
        numeroIdentificacion: '32727960',
        correo: 'leo@uni.edu',
      ),
      expect: () => [isA<EditarUsuarioCargado>(), isA<EditarUsuarioGuardado>()],
      verify: (_) {
        verify(() => repositorio.actualizarUsuario(
              usuarioId: 'user-1',
              primerNombre: 'Leo',
              segundoNombre: null,
              primerApellido: 'Alvarez',
              segundoApellido: null,
              numeroIdentificacion: '32727960',
              correo: 'leo@uni.edu',
              telefono: null,
              huboCambioFoto: false,
              urlAvatar: null,
            )).called(1);
      },
    );

    blocTest<EditarUsuarioCubit, EditarUsuarioEstado>(
      'envía la nueva url_avatar cuando hubo cambio de foto',
      build: build,
      seed: () => const EditarUsuarioCargado(
        usuarioId: 'user-1',
        authId: 'auth-1',
        primerNombreInicial: 'Leo',
        primerApellidoInicial: 'Alvarez',
        correoInicial: 'leo@uni.edu',
      ),
      setUp: () => when(() => repositorio.actualizarUsuario(
            usuarioId: any(named: 'usuarioId'),
            primerNombre: any(named: 'primerNombre'),
            segundoNombre: any(named: 'segundoNombre'),
            primerApellido: any(named: 'primerApellido'),
            segundoApellido: any(named: 'segundoApellido'),
            numeroIdentificacion: any(named: 'numeroIdentificacion'),
            correo: any(named: 'correo'),
            telefono: any(named: 'telefono'),
            huboCambioFoto: any(named: 'huboCambioFoto'),
            urlAvatar: any(named: 'urlAvatar'),
          )).thenAnswer((_) async {}),
      act: (c) => c.guardar(
        primerNombre: 'Leo',
        primerApellido: 'Alvarez',
        numeroIdentificacion: '32727960',
        correo: 'leo@uni.edu',
        huboCambioFoto: true,
        urlAvatar: 'https://ejemplo.com/avatars/auth-1.jpg',
      ),
      expect: () => [isA<EditarUsuarioCargado>(), isA<EditarUsuarioGuardado>()],
      verify: (_) {
        verify(() => repositorio.actualizarUsuario(
              usuarioId: 'user-1',
              primerNombre: 'Leo',
              segundoNombre: null,
              primerApellido: 'Alvarez',
              segundoApellido: null,
              numeroIdentificacion: '32727960',
              correo: 'leo@uni.edu',
              telefono: null,
              huboCambioFoto: true,
              urlAvatar: 'https://ejemplo.com/avatars/auth-1.jpg',
            )).called(1);
      },
    );

    blocTest<EditarUsuarioCubit, EditarUsuarioEstado>(
      'emite error de validación cuando el primer nombre está vacío',
      build: build,
      seed: () => const EditarUsuarioCargado(
        usuarioId: 'user-1',
        authId: 'auth-1',
        primerNombreInicial: 'Leo',
        primerApellidoInicial: 'Alvarez',
        correoInicial: 'leo@uni.edu',
      ),
      act: (c) => c.guardar(
        primerNombre: '',
        primerApellido: 'Alvarez',
        numeroIdentificacion: '32727960',
        correo: 'leo@uni.edu',
      ),
      expect: () => [
        isA<EditarUsuarioCargado>().having(
          (e) => e.errorValidacion,
          'errorValidacion',
          'El primer nombre es requerido.',
        ),
      ],
      verify: (_) {
        verifyNever(() => repositorio.actualizarUsuario(
              usuarioId: any(named: 'usuarioId'),
              primerNombre: any(named: 'primerNombre'),
              segundoNombre: any(named: 'segundoNombre'),
              primerApellido: any(named: 'primerApellido'),
              segundoApellido: any(named: 'segundoApellido'),
              numeroIdentificacion: any(named: 'numeroIdentificacion'),
              correo: any(named: 'correo'),
              telefono: any(named: 'telefono'),
              huboCambioFoto: any(named: 'huboCambioFoto'),
              urlAvatar: any(named: 'urlAvatar'),
            ));
      },
    );

    blocTest<EditarUsuarioCubit, EditarUsuarioEstado>(
      'emite error de validación cuando la cédula está vacía',
      build: build,
      seed: () => const EditarUsuarioCargado(
        usuarioId: 'user-1',
        authId: 'auth-1',
        primerNombreInicial: 'Leo',
        primerApellidoInicial: 'Alvarez',
        correoInicial: 'leo@uni.edu',
      ),
      act: (c) => c.guardar(
        primerNombre: 'Leo',
        primerApellido: 'Alvarez',
        correo: 'leo@uni.edu',
      ),
      expect: () => [
        isA<EditarUsuarioCargado>().having(
          (e) => e.errorValidacion,
          'errorValidacion',
          'La cédula es requerida — el usuario la necesita para iniciar sesión.',
        ),
      ],
      verify: (_) {
        verifyNever(() => repositorio.actualizarUsuario(
              usuarioId: any(named: 'usuarioId'),
              primerNombre: any(named: 'primerNombre'),
              segundoNombre: any(named: 'segundoNombre'),
              primerApellido: any(named: 'primerApellido'),
              segundoApellido: any(named: 'segundoApellido'),
              numeroIdentificacion: any(named: 'numeroIdentificacion'),
              correo: any(named: 'correo'),
              telefono: any(named: 'telefono'),
              huboCambioFoto: any(named: 'huboCambioFoto'),
              urlAvatar: any(named: 'urlAvatar'),
            ));
      },
    );
  });
}
