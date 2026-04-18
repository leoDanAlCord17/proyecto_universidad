import 'package:flutter/material.dart';
import 'package:uniasist/compartido/widgets/avatares/avatar_usuario.dart';
import 'package:uniasist/compartido/widgets/botones/boton_app.dart';
import 'package:uniasist/compartido/widgets/botones/boton_icono.dart';
import 'package:uniasist/compartido/widgets/botones/boton_regresar.dart';
import 'package:uniasist/compartido/widgets/formularios/campo_texto_app.dart';
import 'package:uniasist/compartido/widgets/indicadores/barra_estadistica.dart';
import 'package:uniasist/compartido/widgets/indicadores/insignia_estado.dart';
import 'package:uniasist/compartido/widgets/listas/fila_rol.dart';
import 'package:uniasist/compartido/widgets/tarjetas/tarjeta_app.dart';
import 'package:uniasist/compartido/widgets/tarjetas/tarjeta_asistente.dart';
import 'package:uniasist/compartido/widgets/tarjetas/tarjeta_evento.dart';
import 'package:uniasist/compartido/widgets/tarjetas/tarjeta_evento_compacta.dart';
import 'package:uniasist/compartido/widgets/tarjetas/tarjeta_salida_anticipada.dart';
import 'package:uniasist/configuracion/colores_app.dart';

/// Pantalla de desarrollo — muestra visualmente todos los widgets de la app.
/// Solo para uso interno del equipo. No incluir en producción.
class VistaWidgetsPantalla extends StatefulWidget {
  const VistaWidgetsPantalla({super.key});

  @override
  State<VistaWidgetsPantalla> createState() => _VistaWidgetsPantallaState();
}

class _VistaWidgetsPantallaState extends State<VistaWidgetsPantalla> {
  final _controladorTexto     = TextEditingController(text: 'Texto de ejemplo');
  final _controladorClave     = TextEditingController();

  @override
  void dispose() {
    _controladorTexto.dispose();
    _controladorClave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresApp.fondo,
      appBar: AppBar(
        title: const Text('Vista de Widgets — DEV'),
        backgroundColor: ColoresApp.superficiePrimaria,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SeccionBotones(),
            _SeccionFormularios(
              controladorTexto: _controladorTexto,
              controladorClave: _controladorClave,
            ),
            _SeccionIndicadores(),
            _SeccionAvatares(),
            _SeccionTarjetasBase(),
            _SeccionTarjetasContenido(),
            _SeccionListas(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ─── UTILIDADES ───────────────────────────────────────────────────

class _TituloSeccion extends StatelessWidget {
  const _TituloSeccion(this.titulo);
  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo.toUpperCase(),
            style: const TextStyle(
              color:         ColoresApp.acento,
              fontSize:      11,
              fontWeight:    FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          const Divider(color: ColoresApp.bordesuave, height: 1),
        ],
      ),
    );
  }
}

class _ItemWidget extends StatelessWidget {
  const _ItemWidget({required this.nombre, required this.child, this.descripcion});
  final String nombre;
  final Widget child;
  final String? descripcion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          child,
          const SizedBox(height: 6),
          Text(
            nombre,
            style: const TextStyle(
              color:      ColoresApp.acento,
              fontSize:   11,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (descripcion != null)
            Text(
              descripcion!,
              style: const TextStyle(
                color:   ColoresApp.textoSecundario,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── SECCIÓN: BOTONES ─────────────────────────────────────────────

class _SeccionBotones extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _TituloSeccion('Botones'),

        _ItemWidget(
          nombre:      'BotonApp — primario',
          descripcion: 'Acción principal. Gradiente morado. Se deshabilita pasando alPresionar: null.',
          child: BotonApp(texto: 'Iniciar sesión', alPresionar: () {}),
        ),

        _ItemWidget(
          nombre:      'BotonApp — primario con ícono',
          descripcion: 'Mismo botón pero con ícono a la izquierda del texto.',
          child: BotonApp(
            texto:       'Registrar entrada',
            icono:       Icons.check_rounded,
            alPresionar: () {},
          ),
        ),

        _ItemWidget(
          nombre:      'BotonApp — primario cargando',
          descripcion: 'Estado estaCargando: true. Deshabilita el botón y muestra spinner.',
          child: BotonApp(
            texto:        'Guardando...',
            estaCargando: true,
            alPresionar:  () {},
          ),
        ),

        _ItemWidget(
          nombre:      'BotonApp — ghost',
          descripcion: 'Acción secundaria. Fondo transparente con borde morado.',
          child: BotonApp(
            texto:    'Cancelar',
            variante: VarianteBoton.ghost,
            alPresionar: () {},
          ),
        ),

        _ItemWidget(
          nombre:      'BotonApp — rojo',
          descripcion: 'Acción destructiva. Fondo rojo sólido.',
          child: BotonApp(
            texto:    'Marcar salida',
            variante: VarianteBoton.rojo,
            alPresionar: () {},
          ),
        ),

        _ItemWidget(
          nombre:      'BotonApp — ancho personalizado',
          descripcion: 'Parámetro ancho: para botones compactos dentro de tarjetas.',
          child: BotonApp(
            texto:    'Quitar',
            variante: VarianteBoton.rojo,
            ancho:    100,
            alPresionar: () {},
          ),
        ),

        _ItemWidget(
          nombre:      'BotonRegresar',
          descripcion: 'Botón de retroceso estándar. Usa context.pop() por defecto.',
          child: BotonRegresar(alPresionar: () {}),
        ),

        _ItemWidget(
          nombre:      'BotonIcono — variantes',
          descripcion: 'normal / acento / rojo. Solo ícono, sin texto. Para acciones dentro de tarjetas.',
          child: Row(
            children: [
              BotonIcono(icono: Icons.settings_outlined,  alPresionar: () {}),
              const SizedBox(width: 12),
              BotonIcono(
                icono:    Icons.qr_code_scanner,
                variante: VarianteBotonIcono.acento,
                alPresionar: () {},
              ),
              const SizedBox(width: 12),
              BotonIcono(
                icono:    Icons.delete_outline,
                variante: VarianteBotonIcono.rojo,
                alPresionar: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── SECCIÓN: FORMULARIOS ─────────────────────────────────────────

class _SeccionFormularios extends StatelessWidget {
  const _SeccionFormularios({
    required this.controladorTexto,
    required this.controladorClave,
  });

  final TextEditingController controladorTexto;
  final TextEditingController controladorClave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _TituloSeccion('Formularios'),

        _ItemWidget(
          nombre:      'CampoTextoApp — normal',
          descripcion: 'Campo de texto estándar con etiqueta.',
          child: CampoTextoApp(
            etiqueta:   'Correo institucional',
            hintText:   'maria.gonzalez@uni.edu',
            controller: controladorTexto,
          ),
        ),

        _ItemWidget(
          nombre:      'CampoTextoApp — contraseña',
          descripcion: 'Con esContrasena: true. Muestra ojo para alternar visibilidad.',
          child: CampoTextoApp(
            etiqueta:      'Contraseña',
            hintText:      '••••••••',
            controller:    controladorClave,
            esContrasena:  true,
          ),
        ),

        _ItemWidget(
          nombre:      'CampoTextoApp — solo lectura',
          descripcion: 'Con soloLectura: true. El usuario no puede editar el valor.',
          child: CampoTextoApp(
            etiqueta:    'Correo (no editable)',
            hintText:    '',
            controller:  controladorTexto,
            soloLectura: true,
          ),
        ),
      ],
    );
  }
}

// ─── SECCIÓN: INDICADORES ─────────────────────────────────────────

class _SeccionIndicadores extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const estatusEventos    = ['en_curso', 'programado', 'finalizado', 'cancelado', 'borrador'];
    const estatusAsistencia = ['presente', 'completado', 'esperado', 'ausente', 'salio_anticipado', 'anulado'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _TituloSeccion('Indicadores'),

        _ItemWidget(
          nombre:      'InsigniaEstado — estatus de eventos',
          descripcion: 'Pastilla de color semántico. El color se asigna automáticamente por estatus.',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in estatusEventos) InsigniaEstado(key: ValueKey(e), estatus: e),
            ],
          ),
        ),

        _ItemWidget(
          nombre:      'InsigniaEstado — estatus de asistencia',
          descripcion: 'Mismo widget, distintos valores de estatus.',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in estatusAsistencia) InsigniaEstado(key: ValueKey(e), estatus: e),
            ],
          ),
        ),

        _ItemWidget(
          nombre:      'InsigniaEstado — tamaño pequeño',
          descripcion: 'Con tamanio: TamanioInsignia.pequeno para espacios reducidos.',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in estatusEventos)
                InsigniaEstado(key: ValueKey('p_$e'), estatus: e, tamanio: TamanioInsignia.pequeno),
            ],
          ),
        ),

        const _ItemWidget(
          nombre:      'BarraEstadistica — 75%',
          descripcion: 'Label + porcentaje + barra de progreso. Porcentaje entre 0.0 y 1.0.',
          child: TarjetaApp(
            child: BarraEstadistica(
              etiqueta:   'Tasa de asistencia',
              porcentaje: 0.75,
            ),
          ),
        ),

        const _ItemWidget(
          nombre:      'BarraEstadistica — colores personalizados',
          descripcion: 'Se pueden sobreescribir colorBarra, colorEtiqueta y colorPorcentaje.',
          child: TarjetaApp(
            child: BarraEstadistica(
              etiqueta:        'Eventos completados',
              porcentaje:      0.40,
              colorBarra:      ColoresApp.ambar,
              colorPorcentaje: ColoresApp.ambar,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── SECCIÓN: AVATARES ────────────────────────────────────────────

class _SeccionAvatares extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TituloSeccion('Avatares'),

        _ItemWidget(
          nombre:      'AvatarUsuario — iniciales (tamaños)',
          descripcion: 'Muestra iniciales. El tamaño del texto escala automáticamente.',
          child: Row(
            children: [
              AvatarUsuario(iniciales: 'PM', tamanio: 32),
              SizedBox(width: 12),
              AvatarUsuario(iniciales: 'LR', tamanio: 40),
              SizedBox(width: 12),
              AvatarUsuario(iniciales: 'JG', tamanio: 52),
              SizedBox(width: 12),
              AvatarUsuario(iniciales: 'AD', tamanio: 64),
            ],
          ),
        ),

        _ItemWidget(
          nombre:      'AvatarUsuario — colores personalizados',
          descripcion: 'colorFondo y colorTexto sobreescriben los defaults morados.',
          child: Row(
            children: [
              AvatarUsuario(
                iniciales:  'PM',
                colorFondo: ColoresApp.verdeClaro,
                colorTexto: ColoresApp.verde,
              ),
              SizedBox(width: 12),
              AvatarUsuario(
                iniciales:  'LR',
                colorFondo: ColoresApp.ambarClaro,
                colorTexto: ColoresApp.ambar,
              ),
              SizedBox(width: 12),
              AvatarUsuario(
                iniciales:  'JG',
                colorFondo: ColoresApp.tealClaro,
                colorTexto: ColoresApp.teal,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── SECCIÓN: TARJETAS BASE ───────────────────────────────────────

class _SeccionTarjetasBase extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _TituloSeccion('Tarjetas Base (TarjetaApp)'),

        const _ItemWidget(
          nombre:      'TarjetaApp — normal',
          descripcion: 'Tarjeta estándar. Base de todas las tarjetas de contenido.',
          child: TarjetaApp(
            child: Text('Contenido de la tarjeta normal'),
          ),
        ),

        const _ItemWidget(
          nombre:      'TarjetaApp — acento',
          descripcion: 'Fondo morado claro con borde izquierdo acento. Para destacar información.',
          child: TarjetaApp(
            variante: VarianteTarjeta.acento,
            child:    Text('Contenido destacado con acento'),
          ),
        ),

        const _ItemWidget(
          nombre:      'TarjetaApp — punteada',
          descripcion: 'Borde punteado. Para indicar que algo puede agregarse.',
          child: TarjetaApp(
            variante: VarianteTarjeta.punteada,
            child:    Center(child: Text('+ Agregar elemento')),
          ),
        ),

        _ItemWidget(
          nombre:      'TarjetaApp — presionable',
          descripcion: 'Pasar alPresionar convierte cualquier variante en botón con efecto ripple.',
          child: TarjetaApp(
            alPresionar: () {},
            child: const Text('Esta tarjeta es presionable'),
          ),
        ),
      ],
    );
  }
}

// ─── SECCIÓN: TARJETAS DE CONTENIDO ──────────────────────────────

class _SeccionTarjetasContenido extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _TituloSeccion('Tarjetas de Contenido'),

        _ItemWidget(
          nombre:      'TarjetaEvento — completa',
          descripcion: 'Muestra estatus, horario, lugar y contador de asistentes.',
          child: TarjetaEvento(
            titulo:         'Seminario ETA',
            estatus:        'en_curso',
            horario:        '08:00 – 12:00',
            lugar:          'Aula 305',
            contadorTexto:  '35/33',
            alPresionar:    () {},
          ),
        ),

        const _ItemWidget(
          nombre:      'TarjetaEvento — mínima',
          descripcion: 'Solo los campos requeridos: titulo y estatus.',
          child: TarjetaEvento(
            titulo:  'Taller de Flutter',
            estatus: 'programado',
          ),
        ),

        _ItemWidget(
          nombre:      'TarjetaEventoCompacta',
          descripcion: 'Versión reducida para listas densas. Título + subtítulo de una línea.',
          child: TarjetaEventoCompacta(
            titulo:      'Física II',
            subtitulo:   '10:30 · Lab. 2 · 18 esperados',
            alPresionar: () {},
          ),
        ),

        _ItemWidget(
          nombre:      'TarjetaAsistente — con botón',
          descripcion: 'Avatar + nombre + detalle + estatus + botón de acción.',
          child: TarjetaAsistente(
            iniciales:       'PM',
            nombre:          'Pedro Martínez',
            detalle:         'V-22.100.004 · Estudiante',
            estatus:         'esperado',
            textoBoton:      'Registrar entrada',
            alPresionarBoton: () {},
          ),
        ),

        const _ItemWidget(
          nombre:      'TarjetaAsistente — sin botón',
          descripcion: 'Sin textoBoton el botón desaparece. Útil en modo solo lectura.',
          child: TarjetaAsistente(
            iniciales: 'LR',
            nombre:    'Laura Ramírez',
            detalle:   'V-18.450.201 · Docente',
            estatus:   'presente',
          ),
        ),

        const _ItemWidget(
          nombre:      'TarjetaSalidaAnticipada',
          descripcion: 'Muestra quién salió antes, el horario y el motivo.',
          child: TarjetaSalidaAnticipada(
            iniciales: 'LR',
            nombre:    'Luis Rodríguez',
            estatus:   'salio_anticipado',
            horario:   '08:05 → 09:30',
            motivo:    'Consulta médica',
          ),
        ),
      ],
    );
  }
}

// ─── SECCIÓN: LISTAS ─────────────────────────────────────────────

class _SeccionListas extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _TituloSeccion('Listas'),

        const _ItemWidget(
          nombre:      'FilaRol — con insignia Sistema',
          descripcion: 'esSistema: true muestra la pastilla "Sistema". No tiene botón de acción.',
          child: FilaRol(
            nombre:    'Superadmin',
            esSistema: true,
          ),
        ),

        _ItemWidget(
          nombre:      'FilaRol — con botón Quitar',
          descripcion: 'textoBoton y alPresionarBoton activan el botón de acción.',
          child: FilaRol(
            nombre:           'Coordinador',
            descripcion:      'Persona encargada de las auditorías',
            textoBoton:       'Quitar',
            alPresionarBoton: () {},
          ),
        ),

        _ItemWidget(
          nombre:      'FilaRol — presionable',
          descripcion: 'alPresionar convierte toda la fila en un elemento navegable.',
          child: FilaRol(
            nombre:      'Profesor',
            descripcion: 'Puede crear y gestionar eventos',
            alPresionar: () {},
          ),
        ),
      ],
    );
  }
}
