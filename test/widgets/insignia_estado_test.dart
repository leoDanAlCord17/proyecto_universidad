import 'package:flutter_test/flutter_test.dart';
import 'package:uniasist/compartido/widgets/indicadores/insignia_estado.dart';

import '../helpers.dart';

void main() {
  group('InsigniaEstado', () {
    testWidgets('muestra texto correcto para "en_curso"', (tester) async {
      await tester.pumpWidget(
        enMarcoApp(const InsigniaEstado(estatus: 'en_curso')),
      );
      expect(find.text('En curso'), findsOneWidget);
    });

    testWidgets('muestra texto correcto para "programado"', (tester) async {
      await tester.pumpWidget(
        enMarcoApp(const InsigniaEstado(estatus: 'programado')),
      );
      expect(find.text('Programado'), findsOneWidget);
    });

    testWidgets('muestra texto correcto para "finalizado"', (tester) async {
      await tester.pumpWidget(
        enMarcoApp(const InsigniaEstado(estatus: 'finalizado')),
      );
      expect(find.text('Finalizado'), findsOneWidget);
    });

    testWidgets('muestra texto correcto para "cancelado"', (tester) async {
      await tester.pumpWidget(
        enMarcoApp(const InsigniaEstado(estatus: 'cancelado')),
      );
      expect(find.text('Cancelado'), findsOneWidget);
    });

    testWidgets('muestra texto correcto para "presente"', (tester) async {
      await tester.pumpWidget(
        enMarcoApp(const InsigniaEstado(estatus: 'presente')),
      );
      expect(find.text('Presente'), findsOneWidget);
    });

    testWidgets('muestra texto correcto para "ausente"', (tester) async {
      await tester.pumpWidget(
        enMarcoApp(const InsigniaEstado(estatus: 'ausente')),
      );
      expect(find.text('Ausente'), findsOneWidget);
    });

    testWidgets('muestra texto correcto para "salio_anticipado"',
        (tester) async {
      await tester.pumpWidget(
        enMarcoApp(const InsigniaEstado(estatus: 'salio_anticipado')),
      );
      expect(find.text('Anticipado'), findsOneWidget);
    });

    testWidgets(
      'muestra el estatus raw cuando no está registrado en el mapa',
      (tester) async {
        await tester.pumpWidget(
          enMarcoApp(const InsigniaEstado(estatus: 'estado_desconocido')),
        );
        expect(find.text('estado_desconocido'), findsOneWidget);
      },
    );

    testWidgets('tamaño pequeño renderiza sin errores', (tester) async {
      await tester.pumpWidget(
        enMarcoApp(
          const InsigniaEstado(
            estatus: 'presente',
            tamanio: TamanioInsignia.pequeno,
          ),
        ),
      );
      expect(find.text('Presente'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('todos los estatus conocidos renderizan sin excepciones',
        (tester) async {
      const todosLosEstatus = [
        'en_curso', 'programado', 'finalizado', 'cancelado', 'borrador',
        'presente', 'completado', 'ausente', 'esperado', 'salio_anticipado',
        'anulado',
      ];

      for (final estatus in todosLosEstatus) {
        await tester.pumpWidget(
          enMarcoApp(InsigniaEstado(estatus: estatus)),
        );
        expect(tester.takeException(), isNull,
            reason: 'estatus "$estatus" lanzó una excepción',);
      }
    });
  });
}
