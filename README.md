# PocketBait

App para poner límites de tiempo de pantalla entre amigos, de mutuo
acuerdo: le das acceso a un amigo para que te proponga límites en ciertas
apps, él te manda la propuesta, y tú decides si la aceptas o no. Nadie
puede ponerte un límite sin que tú lo apruebes primero.

**Fase actual (1): sin dinero de por medio.** El sistema de apuestas
(grupos que apuestan a quién usa menos el celular) está planeado para una
fase futura, una vez resuelto el tema legal/regulatorio de manejar dinero
de terceros — ver la sección "Roadmap" más abajo.

## Primeros pasos

Si es tu primera vez configurando este proyecto (Supabase, Google
Sign-In, correr la app), sigue la guía paso a paso en
**[`docs/SETUP.md`](docs/SETUP.md)** — está escrita asumiendo que no
tienes experiencia previa con estas herramientas.

## Stack técnico

| Parte | Tecnología | Por qué |
|---|---|---|
| App (iOS + Android) | [Flutter](https://flutter.dev) | Un solo código para ambas plataformas. |
| Base de datos + Auth + backend | [Supabase](https://supabase.com) (Postgres) | Postgres real, con Row Level Security (la base de datos rechaza cualquier acceso indebido, no solo la app) y login social ya integrado. |
| Manejo de estado | [Riverpod](https://riverpod.dev) | Estándar actual en apps Flutter profesionales. |
| Navegación | [go_router](https://pub.dev/packages/go_router) | Rutas declarativas, con redirección automática a login si no hay sesión. |
| Login | Google Sign-In / Sign in with Apple | Vía Supabase Auth (`signInWithIdToken`). |

## Estructura del repo

```
lib/
  core/                 # Config, tema, router, widgets y utilidades compartidas
  features/
    auth/                # Login (Google/Apple) y sesión
    friends/              # Buscar/agregar amigos, solicitudes
    limits/                # Dar acceso, proponer/aceptar/rechazar límites
    profile/                # Perfil y cerrar sesión
    home/                    # Barra de navegación inferior
supabase/
  migrations/            # Esquema de la base de datos + seguridad (RLS), en SQL
test/
  domain/                # Pruebas unitarias de las reglas de negocio
docs/
  SETUP.md               # Guía paso a paso para configurar todo desde cero
```

## Seguridad de los datos

La regla de oro de este proyecto: **la seguridad vive en la base de
datos, no solo en la app.** Cada tabla en `supabase/migrations` tiene Row
Level Security (RLS) activada, con políticas que a nivel de Postgres
garantizan cosas como:

- Nadie puede proponerte un límite si tú no le diste acceso primero
  (tabla `permission_grants`), y esa fila solo se puede crear entre
  amigos que ya se aceptaron mutuamente.
- Solo tú puedes aceptar o rechazar una propuesta que te hicieron a ti.
- Nadie puede leer/editar datos de otra persona con la que no tiene
  relación (amistad, propuesta, etc.).

Esto significa que aunque hubiera un bug en la app, o alguien intentara
llamar directamente a la base de datos saltándose la app, Postgres
seguiría rechazando cualquier operación fuera de estas reglas.

## Comandos útiles

```bash
flutter pub get       # instalar dependencias
flutter run            # correr la app en un simulador/emulador conectado
flutter analyze         # revisar el código (debe salir "No issues found!")
flutter test              # correr las pruebas unitarias
```

## Roadmap

- ✅ **Fase 1 (este código):** login, amigos, dar acceso, proponer/aceptar
  límites. Todavía no lee/bloquea apps de verdad en el teléfono.
- 🔜 **Fase 1.5 — Screen Time real:** módulos nativos (Swift para
  `FamilyControls`/`DeviceActivity`/`ManagedSettings` en iOS; Kotlin con
  `UsageStatsManager` + `AccessibilityService` en Android) para que el
  límite aceptado sí bloquee la app de verdad. Requiere solicitar el
  entitlement de Family Controls a Apple con tiempo.
- 🔒 **Fase 2 — Apuestas con dinero real:** en pausa hasta resolver
  licencias de apuestas/manejo de fondos de terceros con un abogado —
  ver la nota en `docs/SETUP.md`.
