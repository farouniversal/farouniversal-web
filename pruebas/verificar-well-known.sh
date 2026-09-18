#!/bin/bash
# pruebas/verificar-well-known.sh — T1691: valida la FORMA de los dos
# archivos de asociación de passkeys bajo /.well-known/
# (apple-app-site-association para iOS, assetlinks.json para Android).
#
# ⚠️ Los archivos reales TODAVÍA NO EXISTEN — publicarlos con un valor de
# relleno (Team ID/huella falsos) rompería en silencio la verificación de
# iOS/Android, así que T1691 no los generó (faltan dos datos que sólo tiene
# Fernán: ver necesito-a-fernan/T1691-team-id-y-huella-de-firma.md). Esta
# prueba corre en VERDE hoy igual: valida el FORMATO que van a tener CUANDO
# existan, contra los datos ya decididos en passkeys-apps.json. Cuando
# scripts/generar-well-known.sh los escriba con datos reales, esta misma
# prueba pasa a validar los archivos de verdad — no hace falta tocarla.
#
# Qué chequea, si el archivo existe: JSON bien formado, campos requeridos
# presentes, appId de cada app = los de passkeys-apps.json (decisión ya
# inferida del proyecto — el verificador NO lee capacitor.config.* de otro
# repo en vivo), sin valores de relleno (COMPLETAR, huella con forma
# inválida, Team ID con forma inválida), .nojekyll presente si .well-known/
# existe.
#
# Uso:
#   pruebas/verificar-well-known.sh            # sólo el árbol local
#   pruebas/verificar-well-known.sh --en-vivo  # además pega contra producción
#
#   0 = OK (ver arriba: puede ser "OK, no hay nada que validar todavía").
#   1 = ROJO — algo con forma inválida, o un valor de relleno.
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR" || exit 1

EN_VIVO=0
[ "${1:-}" = "--en-vivo" ] && EN_VIVO=1

ROJO=0
falla() { echo "❌ $1"; ROJO=1; }
ok() { echo "✅ $1"; }

if ! command -v jq >/dev/null 2>&1; then
  echo "🚨 verificar-well-known.sh: falta 'jq'."
  exit 1
fi

DATOS="passkeys-apps.json"
if [ ! -f "$DATOS" ]; then
  falla "no existe $DATOS (la fuente de datos de las apps)."
else
  if ! jq empty "$DATOS" >/dev/null 2>&1; then
    falla "$DATOS no es JSON válido."
  else
    ok "$DATOS es JSON válido."
    # Sin valores de relleno en la fuente de datos tampoco.
    if jq -e '.apps[]? | .. | strings | test("COMPLETAR"; "i")' "$DATOS" >/dev/null 2>&1; then
      falla "$DATOS tiene un valor de relleno tipo COMPLETAR."
    fi
  fi
fi

# appIds esperados, según la decisión ya inferida (passkeys-apps.json).
# NO se lee capacitor.config.* de otro repo — es a propósito (T1140: un
# cotejo entre dos repos no se dispara solo).
APPIDS_ESPERADOS="$(jq -r '.apps[]?.appId' "$DATOS" 2>/dev/null | sort)"
N_APPS_ESPERADAS="$(printf '%s\n' "$APPIDS_ESPERADOS" | grep -c . || true)"

if [ "$N_APPS_ESPERADAS" -lt 1 ]; then
  falla "$DATOS no declara ninguna app en 'apps' — no hay nada que un archivo de asociación pueda listar."
fi

AASA=".well-known/apple-app-site-association"
ASSETLINKS=".well-known/assetlinks.json"
HAY_WELL_KNOWN=0
[ -f "$AASA" ] && HAY_WELL_KNOWN=1
[ -f "$ASSETLINKS" ] && HAY_WELL_KNOWN=1

if [ "$HAY_WELL_KNOWN" -eq 0 ]; then
  echo "ℹ️  Ni $AASA ni $ASSETLINKS existen todavía en este árbol — eso es lo esperado"
  echo "    hasta que lleguen el Team ID y la huella de firma (ver"
  echo "    necesito-a-fernan/T1691-team-id-y-huella-de-firma.md). Esta prueba sólo"
  echo "    valida el FORMATO que van a tener cuando existan; no hay nada más que"
  echo "    correr en este árbol."
else
  # Si CUALQUIERA de los dos existe, .well-known/ existe, y entonces GitHub
  # Pages necesita .nojekyll en la raíz (Jekyll ignora directorios con punto).
  if [ -f ".nojekyll" ]; then
    ok ".nojekyll está en la raíz (hace falta porque .well-known/ existe)."
  else
    falla ".well-known/ existe pero falta .nojekyll en la raíz — GitHub Pages (Jekyll) va a ignorar el directorio."
  fi
fi

# --- apple-app-site-association ---
if [ -f "$AASA" ]; then
  if ! jq empty "$AASA" >/dev/null 2>&1; then
    falla "$AASA no es JSON válido."
  else
    ok "$AASA es JSON válido."
    if ! jq -e '.webcredentials.apps | type == "array" and length > 0' "$AASA" >/dev/null 2>&1; then
      falla "$AASA no tiene webcredentials.apps como array no vacío."
    else
      APPS_AASA="$(jq -r '.webcredentials.apps[]' "$AASA")"
      while IFS= read -r entrada; do
        [ -z "$entrada" ] && continue
        # Forma exigida: <TeamID:10 alfanumérico>.<bundleId>
        if ! printf '%s' "$entrada" | grep -qE '^[A-Za-z0-9]{10}\.[A-Za-z0-9.]+$'; then
          falla "$AASA: '$entrada' no tiene forma <TeamID de 10 caracteres>.<bundleId>."
        fi
        if printf '%s' "$entrada" | grep -qiE 'completar'; then
          falla "$AASA: '$entrada' es un valor de relleno."
        fi
        BUNDLE_ID="${entrada#*.}"
        if ! printf '%s\n' "$APPIDS_ESPERADOS" | grep -qxF "$BUNDLE_ID"; then
          falla "$AASA: bundleId '$BUNDLE_ID' no está en $DATOS (apps esperadas: $(printf '%s' "$APPIDS_ESPERADOS" | tr '\n' ' '))."
        fi
      done <<< "$APPS_AASA"
      [ "$ROJO" -eq 0 ] && ok "$AASA: todas las apps tienen Team ID con forma válida y coinciden con $DATOS."
    fi
  fi
fi

# --- assetlinks.json ---
if [ -f "$ASSETLINKS" ]; then
  if ! jq empty "$ASSETLINKS" >/dev/null 2>&1; then
    falla "$ASSETLINKS no es JSON válido."
  else
    ok "$ASSETLINKS es JSON válido."
    if ! jq -e 'type == "array" and length > 0' "$ASSETLINKS" >/dev/null 2>&1; then
      falla "$ASSETLINKS no es un array no vacío."
    else
      N="$(jq 'length' "$ASSETLINKS")"
      i=0
      while [ "$i" -lt "$N" ]; do
        RELACION="$(jq -r ".[$i].relation | join(\",\")" "$ASSETLINKS")"
        if [ "$RELACION" != "delegate_permission/common.get_login_creds" ]; then
          falla "$ASSETLINKS[$i]: relation es '$RELACION', tiene que ser exactamente delegate_permission/common.get_login_creds (NO handle_all_urls)."
        fi
        NAMESPACE="$(jq -r ".[$i].target.namespace" "$ASSETLINKS")"
        [ "$NAMESPACE" = "android_app" ] || falla "$ASSETLINKS[$i]: target.namespace es '$NAMESPACE', tiene que ser android_app."
        PKG="$(jq -r ".[$i].target.package_name" "$ASSETLINKS")"
        if [ -z "$PKG" ] || [ "$PKG" = "null" ]; then
          falla "$ASSETLINKS[$i]: falta target.package_name."
        elif ! printf '%s\n' "$APPIDS_ESPERADOS" | grep -qxF "$PKG"; then
          falla "$ASSETLINKS[$i]: package_name '$PKG' no está en $DATOS."
        fi
        N_HUELLAS="$(jq ".[$i].target.sha256_cert_fingerprints | length" "$ASSETLINKS" 2>/dev/null || echo 0)"
        if [ "$N_HUELLAS" -lt 1 ]; then
          falla "$ASSETLINKS[$i]: sin sha256_cert_fingerprints."
        else
          j=0
          while [ "$j" -lt "$N_HUELLAS" ]; do
            HUELLA="$(jq -r ".[$i].target.sha256_cert_fingerprints[$j]" "$ASSETLINKS")"
            if ! printf '%s' "$HUELLA" | grep -qE '^([0-9A-Fa-f]{2}:){31}[0-9A-Fa-f]{2}$'; then
              falla "$ASSETLINKS[$i]: huella #$j no son 32 bytes en hex separados por ':' ('$HUELLA')."
            fi
            if printf '%s' "$HUELLA" | grep -qi 'completar'; then
              falla "$ASSETLINKS[$i]: huella #$j es un valor de relleno."
            fi
            j=$((j + 1))
          done
        fi
        i=$((i + 1))
      done
      [ "$ROJO" -eq 0 ] && ok "$ASSETLINKS: relation, namespace, package_name y huellas con forma válida."
    fi
  fi
fi

# --- --en-vivo: contra producción ya desplegada ---
if [ "$EN_VIVO" -eq 1 ]; then
  echo ""
  echo "--en-vivo: midiendo contra https://farouniversal.com.ar/.well-known/ ..."
  for archivo in apple-app-site-association assetlinks.json; do
    URL="https://farouniversal.com.ar/.well-known/$archivo"
    if [ -f ".well-known/$archivo" ]; then
      LOCAL_EXISTE=1
    else
      LOCAL_EXISTE=0
    fi
    # -w con %{http_code}/%{content_type}/%{redirect_url}: pedirle a curl que
    # resuelva el código final es más confiable que parsear el primer
    # renglón de cabeceras a mano — con un proxy HTTP delante (como el de
    # este sandbox) ese primer renglón es el "200 Connection established"
    # del CONNECT, no la respuesta real.
    INFO="$(curl -s -o /tmp/verificar-well-known-body.$$ --max-redirs 0 \
      -w '%{http_code}\t%{content_type}\t%{redirect_url}' "$URL" 2>/dev/null)"
    CODIGO="$(printf '%s' "$INFO" | cut -f1)"
    CONTENT_TYPE="$(printf '%s' "$INFO" | cut -f2)"
    LOCATION="$(printf '%s' "$INFO" | cut -f3)"
    rm -f /tmp/verificar-well-known-body.$$
    if [ "$LOCAL_EXISTE" -eq 0 ]; then
      # El archivo real todavía no se generó/publicó (T1691 parcial): un 404
      # en vivo es el estado ESPERADO, no un rojo de esta prueba.
      if [ "$CODIGO" = "200" ]; then
        falla "$URL → 200, pero .well-known/$archivo no existe en este árbol — hay algo publicado que este repo no tiene registrado."
      else
        echo "ℹ️  $URL → $CODIGO (esperado: el archivo real todavía no está publicado, T1691 parcial)."
      fi
    else
      if [ "$CODIGO" != "200" ]; then
        falla "$URL → $CODIGO (esperado 200 — el archivo local existe, así que debería estar publicado)."
      else
        ok "$URL → 200, $CONTENT_TYPE"
      fi
      if [ -n "$LOCATION" ]; then
        falla "$URL redirige ($LOCATION) — Apple/Google no siguen redirecciones para estos archivos."
      fi
    fi
  done
fi

if [ "$ROJO" -eq 1 ]; then
  echo ""
  echo "🚨 verificar-well-known.sh: hay algo con forma inválida o un valor de relleno arriba."
  exit 1
fi

echo ""
echo "✅ verificar-well-known.sh: todo lo que existe tiene forma válida."
exit 0
