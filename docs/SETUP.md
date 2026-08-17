# Guía de configuración (paso a paso, desde cero)

Esta guía asume que nunca has usado Supabase ni Google Cloud Console. Sigue
los pasos en orden — cada uno depende del anterior.

Tiempo estimado: 30-45 minutos la primera vez.

---

## 1. Crear el proyecto en Supabase (la base de datos)

1. Ve a [supabase.com](https://supabase.com) y crea una cuenta gratis
   (puedes entrar con tu cuenta de Google).
2. Clic en **"New project"**.
   - Ponle un nombre, por ejemplo `pocketbait`.
   - Elige una contraseña de base de datos segura y **guárdala** en un
     lugar seguro (gestor de contraseñas) — la vas a necesitar poco, pero
     si la pierdes es difícil de recuperar.
   - Elige la región más cercana a México (por ejemplo `us-west-1`).
3. Espera 1-2 minutos a que Supabase termine de crear el proyecto.

### 1.1 Correr el esquema de la base de datos

1. En el menú izquierdo del dashboard de Supabase, entra a **SQL Editor**.
2. Clic en **"New query"**.
3. Abre el archivo [`supabase/migrations/0001_init.sql`](../supabase/migrations/0001_init.sql)
   de este repo, copia **todo** su contenido, pégalo en el editor de
   Supabase, y dale **Run** (▶️).
   - Debería decir "Success. No rows returned".
4. Repite el mismo paso, en este orden, con:
   - [`supabase/migrations/0002_views.sql`](../supabase/migrations/0002_views.sql)
   - [`supabase/migrations/0003_email_password_auth.sql`](../supabase/migrations/0003_email_password_auth.sql)
     (agrega el login con correo/usuario + contraseña, además de
     Google/Apple)

> Si ya habías corrido 0001 y 0002 antes y solo agregaron
> `0003_email_password_auth.sql` después, nada más corre ese archivo
> nuevo — no hace falta repetir los anteriores.

Con esto ya tienes las tablas, los permisos de seguridad (Row Level
Security) y las vistas listas.

### 1.2 Obtener tus claves de API

1. En el dashboard, ve a **Project Settings** (ícono de engranaje) →
   **API**.
2. Copia dos valores, los vas a necesitar más adelante:
   - **Project URL** (algo como `https://xxxxx.supabase.co`)
   - **Publishable key** (una cadena larga; en proyectos más viejos de
     Supabase puede aparecer como "anon" / "public" key — es la misma
     idea, una llave pública, no la "secret"/"service_role" que **nunca**
     debe ir en la app).

---

## 2. Configurar "Iniciar sesión con Google"

### 2.1 Crear las credenciales en Google Cloud Console

1. Ve a [console.cloud.google.com](https://console.cloud.google.com) y
   crea un proyecto nuevo (o usa uno existente), por ejemplo `PocketBait`.
2. Ve a **APIs & Services → OAuth consent screen** y configúralo:
   - Tipo de usuario: **External**.
   - Llena el nombre de la app, correo de soporte, correo de contacto.
   - En "Scopes" no necesitas agregar nada especial para empezar.
3. Ve a **APIs & Services → Credentials → Create Credentials → OAuth
   client ID**. Vas a crear **dos** client IDs:
   - **Tipo "Web application"** → este es tu `GOOGLE_WEB_CLIENT_ID`. En
     "Authorized redirect URIs" agrega:
     `https://TU-PROYECTO.supabase.co/auth/v1/callback` (con tu URL real
     de Supabase del paso 1.2).
   - **Tipo "iOS"** → este es tu `GOOGLE_IOS_CLIENT_ID`. Te va a pedir el
     "Bundle ID" de la app iOS — usa `com.pocketbait.pocketbait` (o el que
     hayas configurado en `ios/Runner.xcodeproj`).

### 2.2 Conectar Google con Supabase

1. En el dashboard de Supabase, ve a **Authentication → Providers →
   Google**.
2. Actívalo, y pega ahí el **Web client ID** (el mismo que usaste arriba).
3. Activa la opción **"Skip nonce checks"** — sin esto, el login de Google
   en iOS falla (es un detalle técnico del flujo nativo que usamos).
4. Guarda.

### 2.3 El login con correo/usuario + contraseña ya viene activado

Supabase trae el proveedor de "Email" activado por default, no necesitas
configurar nada extra para que funcione el registro y login con
correo/usuario + contraseña. Dos cosas a tener en cuenta:

- En **Authentication → Providers → Email**, el interruptor **"Confirm
  email"** decide si un usuario nuevo puede iniciar sesión de inmediato o
  primero tiene que confirmar su correo con un link. Está activado por
  default (más seguro) — déjalo así salvo que quieras probar más rápido
  sin ese paso.
- El correo de confirmación y el de "olvidé mi contraseña" los manda
  Supabase automáticamente con su propio servicio (funciona sin
  configurar nada, con un límite bajo de correos por hora — suficiente
  para pruebas; para producción real conviene configurar un proveedor de
  correo propio en **Authentication → Emails**).

---

## 3. Configurar "Iniciar sesión con Apple" (opcional al inicio)

Esto **solo hace falta cuando vayan a probar en un iPhone/iPad real o
publicar en la App Store** — pueden posponerlo y probar solo con Google
mientras desarrollan. Requiere:

1. Una cuenta de [Apple Developer Program](https://developer.apple.com/programs/)
   (de pago, ~$99 USD/año) — la necesitarán de todos modos para publicar
   la app en la App Store.
2. En Apple Developer, crear un **Identifier** de tipo "App ID" con
   "Sign in with Apple" habilitado, y un **Services ID** apuntando al
   dominio de callback de Supabase.
3. En Supabase: **Authentication → Providers → Apple**, activarlo y
   llenar los datos que pide (Services ID, Team ID, Key ID, clave
   privada `.p8`) — Supabase tiene una guía detallada con capturas en
   su [documentación oficial](https://supabase.com/docs/guides/auth/social-login/auth-apple).
4. Además, en el dashboard: agregar el Bundle ID de la app iOS en
   **Authentication → Providers → Apple → "Authorized Client IDs"** — así
   el login nativo (sin pasar por el navegador) también funciona.

Sin esto configurado, el botón de Apple simplemente no aparece en Android
y fallará en iOS — no rompe el resto de la app.

---

## 4. Configurar el archivo `.env` local

1. En la raíz del proyecto, copia `.env.example` a un archivo nuevo
   llamado `.env` (mismo folder).
2. Llena los 4 valores con lo que obtuviste en los pasos anteriores:

```env
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_PUBLISHABLE_KEY=tu-publishable-key
GOOGLE_WEB_CLIENT_ID=tu-client-id.apps.googleusercontent.com
GOOGLE_IOS_CLIENT_ID=tu-client-id.apps.googleusercontent.com
```

Este archivo **nunca se sube a git** (está en `.gitignore`) — cada
persona del equipo, y cada ambiente (desarrollo, producción), tiene el
suyo con sus propias claves.

---

## 5. (Opción más rápida) Probar en el navegador, sin instalar nada

Esta es la forma más simple de ver la app funcionando — se publica en una
URL que abres en Chrome/Edge/Safari, en cualquier compu o celular.

1. Igual que en la sección siguiente, crea los 4 secrets del repo si no
   lo has hecho (Settings → Secrets and variables → Actions).
2. Una sola vez: ve a **Settings → Pages** → en "Source" elige
   **"GitHub Actions"**.
3. Ve a la pestaña **Actions** → **"Compilar y publicar la versión web"**
   → **Run workflow** → elige la rama `claude/screen-time-betting-app-iuk66z`
   → Run workflow.
4. Espera unos minutos. Cuando termine, en la pestaña **Settings → Pages**
   va a aparecer la URL pública, algo como
   `https://pocketbait.github.io/APP/`.
5. **Importante:** antes de abrirla, ve a tu proyecto de Supabase →
   **Authentication → URL Configuration** → en **"Redirect URLs"** agrega
   esa misma URL (`https://pocketbait.github.io/APP/`) y guarda. Sin este
   paso, Supabase va a rechazar el regreso del login de Google por
   seguridad.

Con eso, entra a la URL y el botón "Continuar con Google" ya debería
funcionar de verdad, tal cual en el celular.

## 6. (Alternativa) Probar en Android sin instalar nada en tu compu

Si no quieres instalar Flutter/Android Studio todavía, puedes dejar que
**GitHub compile el `.apk` por ti** y solo lo descargas:

1. En GitHub, entra al repo → **Settings → Secrets and variables →
   Actions → New repository secret**, y crea estos 4 secretos (uno por
   uno), con los mismos valores que pusiste en tu `.env`:
   - `SUPABASE_URL`
   - `SUPABASE_PUBLISHABLE_KEY`
   - `GOOGLE_WEB_CLIENT_ID`
   - `GOOGLE_IOS_CLIENT_ID`
2. Ve a la pestaña **Actions** del repo → en la lista de la izquierda
   elige **"Compilar APK de Android"** → botón **"Run workflow"** →
   asegúrate de elegir la rama `claude/screen-time-betting-app-iuk66z` →
   **Run workflow**.
3. Espera 3-5 minutos a que termine (ícono verde ✅).
4. Dale clic a esa ejecución terminada → abajo, en **"Artifacts"**,
   descarga **`pocketbait-debug-apk`** (es un .zip con el `.apk` adentro).
5. Pasa ese `.apk` a un celular Android (por USB, WhatsApp, correo, Google
   Drive, lo que sea) y ábrelo ahí para instalarlo — puede que Android te
   pida activar "Instalar apps de orígenes desconocidos", es normal para
   apps que no vienen de la Play Store todavía.

## 7. Instalar Flutter y correr la app (para desarrollar de verdad)

1. Instala el SDK de Flutter siguiendo la [guía oficial](https://docs.flutter.dev/get-started/install)
   para tu sistema operativo.
2. Verifica que todo esté bien instalado:
   ```bash
   flutter doctor
   ```
   Resuelve cualquier ❌ que te marque (normalmente pide instalar Xcode
   para iOS, o Android Studio para Android).
3. Dentro de la carpeta del proyecto:
   ```bash
   flutter pub get      # instala las dependencias
   flutter run            # elige un simulador/emulador y corre la app
   ```

Si todo está bien configurado, deberías ver la pantalla de login con el
botón "Continuar con Google" funcionando de verdad.

---

## 8. Nota sobre la Fase 2 (apuestas con dinero real)

Antes de activar cualquier funcionalidad de dinero real (apuestas entre
amigos o grupos), es indispensable:

1. Consultar con un abogado especializado en fintech/apuestas en cada país
   donde se vaya a operar — para saber si aplica como "juego con apuesta"
   y qué licencia se necesita.
2. Conseguir un proveedor de pagos que permita explícitamente este caso de
   uso (la mayoría de proveedores estándar como Stripe/Mercado Pago lo
   prohíben en sus términos de servicio salvo autorización especial).
3. Revisar las políticas de Apple App Store y Google Play sobre apps de
   apuestas/dinero real antes de intentar publicarla con esa función
   activada — puede requerir aprobación especial por país.

Hasta resolver eso, esta app se queda en modo "Fase 1": compromisos entre
amigos sin dinero de por medio.
