# Praktikum_WS2122_Tobias_Telge

*Procgen Spiel BigFish implementiert in Julia auf der CPU*

## Schnellstart

1. Instantiiere die notwendigen Pakete wie in der Project.toml definiert durch Befolgen folgender Schritte:
    - Navigiere in einem Terminal zu diesem Ordner (welcher die Project.toml enthält).
    - Führe `julia --project=.` aus, um ein julia REPL zu starten.
    - Gehe dann in den Paket-Modus, indem du ] eingibst.
    - Führe das Kommando `instantiate` aus.
    - Nachdem alle Pakete instantiiert wurden, verlasse den Paket-Modus, indem du die Backspace-Taste oder STRG-C drückst.
    - Verlasse das julia REPL mit STRG-D.
2. Führe `julia --project=. procgen/games/visualization.jl` aus, um das Spiel zu starten.

## BigFish

Beim Procgen-Spiel BigFish spielt der Spieler einen Fisch der kleinere Fische fressen soll und dabei Fischen, die größer als er selbst sind, ausweicht.
Durch das Fressen von Fischen erhält der Spieler eine Belohnung und wird größer.
Wird er jedoch durch Kontakt mit einem größeren Fisch selbst gefressen, endet die Episode.
Sobald der Spieler größer wird als alle anderen Fische erhält er eine große Belohnung und die Episode ist vorbei.
Die Spielweise des in Julia implementierten Spiels entspricht genau dem Originalspiel.

## Optionen

Es stehen verschiedene Optionen zur Verfügung, die in der visualization.jl-Datei durch Aufheben der entsprechenden Auskommentierung aktiviert werden können.

* `restrict_themes = true` - Alle Fische außer dem Spieler sehen gleich aus.
* `use_monochrome_assets = true` - Das Spiel verwendet einfarbige Rechtecke anstatt Bildern.
* `use_backgrounds = false` - Das Spiel verwendet einen schwarzen Hintergrund.
* `use_sequential_levels = true` - Wird das Ende eines Levels erreicht, endet die Episode nicht, sondern ein neues Level wird gestartet.
* `distribution_mode = EasyMode` - Der Schwierigkeitsgrad des Spiels wird gesenkt.

## Dokumentation

Im Ordner **documentation** befinden sich der schriftliche Praktikumsbericht und die Folien der Abschlusspräsentation.