#!/usr/bin/env bash
# ============================================================
# VERTEBR — vertebr_diagnostics.sh
# Diagnostic complet : daemon, modules, audio, réseau,
# journaux noyau, socket, routes, system calls
# Usage : sudo ./vertebr_diagnostics.sh | tee vertebr_diag.log
# Auteur : Houssam | Licence : MIT
# ============================================================

GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m';
RED='\033[0;31m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

REAL_USER="${SUDO_USER:-$USER}"
REAL_UID=$(id -u "$REAL_USER")
LOG_FILE="vertebr_diag_$(date +%Y%m%d_%H%M%S).log"
SOCK="/tmp/vertebr.sock"
PASS=0; FAIL=0; WARN_COUNT=0

sec()     { echo ""; echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; echo -e "  $1${NC}"; echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; }
ok()      { echo -e "  ${GREEN}[PASS]${NC} $1"; ((PASS++)); }
fail()    { echo -e "  ${RED}[FAIL]${NC} $1"; ((FAIL++)); }
warn()    { echo -e "  ${YELLOW}[WARN]${NC} $1"; ((WARN_COUNT++)); }
info()    { echo -e "  ${BLUE}[INFO]${NC} $1"; }
result()  { echo -e "  ${CYAN}[DATA]${NC} $1"; }
cmd_out() { echo -e "  ${YELLOW}  └─${NC} $1"; }

ask_daemon() {
    local route="$1" payload="${2:-{}}" desc="$3"
    local resp
    resp=$(echo "{\"route\":\"$route\",\"payload\":$payload}" \
           | timeout 5 socat - UNIX-CONNECT:"$SOCK" 2>/dev/null | head -c 1000)
    if echo "$resp" | grep -q '"status":"success"'; then
        ok "$desc"
        cmd_out "$(echo "$resp" | python3 -m json.tool 2>/dev/null | head -8 || echo "$resp" | head -c 300)"
    elif echo "$resp" | grep -q '"status":"error"'; then
        local err=$(echo "$resp" | grep -o '"error":"[^"]*"' | cut -d'"' -f4)
        fail "$desc → $err"
    else
        fail "$desc → Pas de réponse (timeout ou socket fermé)"
    fi
}

# ============================================================
echo ""
echo -e "${BOLD}${CYAN}"
echo "  ██╗   ██╗███████╗██████╗ ████████╗███████╗██████╗ ██████╗ "
echo "  ██║   ██║██╔════╝██╔══██╗╚══██╔══╝██╔════╝██╔══██╗██╔══██╗"
echo "  ██║   ██║█████╗  ██████╔╝   ██║   █████╗  ██████╔╝██████╔╝"
echo "  ╚██╗ ██╔╝██╔══╝  ██╔══██╗   ██║   ██╔══╝  ██╔══██╗██╔══██╗"
echo "   ╚████╔╝ ███████╗██║  ██║   ██║   ███████╗██████╔╝██║  ██║"
echo "    ╚═══╝  ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═════╝ ╚═╝  ╚═╝"
echo -e "${NC}"
echo -e "  ${BOLD}VERTEBR — Diagnostic Système Complet${NC}"
echo -e "  Date    : $(date)"
echo -e "  User    : $REAL_USER (uid=$REAL_UID)"
echo -e "  Host    : $(hostname)"
echo -e "  Kernel  : $(uname -r)"
echo -e "  Log     : $LOG_FILE"
echo ""

# ── SECTION 1 : Prérequis ────────────────────────────────────
sec "1/10 ── PRÉREQUIS SYSTÈME"

# Test 1
if command -v socat &>/dev/null; then
    ok "socat disponible ($(socat -V 2>&1 | head -1))"
else
    fail "socat manquant → installe : sudo apt install socat"
fi

# Test 2
if command -v cargo &>/dev/null; then
    ok "Rust/Cargo disponible : $(cargo --version)"
else
    fail "Cargo manquant → Rust non installé"
fi

# Test 3
if command -v node &>/dev/null; then
    ok "Node.js : $(node --version)"
else
    fail "Node.js manquant"
fi

# Test 4
if [ -f "/usr/bin/vertebr-daemon" ]; then
    ok "vertebr-daemon installé dans /usr/bin/"
    cmd_out "Taille : $(du -h /usr/bin/vertebr-daemon | cut -f1)"
else
    fail "vertebr-daemon introuvable dans /usr/bin/"
fi

# Test 5
MODULE_COUNT=$(ls /usr/lib/vertebr/modules/*.so 2>/dev/null | wc -l)
if [ "$MODULE_COUNT" -gt 0 ]; then
    ok "$MODULE_COUNT module(s) .so installé(s) dans /usr/lib/vertebr/modules/"
    for m in /usr/lib/vertebr/modules/*.so; do
        cmd_out "$(basename $m) — $(du -h $m | cut -f1)"
    done
else
    fail "Aucun module .so dans /usr/lib/vertebr/modules/"
fi

# Test 6
if [ -f "/etc/vertebr/routes.toml" ]; then
    ROUTE_COUNT=$(grep -c '^\[\[route\]\]' /etc/vertebr/routes.toml)
    ok "routes.toml présent — $ROUTE_COUNT routes configurées"
else
    fail "routes.toml manquant dans /etc/vertebr/"
fi

# ── SECTION 2 : Service Systemd ──────────────────────────────
sec "2/10 ── SERVICE SYSTEMD"

# Test 7
DAEMON_STATUS=$(systemctl is-active vertebr 2>/dev/null)
if [ "$DAEMON_STATUS" = "active" ]; then
    ok "Service vertebr : ACTIF"
else
    fail "Service vertebr : $DAEMON_STATUS"
fi

# Test 8
DAEMON_ENABLED=$(systemctl is-enabled vertebr 2>/dev/null)
if [ "$DAEMON_ENABLED" = "enabled" ]; then
    ok "Service vertebr activé au démarrage"
else
    warn "Service vertebr non activé au démarrage ($DAEMON_ENABLED)"
fi

# Test 9 — Variables d'environnement du service
info "Variables d'environnement du service :"
systemctl show vertebr --property=Environment 2>/dev/null | tr ' ' '\n' | while read -r var; do
    cmd_out "$var"
done

# Test 10 — PID et ressources
DAEMON_PID=$(systemctl show vertebr --property=MainPID --value 2>/dev/null)
if [ -n "$DAEMON_PID" ] && [ "$DAEMON_PID" != "0" ]; then
    ok "PID daemon : $DAEMON_PID"
    MEM=$(cat /proc/"$DAEMON_PID"/status 2>/dev/null | grep VmRSS | awk '{print $2, $3}')
    cmd_out "Mémoire RSS : ${MEM:-N/A}"
    cmd_out "Threads : $(cat /proc/$DAEMON_PID/status 2>/dev/null | grep Threads | awk '{print $2}')"
    cmd_out "FDs ouverts : $(ls /proc/$DAEMON_PID/fd 2>/dev/null | wc -l)"
else
    warn "PID daemon introuvable"
fi

# ── SECTION 3 : Socket Unix ──────────────────────────────────
sec "3/10 ── SOCKET UNIX /tmp/vertebr.sock"

# Test 11
if [ -S "$SOCK" ]; then
    PERMS=$(stat -c "%a" "$SOCK")
    OWNER=$(stat -c "%U:%G" "$SOCK")
    ok "Socket présent — propriétaire: $OWNER — permissions: $PERMS"
    if [ "$PERMS" = "777" ] || [ "$PERMS" = "666" ]; then
        ok "Permissions socket suffisantes ($PERMS)"
    else
        fail "Permissions insuffisantes ($PERMS) → EACCES pour les non-root"
        cmd_out "Fix : sudo chmod 777 $SOCK"
    fi
else
    fail "Socket absent : $SOCK"
fi

# Test 12 — Connexion brute
if [ -S "$SOCK" ]; then
    CONN_TEST=$(echo '{}' | timeout 3 socat - UNIX-CONNECT:"$SOCK" 2>&1 | head -1)
    if echo "$CONN_TEST" | grep -q '"status"'; then
        ok "Connexion au socket : réussie"
    elif echo "$CONN_TEST" | grep -q 'ECONNREFUSED'; then
        fail "Socket présent mais daemon ne répond pas (ECONNREFUSED)"
    elif echo "$CONN_TEST" | grep -q 'EACCES'; then
        fail "Permission refusée sur le socket (EACCES)"
    else
        warn "Réponse socket inattendue : $CONN_TEST"
    fi
fi

# ── SECTION 4 : Routes Vertebr — Réseau ─────────────────────
sec "4/10 ── ROUTES VERTEBR — RÉSEAU"

# Test 13
ask_daemon "wifi:status"  "{}" "wifi:status — État Wi-Fi"

# Test 14
ask_daemon "wifi:list"    "{}" "wifi:list — Liste des réseaux"

# Test 15
ask_daemon "bluetooth:status" "{}" "bluetooth:status — État Bluetooth"

# Test 16
ask_daemon "bluetooth:list"   "{}" "bluetooth:list — Périphériques couplés"

# ── SECTION 5 : Routes Vertebr — Système ────────────────────
sec "5/10 ── ROUTES VERTEBR — SYSTÈME"

# Test 17
ask_daemon "power:status" "{}" "power:status — Batterie & profil"

# Test 18
ask_daemon "system:info"  "{}" "system:info — Informations OS"

# Test 19
ask_daemon "system:timezone" "{}" "system:timezone — Fuseau horaire"

# Test 20
ask_daemon "system:user"     "{}" "system:user — Utilisateur courant"

# Test 21
ask_daemon "theme:get"    "{}" "theme:get — Thème GNOME"

# ── SECTION 6 : Routes Vertebr — Audio ──────────────────────
sec "6/10 ── ROUTES VERTEBR — AUDIO (pactl)"

# Test 22
ask_daemon "audio:sinks"   "{}" "audio:sinks — Sorties audio"

# Test 23
ask_daemon "audio:sources" "{}" "audio:sources — Entrées audio (micros)"

# Diagnostic pactl direct
info "Test pactl en direct (user $REAL_USER) :"
PACTL_DIRECT=$(runuser -u "$REAL_USER" -- \
    env XDG_RUNTIME_DIR=/run/user/$REAL_UID \
        PULSE_SERVER=unix:/run/user/$REAL_UID/pulse/native \
    pactl list sinks short 2>&1)
if echo "$PACTL_DIRECT" | grep -q "Name\|alsa\|bluez\|pipewire"; then
    ok "pactl direct fonctionne en tant que $REAL_USER"
    echo "$PACTL_DIRECT" | while IFS= read -r line; do cmd_out "$line"; done
else
    fail "pactl direct échoue : $PACTL_DIRECT"
    cmd_out "Vérifier : systemctl --user status pipewire"
fi

# Test wrapper vertebr-pactl
if [ -f /usr/local/bin/vertebr-pactl ]; then
    WRAPPER_TEST=$(/usr/local/bin/vertebr-pactl list sinks short 2>&1)
    if echo "$WRAPPER_TEST" | grep -q "Name\|alsa\|bluez\|pipewire"; then
        ok "Wrapper vertebr-pactl fonctionne"
        echo "$WRAPPER_TEST" | while IFS= read -r line; do cmd_out "$line"; done
    else
        fail "Wrapper vertebr-pactl échoue : $WRAPPER_TEST"
    fi
else
    warn "Wrapper vertebr-pactl absent — run fix_audio.sh"
fi

# ── SECTION 7 : Routes Vertebr — Affichage ──────────────────
sec "7/10 ── ROUTES VERTEBR — AFFICHAGE (xrandr/Wayland)"

# Test 24
ask_daemon "display:list" "{}" "display:list — Écrans détectés"

# Détecter X11 vs Wayland
WAYLAND_DISPLAY_VAL=$(runuser -u "$REAL_USER" -- bash -c 'echo $WAYLAND_DISPLAY' 2>/dev/null)
X11_DISPLAY_VAL=$(runuser -u "$REAL_USER" -- bash -c 'echo $DISPLAY' 2>/dev/null)

info "Protocole graphique :"
if [ -n "$WAYLAND_DISPLAY_VAL" ]; then
    warn "Session Wayland détectée (WAYLAND_DISPLAY=$WAYLAND_DISPLAY_VAL)"
    cmd_out "xrandr ne fonctionne pas nativement sous Wayland"
    cmd_out "Solution : gnome-randr ou wlr-randr"

    # Tester gnome-randr
    if command -v gnome-randr &>/dev/null; then
        ok "gnome-randr disponible"
        runuser -u "$REAL_USER" -- gnome-randr 2>&1 | head -5 | while IFS= read -r line; do cmd_out "$line"; done
    else
        warn "gnome-randr non installé"
        cmd_out "Installe : pip3 install gnome-randr --user"
    fi

    # Tester wlr-randr
    if command -v wlr-randr &>/dev/null; then
        ok "wlr-randr disponible"
    else
        warn "wlr-randr non installé"
    fi
else
    ok "Session X11 (DISPLAY=$X11_DISPLAY_VAL)"
    # Test xrandr
    XRANDR_OUT=$(DISPLAY="${X11_DISPLAY_VAL:-:0}" xrandr --query 2>&1 | head -5)
    if echo "$XRANDR_OUT" | grep -q "connected"; then
        ok "xrandr fonctionne"
        echo "$XRANDR_OUT" | while IFS= read -r line; do cmd_out "$line"; done
    else
        fail "xrandr échoue : $XRANDR_OUT"
    fi
fi

# ── SECTION 8 : CAPABILITIES ────────────────────────────────
sec "8/10 ── ROUTES VERTEBR — CAPABILITIES"

# Test 25
ask_daemon "caps:list" "{}" "caps:list — Liste des CAPABILITIES disponibles"

# Test 26
ask_daemon "caps:get" '{"binary":"/usr/bin/ping"}' "caps:get /usr/bin/ping"

# Vérifier les caps du daemon lui-même
info "CAPABILITIES du daemon (PID=$DAEMON_PID) :"
if [ -n "$DAEMON_PID" ] && [ "$DAEMON_PID" != "0" ]; then
    CAP_EFF=$(grep CapEff /proc/"$DAEMON_PID"/status 2>/dev/null | awk '{print $2}')
    cmd_out "CapEff (hex) : $CAP_EFF"
    # Décoder les caps principales
    if [ -n "$CAP_EFF" ]; then
        CAP_INT=$(printf "%d" "0x$CAP_EFF" 2>/dev/null)
        [ $(( CAP_INT & (1<<12) )) -ne 0 ] && cmd_out "  ✓ CAP_NET_ADMIN (bit 12)"
        [ $(( CAP_INT & (1<<21) )) -ne 0 ] && cmd_out "  ✓ CAP_SYS_ADMIN (bit 21)"
        [ $(( CAP_INT & (1<<22) )) -ne 0 ] && cmd_out "  ✓ CAP_SYS_BOOT  (bit 22)"
        [ $(( CAP_INT & (1<< 1) )) -ne 0 ] && cmd_out "  ✓ CAP_DAC_OVERRIDE (bit 1)"
        [ $(( CAP_INT & (1<<31) )) -ne 0 ] && cmd_out "  ✓ CAP_SETFCAP   (bit 31)"
    fi
fi

# ── SECTION 9 : Journaux Système ────────────────────────────
sec "9/10 ── JOURNAUX SYSTÈME (kernel + daemon)"

# Test 27 — Logs daemon (dernières 30 lignes)
info "Derniers logs du daemon vertebr :"
journalctl -u vertebr --no-pager -n 30 2>/dev/null | while IFS= read -r line; do
    if echo "$line" | grep -qi "error\|failed\|fatal"; then
        cmd_out "${RED}$line${NC}"
    elif echo "$line" | grep -qi "warn"; then
        cmd_out "${YELLOW}$line${NC}"
    else
        cmd_out "$line"
    fi
done

# Test 28 — Erreurs kernel récentes
info "Erreurs kernel récentes (dmesg) :"
KERNEL_ERRORS=$(dmesg --level=err,crit,alert,emerg 2>/dev/null | tail -10)
if [ -n "$KERNEL_ERRORS" ]; then
    warn "Erreurs kernel détectées :"
    echo "$KERNEL_ERRORS" | while IFS= read -r line; do cmd_out "$line"; done
else
    ok "Aucune erreur kernel critique récente"
fi

# Test 29 — Messages kernel liés au réseau
info "Messages kernel réseau (wifi/bluetooth) :"
dmesg 2>/dev/null | grep -iE "wlan|wifi|iwl|ath|bluetooth|btusb|rfkill" \
    | tail -8 | while IFS= read -r line; do cmd_out "$line"; done

# Test 30 — AppArmor / SELinux (peut bloquer le socket)
info "AppArmor / sécurité :"
if command -v aa-status &>/dev/null; then
    AA_STATUS=$(aa-status 2>/dev/null | head -5)
    cmd_out "AppArmor : $AA_STATUS"
    # Chercher des blocages liés à vertebr ou electron
    DENIALS=$(journalctl -k --no-pager -n 200 2>/dev/null | grep -i "apparmor.*DENIED" | grep -i "electron\|vertebr\|sock" | tail -5)
    if [ -n "$DENIALS" ]; then
        warn "AppArmor blocages détectés :"
        echo "$DENIALS" | while IFS= read -r line; do cmd_out "$line"; done
    else
        ok "Aucun blocage AppArmor détecté pour Vertebr/Electron"
    fi
else
    ok "AppArmor non actif"
fi

# Test 31 — Logs PipeWire/PulseAudio
info "Logs PipeWire (utilisateur $REAL_USER) :"
runuser -u "$REAL_USER" -- \
    journalctl --user -u pipewire --no-pager -n 10 2>/dev/null \
    | tail -8 | while IFS= read -r line; do cmd_out "$line"; done

# Test 32 — État PipeWire
PW_STATUS=$(runuser -u "$REAL_USER" -- \
    env XDG_RUNTIME_DIR=/run/user/$REAL_UID \
    systemctl --user is-active pipewire 2>/dev/null)
if [ "$PW_STATUS" = "active" ]; then
    ok "PipeWire actif (user)"
else
    fail "PipeWire non actif : $PW_STATUS"
    cmd_out "Fix : runuser -u $REAL_USER -- systemctl --user start pipewire pipewire-pulse"
fi

# ── SECTION 10 : Résumé Global ───────────────────────────────
sec "10/10 ── RÉSUMÉ GLOBAL"

echo ""
echo -e "  ${BOLD}Résultats :${NC}"
echo -e "  ${GREEN}PASS  : $PASS${NC}"
echo -e "  ${RED}FAIL  : $FAIL${NC}"
echo -e "  ${YELLOW}WARN  : $WARN_COUNT${NC}"
echo ""

# Recommandations automatiques
if [ "$FAIL" -gt 0 ]; then
    echo -e "  ${BOLD}Recommandations :${NC}"

    ! [ -S "$SOCK" ] && \
        echo -e "  ${RED}→${NC} Socket absent → sudo systemctl restart vertebr"

    [ -S "$SOCK" ] && [ "$(stat -c '%a' $SOCK)" != "777" ] && \
        echo -e "  ${RED}→${NC} Permissions socket → sudo chmod 777 $SOCK"

    ! command -v socat &>/dev/null && \
        echo -e "  ${RED}→${NC} socat manquant → sudo apt install socat"

    [ "$PW_STATUS" != "active" ] && \
        echo -e "  ${RED}→${NC} PipeWire → runuser -u $REAL_USER -- systemctl --user start pipewire pipewire-pulse"

    ! [ -f /usr/local/bin/vertebr-pactl ] && \
        echo -e "  ${RED}→${NC} Audio → sudo ./fix_audio.sh"

    [ -n "$WAYLAND_DISPLAY_VAL" ] && \
        echo -e "  ${YELLOW}→${NC} Affichage Wayland → pip3 install gnome-randr --user"
fi

echo "Nouveau test (features): "
# Test direct — ça marche parfaitement
echo '{"route":"wifi:list","payload":{}}' | socat - UNIX-CONNECT:/tmp/vertebr.sock
echo '{"route":"theme:get","payload":{}}' | socat - UNIX-CONNECT:/tmp/vertebr.sock  
echo '{"route":"audio:sinks","payload":{}}' | socat - UNIX-CONNECT:/tmp/vertebr.sock
echo '{"route":"power:status","payload":{}}' | socat - UNIX-CONNECT:/tmp/vertebr.sock
echo '{"route":"caps:list","payload":{}}' | socat - UNIX-CONNECT:/tmp/vertebr.sock
echo '{"route":"display:list","payload":{}}' | socat - UNIX-CONNECT:/tmp/vertebr.sock
echo '{"route":"system:info","payload":{}}' | socat - UNIX-CONNECT:/tmp/vertebr.sock






echo ""
echo -e "  ${BOLD}Log sauvegardé dans :${NC} $LOG_FILE"
echo ""
