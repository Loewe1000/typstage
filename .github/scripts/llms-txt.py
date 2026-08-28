#!/usr/bin/env python3
# =============================================================================
# llms-txt.py — llms.txt für die Website, aus den gebauten Handbüchern
# =============================================================================
# Aufruf nach dem Handbuchbau, aus dem Repo-Wurzelverzeichnis:
#
#     python3 .github/scripts/llms-txt.py _site
#
# Ergebnis: `_site/llms.txt`, eine Zeile je Kapitel, Titel und erster Satz,
# beide Sprachen. Das Format ist llmstxt.org: eine Überschrift, ein Zitatblock
# mit der Kurzbeschreibung, dann Listen aus Verweisen.
#
# Warum aus dem *gebauten* HTML und nicht aus `docs/content.typ`: die
# Sprungmarken (`#die-erste-praesentation`) vergibt `schuldocs` beim Setzen,
# mit eigenen Regeln für Umlaute. Würde diese Datei sie noch einmal ausrechnen,
# hätte das Projekt zwei Fassungen derselben Regel, und die eine würde von der
# anderen wegdriften — genau das, was die Datei verhindern soll. Aus dem HTML
# gelesen kann eine Sprungmarke hier gar nicht falsch sein.
# =============================================================================

import html
import os
import re
import sys
import tomllib

WURZEL = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

# <h2 id="…">Titel<a class="anker" …>#</a></h2> und der Absatz darunter.
#
# ACHTUNG, wenn das Handbuch je Kapitel in eine eigene Datei geschrieben wird:
# heute sind die Kapitel `<h2>`, weil alle auf einer Seite stehen und `<h1>` der
# Titel des Handbuchs ist. Auf einer Seite je Kapitel wird das Kapitel zum
# `<h1>` und die Abschnitte werden zu `<h2>` -- derselbe Ausdruck liest dann
# eine Ebene tiefer. Am Prototyp gemessen: 12 Treffer statt der erwarteten
# Kapitel. Wer aufteilt, passt hier die Ebene an; die Dateiliste darunter
# stimmt bereits.
KAPITEL = re.compile(
  r'<h2 id="([^"]+)">(.*?)(?:<a class="anker".*?</a>)?</h2>\s*<p>(.*?)</p>',
  re.S)


def text(roh):
  """HTML-Schnipsel zu gewöhnlichem Text."""
  return html.unescape(re.sub(r"<[^>]+>", "", roh)).strip()


def erster_satz(absatz):
  """Bis zum ersten Punkt, der wirklich einen Satz schließt. Auf ihn muss ein
  Großbuchstabe folgen oder das Ende, damit „0.15" nicht trennt; und davor darf
  kein einzeln stehender Buchstabe sein, damit „z. B." es auch nicht tut."""
  t = " ".join(absatz.split())
  treffer = re.search(r"(?<!\b[A-Za-zÄÖÜäöü])[.!?](?=\s+[A-ZÄÖÜ„\"]|$)", t)
  return t[:treffer.end()] if treffer else t


def kapitel(pfad):
  roh = open(pfad, encoding="utf-8").read()
  return [(marke, text(titel), erster_satz(text(absatz)))
          for marke, titel, absatz in KAPITEL.findall(roh)]


# Ein Verweis im Inhaltsverzeichnis: entweder `#marke` auf derselben Seite oder
# `datei.html#marke` auf einer anderen.
TOC_ZIEL = re.compile(r'<nav class="inhalt".*?</nav>', re.S)
TOC_VERWEIS = re.compile(r'href="([^"#]*)#[^"]*"')


def seitenliste(ziel, einstieg):
  """Welche Dateien die Kapitel dieses Handbuchs tragen.

  Heute ist das nur die Einstiegsseite: das Inhaltsverzeichnis verweist mit
  blossen `#marke` auf dieselbe Datei. Wird das Handbuch spaeter je Kapitel in
  eine eigene Datei geschrieben, stehen dort `kapitel.html#marke`, und dann
  liest diese Funktion sie heraus.

  Warum aus dem Inhaltsverzeichnis und nicht aus einer Liste hier: dieselbe
  Ueberlegung wie bei den Sprungmarken weiter oben. Wer die Dateinamen hier
  noch einmal aufschreibt, hat zwei Fassungen derselben Wahrheit, und die eine
  driftet von der anderen weg. Was das gebaute Inhaltsverzeichnis nennt, ist
  das, was es gibt.
  """
  pfad = os.path.join(ziel, einstieg)
  if not os.path.exists(pfad):
    return []
  roh = open(pfad, encoding="utf-8").read()
  dateien = [einstieg]
  toc = TOC_ZIEL.search(roh)
  if toc:
    for datei in TOC_VERWEIS.findall(toc.group(0)):
      if datei and datei not in dateien and os.path.exists(os.path.join(ziel, datei)):
        dateien.append(datei)
  return dateien


def haupt(ziel):
  paket = tomllib.load(open(os.path.join(WURZEL, "typst.toml"), "rb"))["package"]
  # Die Adresse der Seite steht nirgends eigens; sie folgt aus dem Repo.
  nutzer, repo = paket["repository"].rstrip("/").split("/")[-2:]
  basis = "https://%s.github.io/%s/" % (nutzer.lower(), repo)

  seiten = [
    ("Handbuch (Deutsch)", "index.html"),
    ("Manual (English)", "en.html"),
  ]
  zeilen = [
    "# %s %s" % (paket["name"], paket["version"]),
    "",
    "> " + " ".join(paket["description"].split()),
    "",
    ("Zwei Handbücher aus einer Quelle, je eine Seite. Die Sprungmarken unten "
     "führen in das jeweilige Kapitel; die PDF-Fassungen liegen unter "
     "`typstage.pdf` und `typstage-en.pdf`."),
  ]
  gesamt = 0
  for name, einstieg in seiten:
    dateien = seitenliste(ziel, einstieg)
    if not dateien:
      continue
    zeilen += ["", "## " + name, ""]
    for datei in dateien:
      # `index.html` ist die Wurzel der Seite; ein Verweis darauf braucht den
      # Dateinamen nicht und saehe mit ihm auch nicht aus wie eine Startseite.
      anhang = "" if datei == "index.html" else datei
      for marke, titel, satz in kapitel(os.path.join(ziel, datei)):
        zeilen.append("- [%s](%s%s#%s): %s" % (titel, basis, anhang, marke, satz))
        gesamt += 1

  zeilen += [
    "",
    "## Quelle",
    "",
    "- [Repository](%s): Paketquellen, Beispieldecks und der Seitenbau."
    % paket["repository"],
    "- [Beispiele](%sbeispiele/): die siebzehn Beispielpräsentationen, laufend "
    "im Browser." % basis,
    "",
  ]
  raus = os.path.join(ziel, "llms.txt")
  open(raus, "w", encoding="utf-8").write("\n".join(zeilen))
  print("  → llms.txt: %d Kapitel" % gesamt)
  return 0 if gesamt else 1


if __name__ == "__main__":
  sys.exit(haupt(sys.argv[1] if len(sys.argv) > 1 else os.path.join(WURZEL, "_site")))
