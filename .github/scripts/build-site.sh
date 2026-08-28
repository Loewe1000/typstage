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
#     en.html, typstage-en.pdf               das englische Handbuch
#     llms.txt                               eine Zeile je Kapitel, für Maschinen
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

# Kein Begleitpaket mehr im Paketpfad: GeoGebra steckt seit der Zusammenlegung
# im Kern, und kein Handbuchbeispiel importiert noch ein zweites @schule-Paket.
# Die Vorkehrung im Beispielprüfer bleibt trotzdem stehen -- sie gilt jedem
# künftigen Begleiter, nicht diesem einen.

typst --version
echo "=== typstage $VERSION ==="

# --- Beispiele in den Handbüchern -------------------------------------------
# Vor dem Satz, nicht danach: ein Beispiel, das nicht mehr übersetzt, soll den
# Bau anhalten und nicht als hübsch gesetzter Fehler auf der Website landen.
# Und vor dem Aufräumen von `_site`, damit ein Fehlschlag nicht auch noch die
# vorhandene Fassung mitnimmt.
python3 "$WURZEL/.github/scripts/pruefe-beispiele.py" --paketpfad "$PAKETPFAD"

rm -rf "$ZIEL"
mkdir -p "$ZIEL"

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
echo "  → Handbuch: index.html, docs.css, typstage.pdf"

# --- Englisches Handbuch ----------------------------------------------------
# Eigener Lauf, weil `docs()` eine Show-Regel ist und je Datei genau zwei
# Ausgaben schreibt. Die Datei nennt ihre Ausgaben selbst (`en.html`,
# `typstage-en.pdf`), landet also neben der deutschen, ohne sie zu überschreiben;
# `docs.css` schreiben beide, mit demselben Inhalt.
if [[ -f "$WURZEL/docs/manual-en.typ" ]]; then
  (
    cd "$WURZEL/docs"
    typst compile \
      --format bundle \
      --features bundle,html \
      --package-path "$PAKETPFAD" \
      --root "$WURZEL" \
      manual-en.typ \
      "$ZIEL" \
      2>&1 | awk '!/^ *warning: (bundle|html) export/ && !/^ *= hint:/ && NF { print }'
    exit "${PIPESTATUS[0]}"
  )
  [[ -f "$ZIEL/en.html" ]] || { echo "FEHLER: englisches Handbuch ohne en.html" >&2; exit 1; }
  echo "  → Manual (en): en.html, typstage-en.pdf"
fi

# --- llms.txt ---------------------------------------------------------------
# Aus den gebauten Seiten, nicht aus `docs/content.typ`: die Sprungmarken
# vergibt schuldocs beim Setzen, und zweimal ausgerechnet driften sie auseinander.
python3 "$WURZEL/.github/scripts/llms-txt.py" "$ZIEL"

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
 #
 # `cp -R` und nicht `cp`: hier stand einmal `[ -f "$bei" ] && cp …`, und das
 # sprang über jedes Verzeichnis hinweg -- wortlos, denn eine fehlgeschlagene
 # `&&`-Liste als letzter Befehl im Schleifenrumpf beendet auch unter `set -e`
 # nichts. Vier Unterordner in `examples/` wurden so übersprungen. Folgenlos
 # war das nur, weil `image()` von Typst als `data:`-URI eingebettet wird und
 # die einzige `video()`-Datei oben liegt; ein `video("medien/clip.mp4")`
 # hätte auf der Seite ein leeres Videofenster ergeben, ohne eine Meldung im
 # Bau. `render.typ` schreibt den Pfad wörtlich in die HTML, und der Browser
 # löst ihn relativ zur Seite auf.
 for bei in "$WURZEL/examples"/*; do
   case "$bei" in *.typ) continue;; esac
   cp -R "$bei" "$ZIEL/beispiele/"
 done

BSP_PAKET="typstage" BSP_VERSION="$VERSION" BSP_NAMEN="${namen[*]}" \
  python3 "$AGGREGAT/.github/scripts/beispiele-index.py" "$ZIEL/beispiele/index.html"
echo "  → Beispiele: ${#namen[@]} Präsentationen (${namen[*]})"
echo "=== fertig in $ZIEL ==="
