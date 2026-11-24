#!/bin/bash
# Aloft Dedicated Server – Launcher für AMP (Wine)
# Wird von AMP mit diesen Argumenten aufgerufen:
#   1 MapName  2 IslandCount  3 CorruptionCount  4 Creative
#   5 ServerName  6 IsVisible  7 PrivateIslands  8 MaxPlayers  9 Port
#   10.. Admin-Steam-IDs (Leerzeichen oder Komma getrennt, optional)
#
# Gibt es den Weltordner noch nicht, wird die Welt zuerst erzeugt
# (Aloft beendet sich danach selbst), anschließend wird sie geladen.

set -u

MAP="${1:?MapName fehlt}"; ISLANDS="${2:-normal}"; CORRUPTION="${3:-normal}"; CREATIVE="${4:-false}"
NAME="${5:-AloftServer}"; VISIBLE="${6:-true}"; PRIVATE="${7:-false}"; PLAYERS="${8:-8}"; PORT="${9:-0}"
shift 9 2>/dev/null || shift $#

if [[ "$MAP" =~ [^A-Za-z0-9_-] || "$NAME" =~ [^A-Za-z0-9_-] ]]; then
    echo "[AMP] FEHLER: Weltname und Servername dürfen nur Buchstaben, Ziffern, _ und - enthalten (keine Leerzeichen)."
    exit 1
fi

ADMINS=()
for arg in "$@"; do
    for id in ${arg//,/ }; do
        [[ "$id" =~ ^[0-9]+$ ]] && ADMINS+=("admin#${id}#")
    done
done
# Platzhalter wie in der offiziellen Vorlage, falls kein Admin gesetzt ist
[[ ${#ADMINS[@]} -eq 0 ]] && ADMINS=("admin#-1#")

if [[ ! -x /usr/bin/wine ]]; then
    echo "[AMP] FEHLER: Wine fehlt. Instanz im Container mit Image cubecoders/ampbase:wine-stable betreiben."
    exit 1
fi

SAVES="${WINEPREFIX:-$HOME/.wine}/drive_c/users/$(id -un)/AppData/LocalLow/Astrolabe Interactive/Aloft/Data01/Saves"
EXE="./Aloft.exe"
[[ -f "$EXE" ]] || { echo "[AMP] FEHLER: Aloft.exe nicht gefunden. Erst 'Update' ausführen (Steam-Login nötig)."; exit 1; }

PID=""
stop_server() {
    if [[ -n "$PID" ]] && kill -0 "$PID" 2>/dev/null; then
        echo "[AMP] Stoppe Aloft ..."
        kill -INT "$PID" 2>/dev/null
        for _ in $(seq 1 25); do kill -0 "$PID" 2>/dev/null || break; sleep 1; done
        kill -TERM "$PID" 2>/dev/null
        wineserver -k 2>/dev/null
    fi
    exit 0
}
trap stop_server INT TERM

# Startet Aloft im Hintergrund, spiegelt das Logfile in die AMP-Konsole und wartet
run_aloft() {
    local logfile="$1"; shift
    : > "$logfile"
    /usr/bin/wine "$EXE" -batchmode -nographics -server -logFile "$logfile" "$@" &
    PID=$!
    tail -n +1 -F "$logfile" --pid="$PID" 2>/dev/null &
    wait "$PID"
    local rc=$?
    PID=""
    return $rc
}

if [[ ! -d "$SAVES/w_${MAP}" ]]; then
    echo "[AMP] Welt '${MAP}' existiert noch nicht – wird erzeugt (Inseln: ${ISLANDS}, Korruption: ${CORRUPTION}, Kreativ: ${CREATIVE}) ..."
    run_aloft create.log "create#${MAP}#" "islandcount#${ISLANDS}#" "corruptioncount#${CORRUPTION}#" "creative#${CREATIVE}#" "log#ERROR#"
    if [[ ! -d "$SAVES/w_${MAP}" ]]; then
        echo "[AMP] WARNUNG: Weltordner w_${MAP} wurde nicht gefunden. Gefundene Saves:"
        ls -1 "$SAVES" 2>/dev/null || echo "  (keine)"
    else
        echo "[AMP] Welt erzeugt."
    fi
fi

# Server-Code ausgeben, sobald Aloft ihn in ServerRoomCode*.txt schreibt
MARKER="$(mktemp)"
(
    for _ in $(seq 1 300); do
        f="$(find . -maxdepth 3 -iname 'ServerRoomCode*' -newer "$MARKER" 2>/dev/null | head -n1)"
        if [[ -n "$f" ]]; then
            sleep 1
            echo "[AMP] Server code: $(tr -d '\r\n' < "$f")"
            break
        fi
        sleep 2
    done
    rm -f "$MARKER"
) &

echo "[AMP] Lade Welt '${MAP}' als '${NAME}' (Port ${PORT}, max. ${PLAYERS} Spieler, sichtbar: ${VISIBLE}) ..."
run_aloft server.log "load#${MAP}#" "servername#${NAME}#" "log#ERROR#" "isvisible#${VISIBLE}#" \
    "privateislands#${PRIVATE}#" "playercount#${PLAYERS}#" "serverport#${PORT}#" "${ADMINS[@]}" "disablevideo#true#"
exit $?
