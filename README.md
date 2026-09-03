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
**Pero volvió a caerse**: verificado el 2026-09-03, GitHub Pages está
apagado en el repo (`has_pages: false`, `farouniversal.com.ar` da 404 con
"Site not found · GitHub Pages") aunque el repo sigue público y el DNS
sigue apuntando bien a Cloudflare/GitHub. No es un problema de este
contenido ni del DNS — es sólo el toggle de Pages, que se puede haber
apagado solo (pasa cuando GitHub no puede reverificar el dominio custom por
un tiempo). Reactivarlo es cosa de Fernán —el clasificador de esta sesión
bloqueó que lo hiciera por API—: ver
`~/Faro/.hilos/necesito-a-fernan/T781-el-sitio-se-cayo-github-pages-esta-apagado.md`.

Mientras tanto, este README sigue siendo la referencia de cómo se sirve:
Settings → Pages → Source: rama `main`, carpeta `/`, confirmar el dominio
custom `farouniversal.com.ar` una vez reactivado.

## El mail de contacto

La página linkea a `contacto@farouniversal.com.ar`. Esa casilla **todavía no
existe** — la mayoría de los registradores de dominio ofrecen reenvío de mail
gratis (sin necesitar un Google Workspace pago), y es lo único que hace
falta para que ese link funcione de verdad.

## Actualizar el contenido

Es un solo archivo (`index.html`) y una sola hoja de estilos
(`estilos.css`). Sin build: editar y commitear alcanza, GitHub Pages sirve
el `main` tal cual.
