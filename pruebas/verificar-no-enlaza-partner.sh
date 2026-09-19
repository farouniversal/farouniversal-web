#!/bin/bash
# pruebas/verificar-no-enlaza-partner.sh — T1716: farouniversal-web (y el
# material de redes, si está en disco) no puede enlazar nunca la web de
# Faro Partner. Calcado de pruebas/verificar-no-enlaza-connect.sh (T1674,
# mismo mecanismo/estilo para Faro Connect), aplicado ahora al host de
# Faro Partner: partner.farouniversal.com.ar (confirmado en
# informes/phone-app-architect-T1637-web-faro-partner-20260918.md, no
# publicado todavía — panel del discernidor de T1637 sigue sin cerrar si
# se publica o no; el chequeo la cuida desde antes de que exista el link
# real, igual que T1674 cuidó a Connect).
#
# Qué prohíbe: cualquier URL de la web de Faro Partner
# (partner.farouniversal.com.ar) apareciendo como link en este repo. El
# dominio se arma con printf para que este mismo archivo no se detecte a
# sí mismo.
#
#   0 = OK   — ningún archivo enlaza la web de Partner.
#   1 = ROJO — algún archivo la enlaza. Se listan los hits.
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR" || exit 1

# El dominio prohibido, armado en partes para no auto-detectarse.
DOMINIO="partner.farouniversal$(printf '.com.ar')"
PATRON="https?://${DOMINIO}"

ENCONTRADO=0

verificar_archivo() {
  local archivo="$1"
  local etiqueta="$2"
  [ -f "$archivo" ] || return 0
  local hits
  hits="$(grep -InE "$PATRON" -- "$archivo" 2>/dev/null | grep -v 'verificar-no-enlaza-partner\.sh')"
  if [ -n "$hits" ]; then
    echo "❌ $etiqueta enlaza $DOMINIO:"
    echo "$hits" | sed 's/^/   /'
    ENCONTRADO=1
  fi
}

# 1) El propio repo farouniversal-web: todo lo trackeado por git, menos
#    este script (que necesariamente nombra el dominio para poder buscarlo).
while IFS= read -r f; do
  verificar_archivo "$f" "farouniversal-web:$f"
done < <(git -C "$DIR" ls-files -- ':!:pruebas/verificar-no-enlaza-partner.sh')

# 2) Material de redes, best-effort: si el checkout tiene el resto del
#    árbol de Faro al lado (no es un requisito — en un checkout aislado de
#    solo este repo, simplemente no hay nada que mirar acá), se revisan los
#    repos donde vive contenido de marketing/redes.
RAIZ_GIT_COMMON="$(git -C "$DIR" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)"
if [ -n "$RAIZ_GIT_COMMON" ]; then
  RAIZ_FARO="$(cd "$(dirname "$RAIZ_GIT_COMMON")/.." && pwd)"
  for repo_relativo in "farouniversal-sa/marketing" "faro-media/contenidos" "faro-media/catalogo"; do
    ruta="$RAIZ_FARO/$repo_relativo"
    [ -d "$ruta" ] || continue
    while IFS= read -r f; do
      verificar_archivo "$f" "redes:${f#"$RAIZ_FARO"/}"
    done < <(find "$ruta" -type f \( -name '*.md' -o -name '*.html' -o -name '*.txt' \) 2>/dev/null)
  done
fi

if [ "$ENCONTRADO" -eq 1 ]; then
  echo "🚨 verificar-no-enlaza-partner.sh: hay un link a la web de Faro Partner — sacalo (T1716/T1635 punto 4: no se enlaza nunca desde nada público)."
  exit 1
fi

echo "✅ verificar-no-enlaza-partner.sh: nadie enlaza $DOMINIO"
exit 0
