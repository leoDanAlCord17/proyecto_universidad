import 'package:flutter/material.dart';

import '../../avatar_repositorio.dart';
import '../../errores.dart';
import '../../../configuracion/colores_app.dart';
import '../../../configuracion/dependencias.dart';
import '../avisos/aviso_app.dart';
import '../panel/panel_opciones.dart';
import 'avatar_usuario.dart';

/// Círculo de avatar tocable que abre un panel para tomar/elegir/quitar la
/// foto de perfil. Widget controlado: el padre guarda [urlActual] en su
/// propio estado y lo actualiza cuando [alCambiar] reporta el resultado —
/// este widget no persiste nada en la tabla `usuarios` por su cuenta, solo
/// sube el archivo al bucket y devuelve la URL (o `null` si se quitó).
class SelectorFotoPerfil extends StatefulWidget {
  const SelectorFotoPerfil({
    super.key,
    required this.authId,
    required this.iniciales,
    required this.alCambiar,
    this.urlActual,
    this.tamanio = 88,
    this.colorFondo,
    this.colorTexto,
  });

  final String authId;
  final String iniciales;
  final String? urlActual;
  final double tamanio;
  final ValueChanged<String?> alCambiar;
  final Color? colorFondo;
  final Color? colorTexto;

  @override
  State<SelectorFotoPerfil> createState() => _SelectorFotoPerfilState();
}

class _SelectorFotoPerfilState extends State<SelectorFotoPerfil> {
  bool _procesando = false;

  Future<void> _elegir(OrigenFoto origen) async {
    setState(() => _procesando = true);
    try {
      final url =
          await obtenerIt<AvatarRepositorio>().seleccionarProcesarYSubir(
        origen: origen,
        authId: widget.authId,
      );
      if (url != null) widget.alCambiar(url);
    } on FallaServidor catch (e) {
      if (mounted) {
        AvisoApp.mostrar(context, texto: e.mensaje, estilo: EstiloAviso.error);
      }
    } on FallaInesperada catch (e) {
      if (mounted) {
        AvisoApp.mostrar(context, texto: e.mensaje, estilo: EstiloAviso.error);
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _quitar() async {
    setState(() => _procesando = true);
    try {
      await obtenerIt<AvatarRepositorio>().eliminar(widget.authId);
      widget.alCambiar(null);
    } on FallaServidor catch (e) {
      if (mounted) {
        AvisoApp.mostrar(context, texto: e.mensaje, estilo: EstiloAviso.error);
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  void _abrirPanel() {
    PanelOpciones.mostrar(
      context,
      opciones: [
        OpcionPanel(
          icono: Icons.photo_camera_outlined,
          colorFondo: ColoresApp.acentoClaro,
          colorIcono: ColoresApp.acento,
          titulo: 'Tomar foto',
          descripcion: 'Usar la cámara',
          alPresionar: () {
            Navigator.of(context, rootNavigator: true).pop();
            _elegir(OrigenFoto.camara);
          },
        ),
        OpcionPanel(
          icono: Icons.photo_library_outlined,
          colorFondo: ColoresApp.acentoClaro,
          colorIcono: ColoresApp.acento,
          titulo: 'Elegir de la galería',
          descripcion: 'Usar una foto existente',
          alPresionar: () {
            Navigator.of(context, rootNavigator: true).pop();
            _elegir(OrigenFoto.galeria);
          },
        ),
        if (widget.urlActual != null)
          OpcionPanel(
            icono: Icons.delete_outline_rounded,
            colorFondo: ColoresApp.rojoClaro,
            colorIcono: ColoresApp.rojo,
            colorTitulo: ColoresApp.rojo,
            titulo: 'Quitar foto',
            descripcion: 'Volver a mostrar tus iniciales',
            alPresionar: () {
              Navigator.of(context, rootNavigator: true).pop();
              _quitar();
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _procesando ? null : _abrirPanel,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AvatarUsuario(
            iniciales: widget.iniciales,
            urlFoto: widget.urlActual,
            tamanio: widget.tamanio,
            colorFondo: widget.colorFondo,
            colorTexto: widget.colorTexto,
          ),
          if (_procesando)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.35),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ColoresApp.acento,
                border:
                    Border.all(color: ColoresApp.superficiePrimaria, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
