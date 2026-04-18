import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:uniasist/configuracion/colores_app.dart';

class AvatarUsuario extends StatelessWidget {
  const AvatarUsuario({
    super.key,
    required this.iniciales,
    this.urlFoto,
    this.tamanio = 40,
    this.colorFondo,
    this.colorTexto,
  });

  final String iniciales;
  final String? urlFoto;
  final double tamanio;
  final Color? colorFondo;
  final Color? colorTexto;

  @override
  Widget build(BuildContext context) {
    final fondo = colorFondo ?? ColoresApp.acentoClaro;
    final texto = colorTexto ?? ColoresApp.acento;

    return Container(
      width:  tamanio,
      height: tamanio,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: urlFoto != null ? null : fondo,
        image: urlFoto != null
            ? DecorationImage(
                image: CachedNetworkImageProvider(urlFoto!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: urlFoto != null
          ? null
          : Center(
              child: Text(
                iniciales.toUpperCase(),
                style: TextStyle(
                  color:         texto,
                  fontSize:      tamanio * 0.35,
                  fontWeight:    FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
    );
  }
}
