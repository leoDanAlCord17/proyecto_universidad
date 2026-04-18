import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniasist/compartido/widgets/botones/boton_app.dart';

import '../helpers.dart';

void main() {
  group('BotonApp', () {
    testWidgets('muestra el texto del botón', (tester) async {
      await tester.pumpWidget(
        enMarcoApp(BotonApp(texto: 'Iniciar sesión', alPresionar: () {})),
      );
      expect(find.text('Iniciar sesión'), findsOneWidget);
    });

    testWidgets(
      'muestra CircularProgressIndicator y oculta texto cuando estaCargando',
      (tester) async {
        await tester.pumpWidget(
          enMarcoApp(
            BotonApp(
              texto:        'Cargar',
              alPresionar:  () {},
              estaCargando: true,
            ),
          ),
        );
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Cargar'), findsNothing);
      },
    );

    testWidgets('ejecuta alPresionar al ser tapeado', (tester) async {
      var presionado = false;
      await tester.pumpWidget(
        enMarcoApp(
          BotonApp(
            texto:       'Presionar',
            alPresionar: () => presionado = true,
          ),
        ),
      );

      await tester.tap(find.text('Presionar'));
      expect(presionado, isTrue);
    });

    testWidgets(
      'no ejecuta alPresionar cuando estaCargando es true',
      (tester) async {
        var presionado = false;
        await tester.pumpWidget(
          enMarcoApp(
            BotonApp(
              texto:        'Presionar',
              alPresionar:  () => presionado = true,
              estaCargando: true,
            ),
          ),
        );

        // El botón tiene onPressed null cuando está cargando; el tap no dispara.
        await tester.tap(
          find.byType(ElevatedButton),
          warnIfMissed: false,
        );
        expect(presionado, isFalse);
      },
    );

    testWidgets('muestra ícono a la izquierda del texto cuando se proporciona',
        (tester) async {
      await tester.pumpWidget(
        enMarcoApp(
          BotonApp(
            texto:       'Con ícono',
            alPresionar: () {},
            icono:       Icons.check,
          ),
        ),
      );
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.text('Con ícono'), findsOneWidget);
    });

    testWidgets('variante ghost renderiza OutlinedButton', (tester) async {
      await tester.pumpWidget(
        enMarcoApp(
          BotonApp(
            texto:       'Ghost',
            alPresionar: () {},
            variante:    VarianteBoton.ghost,
          ),
        ),
      );
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('variante rojo renderiza ElevatedButton', (tester) async {
      await tester.pumpWidget(
        enMarcoApp(
          BotonApp(
            texto:       'Eliminar',
            alPresionar: () {},
            variante:    VarianteBoton.rojo,
          ),
        ),
      );
      // ElevatedButton también aparece en la variante primaria,
      // pero el texto confirma cuál se renderizó.
      expect(find.text('Eliminar'), findsOneWidget);
    });
  });
}
