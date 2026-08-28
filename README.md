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

Para que quede sirviendo el dominio de verdad, faltan **dos pasos que no
pude hacer yo** (ver el detalle completo en
`~/Faro/.hilos/necesito-a-fernan/T781-repo-listo-faltan-tres-pasos-de-fernan.md`
del lado de quien lea esto desde el hilo de trabajo):

1. **Hacer público este repo** (o mudar el contenido a uno público): GitHub
   Pages con dominio propio no está disponible en repos privados con el plan
   free de la organización.
2. **Apuntar el DNS de `farouniversal.com.ar`** a GitHub Pages, en el
   registrador del dominio:
   - 4 registros `A` en la raíz, a `185.199.108.153`, `185.199.109.153`,
     `185.199.110.153` y `185.199.111.153` (las IPs públicas de GitHub
     Pages), **o** un registro `ALIAS`/`ANAME` a `farouniversal.github.io` si
     el registrador lo soporta (una `A` a la raíz de un dominio no puede ser
     un `CNAME` — esa es la limitación que resuelve `ALIAS`/`ANAME` cuando
     existe).
   - Después, en la configuración de Pages del repo (Settings → Pages),
     confirmar el dominio custom una vez que el DNS ya propagó.

Con esos dos pasos, `farouniversal.com.ar` empieza a servir esta página.
Hasta entonces, el contenido se puede ver en
`https://farouniversal.github.io/farouniversal-web/` una vez que Pages esté
habilitado sobre el repo público.

## El mail de contacto

La página linkea a `contacto@farouniversal.com.ar`. Esa casilla **todavía no
existe** — la mayoría de los registradores de dominio ofrecen reenvío de mail
gratis (sin necesitar un Google Workspace pago), y es lo único que hace
falta para que ese link funcione de verdad.

## Actualizar el contenido

Es un solo archivo (`index.html`) y una sola hoja de estilos
(`estilos.css`). Sin build: editar y commitear alcanza, GitHub Pages sirve
el `main` tal cual.
