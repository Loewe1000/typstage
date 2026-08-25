#!/usr/bin/env python3
# =============================================================================
# pruefe-beispiele.py — jedes Codebeispiel der Handbücher gegen das echte Paket
# =============================================================================
# Aufruf aus dem Repo-Wurzelverzeichnis:
#
#     python3 .github/scripts/pruefe-beispiele.py
#     python3 .github/scripts/pruefe-beispiele.py --leise   # nur die Bilanz
#     python3 .github/scripts/pruefe-beispiele.py --paketpfad /pfad
#
# Rückgabewert 0, wenn alles hält, sonst 1. `--paketpfad` wird an typst als
# `--package-path` durchgereicht, für Läufe außerhalb eines eingerichteten
# Paketverzeichnisses; der Seitenbau gibt seinen eigenen mit.
#
# Warum es das gibt: die beiden Handbücher enthalten über tausend Zeilen
# Beispielcode. Ohne diesen Lauf prüft sie niemand gegen die Quelle, und ein
# Beispiel, das nach einer Umbenennung nicht mehr übersetzt, fällt erst dem
# Leser auf. Der Lauf holt jeden ```typ-Block aus `docs/content.typ` und
# `docs/content-en.typ`, setzt ihn in eine übersetzbare Hülle und ruft `typst`
# darauf. Dazu kommt jede Datei unter `examples/`, die ein Handbuch mit
# `read(…)` einbindet, statt sie abzuschreiben: die wird als ganze Datei
# übersetzt.
#
# --- Was die Hülle leistet, und was nicht ------------------------------------
# Die meisten Blöcke sind Bruchstücke: `#fit(wrap: false, meine-tabelle)` ist
# keine Datei. Der Prüfer legt darum je nach Art des Blocks etwas darum:
#
#   ganz     der Block ist schon eine vollständige Datei (er importiert das
#            Paket selbst) und wird unverändert übersetzt
#   dokument Import davor; der Block bringt seine eigene Show-Regel mit
#   folgen   Import und `#show: presentation.with()` davor; der Block ist eine
#            oder mehrere Folien und fängt mit einer Überschrift an
#   folie    Import, Show-Regel und eine Überschrift davor; der Block ist der
#            Rumpf einer einzelnen Folie (die Vorgabe)
#
# Die Art wird geraten, und das Raten ist grob: Import im Block heißt „ganz",
# eine Zeile, die mit `#show: presentation` oder `#show: bundle` anfängt, heißt
# „dokument", eine Zeile, die mit `=` anfängt, heißt „folgen", sonst „folie".
# Wo das Raten danebenliegt oder ein Block mehr braucht, steht im Handbuch eine
# Prüfzeile darüber. Sie ist ein gewöhnlicher Typst-Kommentar, steht außerhalb
# des Codeblocks und erscheint deshalb weder im PDF noch auf der Website:
#
#     // check: folie pre=tabelle
#     #show-code[```typ
#     #fit(wrap: false, meine-tabelle)
#     ```]
#
# Eine Prüfzeile gilt für den nächsten ```typ-Block, der ihr folgt. Der
# Schlüssel steht in beiden Handbüchern gleich, damit ein Prüfer genügt.
#
#     check: ganz | dokument | folgen | folie
#     check: aus=<grund>          nicht übersetzen, Grund erscheint im Bericht
#     ziel=bundle                 mit --format bundle statt --format html
#     pre=<name>                  benannten Vorspann davorsetzen (siehe VORSPANN)
#     davor                       den vorigen ```typ-Block desselben Handbuchs
#                                 davorsetzen (für Beispiele, die auf einem
#                                 `#let` aus dem Absatz darüber aufbauen)
#     dateien=a.png,b.mp4         genannte Dateien als Platzhalter anlegen
#     fehlt=2                     Zeile 2 des Blocks *muss* fehlschlagen; der
#                                 Rest muss übersetzen. Für Gegenüberstellungen
#                                 („so — nicht so"). Übersetzt sie plötzlich, ist
#                                 das ein Fehler, kein Erfolg.
#     weil=cannot stand inside    Woran sie fehlschlagen muss. Ohne diese Angabe
#                                 zählt jeder Fehlschlag, auch ein Tippfehler
#                                 oder eine vergessene Einbindung -- und dann
#                                 besteht der Test aus dem falschen Grund. Der
#                                 Text muss in der Meldung von `typst` vorkommen.
#
# Ein Beispiel, das ein Begleitpaket braucht, das im Paketpfad nicht liegt,
# wird gemeldet und übersprungen, nicht als Fehler ausgegeben.
#
# Ehrlich gesagt, was das *nicht* prüft: ob das Beispiel das Richtige *zeigt*.
# Der Lauf sagt „übersetzt" und „übersetzt nicht", mehr nicht. Er sieht die
# Folie nicht an. Und ein Bruchstück wird in einer Hülle geprüft, nicht in der
# Umgebung, aus der der Text es geschnitten hat.
# =============================================================================

import argparse
import base64
import os
import re
import shutil
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor

WURZEL = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
HANDBUECHER = ["docs/content.typ", "docs/content-en.typ"]
IMPORT = '#import "@schule/typstage:0.1.0": *\n'

# Namen, die die Handbücher als Platzhalter benutzen, ohne sie zu erklären —
# „meine-tabelle" steht im Text für „irgendeine Tabelle". Der Prüfer muss
# etwas darunter legen, sonst prüft er nur, dass ein Name fehlt.
VORSPANN = {
  "tabelle": (
    "#let meine-tabelle = table(columns: 2, [Jahr], [Wert], [2024], [7])\n"
    "#let my-table = meine-tabelle\n"
  ),
}

# Ein 1x1-Pixel-PNG. `image()` liest die Datei beim Übersetzen, ein leerer
# Platzhalter genügt ihr also nicht.
PNG = base64.b64decode(
  "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk"
  "+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
)

PAKET = re.compile(r'"@schule/([a-z0-9-]+):([0-9.]+)"')
FENCE = re.compile(r"(`{3,})([a-zA-Z][a-zA-Z0-9]*)\s*$")
PRUEFZEILE = re.compile(r"^\s*//\s*check:\s*(.+?)\s*$")
LESEN = re.compile(r'read\(\s*"((?:\.\./)*examples/[^"]+\.typ)"\s*\)')


def paketwurzeln(paketpfad):
  """Wo Typst nach `@schule/...` sucht. Der Prüfer schaut selbst nach, damit er
  ein fehlendes Begleitpaket melden kann, statt es als Fehler auszugeben."""
  # `--package-path` ersetzt bei typst das Vorgabeverzeichnis, es kommt nicht
  # dazu. Der Prüfer muss deshalb genauso schauen, sonst hält er ein Paket für
  # vorhanden, das der Übersetzer nicht sieht.
  if paketpfad:
    return [paketpfad] if os.path.isdir(paketpfad) else []
  wurzeln = []
  daten = os.environ.get("XDG_DATA_HOME")
  wurzeln += [
    os.path.expanduser("~/Library/Application Support/typst/packages"),
    os.path.join(daten, "typst", "packages") if daten
    else os.path.expanduser("~/.local/share/typst/packages"),
  ]
  return [w for w in wurzeln if os.path.isdir(w)]


def fehlende_pakete(quelle, wurzeln):
  """Welche @schule-Pakete eines Blocks nirgends im Paketpfad liegen.

  Gefragt wird nach der `typst.toml`, nicht nach dem Verzeichnis. Ein
  Begleitpaket ist im Aggregat ein Submodul, und ein Checkout ohne
  `submodules: true` legt sein Verzeichnis leer an. Auf das Verzeichnis zu
  sehen hieße dort "vorhanden", der Block liefe los, und `typst` bräche an der
  fehlenden `typst.toml` ab -- statt dass der Lauf ihn sauber überspringt.
  Genau so ist der Seitenbau in der CI gestorben.
  """
  fehlt = []
  for name, version in set(PAKET.findall(quelle)):
    if not any(os.path.isfile(os.path.join(w, "schule", name, version, "typst.toml"))
               for w in wurzeln):
      fehlt.append("@schule/%s:%s" % (name, version))
  return sorted(fehlt)


def dedent(zeilen):
  """Führende Leerzeichen abziehen, wie Typst es beim Setzen des Blocks tut."""
  tiefe = min([len(z) - len(z.lstrip()) for z in zeilen if z.strip()] or [0])
  return "\n".join(z[tiefe:] if z.strip() else "" for z in zeilen)


def bloecke(pfad):
  """Alle Codeblöcke einer Handbuchdatei, mit ihrer Prüfzeile."""
  zeilen = open(pfad, encoding="utf-8").read().split("\n")
  gefunden, offen, i = [], None, 0
  while i < len(zeilen):
    treffer = FENCE.search(zeilen[i])
    if treffer:
      zaun, sprache = treffer.group(1), treffer.group(2)
      schluss = re.compile(r"^\s*" + zaun)
      j, rumpf = i + 1, []
      while j < len(zeilen) and not schluss.match(zeilen[j]):
        rumpf.append(zeilen[j])
        j += 1
      gefunden.append({
        "datei": pfad, "zeile": i + 1, "sprache": sprache,
        "rumpf": dedent(rumpf), "regie": offen,
      })
      offen, i = None, j + 1
      continue
    p = PRUEFZEILE.match(zeilen[i])
    if p:
      offen = p.group(1)
    i += 1
  return gefunden


def regie_lesen(text):
  """Eine Prüfzeile in ein Wörterbuch übersetzen."""
  r = {"art": None, "aus": None, "ziel": "html", "pre": [], "davor": False,
       "dateien": [], "fehlt": [], "weil": None}
  for wort in (text or "").split():
    if wort in ("ganz", "dokument", "folgen", "folie", "argument"):
      r["art"] = wort
    elif wort == "davor":
      r["davor"] = True
    elif wort.startswith("aus="):
      r["aus"] = wort[4:].replace("_", " ")
    elif wort.startswith("ziel="):
      r["ziel"] = wort[5:]
    elif wort.startswith("pre="):
      r["pre"] += wort[4:].split(",")
    elif wort.startswith("dateien="):
      r["dateien"] += wort[8:].split(",")
    elif wort.startswith("fehlt="):
      r["fehlt"] += [int(n) for n in wort[6:].split(",")]
    elif wort.startswith("weil="):
      r["weil"] = wort[5:].replace("_", " ")
    else:
      raise SystemExit("unbekanntes Wort in einer Prüfzeile: " + wort)
  return r


def art_raten(rumpf):
  if re.search(r'^#import\s+"@schule/typstage', rumpf, re.M):
    return "ganz"
  if re.search(r"^#show:\s*(presentation|bundle)", rumpf, re.M):
    return "dokument"
  if re.search(r"^=+\s", rumpf, re.M):
    return "folgen"
  return "folie"


def huelle(art, rumpf, vorspann):
  if art == "ganz":
    return rumpf
  kopf = IMPORT + vorspann
  if art == "dokument":
    return kopf + rumpf
  # Die Argumentschreibweise: `slide(..)` gibt ein Wörterbuch zurück und muss
  # `presentation` als Argument erreichen. Unter einer Show-Regel steht es im
  # Rumpf, und dort ist es nichts -- gemessen ergibt dieselbe Zeile so 0 Folien
  # statt 1, fehlerfrei. Eine Hülle, in der ein Beispiel spurlos verschwindet,
  # prüft nichts.
  if art == "argument":
    # Das führende `#` fällt weg: im Handbuch steht die Zeile als Aufruf im
    # Fließtext, als Argument steht sie in Code, und dort ist `#` ungültig.
    # Genau der Handgriff, den ein Leser beim Einsetzen macht.
    ohne = "\n".join(z[1:] if z.startswith("#") else z
                     for z in rumpf.split("\n"))
    return kopf + "#presentation(\n" + ohne + ",\n)\n"
  kopf += "#show: presentation.with()\n"
  if art == "folgen":
    return kopf + rumpf
  return kopf + "== Beispiel\n" + rumpf


def uebersetzen(quelle, ziel, dateien, paketpfad=None):
  """Einmal `typst compile`. Gibt (geklappt, Meldung) zurück."""
  with tempfile.TemporaryDirectory(dir=os.path.join(WURZEL, ".pruef-tmp")) as d:
    datei = os.path.join(d, "beispiel.typ")
    open(datei, "w", encoding="utf-8").write(quelle)
    for name in dateien:
      pfad = os.path.join(d, os.path.basename(name))
      with open(pfad, "wb") as f:
        f.write(PNG if name.lower().endswith((".png", ".jpg", ".jpeg")) else b"")
    if ziel == "bundle":
      befehl = ["typst", "compile", "--format", "bundle",
                "--features", "bundle,html", "--root", WURZEL, datei, d]
    else:
      befehl = ["typst", "compile", "--format", "html", "--features", "html",
                "--root", WURZEL, datei, os.path.join(d, "beispiel.html")]
    if paketpfad:
      befehl[2:2] = ["--package-path", paketpfad]
    lauf = subprocess.run(befehl, capture_output=True, text=True)
  meldung = "\n".join(
    z for z in lauf.stderr.split("\n")
    if z.strip() and not re.match(r"^\s*(warning: (html|bundle) export|= hint:)", z)
  )
  return lauf.returncode == 0, meldung


def pruefen(auftrag):
  block, voriger, paketpfad, wurzeln = auftrag
  ort = "%s:%d" % (os.path.relpath(block["datei"], WURZEL), block["zeile"])
  regie = regie_lesen(block["regie"])
  if regie["aus"]:
    return {"ort": ort, "stand": "aus", "grund": regie["aus"]}
  art = regie["art"] or art_raten(block["rumpf"])
  vorspann = "".join(VORSPANN[n] for n in regie["pre"])
  if regie["davor"]:
    if voriger is None:
      return {"ort": ort, "stand": "fehler", "art": art,
              "meldung": "`davor` verlangt einen Block darüber, es gibt keinen"}
    vorspann += voriger + "\n"

  # Ein Beispiel, das ein Begleitpaket braucht, das hier nicht liegt, wird
  # gemeldet und übersprungen, nicht als Fehler ausgegeben. Wer nur typstage
  # ausgecheckt hat, soll den Lauf trotzdem grün bekommen und dabei sehen,
  # was ungeprüft blieb.
  fehlt_paket = fehlende_pakete(block["rumpf"], wurzeln)
  if fehlt_paket:
    return {"ort": ort, "stand": "aus", "grund": "ohne " + ", ".join(fehlt_paket)}

  zeilen = block["rumpf"].split("\n")
  for n in regie["fehlt"]:
    if not 1 <= n <= len(zeilen):
      return {"ort": ort, "stand": "fehler", "art": art,
              "meldung": "fehlt=%d, aber der Block hat nur %d Zeilen" % (n, len(zeilen))}

  # Erst der Rest ohne die Zeilen, die fehlschlagen sollen: der muss übersetzen.
  rest = "\n".join(z for i, z in enumerate(zeilen, 1) if i not in regie["fehlt"])
  geklappt, meldung = uebersetzen(
    huelle(art, rest, vorspann), regie["ziel"], regie["dateien"], paketpfad)
  if not geklappt:
    return {"ort": ort, "stand": "fehler", "art": art, "meldung": meldung}

  # Dann jede einzelne dieser Zeilen für sich: die muss fehlschlagen.
  for n in regie["fehlt"]:
    geklappt, meldung = uebersetzen(
      huelle(art, zeilen[n - 1], vorspann), regie["ziel"], regie["dateien"],
      paketpfad)
    if geklappt:
      return {
        "ort": ort, "stand": "fehler", "art": art,
        "meldung": ("Zeile %d ist als „soll fehlschlagen\" geführt, übersetzt "
                    "aber: %s" % (n, zeilen[n - 1].strip())),
      }
    # Und am richtigen Grund. Ein Fehlschlag an einem Tippfehler wäre ein
    # bestandener Test aus dem falschen Grund, und das ist schlimmer als ein
    # durchgefallener.
    if regie["weil"] and regie["weil"] not in meldung:
      return {
        "ort": ort, "stand": "fehler", "art": art,
        "meldung": ("Zeile %d schlägt fehl, aber nicht an „%s\": %s"
                    % (n, regie["weil"], meldung.strip().splitlines()[0]
                       if meldung.strip() else "(ohne Meldung)")),
      }
  return {"ort": ort, "stand": "gut", "art": art, "fehlt": len(regie["fehlt"])}


def gelesene_dateien():
  """Beispiele, die das Handbuch aus einer echten Datei liest, statt sie
  abzuschreiben. Die werden als ganze Dateien übersetzt."""
  raus = []
  for name in HANDBUECHER:
    pfad = os.path.join(WURZEL, name)
    text = open(pfad, encoding="utf-8").read()
    for treffer in sorted(set(LESEN.findall(text))):
      ziel = os.path.normpath(os.path.join(os.path.dirname(pfad), treffer))
      raus.append((name, treffer, ziel))
  return raus


def haupt():
  s = argparse.ArgumentParser(add_help=True)
  s.add_argument("--leise", action="store_true", help="nur die Bilanz ausgeben")
  s.add_argument("--paketpfad", default=None,
                 help="an typst durchgereicht (--package-path), für Läufe "
                      "außerhalb eines eingerichteten Paketverzeichnisses")
  args = s.parse_args()
  wurzeln = paketwurzeln(args.paketpfad)

  # Eigenes Wegwerfverzeichnis *innerhalb* der Paketwurzel, weil typst nur
  # übersetzt, was unter --root liegt. Vorher leeren, falls ein abgebrochener
  # Lauf etwas hat stehen lassen.
  wegwerf = os.path.join(WURZEL, ".pruef-tmp")
  shutil.rmtree(wegwerf, ignore_errors=True)
  os.makedirs(wegwerf, exist_ok=True)
  auftraege, ergebnisse = [], []
  # Was nicht `typ` heißt, wird nicht geprüft -- und ein Block, der lautlos
  # aus der Prüfung fällt, ist genau die Art, wie so ein Lauf über die Jahre
  # stumpf wird. Deshalb werden die anderen Sprachen gezählt und am Ende
  # genannt, und ein Zaun, der wie ein verschriebenes `typ` aussieht, ist ein
  # Fehler: `typst` und `typc` sind keine Sprachen, die hier etwas zu suchen
  # haben, wohl aber ein naheliegender Griff daneben.
  andere, verschrieben = {}, []
  for name in HANDBUECHER:
    voriger = None
    for block in bloecke(os.path.join(WURZEL, name)):
      if block["sprache"] != "typ":
        if block["sprache"] in ("typst", "typc", "typ:"):
          verschrieben.append("%s:%d hat ```%s -- gemeint ist ```typ"
                              % (block["datei"], block["zeile"], block["sprache"]))
        andere[block["sprache"]] = andere.get(block["sprache"], 0) + 1
        continue
      auftraege.append((block, voriger, args.paketpfad, wurzeln))
      voriger = block["rumpf"]
  if verschrieben:
    for z in verschrieben:
      print("--- FEHLER " + z)
    return 1

  with ThreadPoolExecutor(max_workers=max(4, os.cpu_count() or 4)) as pool:
    ergebnisse = list(pool.map(pruefen, auftraege))

  # Die aus echten Dateien gelesenen Beispiele.
  gelesen = gelesene_dateien()
  for handbuch, ref, ziel in gelesen:
    ort = "%s → %s" % (handbuch, ref)
    if not os.path.exists(ziel):
      ergebnisse.append({"ort": ort, "stand": "fehler", "art": "ganz",
                         "meldung": "die gelesene Datei gibt es nicht: " + ziel})
      continue
    quelle = open(ziel, encoding="utf-8").read()
    fehlt_paket = fehlende_pakete(quelle, wurzeln)
    if fehlt_paket:
      ergebnisse.append({"ort": ort, "stand": "aus",
                         "grund": "ohne " + ", ".join(fehlt_paket)})
      continue
    geklappt, meldung = uebersetzen(quelle, "html", [], args.paketpfad)
    ergebnisse.append({"ort": ort, "art": "gelesen",
                       "stand": "gut" if geklappt else "fehler",
                       "meldung": meldung})

  gut = [e for e in ergebnisse if e["stand"] == "gut"]
  aus = [e for e in ergebnisse if e["stand"] == "aus"]
  fehler = [e for e in ergebnisse if e["stand"] == "fehler"]
  gegen = sum(e.get("fehlt", 0) for e in gut)

  if not args.leise:
    for e in aus:
      print("  übersprungen  %-34s %s" % (e["ort"], e["grund"]))
  for e in fehler:
    print("\n--- FEHLER %s  [%s]" % (e["ort"], e.get("art", "?")))
    print("\n".join("    " + z for z in e["meldung"].split("\n")[:14]))
  if andere:
    print("nicht geprüft, weil andere Zaunsprache: "
          + ", ".join("%dx %s" % (n, k) for k, n in sorted(andere.items())))
  print("\nBeispiele: %d übersetzt · %d als „soll fehlschlagen\" geprüft · "
        "%d übersprungen · %d Fehler"
        % (len(gut), gegen, len(aus), len(fehler)))
  shutil.rmtree(wegwerf, ignore_errors=True)
  return 1 if fehler else 0


if __name__ == "__main__":
  sys.exit(haupt())
