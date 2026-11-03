#!/usr/bin/env bash
# =====================================================================
#  cyberx-setup.sh  —  builds the "First Day at CyberX Coffee" lab
#
#  For students' own Ubuntu 26.04 VMs. Run it as the normal user you
#  created when you installed Ubuntu (not as root):
#
#    bash cyberx-setup.sh         # first time: checks tools, builds ~/cyberx
#    cyberx-setup                 # after the first run: rebuild the lab
#    cyberx-setup --incident      # start the runaway process (Mission 5)
#    cyberx-setup --reset         # stop the runaway process, delete ~/cyberx
#    cyberx-setup --check         # only check that the needed tools exist
#
#  The first run asks for your password once (sudo) to install any
#  missing tools (vim, psmisc, ...) and to install this script as the
#  command "cyberx-setup". Add --no-sudo to skip both.
#
#  Data is deterministic: every student gets identical files, so the
#  instructor's answer key matches.
# =====================================================================
set -euo pipefail

LAB="${CYBERX_LAB:-$HOME/cyberx}"
ME="$(id -un)"
BIN="/usr/local/bin/cyberx-setup"
MODE="${1:-}"
NO_SUDO=""
[[ "${1:-}" == "--no-sudo" || "${2:-}" == "--no-sudo" ]] && NO_SUDO=1
[[ "$MODE" == "--no-sudo" ]] && MODE=""

if [[ "$(id -u)" -eq 0 && -z "${CYBERX_ALLOW_ROOT:-}" ]]; then
  echo "Please run this as your normal user, not as root (no sudo in front)."
  echo "The script asks for your password itself when it needs it."
  exit 1
fi

# ---------------------------------------------------------------------
# Tools the lab needs:  command -> Ubuntu package
# ---------------------------------------------------------------------
REQUIRED=(
  "vim:vim" "killall:psmisc" "pkill:procps" "top:procps" "ps:procps"
  "file:file" "man:man-db" "less:less" "gzip:gzip" "tar:tar"
  "awk:mawk" "grep:grep" "sed:sed" "setsid:util-linux" "mkfs.ext4:e2fsprogs"
)

missing_packages() {
  local item cmd pkg out=()
  for item in "${REQUIRED[@]}"; do
    cmd="${item%%:*}"; pkg="${item##*:}"
    if ! command -v "$cmd" >/dev/null 2>&1 && [[ ! -x "/usr/sbin/$cmd" && ! -x "/sbin/$cmd" ]]; then
      [[ " ${out[*]-} " == *" $pkg "* ]] || out+=("$pkg")
    fi
  done
  echo "${out[*]-}"
}

check_tools() {
  local miss
  miss="$(missing_packages)"
  if [[ -n "$miss" ]]; then
    echo "Missing packages: $miss"
    echo "Install them with:  sudo apt install -y $miss"
    return 1
  fi
  if ! man -w ls >/dev/null 2>&1; then
    echo "Manual pages are missing (minimized Ubuntu). Fix with:  sudo unminimize"
    return 1
  fi
  echo "All tools present."
}

prepare_system() {           # install missing tools + the cyberx-setup command
  local miss self need_install=""
  miss="$(missing_packages)"
  self="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || true)"
  if [[ -f "$self" && "$self" != "$BIN" ]] && ! cmp -s "$self" "$BIN" 2>/dev/null; then
    need_install=1
  fi
  [[ -z "$miss" && -z "$need_install" ]] && return 0

  if [[ -n "$NO_SUDO" ]] || ! command -v sudo >/dev/null 2>&1; then
    [[ -n "$miss" ]] && echo "note: missing packages ($miss) — some missions won't work until you run: sudo apt install -y $miss"
    return 0
  fi

  echo "One-time setup needs your password (the one you use to log in)."
  if [[ -n "$miss" ]]; then
    echo "==> Installing missing tools: $miss"
    if ! { sudo apt-get update -qq && sudo apt-get install -y -qq $miss; }; then
      echo "note: could not install $miss (no internet?). Try later: sudo apt install -y $miss"
    fi
  fi
  if [[ -n "$need_install" ]]; then
    echo "==> Installing the command: cyberx-setup"
    sudo install -m 755 "$self" "$BIN" || echo "note: could not install $BIN; keep using: bash $self"
  fi
  hash -r 2>/dev/null || true
}

stop_incident() {
  # Only this user's own copies.
  pkill -u "$ME" -x brewlogd 2>/dev/null || true
}

case "$MODE" in
  ""|--incident|--reset|--check) ;;
  *) sed -n '3,21p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac

if [[ "$MODE" == "--check" ]]; then
  check_tools
  exit $?
fi

if [[ "$MODE" == "--reset" ]]; then
  stop_incident
  rm -rf "$LAB" "$HOME/current.log"
  echo "Lab removed."
  exit 0
fi

if [[ "$MODE" == "--incident" ]]; then
  [[ -x "$LAB/bin/brewlogd" ]] || { echo "Run setup first."; exit 1; }
  stop_incident
  cd "$LAB"
  for i in 1 2 3; do
    setsid nohup "$LAB/bin/brewlogd" >/dev/null 2>&1 < /dev/null &
  done
  echo "Incident started: 3 x brewlogd running."
  exit 0
fi

prepare_system

stop_incident
rm -rf "$LAB" "$HOME/current.log"
mkdir -p "$LAB"/{etc,data,logs/old,bin,disk,temp_do_not_delete}
cd "$LAB"

# ---------------------------------------------------------------------
# Handover note from the previous admin
# ---------------------------------------------------------------------
cat > HANDOVER.txt <<'EOF'
=====================================================================
  HANDOVER — from Sam Okafor (ex-sysadmin, CyberX Coffee Roasters)
=====================================================================
Hi! Sorry to leave in a rush. Here's where everything lives:

  etc/        config for BrewBot, our online order system
  data/       order exports, customer list
  logs/       BrewBot logs  (logs/old = rotated logs, never cleaned...)
  bin/        little helper scripts
  disk/       archive.img = an old disk image with 2023 receipts

Things I never got around to:
  1. BrewBot config has a wrong port and is too chatty (debug logging).
     Marta (ops) says it must be port 8080, log level warn, and alerts
     must go to ops@cyberx.example now, not to me.
  2. Marta wants a list of our top-selling products from last week.
  3. Payment provider says we had "a lot of declines" yesterday.
     Someone should check the logs and find which IP keeps failing.
  4. Disk space is getting tight. logs/old should be archived.
  5. The 3 mystery files in data/ came from the old POS system.
     No idea what they are. No extensions, sorry.

There's also a private notes file somewhere in this folder. You'll
find it if you look properly.  :)

Good luck!  — Sam
EOF

cat > .sam_notes <<'EOF'
Private notes (Sam)
- The vendor wants a copy of yesterday's log but WITHOUT customer
  emails. GDPR. Redact them before sending.
- brewlogd is the debug logger I wrote. If it ever goes wild, kill it.
  There can be more than one copy running.
- Don't delete temp_do_not_delete. (Actually it's empty. Delete it.)
EOF

# ---------------------------------------------------------------------
# Config file with deliberate mistakes (Mission 2)
# ---------------------------------------------------------------------
cat > etc/brewbot.conf <<'EOF'
# BrewBot configuration
# Edited by Sam, 2026-03-14

shop_name=CyberX Coffee Roasters
listen_port=80800
log_level=debug
log_file=/home/cyberx/logs/brewbot.log
alert_email=sam@cyberx.example
max_orders_per_minute=120
TEMP_HACK=1   # remove me before go-live!!!
currency=EUR
EOF

# ---------------------------------------------------------------------
# Deterministic data generator (Park-Miller LCG, same on gawk and mawk)
# ---------------------------------------------------------------------
gen() { awk -v seed="$1" "$2"; }

# customers.txt: id name city
cat > data/customers.txt <<'EOF'
C101 Anna Munich
C102 Ben Augsburg
C103 Chiara Munich
C104 Deniz Nuremberg
C105 Elif Regensburg
C106 Felix Munich
C107 Greta Passau
C108 Hamid Augsburg
C109 Ines Munich
C110 Jonas Ingolstadt
C111 Katrin Munich
C112 Lukas Rosenheim
EOF

# orders.csv
gen 42 '
function r(n){ seed=(seed*16807)%2147483647; return int(seed/2147483647*n) }
BEGIN{
  split("Espresso Blend,Ethiopia Yirgacheffe,Colombia Huila,Brazil Cerrado,Kenya AA,Decaf House,Cold Brew Pack,Guatemala Antigua",P,",")
  split("8.50,14.90,12.50,10.90,16.90,11.50,9.90,13.50",PR,",")
  w[1]=6;w[2]=2;w[3]=3;w[4]=4;w[5]=1;w[6]=2;w[7]=3;w[8]=2; tot=23
  print "order_id,customer_id,product,qty,unit_price,date"
  for(i=1;i<=600;i++){
    x=r(tot); s=0; for(p=1;p<=8;p++){ s+=w[p]; if(x<s) break }
    c=sprintf("C%d",101+r(12)); q=1+r(4); d=sprintf("2026-10-%02d",14+int((i-1)/100))
    printf "%d,%s,%s,%d,%s,%s\n", 5000+i, c, P[p], q, PR[p], d
  }
}' > data/orders.csv

# ---------------------------------------------------------------------
# Mystery files (file, gzip, tar)
# ---------------------------------------------------------------------
printf 'Z-REPORT 2023-12-31\r\nTotal sales: 4821.40\r\nCash: 1203.10\r\nCard: 3618.30\r\n' > data/mystery3
head -n 40 data/orders.csv | gzip -9 > data/mystery1
POSTMP=$(mktemp -d)
mkdir -p "$POSTMP/pos" && cp data/customers.txt "$POSTMP/pos/"
printf 'terminal=POS-2\nlocation=Viktualienmarkt\n' > "$POSTMP/pos/pos.ini"
tar -cf data/mystery2 -C "$POSTMP" pos
rm -rf "$POSTMP"

# ---------------------------------------------------------------------
# Main log (Mission 4) — 2000 lines for 2026-10-20
# ---------------------------------------------------------------------
gen 7 '
function r(n){ seed=(seed*16807)%2147483647; return int(seed/2147483647*n) }
BEGIN{
  split("anna.k@mail.example ben.wolf@mail.example chiara@web.example deniz.y@mail.example elif@post.example felix.m@web.example greta@mail.example hamid@post.example",E," ")
  bad="203.0.113.77"
  for(i=0;i<2000;i++){
    t=i*43; h=int(t/3600); m=int((t%3600)/60); s=t%60
    ts=sprintf("2026-10-20 %02d:%02d:%02d",h,m,s)
    ip=sprintf("192.168.%d.%d",1+r(3),10+r(40))
    x=r(100); o=5000+r(600); e=E[1+r(8)]
    if(x<62)      printf "%s INFO  order %d placed by %s from %s\n",ts,o,e,ip
    else if(x<74) printf "%s INFO  health check ok\n",ts
    else if(x<84) printf "%s WARN  slow response 1%d%d0 ms from %s\n",ts,r(9),r(9),ip
    else if(x<92) printf "%s ERROR payment declined for order %d from %s\n",ts,o,bad
    else if(x<96) printf "%s ERROR payment declined for order %d from %s\n",ts,o,ip
    else if(x<98) printf "%s error db timeout after 30s\n",ts
    else          printf "%s DEBUG cache hit ratio 0.%d%d\n",ts,r(9),r(9)
  }
}' > logs/brewbot.log

# Rotated logs: ~1.5 MB each, 12 files (18 MB total)  (Mission 6)
for n in $(seq 1 12); do
  awk -v seed="$((100+n))" -v n="$n" '
  function r(k){ seed=(seed*16807)%2147483647; return int(seed/2147483647*k) }
  BEGIN{ for(i=0;i<26000;i++) printf "2026-09-%02d 0%d:%02d:%02d DEBUG cache hit ratio 0.%d%d tick %d\n", n, r(9), r(60), r(60), r(9), r(9), i }' \
    > "logs/old/brewbot.log.$n"
done

# ---------------------------------------------------------------------
# The runaway "debug logger" (Mission 5)
# ---------------------------------------------------------------------
cat > bin/brewlogd <<'EOF'
#!/bin/bash
# brewlogd — Sam's debug logger. Writes way too much. Caps itself at 10 MB.
# Kept light on purpose (bash builtins only, 10 lines/s).
LOG="$(dirname "$0")/../logs/runaway.log"
n=0
while true; do
  if (( n % 50 == 0 )) && [ -f "$LOG" ] && [ "$(stat -c %s "$LOG" 2>/dev/null || echo 0)" -gt 10485760 ]; then
    sleep 5; continue
  fi
  printf '%(%F %T)T DEBUG brewlogd[%d] heartbeat queue=%d ok\n' -1 "$$" "$RANDOM" >> "$LOG"
  n=$((n + 1))
  sleep 0.1
done
EOF
chmod +x bin/brewlogd

# ---------------------------------------------------------------------
# Disk image with 2023 receipts (Mission 6 mount/umount, needs sudo)
# ---------------------------------------------------------------------
MKFS=$(command -v mkfs.ext4 || ls /sbin/mkfs.ext4 /usr/sbin/mkfs.ext4 2>/dev/null | head -n1 || true)
if [[ -n "$MKFS" ]]; then
  IMGSRC=$(mktemp -d)
  mkdir -p "$IMGSRC/receipts-2023"
  for mo in 01 02 03 04 05 06 07 08 09 10 11 12; do
    printf 'CyberX receipts 2023-%s\nTotal: %d.00 EUR\n' "$mo" "$((3000 + 10#$mo * 137))" > "$IMGSRC/receipts-2023/2023-$mo.txt"
  done
  echo "If you can read this, the mount worked. — Sam" > "$IMGSRC/README"
  truncate -s 16M disk/archive.img
  "$MKFS" -q -F -d "$IMGSRC" disk/archive.img >/dev/null 2>&1 || echo "note: could not build disk image (skip task 6.11)"
  rm -rf "$IMGSRC"
else
  echo "note: mkfs.ext4 not found; disk/archive.img not created (skip task 6.11)"
fi

echo
echo "CyberX lab ready in $LAB"
echo "Next:              cd ~/cyberx && cat HANDOVER.txt"
if command -v cyberx-setup >/dev/null 2>&1; then
  echo "Before Mission 5:  cyberx-setup --incident"
else
  echo "Before Mission 5:  bash $(readlink -f "${BASH_SOURCE[0]}") --incident"
fi
