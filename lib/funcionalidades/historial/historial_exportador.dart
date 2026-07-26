import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../compartido/constantes.dart';
import 'historial_item.dart';

/// Genera un PDF con el historial de asistencia y abre el selector nativo de compartir.
class HistorialExportador {
  HistorialExportador._();

  // ── Paleta del documento ─────────────────────────────────────────────────────
  static final _azul = PdfColor.fromHex('#5B3FD4');
  static final _azulFondo = PdfColor.fromHex('#EDE9FB');
  static final _grisOs = PdfColor.fromHex('#1C1830');
  static final _grisMed = PdfColor.fromHex('#6B6480');
  static final _grisCla = PdfColor.fromHex('#F4F3F9');
  static final _bordTabla = PdfColor.fromHex('#E8E6F2');
  static final _verde = PdfColor.fromHex('#1A9462');
  static final _verdeFondo = PdfColor.fromHex('#E2F5EE');
  static final _ambar = PdfColor.fromHex('#B97010');
  static final _ambarFondo = PdfColor.fromHex('#FDF2E0');
  static final _rojo = PdfColor.fromHex('#C23B3B');
  static final _rojoFondo = PdfColor.fromHex('#FBEAEA');

  static Future<void> generarYCompartirPdf({
    required String nombreUsuario,
    required List<HistorialItem> items,
  }) async {
    final doc = pw.Document();

    final totalAsistio = items.where((i) => i.esAsistido).length;
    final totalSalio = items.where((i) => i.esSalidaAnticipada).length;
    final totalAusente = items.where((i) => i.esAusente).length;
    final pctAsistio = items.isEmpty ? 0 : (totalAsistio * 100 ~/ items.length);
    final pctAusente = items.isEmpty ? 0 : (totalAusente * 100 ~/ items.length);

    final now = DateTime.now();
    final fechaGen = '${_d2(now.day)}/${_d2(now.month)}/${now.year}';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 36),
        footer: (_) => _pie(fechaGen),
        build: (_) => [
          _encabezado(nombreUsuario, fechaGen),
          pw.SizedBox(height: 22),
          _tituloSeccion('Resumen'),
          pw.SizedBox(height: 8),
          _bloqueResumen(items.length, totalAsistio, pctAsistio, totalSalio,
              totalAusente, pctAusente),
          pw.SizedBox(height: 26),
          _tituloSeccion('Detalle de eventos'),
          pw.SizedBox(height: 8),
          _tablaEventos(items),
        ],
      ),
    );

    final bytes = await doc.save();
    final dir = await getTemporaryDirectory();
    final archivo = File(
        '${dir.path}/historial_activiti_${now.millisecondsSinceEpoch}.pdf');
    await archivo.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(archivo.path, mimeType: 'application/pdf')],
      subject: 'Historial de asistencia — $nombreUsuario',
    );
  }

  // ── Secciones ────────────────────────────────────────────────────────────────

  static pw.Widget _encabezado(String nombre, String fecha) => pw.Container(
        padding: const pw.EdgeInsets.all(20),
        decoration: pw.BoxDecoration(
          color: _azul,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Activiti',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              'Historial de Asistencia',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.white),
            ),
            pw.SizedBox(height: 16),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  nombre,
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.Text(
                  'Generado el $fecha',
                  style:
                      const pw.TextStyle(fontSize: 10, color: PdfColors.white),
                ),
              ],
            ),
          ],
        ),
      );

  static pw.Widget _tituloSeccion(String texto) => pw.Text(
        texto,
        style: pw.TextStyle(
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
          color: _grisOs,
        ),
      );

  static pw.Widget _bloqueResumen(
    int total,
    int asistio,
    int pctAsistio,
    int salio,
    int ausente,
    int pctAusente,
  ) =>
      pw.Row(
        children: [
          _tarjeta('Total', '$total', _azul, _azulFondo),
          pw.SizedBox(width: 8),
          _tarjeta('Asistí', '$asistio ($pctAsistio%)', _verde, _verdeFondo),
          pw.SizedBox(width: 8),
          _tarjeta('Salió antes', '$salio', _ambar, _ambarFondo),
          pw.SizedBox(width: 8),
          _tarjeta('Ausencias', '$ausente ($pctAusente%)', _rojo, _rojoFondo),
        ],
      );

  static pw.Widget _tarjeta(
          String label, String valor, PdfColor color, PdfColor fondo) =>
      pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          decoration: pw.BoxDecoration(
            color: fondo,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            border: pw.Border.all(color: color, width: 0.5),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                valor,
                style: pw.TextStyle(
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                  color: color,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                label,
                style: pw.TextStyle(fontSize: 9, color: _grisMed),
              ),
            ],
          ),
        ),
      );

  static pw.Widget _tablaEventos(List<HistorialItem> items) {
    if (items.isEmpty) {
      return pw.Center(
        child: pw.Text(
          'No hay eventos en el historial',
          style: pw.TextStyle(fontSize: 11, color: _grisMed),
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: _bordTabla, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(3.0),
        1: pw.FlexColumnWidth(1.4),
        2: pw.FlexColumnWidth(1.8),
        3: pw.FlexColumnWidth(1.4),
        4: pw.FlexColumnWidth(1.1),
        5: pw.FlexColumnWidth(1.1),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _azul),
          children: [
            _celda('Evento', cabecera: true),
            _celda('Fecha', cabecera: true),
            _celda('Lugar', cabecera: true),
            _celda('Estado', cabecera: true),
            _celda('Entrada', cabecera: true),
            _celda('Salida', cabecera: true),
          ],
        ),
        ...items.asMap().entries.map((e) {
          final fondo = e.key.isEven ? _grisCla : PdfColors.white;
          final item = e.value;
          final (etiq, color, fondoEstatus) = _estatusConfig(item.estatus);
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: fondo),
            children: [
              _celda(item.eventoTitulo),
              _celda(item.etiquetaFecha.isNotEmpty ? item.etiquetaFecha : '—'),
              _celda(item.eventoLugar ?? '—'),
              _celdaBadge(etiq, color, fondoEstatus),
              _celda(item.horaEntrada ?? '—'),
              _celda(item.horaSalida ?? '—'),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _pie(String fecha) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 8),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generado por Activiti  •  $fecha',
              style: pw.TextStyle(fontSize: 8, color: _grisMed),
            ),
            pw.Text(
              'activiti.app',
              style: pw.TextStyle(fontSize: 8, color: _grisMed),
            ),
          ],
        ),
      );

  // ── Helpers de celdas ────────────────────────────────────────────────────────

  static pw.Widget _celda(String texto, {bool cabecera = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 5),
        child: pw.Text(
          texto,
          maxLines: 2,
          style: pw.TextStyle(
            fontSize: cabecera ? 9 : 8,
            fontWeight: cabecera ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: cabecera ? PdfColors.white : _grisOs,
          ),
        ),
      );

  static pw.Widget _celdaBadge(String texto, PdfColor color, PdfColor fondo) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 5),
        child: pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
          decoration: pw.BoxDecoration(
            color: fondo,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            border: pw.Border.all(color: color, width: 0.5),
          ),
          child: pw.Text(
            texto,
            style: pw.TextStyle(
              fontSize: 7,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ),
      );

  // ── Utilidades ───────────────────────────────────────────────────────────────

  static (String, PdfColor, PdfColor) _estatusConfig(String estatus) =>
      switch (estatus) {
        EstatusAsistencia.presente => ('Presente', _verde, _verdeFondo),
        EstatusAsistencia.completado => ('Completado', _verde, _verdeFondo),
        EstatusAsistencia.salioAnticipado => (
            'Salió antes',
            _ambar,
            _ambarFondo
          ),
        EstatusAsistencia.ausente => ('Ausente', _rojo, _rojoFondo),
        _ => ('—', _grisMed, _grisCla),
      };

  static String _d2(int n) => n.toString().padLeft(2, '0');
}
