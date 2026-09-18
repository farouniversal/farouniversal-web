# farouniversal-web

El sitio de información de Faro en `farouniversal.com.ar` (`T781`). Marketing,
sin backend propio — quién es Faro, qué resuelve, cómo se contrata.

## Por qué es un repo aparte

Mismo principio que ya fija `docs/64` §2 de `farouniversal-tecnico` para el
borde de TTLock: la infraestructura de la web de marketing va separada de la
infraestructura de las casas (`farouniversal-connect`, el relay), para que
cambiar el hosting de una nunca toque la otra. Esta web **no depende de
Connect ni de `T706`** — arranca sola.

## Por qué HTML/CSS a secas, sin framework ni build

`T781` deja el framework y el hosting a criterio de quien lo construya. Elegí
lo más simple que resuelve el pedido: una landing de una sola página, sin
JavaScript, sin build step. Nada que instalar, nada que se rompa por una
versión de Node vieja dentro de tres años, y se puede servir desde
**cualquier** hosting estático sin adaptar nada — GitHub Pages, Netlify,
Vercel, un bucket S3, un nginx cualquiera.

## Cómo se despliega

Elegí **GitHub Pages** como default, por ser gratis y no depender de una
cuenta de un tercero además de GitHub (que el equipo ya usa). El archivo
`CNAME` ya está en el repo con `farouniversal.com.ar`.

Los tres pasos que hacían falta (repo público, DNS, mail de contacto) los
hizo Fernán el 2026-08-28 — ver
`~/Faro/.hilos/necesito-a-fernan/.resueltos/T781-repo-listo-faltan-tres-pasos-de-fernan.md`.
El sitio **está vivo** (verificado T1691, 2026-09-18: `curl -sI
https://farouniversal.com.ar/` → `HTTP/2 200`, `server: cloudflare`,
GitHub Pages detrás de Cloudflare); la caída que este README documentaba
(verificada el 2026-09-03, `has_pages: false`) ya se resolvió.

Settings → Pages → Source: rama `main`, carpeta `/`, dominio custom
`farouniversal.com.ar`.

⚠️ Sirve el sitio pasado por **Jekyll** (el comportamiento default de
GitHub Pages), que **ignora los directorios que empiezan con punto** — por
eso el repo tiene un `.nojekyll` vacío en la raíz: sin él, `.well-known/`
(ver más abajo) no se serviría nunca.

## El mail de contacto

La página linkea a `contacto@farouniversal.com.ar`. Esa casilla **todavía no
existe** — la mayoría de los registradores de dominio ofrecen reenvío de mail
gratis (sin necesitar un Google Workspace pago), y es lo único que hace
falta para que ese link funcione de verdad.

## Actualizar el contenido

Es un solo archivo (`index.html`) y una sola hoja de estilos
(`estilos.css`). Sin build: editar y commitear alcanza, GitHub Pages sirve
el `main` tal cual.

## `/.well-known/`: asociación de passkeys con las apps nativas (`T1691`)

`D-dominio-de-las-passkeys` (`farouniversal-tecnico/docs/14-decisiones-abiertas.md`,
**cerrada**) fijó `farouniversal.com.ar` como `rpId` de todas las passkeys de
Faro — «la misma passkey sirve en toda la familia Faro» — y `docs/83`
(§ el celular nuevo, equipos, revocación y claves) exige textual: «Hay que
publicar y sostener los archivos de asociación de iOS/Android bajo su
`/.well-known/`». Sin esto, ninguna app nativa (Capacitor corre en
`capacitor://localhost` / `https://localhost`, no en `farouniversal.com.ar`)
puede usar una passkey de ese dominio: `navigator.credentials` falla por
origen y hace falta el entitlement/dominio asociado que declaran estos dos
archivos para que iOS/Android confíen en la app.

**⚠️ Estado real, 2026-09-18 (T1691): los dos archivos TODAVÍA NO ESTÁN
PUBLICADOS.** Construir el resto (estructura, datos, generador, verificador)
no pedía ningún dato que sólo tenga Fernán; generarlos con los valores
reales sí. Ver `necesito-a-fernan/T1691-team-id-y-huella-de-firma.md` — la
tarea no se da por cerrada hasta que los archivos reales estén publicados.

### Qué apps se listan (decisión ya tomada, no la vuelvas a discutir)

- **`faro-app-connect`** (`ar.com.farouniversal.connect`) — sí, siempre:
  Connect tiene la sección de cuenta por `docs/83` §9, y ya tiene el
  recorrido «tengo mi passkey acá» esperando el adaptador WebAuthn (ficha
  I3 de la propuesta que originó T1691).
- **`faro-app-society`** (`ar.com.farouniversal.socios`) — **NO** está en
  la lista todavía. Sólo se agrega si Fernán decide que Society corre su
  propia ceremonia nativa de passkeys — es una decisión 🔒 sin cerrar (ver
  `T1683`, que escaló las 13 decisiones pendientes de la revisión de
  provisioning, y `farouniversal-tecnico/docs/14-decisiones-abiertas.md`).
  Agregarla cuando cierre es sumar un objeto a `passkeys-apps.json`, nada
  más.

### Cómo está armado

- **`passkeys-apps.json`** (raíz) — la fuente de datos, **vive en este
  repo como dato**: appId de cada app, Team ID de iOS y huellas SHA-256 de
  Android. A propósito **no** se lee `capacitor.config.*` de otro repo en
  vivo — un cotejo entre dos repos no se dispara solo, y evita acoplar este
  build al de otro repo (mismo principio que `T1140`). Un campo en `null` o
  una lista vacía es un dato **pendiente**; un texto como `COMPLETAR` está
  prohibido en cualquier campo.
- **`scripts/generar-well-known.sh`** — lee `passkeys-apps.json` y escribe
  los dos archivos reales en `.well-known/`. **Se niega** a escribir nada
  si a alguna app le falta el Team ID o la huella (o si tienen forma
  inválida): mejor no tener el archivo que tenerlo con un dato falso, que
  rompería en silencio la verificación de iOS/Android.
- **`.well-known/apple-app-site-association`** (iOS) — JSON **sin
  extensión** (así lo exige Apple), clave `webcredentials.apps` con
  `"<TeamID>.<bundleId>"` por app. El Team ID sale de la cuenta de Apple
  Developer de Faro (Fernán).
- **`.well-known/assetlinks.json`** (Android) — relación
  `delegate_permission/common.get_login_creds` — **no** `handle_all_urls`:
  no se quiere que Android abra la app con cualquier link del dominio,
  sólo que confíe en las credenciales de esta app. La huella sale del
  certificado con el que se firma cada APK.
- **`pruebas/verificar-well-known.sh`** — valida forma (JSON bien
  formado, campos requeridos, appIds contra `passkeys-apps.json`, sin
  relleno, `.nojekyll` presente si `.well-known/` existe) de lo que
  exista; con `--en-vivo` además pega contra
  `https://farouniversal.com.ar/.well-known/` y mide 200 sin
  redirección. Corre en **verde hoy** aunque los archivos reales no
  existan — valida el formato para cuando existan, no lo que no está.

### Dos datos compartidos con otros repos — si uno cambia sin el otro, nada se pone rojo

- **La huella SHA-256 de Android es la MISMA que usa el relay** de
  `farouniversal-connect` para el origen Android permitido
  (`android:apk-key-hash:…`, ficha I2 de la propuesta que originó T1691,
  `T1692` — construye esa mitad, todavía sin construir). Si cambia acá y
  no allá (o al revés), un teléfono Android deja de poder usar la passkey
  y **ninguna de las dos suites se pone roja** — es un chequeo manual al
  rotar la clave de firma.
- **Este repo comparte la zona de Cloudflare de `farouniversal.com.ar`
  con la web de Faro Connect** (`web.farouniversal.com.ar`, `T1636`).
  Medido contra `faro-app-connect origin/main @ cc32633`
  (`wrangler.jsonc:28-31`, `README.md:309-314`): los toggles «Bot Fight
  Mode» y «Block AI bots» de la zona están **apagados a propósito**
  porque valen para toda la zona, y la regla de WAF que bloquea bots está
  filtrada por `http.host eq "web.farouniversal.com.ar"` — no le llega al
  dominio raíz. Si alguien prende esos toggles para toda la zona, el CDN
  de Apple puede dejar de poder leer `apple-app-site-association` **sin
  que ninguna suite se ponga roja**.

## Chequeo: nunca se enlaza la web de Faro Connect

`T1674` — esta landing (y el material de redes, si está en el mismo
checkout) no puede linkear nunca la web de Faro Connect (todavía sin
desplegar, `T1591`/`T1636`): es la medida 4 de las "5 medidas de
no-indexado" que `BACKLOG.md` fija para toda web privada de una app de
Faro. Se verifica con:

```sh
pruebas/verificar-no-enlaza-connect.sh
```

Falla (rojo, exit 1) si aparece un link real a esa web en cualquier
archivo trackeado de este repo, o en el material de redes de
`farouniversal-sa/marketing`/`faro-media` si el checkout los tiene al
lado. Corrió en verde contra este repo y se probó el mutante (agregar y
sacar un `<a href>` real) antes de commitear.

## Banco de pruebas de este repo

```sh
pruebas/verificar-no-enlaza-connect.sh   # T1674 — ver arriba
pruebas/verificar-well-known.sh          # T1691 — ver arriba
pruebas/verificar-well-known.sh --en-vivo  # además mide contra producción
```
