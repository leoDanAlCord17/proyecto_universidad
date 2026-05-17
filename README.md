# UniAsist

## Guía de Desarrollo del Equipo

### Flutter + Supabase · v2.0

---

Este documento define cómo trabaja el equipo de desarrollo.
Cómo se organiza el proyecto, cómo se escribe el código,
qué está permitido, qué está prohibido y por qué.

**Todo el equipo debe leerlo antes de escribir la primera línea de código.**

---

# 1. Filosofía del Proyecto

Antes de entender las reglas técnicas, hay que entender el por qué de cada decisión.
Este proyecto se construye con tres principios que guían todo.

## 1.1 Código que se entienda, no solo que funcione

Un código que funciona hoy pero que nadie entiende mañana es una deuda.
Cada línea debe poder ser leída por cualquier persona del equipo sin tener que preguntar qué hace.

## 1.2 Cada parte tiene un único trabajo

La pantalla muestra datos.
El repositorio habla con Supabase.
El Cubit maneja el estado.

Ninguno hace el trabajo del otro.
Si un archivo hace demasiadas cosas, está mal ubicado.

## 1.3 Simple antes que perfecto

Esta guía usa una arquitectura simplificada adaptada a un equipo de 3 personas con nivel intermedio.
No es la versión más pura del libro de texto, es la versión que funciona bien para este equipo sin volverse una carga.

---

# 2. Estructura del Proyecto

El proyecto está organizado por funcionalidades.
Cada pantalla o módulo de la app tiene su propia carpeta con todo lo que necesita adentro.

No hay que saltar entre 5 carpetas distintas para entender cómo funciona una sola cosa.

> 💡 Cuando abres la carpeta `eventos` encuentras absolutamente todo lo de eventos en un solo lugar.

---

## 2.1 Árbol Principal de Carpetas

```text
uniasist/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   │
│   ├── configuracion/
│   │   ├── rutas.dart
│   │   ├── tema.dart
│   │   └── dependencias.dart
│   │
│   ├── compartido/
│   │   ├── constantes.dart
│   │   ├── errores.dart
│   │   └── widgets/
│   │       ├── boton_app.dart
│   │       ├── avatar_usuario.dart
│   │       ├── insignia_estado.dart
│   │       ├── pastilla_estadistica.dart
│   │       ├── esqueleto_carga.dart
│   │       └── estado_vacio.dart
│   │
│   └── funcionalidades/
│       ├── autenticacion/
│       ├── eventos/
│       ├── asistencia/
│       ├── qr/
│       ├── roles/
│       ├── reportes/
│       └── inicio/
│
├── test/
└── supabase/
    ├── migrations/
    └── seed.sql
```

---

## 2.2 Regla de Widgets

### Widget exclusivo

Si un widget se usa solo dentro de una funcionalidad:

```text
funcionalidades/modulo/widgets/
```

### Widget compartido

Si se usa en más de una funcionalidad:

```text
compartido/widgets/
```

> ⚠️ Nunca al revés.

---

# 3. Flujo del Código

El flujo siempre va en una sola dirección:

```text
Pantalla → Cubit → Repositorio → Supabase
```

## Reglas absolutas

* La pantalla NO llama al repositorio directamente
* El Cubit NO llama a Supabase directamente
* El repositorio NO sabe que existe una pantalla

---

# 4. Convenciones de Nombres

---

## 4.1 Archivos

Todos usan `snake_case`.

| Tipo        | Ejemplo                     |
| ----------- | --------------------------- |
| Pantalla    | eventos_lista_pantalla.dart |
| Cubit       | eventos_lista_cubit.dart    |
| Estado      | eventos_lista_estado.dart   |
| Repositorio | eventos_repositorio.dart    |
| Modelo      | evento.dart                 |
| Widget      | tarjeta_evento.dart         |

---

## 4.2 Clases

Todas usan `PascalCase`.

| Tipo        | Ejemplo              |
| ----------- | -------------------- |
| Modelo      | Evento               |
| Repositorio | EventosRepositorio   |
| Cubit       | EventosListaCubit    |
| Estado      | EventosListaEstado   |
| Pantalla    | EventosListaPantalla |
| Widget      | TarjetaEvento        |
| Error       | FallaServidor        |

---

## 4.3 Variables

Todas usan `camelCase`.
Siempre descriptivas.
Siempre en español.

### Correcto

```dart
final String idEvento;
final List<Evento> listaEventos;
final bool estaCargando;
```

### Incorrecto

```dart
final String id;
final var data;
final bool flag;
```

---

## 4.4 Booleanos

Siempre empiezan con:

* esta
* es
* tiene
* puede
* debe

### Correcto

```dart
bool estaCargando;
bool esAdministrador;
bool puedeMarcarSalida;
```

---

# 5. Comentarios

Los comentarios explican el **por qué**, no el **qué**.

## Correcto

```dart
// Solo se puede marcar salida si ya existe hora de entrada
```

## Incorrecto

```dart
// Incrementa el contador
contador++;
```

---

# 6. Widgets Reutilizables

## Reglas

* Solo reciben datos y funciones
* No acceden a Cubits
* No acceden a Repositorios
* Los parámetros obligatorios usan `required`
* Los opcionales tienen valor por defecto
* No contienen lógica de negocio

---

# 7. Manejo de Estado con Cubit

Cada pantalla tiene su propio Cubit.

## Ejemplos

| Cubit              | Pantalla             |
| ------------------ | -------------------- |
| EventosListaCubit  | Lista de eventos     |
| EventoDetalleCubit | Detalle del evento   |
| CrearEventoCubit   | Crear evento         |
| AuthCubit          | Autenticación global |

---

# 8. Integración con Supabase

---

## 8.1 Inicialización

Supabase se inicializa una sola vez en `main.dart`.

Las credenciales siempre vienen de `.env`.

### Nunca hacer esto

```dart
final url = 'https://proyecto.supabase.co';
```

---

## 8.2 Regla Absoluta

```text
supabase.from()
```

solo puede existir dentro de archivos:

```text
*_repositorio.dart
```

---

# 9. Buenas Prácticas

## Siempre usar constantes

### Correcto

```dart
_supabase.from(TablasSupabase.eventos)
```

### Incorrecto

```dart
_supabase.from('eventos')
```

---

## Manejo de null

### Correcto

```dart
final nombre = usuario.nombre ?? 'Sin nombre';
```

### Incorrecto

```dart
final nombre = usuario.nombre!;
```

---

# 10. Estrictamente Prohibido

---

## Arquitectura

🚫 Llamar Supabase fuera de repositorios
🚫 Lógica de negocio en pantallas
🚫 Importar entre funcionalidades

---

## Código

🚫 `print()` en producción
🚫 `catch {}` vacío
🚫 Credenciales en código
🚫 Métodos de más de 30 líneas
🚫 Widgets con `build()` de más de 100 líneas

---

## Trabajo en Equipo

🚫 Confirmar directamente en `main`
🚫 Aprobar tu propio PR
🚫 Subir `.env` a GitHub
🚫 Mensajes como `cambios`, `update`, `arreglos`

---

# 11. Flujo de Trabajo con Git

---

## Ramas oficiales

| Rama       | Uso                    |
| ---------- | ---------------------- |
| main       | Código estable         |
| desarrollo | Integración del equipo |
| dev-nombre | Rama personal          |

---

## Formato de commits

| Prefijo      | Uso                 |
| ------------ | ------------------- |
| agrego:      | nueva funcionalidad |
| modifico:    | cambio existente    |
| corrigo:     | solución de error   |
| elimino:     | borrar código       |
| refactorizo: | reorganizar         |

### Correcto

```bash
git commit -m "agrego: pantalla de creación de evento"
```

### Incorrecto

```bash
git commit -m "cambios"
```

---

# 12. Seguridad

---

## Variables de Entorno

### .env

```env
SUPABASE_URL=
SUPABASE_ANON_KEY=
```

### .gitignore

```gitignore
.env
*.env
!.env.ejemplo
```

---

## RLS (Row Level Security)

Debe estar activado en todas las tablas desde el primer día.

> 🔒 Nunca se desactiva, ni siquiera para pruebas.

---

# 13. Checklist Antes de Revisión

## Código

* [ ] No hay Supabase fuera de repositorios
* [ ] No hay lógica de negocio en pantallas
* [ ] No hay `print()`
* [ ] No hay `catch` vacíos
* [ ] No hay credenciales en código
* [ ] Métodos menores a 30 líneas

## Nombres

* [ ] Archivos en snake_case
* [ ] Clases en PascalCase
* [ ] Variables en camelCase
* [ ] Booleanos correctos
* [ ] Métodos con verbo

## Git

* [ ] Commit correcto
* [ ] PR hacia desarrollo
* [ ] `.env` no incluido

---

# 14. Glosario

| Término        | Significado                     |
| -------------- | ------------------------------- |
| Cubit          | Maneja estado de una pantalla   |
| Estado sellado | Fuerza manejar todos los casos  |
| Repositorio    | Único que habla con Supabase    |
| Modelo         | Representación de una tabla     |
| RLS            | Seguridad por filas en Supabase |
| snake_case     | nombre_de_archivo               |
| PascalCase     | NombreDeClase                   |
| camelCase      | nombreDeVariable                |

---

# UniAsist · Guía de Desarrollo · v2.0

**Documento de uso interno del equipo de desarrollo**
