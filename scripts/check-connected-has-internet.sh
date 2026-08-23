#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Chequeo hermano de check-no-internet.sh, en el sentido contrario: confirma
# que el flavor "connected" SÍ declara android.permission.INTERNET en su
# manifiesto fusionado de release.
#
# ¿Por qué molestarse en verificar esto? Porque si algún día alguien reordena
# los flavors, borra src/connected/AndroidManifest.xml por accidente, o rompe
# el merge, el chat en línea fallaría en runtime de una forma confusa
# (timeouts silenciosos) en vez de un error claro en CI. Este script convierte
# ese error en algo que se detecta ANTES de publicar, no después.
#
# Uso (tras `flutter build apk --flavor connected --release`):
#   bash scripts/check-connected-has-internet.sh
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "── Verificando que el manifiesto de RELEASE del flavor 'connected' SÍ declare INTERNET ──"

mapfile -t MANIFESTS < <(
  find build android/app/build -type f -name AndroidManifest.xml 2>/dev/null \
    | grep -iE 'merged_manifest' \
    | grep -iE 'connected' \
    | grep -iE 'release' \
    | sort -u
)

if [ "${#MANIFESTS[@]}" -eq 0 ]; then
  echo "::error::No se encontró ningún AndroidManifest.xml fusionado de connected+release."
  echo "Compila primero (flutter build apk --flavor connected --release) y vuelve a ejecutar."
  exit 2
fi

FOUND=0
for manifest in "${MANIFESTS[@]}"; do
  echo "  revisando: $manifest"
  if grep -q 'android.permission.INTERNET' "$manifest"; then
    FOUND=1
  fi
done

if [ "$FOUND" -eq 0 ]; then
  echo "::error::Ningún manifiesto de 'connected' declara INTERNET — el chat en línea no podría funcionar."
  echo "Revisá android/app/src/connected/AndroidManifest.xml y el flavor en build.gradle.kts."
  exit 1
fi

echo "OK: el flavor 'connected' declara INTERNET como se espera."
