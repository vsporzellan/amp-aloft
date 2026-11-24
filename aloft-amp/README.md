# Aloft – AMP-Template

Aloft Dedicated Server für CubeCoders AMP unter Linux (Wine im Container `cubecoders/ampbase:wine-stable`).
Basiert auf der Idee von kryptobaseddev/aloftserver, aber neu aufgebaut nach dem Muster der offiziellen CubeCoders-Templates.

## Einbinden

1. ADS → **Configuration → Instance Deployment → Configuration Repositories**: `vsporzellan/amp-aloft:main` eintragen, **Fetch Latest**.
2. **Create Instance** → Anwendung **Aloft** wählen (läuft automatisch im Container).
3. Instanz öffnen → **Update**. AMP fragt nach Steam-Login + Steam-Guard-Code.
   Der Account muss Aloft besitzen – es gibt keinen anonymen Dedicated-Server-Download.
4. Unter **Configuration → Aloft** Servername, Weltname usw. setzen, dann **Start**.

## Verhalten

- Existiert die Welt (`World Name`) noch nicht, wird sie beim Start automatisch erzeugt
  (Inselanzahl, Korruption, Kreativmodus gelten nur dafür) und danach geladen.
  Neuer Weltname = neue Welt, alte bleibt erhalten.
- Der Join-Code erscheint in der Konsole als `[AMP] Server code: …`.
- Ist „Visible in Lobby Browser“ aus, kommt man nur per Code rein.
- Saves liegen im Wine-Prefix:
  `aloft/.wine/drive_c/users/<user>/AppData/LocalLow/Astrolabe Interactive/Aloft/Data01/Saves/w_<Weltname>`
  und sind damit in den AMP-Backups der Instanz enthalten.

## Dateien

| Datei | Zweck |
|---|---|
| `aloft.kvp` | Haupt-Template |
| `aloftconfig.json` | Einstellungen in der AMP-Oberfläche |
| `aloftports.json` | Spielport (Standard 7790, TCP+UDP) |
| `aloftupdates.json` | SteamCMD-Download, Launcher, Wine-Prefix, winetricks |
| `aloft-launch.sh` | Startskript: Welt erzeugen/laden, Log in die Konsole, sauberes Stoppen |
