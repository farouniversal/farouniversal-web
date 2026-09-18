#!/bin/bash
# scripts/generar-well-known.sh — T1691: genera los dos archivos de
# asociación de passkeys (apple-app-site-association y assetlinks.json) a
# partir de passkeys-apps.json, la fuente de datos de ESTE repo.
#
# Regla dura (T1691): NUNCA se escribe un archivo con un valor de relleno.
# Si a alguna app le falta el Team ID de iOS o la huella SHA-256 de Android,
# este script se niega a generar los archivos reales — lo dice y sale 1.
# Mejor no tener el archivo que tenerlo con un dato falso: un valor inventado
# rompería en silencio la verificación de iOS/Android (no da error visible,
# simplemente ninguna passkey de ese dominio funciona en la app nativa).
#
# Uso: scripts/generar-well-known.sh
#   0 = generados .well-known/apple-app-site-association y
#       .well-known/assetlinks.json a partir de passkeys-apps.json.
#   1 = falta algún dato (Team ID / huella) o el JSON de datos es inválido —
#       no se escribió nada.
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR" || exit 1

DATOS="passkeys-apps.json"
DESTINO=".well-known"

if ! command -v jq >/dev/null 2>&1; then
  echo "🚨 generar-well-known.sh: falta 'jq' (se usa para leer $DATOS)."
  exit 1
fi

if [ ! -f "$DATOS" ]; then
  echo "🚨 generar-well-known.sh: no existe $DATOS."
  exit 1
fi

if ! jq empty "$DATOS" >/dev/null 2>&1; then
  echo "🚨 generar-well-known.sh: $DATOS no es JSON válido."
  exit 1
fi

N_APPS="$(jq '.apps | length' "$DATOS")"
if [ "$N_APPS" -lt 1 ]; then
  echo "🚨 generar-well-known.sh: $DATOS no tiene ninguna app en 'apps'."
  exit 1
fi

FALTA=0
i=0
while [ "$i" -lt "$N_APPS" ]; do
  APP_NOMBRE="$(jq -r ".apps[$i].app" "$DATOS")"
  TEAM_ID="$(jq -r ".apps[$i].ios.teamId" "$DATOS")"
  N_HUELLAS="$(jq ".apps[$i].android.sha256CertFingerprints | length" "$DATOS")"

  # Team ID de Apple Developer: exactamente 10 caracteres alfanuméricos.
  if [ "$TEAM_ID" = "null" ] || [ -z "$TEAM_ID" ]; then
    echo "🚨 falta ios.teamId para '$APP_NOMBRE' en $DATOS."
    FALTA=1
  elif ! printf '%s' "$TEAM_ID" | grep -qE '^[A-Za-z0-9]{10}$'; then
    echo "🚨 ios.teamId de '$APP_NOMBRE' no tiene forma de Team ID válido (10 caracteres alfanuméricos): '$TEAM_ID'."
    FALTA=1
  fi

  # Huella SHA-256: 32 bytes en hex separados por ':' (95 caracteres).
  if [ "$N_HUELLAS" -lt 1 ]; then
    echo "🚨 falta android.sha256CertFingerprints para '$APP_NOMBRE' en $DATOS."
    FALTA=1
  else
    j=0
    while [ "$j" -lt "$N_HUELLAS" ]; do
      HUELLA="$(jq -r ".apps[$i].android.sha256CertFingerprints[$j]" "$DATOS")"
      if ! printf '%s' "$HUELLA" | grep -qE '^([0-9A-Fa-f]{2}:){31}[0-9A-Fa-f]{2}$'; then
        echo "🚨 huella SHA-256 #$j de '$APP_NOMBRE' no son 32 bytes en hex separados por ':': '$HUELLA'."
        FALTA=1
      fi
      j=$((j + 1))
    done
  fi

  # Ningún valor de relleno textual conocido, en ningún campo del app.
  if jq -e ".apps[$i] | .. | strings | test(\"COMPLETAR\"; \"i\")" "$DATOS" >/dev/null 2>&1; then
    echo "🚨 '$APP_NOMBRE' tiene un valor de relleno tipo COMPLETAR en $DATOS."
    FALTA=1
  fi

  i=$((i + 1))
done

if [ "$FALTA" -eq 1 ]; then
  echo "🛑 generar-well-known.sh: no se escribió ningún archivo — completá los datos en $DATOS primero (ver necesito-a-fernan/T1691-team-id-y-huella-de-firma.md)."
  exit 1
fi

mkdir -p "$DESTINO"

# apple-app-site-association — sin extensión (así lo exige iOS), clave
# webcredentials.apps con "<TeamID>.<bundleId>" por app.
jq -n --slurpfile datos "$DATOS" '
  {
    webcredentials: {
      apps: [$datos[0].apps[] | (.ios.teamId + "." + .ios.bundleId)]
    }
  }
' > "$DESTINO/apple-app-site-association"

# assetlinks.json — relación delegate_permission/common.get_login_creds
# (NO handle_all_urls: no se quiere que Android abra la app con cualquier
# link del dominio, sólo que confíe en las credenciales de esta app).
jq -n --slurpfile datos "$DATOS" '
  [$datos[0].apps[] | {
    relation: ["delegate_permission/common.get_login_creds"],
    target: {
      namespace: "android_app",
      package_name: .android.packageName,
      sha256_cert_fingerprints: .android.sha256CertFingerprints
    }
  }]
' > "$DESTINO/assetlinks.json"

echo "✅ generar-well-known.sh: escritos $DESTINO/apple-app-site-association y $DESTINO/assetlinks.json ($N_APPS app(s))."
echo "   Corré pruebas/verificar-well-known.sh y, contra producción ya desplegada, con --en-vivo."
exit 0
