#!/usr/bin/env bash
# =============================================================================
# build-site.sh — Handbuch und Beispielpräsentationen für die eigene Seite
# =============================================================================
# Aufruf aus dem Repo-Wurzelverzeichnis:
#
#     AGGREGAT=/pfad/zu/Typst-Schule bash .github/scripts/build-site.sh
#
# Ergebnis in _site/:
#     index.html, docs.css, typstage.pdf     das Handbuch
#     beispiele/*.html, beispiele/index.html die Decks zum Anklicken
#
# Warum ein fremdes Repo gebraucht wird: docs/docs.typ setzt auf
# @schule/schuldocs, und das liegt in Typst-Schule. Diese Abhängigkeit besteht
# ohnehin — deshalb wird von dort auch gleich der Erzeuger der Beispiel-
# Übersicht mitbenutzt, statt eine zweite Fassung zu pflegen, die abdriftet.
# =============================================================================

set -euo pipefail

WURZEL="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
AGGREGAT="${AGGREGAT:?AGGREGAT muss auf eine Kopie von Typst-Schule zeigen}"
ZIEL="$WURZEL/_site"
VERSION="$(sed -n 's/^version *= *"\(.*\)"/\1/p' "$WURZEL/typst.toml" | head -1)"
PAKETPFAD="$(mktemp -d)"

trap 'rm -rf "$PAKETPFAD"' EXIT

# Paketpfad zusammenstellen: schuldocs aus dem Aggregat, typstage aus *diesem*
# Stand — nicht aus dem Submodul des Aggregats, das älter sein kann.
mkdir -p "$PAKETPFAD/schule/typstage"
cp -R "$AGGREGAT/schuldocs" "$PAKETPFAD/schule/schuldocs"
ln -s "$WURZEL" "$PAKETPFAD/schule/typstage/$VERSION"

rm -rf "$ZIEL"
mkdir -p "$ZIEL"
typst --version
echo "=== typstage $VERSION ==="

# --- Handbuch (Website, Stilvorlage und PDF in einem Bündel-Lauf) ------------
(
  cd "$WURZEL/docs"
  typst compile \
    --format bundle \
    --features bundle,html \
    --package-path "$PAKETPFAD" \
    --root "$WURZEL" \
    docs.typ \
    "$ZIEL" \
    2>&1 | awk '!/^ *warning: (bundle|html) export/ && !/^ *= hint:/ && NF { print }'
  exit "${PIPESTATUS[0]}"
)
[[ -f "$ZIEL/index.html" ]] || { echo "FEHLER: Handbuch ohne index.html" >&2; exit 1; }
echo "  → Handbuch: index.html, docs.css$(cd "$ZIEL" && ls *.pdf 2>/dev/null | sed 's/^/, /' | tr -d '\n')"

# --- Beispielpräsentationen -------------------------------------------------
namen=()
mkdir -p "$ZIEL/beispiele"
for bsp in "$WURZEL/examples"/*.typ; do
  [[ -e "$bsp" ]] || continue
  name="$(basename "${bsp%.typ}")"
  (
    cd "$WURZEL/examples"
    typst compile \
      --format html \
      --features html \
      --package-path "$PAKETPFAD" \
      --root "$WURZEL" \
      "$(basename "$bsp")" \
      "$ZIEL/beispiele/$name.html" \
      2>&1 | awk '!/^ *warning: html export/ && !/^ *= hint:/ && NF { print }'
    exit "${PIPESTATUS[0]}"
  ) && [[ -s "$ZIEL/beispiele/$name.html" ]] || {
    echo "FEHLER: Beispiel $name ließ sich nicht bauen" >&2
    exit 1
  }
  namen+=("$name")
done

[[ ${#namen[@]} -gt 0 ]] || { echo "FEHLER: keine Beispiele gebaut" >&2; exit 1; }
 # Medien neben einem Beispiel reisen mit: `video("demo.mp4")` verweist
 # auf eine Datei, die neben der HTML-Seite liegen muss.
 for bei in "$WURZEL/examples"/*; do
   case "$bei" in *.typ) continue;; esac
   [ -f "$bei" ] && cp "$bei" "$ZIEL/beispiele/"
 done

BSP_PAKET="typstage" BSP_VERSION="$VERSION" BSP_NAMEN="${namen[*]}" \
  python3 "$AGGREGAT/.github/scripts/beispiele-index.py" "$ZIEL/beispiele/index.html"
echo "  → Beispiele: ${#namen[@]} Präsentationen (${namen[*]})"
echo "=== fertig in $ZIEL ==="
