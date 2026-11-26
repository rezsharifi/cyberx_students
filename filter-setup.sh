#!/usr/bin/env bash
# =====================================================================
#  filter-setup.sh  —  builds the CyberX "Output Filtering" labs
#
#    Lab 1  The Log Detective   grep, regular expressions, cut
#    Lab 2  The Clean-up Crew   sed, awk
#
#  For students' own Ubuntu VMs. Run it as your normal user (not root):
#
#    bash filter-setup.sh               # first time: builds ~/filters
#    filter-setup                       # after the first run: rebuild
#    filter-setup --answer 1.07 42      # check your answer to task 1.07
#    filter-setup --answer 2.03         # check a file task (no value)
#    filter-setup --progress            # which tasks you have solved
#    filter-setup --reset               # delete ~/filters
#    filter-setup --check               # only check that the tools exist
#
#  The first run asks for your password once (sudo) to install any
#  missing tools and to install this script as the command
#  "filter-setup". Add --no-sudo to skip both.
#
#  Data is deterministic: every student gets identical files, so the
#  answers (and the instructor's key) match for everyone.
# =====================================================================
set -euo pipefail

LAB="${FILTER_LAB:-$HOME/filters}"
BIN="/usr/local/bin/filter-setup"
PROGRESS="$LAB/.progress"
MODE="${1:-}"
NO_SUDO=""
for a in "$@"; do [[ "$a" == "--no-sudo" ]] && NO_SUDO=1; done
[[ "$MODE" == "--no-sudo" ]] && MODE=""

if [[ "$(id -u)" -eq 0 && -z "${FILTER_ALLOW_ROOT:-}" ]]; then
  echo "Please run this as your normal user, not as root (no sudo in front)."
  exit 1
fi

REQUIRED=( "grep:grep" "sed:sed" "awk:mawk" "cut:coreutils" "sort:coreutils"
           "uniq:coreutils" "wc:coreutils" "tr:coreutils" "head:coreutils"
           "sha256sum:coreutils" "less:less" "man:man-db" )

missing_packages() {
  local item cmd pkg out=()
  for item in "${REQUIRED[@]}"; do
    cmd="${item%%:*}"; pkg="${item##*:}"
    command -v "$cmd" >/dev/null 2>&1 || { [[ " ${out[*]-} " == *" $pkg "* ]] || out+=("$pkg"); }
  done
  echo "${out[*]-}"
}

check_tools() {
  local miss; miss="$(missing_packages)"
  if [[ -n "$miss" ]]; then
    echo "Missing packages: $miss"; echo "Install them with:  sudo apt install -y $miss"; return 1
  fi
  echo "All tools present."
}

prepare_system() {
  local miss self need_install=""
  miss="$(missing_packages)"
  self="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || true)"
  if [[ -f "$self" && "$self" != "$BIN" ]] && ! cmp -s "$self" "$BIN" 2>/dev/null; then need_install=1; fi
  [[ -z "$miss" && -z "$need_install" ]] && return 0
  if [[ -n "$NO_SUDO" ]] || ! command -v sudo >/dev/null 2>&1; then
    [[ -n "$miss" ]] && echo "note: missing packages ($miss): sudo apt install -y $miss"
    return 0
  fi
  echo "One-time setup needs your password (the one you use to log in)."
  if [[ -n "$miss" ]]; then
    sudo apt-get update -qq && sudo apt-get install -y -qq $miss || echo "note: could not install $miss"
  fi
  if [[ -n "$need_install" ]]; then
    echo "==> Installing the command: filter-setup"
    sudo install -m 755 "$self" "$BIN" || echo "note: could not install $BIN; keep using: bash $self"
  fi
  hash -r 2>/dev/null || true
}

# ---------------------------------------------------------------------
# Answer checking. Answers are stored as salted SHA-256 hashes, so
# reading this script does not reveal them. Numbers are compared as
# numbers (42 = 42.0 = 42.00); text ignores case and spaces.
# ---------------------------------------------------------------------
norm() {
  local a
  a=$(printf '%s' "$1" | tr 'A-Z' 'a-z' | tr -d '[:space:]')
  if [[ "$a" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then a=$(awk -v x="$a" 'BEGIN{printf "%.2f", x}'); fi
  printf '%s' "$a"
}
h() { printf 'cyberx-filters:%s:%s' "$1" "$(norm "$2")" | sha256sum | cut -c1-24; }

declare -A KEY=(
  [1.01]=633087c4e6fb6db45b0e618b
  [1.02]=0be94fc24c831893522d52ba
  [1.03]=7a5aea8bc0b535bb115d6dec
  [1.04]=30c002480d50f6b5137b2002
  [1.05]=aae23efe2941e7840cd77fe2
  [1.06]=5a781f16a14c97b2c41908fe
  [1.07]=5a746af8d4da1d74e7fa3ba7
  [1.08]=0aa22a9d5bf26f2d09cca768
  [1.09]=35072486b386160f05d4fd75
  [1.10]=2e23be2c3192c79bb0a1a4e2
  [1.11]=8c316ef69c1d7d004a9e835c
  [1.12]=82bbeec39fa824a52ff793b8
  [1.13]=2089b7d3c54b02ad6b21d984
  [1.14]=4ec4a3b9d04414aab5335e5c
  [1.15]=266811d4fa0a0c85826e5e53
  [1.16]=f79c5812b570e6e491803723
  [1.17]=0788a54e38e4cd02062cea93
  [1.18]=d170ab1b6cf5f5a856729c45
  [1.19]=a6cc215c5c1a35861334d630
  [1.20]=270f757307d14ab1babe48f0
  [2.01]=0c7eae53d05d749444724e70
  [2.02]=a00ed9ea3ec140a87b93b8c3
  [2.07]=1e5f4b23955843661e51715b
  [2.08]=e75cccc554aec42fd822df7b
  [2.09]=2c708baaaf9ffbbaba34b42e
  [2.10]=c4127a4ff6d69c6572e90d73
  [2.11]=f0322230b6d1afb10615c605
  [2.12]=79ea5b11da852c2ce3f6d0a1
  [2.13]=642221e36954e66d89f9c2dc
  [2.14]=72c0166c0c0372ea6c97c0c5
  [2.15]=cf16ae2643c380c7feb3012b
  [2.16]=a5eb307c8d7c1b2592aa212e
  [2.17]=f005ab5ff013abbe7959039d
  [2.18]=c691da500faa0ea66f0809dc
)

EMAIL_RE='[[:alnum:]._%+-]+@[[:alnum:].-]+\.[[:alpha:]]{2,}'

file_task() {           # file_task <task>  -> 0 if the student's file is right
  local t="$1" L1="$LAB/lab1" L2="$LAB/lab2" f exp
  case "$t" in
    2.03)
      f="$L2/out/brewbot.conf"; [[ -f "$f" ]] || { echo "Missing file: $f"; return 1; }
      grep -qx 'listen_port=8080'  "$f" || { echo "listen_port is not 8080";  return 1; }
      grep -qx 'log_level=warn'    "$f" || { echo "log_level is not warn";    return 1; }
      grep -q  'sam@cyberx'        "$f" && { echo "Sam's address is still in the file"; return 1; }
      [[ $(grep -c 'ops@cyberx.example' "$f") -eq 2 ]] || { echo "expected ops@cyberx.example on 2 lines"; return 1; }
      grep -q  'TEMP_HACK'         "$f" && { echo "TEMP_HACK line is still there"; return 1; }
      [[ $(wc -l < "$f") -eq $(( $(wc -l < "$L2/brewbot.conf") - 1 )) ]] || { echo "only the TEMP_HACK line should be gone (line count differs)"; return 1; }
      grep -q '^# BrewBot' "$f" || { echo "comments should stay in this file"; return 1; } ;;
    2.04|2.05)
      f="$L2/out/inventory.csv"; [[ -f "$f" ]] || { echo "Missing file: $f"; return 1; }
      exp=$(sed -e 's/\r$//' -e 's/\([0-9]\),\([0-9]\)/\1.\2/g' -e 's/;/,/g' "$L2/inventory.csv")
      local exp5; exp5=$(printf '%s\n' "$exp" | sed -E 's/([0-9]{2})\.([0-9]{2})\.([0-9]{4})$/\3-\2-\1/')
      local got; got=$(sed 's/[[:space:]]*$//' "$f")
      grep -q $'\r' "$f" && { echo "There are still Windows line endings (\\r)"; return 1; }
      grep -q ';' "$f"    && { echo "There are still semicolons"; return 1; }
      if [[ "$t" == 2.04 ]]; then
        [[ "$got" == "$exp" || "$got" == "$exp5" ]] || { echo "Content differs from the expected clean CSV (check the decimal commas)"; return 1; }
      else
        [[ "$got" == "$exp5" ]] || { echo "Dates are not all YYYY-MM-DD (or something else changed)"; return 1; }
      fi ;;
    2.06)
      f="$L2/out/contacts-redacted.txt"; [[ -f "$f" ]] || { echo "Missing file: $f"; return 1; }
      [[ $(wc -l < "$f") -eq $(wc -l < "$L1/contacts.txt") ]] || { echo "Line count differs from contacts.txt"; return 1; }
      grep -qE "$EMAIL_RE" "$f" && { echo "An email address is still visible:"; grep -noE "$EMAIL_RE" "$f" | head -3; return 1; }
      [[ $(grep -o '\[REDACTED\]' "$f" | wc -l) -eq $(grep -oE "$EMAIL_RE" "$L1/contacts.txt" | wc -l) ]] \
        || { echo "Number of [REDACTED] markers does not match the number of addresses"; return 1; }
      grep -q '+49 89 4411023' "$f" || { echo "Phone numbers must stay untouched"; return 1; } ;;
    *) return 2 ;;
  esac
}

cmd_answer() {
  local t="${1:-}" v="${2:-}" rc
  [[ -d "$LAB" ]] || { echo "Run filter-setup first."; exit 1; }
  [[ "$t" =~ ^[12]\.[0-9]{2}$ ]] || { echo "usage: filter-setup --answer <task, e.g. 1.07> [answer]"; exit 1; }
  rc=0; file_task "$t" || rc=$?
  if [[ $rc -eq 2 ]]; then
    [[ -n "${KEY[$t]:-}" ]] || { echo "No task $t."; exit 1; }
    [[ -n "$v" ]] || { echo "Task $t needs an answer: filter-setup --answer $t <answer>"; exit 1; }
    [[ "$(h "$t" "$v")" == "${KEY[$t]}" ]] && rc=0 || rc=1
  fi
  if [[ $rc -eq 0 ]]; then
    echo "Task $t: CORRECT"
    grep -qx "$t" "$PROGRESS" 2>/dev/null || echo "$t" >> "$PROGRESS"
  else
    echo "Task $t: not yet. Check your filter and try again."; exit 1
  fi
}

cmd_progress() {
  local lab t n all
  for lab in 1 2; do
    all=$( { printf '%s\n' "${!KEY[@]}"; echo 2.03; echo 2.04; echo 2.05; echo 2.06; } | grep "^$lab\." | sort -u)
    n=$(grep -c "^$lab\." "$PROGRESS" 2>/dev/null || true)
    printf 'Lab %s: %s of %s solved\n  ' "$lab" "${n:-0}" "$(echo "$all" | wc -l)"
    for t in $all; do grep -qx "$t" "$PROGRESS" 2>/dev/null && printf '[x]%s ' "$t" || printf '[ ]%s ' "$t"; done
    echo
  done
}

case "$MODE" in
  --check)    check_tools; exit $? ;;
  --answer)   cmd_answer "${2:-}" "${3:-}"; exit 0 ;;
  --progress) cmd_progress; exit 0 ;;
  --reset)    rm -rf "$LAB"; echo "Lab removed."; exit 0 ;;
  "") ;;
  *) sed -n '3,23p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac

prepare_system

KEEP=""
[[ -f "$PROGRESS" ]] && KEEP="$(cat "$PROGRESS")"
rm -rf "$LAB"
mkdir -p "$LAB"/lab1 "$LAB"/lab2/out
[[ -n "$KEEP" ]] && printf '%s\n' "$KEEP" > "$PROGRESS"
cd "$LAB"

cat > README.txt <<'EOF'
=====================================================================
  From: Marta Lindqvist (Ops, CyberX Coffee Roasters)
  To:   you
  Subj: weekend incident + clean-up
=====================================================================
Hi,

Bad weekend. On Sunday 2 November the web shop was slow, the payment
provider complained, and the SSH log on cx-web is full of noise.
I need two things from you:

  lab1/  The Log Detective
         Find out what happened. The logs are copies from the server:
           access.log    web shop requests (nginx)
           auth.log      SSH and sudo log
           staff.passwd  copy of /etc/passwd from cx-web
           contacts.txt  supplier & staff contact list (messy, sorry)
           playground.txt  scratch file for trying regex patterns

  lab2/  The Clean-up Crew
         Fix and summarise our data. Write results to lab2/out/.
           brewbot.conf  BrewBot config (still Sam's settings)
           inventory.csv export from the old warehouse PC
           sales.csv     last week's orders
           fees.csv      delivery fee per city
           shifts.txt    barista shifts last week

Rule: never edit the original files. Read them, filter them, and
write results to new files.

Check an answer:   filter-setup --answer 1.01 <your answer>
See your progress: filter-setup --progress

Thanks!  — Marta
EOF

gen() { awk -v seed="$1" "$2"; }   # deterministic generator (same on mawk and gawk)
LCG='function r(n){ seed=(seed*16807)%2147483647; return int(seed/2147483647*n) }'

# =====================================================================
# LAB 1
# =====================================================================

# --- access.log -------------------------------------------------------
gen 2026 "$LCG"'
function pick(s,  a,n){ n=split(s,a,"|"); return a[1+r(n)] }
BEGIN{
  mon="Nov"
  ua_n="Mozilla/5.0 (Windows NT 10.0; Win64; x64) Firefox/133.0|Mozilla/5.0 (Macintosh; Intel Mac OS X 14_6) Safari/605.1.15|Mozilla/5.0 (Linux; Android 15) Chrome/131.0 Mobile|Mozilla/5.0 (X11; Ubuntu; Linux x86_64) Firefox/132.0|Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
  pages="/|/shop|/shop/espresso-blend|/shop/kenya-aa|/shop/colombia-huila|/shop/decaf-house|/cart|/about|/blog/404-ways-to-brew|/blog/cold-brew-guide|/search?q=espresso|/search?q=decaf|/shop?sort=price"
  static="/static/app.css|/static/app.js|/images/logo.png|/images/beans.jpg|/images/php.png"
  attack="/wp-login.php|/xmlrpc.php|/admin.php|/.env|/phpmyadmin/index.php|/../../etc/passwd|/static/%2e%2e/%2e%2e/etc/passwd|/static/%2E%2E/%2E%2E/etc/shadow|/cgi-bin/../../bin/sh|/backup.zip|/config.php.bak"
  sqli="/shop?id=1%27%20OR%201=1--|/search?q=%27%20UNION%20SELECT%20password%20FROM%20users--|/shop?id=1%20AND%20SLEEP(5)"
  for(i=0;i<3000;i++){
    t=int(i*28.8)+r(20); hh=int(t/3600); if(hh>23)hh=23; mm=int((t%3600)/60); ss=t%60
    # more traffic in the morning rush and lunch: re-draw quiet hours sometimes
    if((hh<6 || hh>21) && r(3)>0){ hh=7+r(4)+ (r(2)?4:0) }
    ts=sprintf("02/%s/2026:%02d:%02d:%02d +0100",mon,hh,mm,ss)
    x=r(100); ua=pick(ua_n); m="GET"; st=200; b=800+r(24000); ref="-"
    if(x<52){ ip=sprintf("198.51.100.%d",1+r(60)); p=pick(pages); if(p ~ /^\/cart/ && r(3)==0){m="POST"; st=302} }
    else if(x<70){ ip=sprintf("198.51.100.%d",1+r(60)); p=pick(static); if(r(4)==0){st=304; b=0} }
    else if(x<76){ ip=sprintf("192.0.2.%d",10+r(30)); m="POST"; p="/api/orders"; st=(r(9)==0)?500:201; b=120+r(300) }
    else if(x<79){ ip=sprintf("192.0.2.%d",10+r(30)); m=(r(2)?"PUT":"DELETE"); p="/api/cart/item/" (100+r(50)); st=204; b=0 }
    else if(x<81){ ip=sprintf("198.51.100.%d",1+r(60)); m="POST"; p="/account/login"; st=(r(4)==0)?401:302; b=310 }
    else if(x<83){ ip="203.0.113.7"; p=pick(pages); ua="Mozilla/5.0 (X11; Linux x86_64) Firefox/128.0" }
    else if(x<92){ ip="203.0.113.77"; ua="curl/8.5.0"; p=pick(attack); st=404; b=153
                   if(p=="/.env" || p=="/backup.zip"){st=403} }
    else if(x<98){ ip="203.0.113.150"; ua=(r(2)?"sqlmap/1.8.11#stable (https://sqlmap.org)":"Mozilla/5.00 (Nikto/2.5.0) (Evasions:None)")
                   if(r(2)){p=pick(sqli); st=(r(3)==0)?500:200}else{p=pick(attack); st=404; b=153} }
    else { ip=sprintf("192.0.2.%d",10+r(30)); p="/checkout"; st=(r(2)?502:503); b=157 }
    if(st==200 && r(40)==0) b=404
    if(p=="/blog/404-ways-to-brew") st=200
    if(ip ~ /^198/ && r(3)==0) ref="https://shop.cyberx.example/shop"
    printf "%s - - [%s] \"%s %s HTTP/1.1\" %d %d \"%s\" \"%s\"\n", ip, ts, m, p, st, b, ref, ua
  }
}' > lab1/access.log
# put the lines in time order (field 4 is "[02/Nov/2026:HH:MM:SS")
LC_ALL=C sort -s -k4,4 lab1/access.log -o lab1/access.log

# --- auth.log ---------------------------------------------------------
gen 77 "$LCG"'
function pick(s,  a,n){ n=split(s,a,"|"); return a[1+r(n)] }
BEGIN{
  bad_users="admin|admin|admin|admin|admin|admin|test|test|test|oracle|oracle|ubuntu|ubuntu|ubuntu|pi|guest|postgres|user|ftp|git"
  for(i=0;i<900;i++){
    t=i*96+r(60); hh=int(t/3600); mm=int((t%3600)/60); ss=t%60
    ts=sprintf("2026-11-02T%02d:%02d:%02d.%06d+01:00 cx-web",hh,mm,ss,r(999999))
    pid=2000+r(7000); port=40000+r(25000)
    x=r(100)
    w=r(10); ip=(w<5)?"203.0.113.77":(w<7)?"192.0.2.44":(w<9)?"198.51.100.250":"192.0.2.201"
    if(x<46){ u=pick(bad_users); printf "%s sshd[%d]: Failed password for invalid user %s from %s port %d ssh2\n",ts,pid,u,ip,port }
    else if(x<58){ u=pick(bad_users); printf "%s sshd[%d]: Invalid user %s from %s port %d\n",ts,pid,u,ip,port }
    else if(x<68){ u=pick("root|root|root|marta|deploy"); printf "%s sshd[%d]: Failed password for %s from %s port %d ssh2\n",ts,pid,u,ip,port }
    else if(x<74){ printf "%s sshd[%d]: Connection closed by authenticating user root %s port %d [preauth]\n",ts,pid,ip,port }
    else if(x<80){ u=pick("marta|martin|deploy"); ip=sprintf("198.51.100.%d",20+r(5))
                   printf "%s sshd[%d]: Accepted publickey for %s from %s port %d ssh2: ED25519 SHA256:%08x%08x\n",ts,pid,u,ip,port,r(2147483647),r(2147483647)
                   printf "%s sshd[%d]: pam_unix(sshd:session): session opened for user %s(uid=%d) by %s(uid=0)\n",ts,pid,u,(u=="marta")?1001:(u=="martin")?1002:1003,"root" }
    else if(x<88){ printf "%s CRON[%d]: pam_unix(cron:session): session opened for user root(uid=0) by root(uid=0)\n",ts,pid }
    else if(x<93){ printf "%s CRON[%d]: pam_unix(cron:session): session closed for user root\n",ts,pid }
    else if(x<97){ printf "%s sudo[%d]:    marta : TTY=pts/0 ; PWD=/home/marta ; USER=root ; COMMAND=/usr/bin/%s\n",ts,pid,pick("apt update|systemctl restart nginx|journalctl -u brewbot|less /var/log/nginx/access.log") }
    else { printf "%s systemd-logind[%d]: New session %d of user %s.\n",ts,812,100+i,pick("marta|martin") }
    if(i==611){
      printf "%s sshd[%d]: Accepted password for deploy from 203.0.113.7 port %d ssh2\n",ts,pid+1,port+1
      printf "%s sshd[%d]: pam_unix(sshd:session): session opened for user deploy(uid=1003) by root(uid=0)\n",ts,pid+1
      printf "%s sudo[%d]:   deploy : TTY=pts/3 ; PWD=/home/deploy ; USER=root ; COMMAND=/usr/bin/cat /etc/shadow\n",ts,pid+2
    }
  }
}' > lab1/auth.log

# --- staff.passwd -----------------------------------------------------
cat > lab1/staff.passwd <<'EOF'
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
sys:x:3:3:sys:/dev:/usr/sbin/nologin
sync:x:4:65534:sync:/bin:/bin/sync
man:x:6:12:man:/var/cache/man:/usr/sbin/nologin
www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin
backup:x:34:34:backup:/var/backups:/usr/sbin/nologin
nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin
systemd-network:x:998:998:systemd Network Management:/:/usr/sbin/nologin
systemd-timesync:x:997:997:systemd Time Synchronization:/:/usr/sbin/nologin
sshd:x:105:65534::/run/sshd:/usr/sbin/nologin
brewbot:x:999:996:BrewBot service:/srv/brewbot:/usr/sbin/nologin
marta:x:1001:1001:Marta Lindqvist,Ops:/home/marta:/bin/bash
martin:x:1002:1002:Martin Brandl,Web:/home/martin:/bin/bash
deploy:x:1003:1003:Deploy user:/home/deploy:/bin/bash
sam:x:1004:1004:Sam Okafor (left):/home/sam:/bin/false
martaj:x:1015:1015:Marta Jovanovic,Barista:/home/martaj:/bin/rbash
intern1:x:1020:1020:Intern:/home/intern1:/bin/rbash
intern2:x:1021:1021:Intern:/home/intern2:/bin/rbash
lea:x:1022:1022:Lea Huber,Roastery:/home/lea:/bin/bash
tom:x:1023:1023:Tom Vogt,Roastery:/home/tom:/usr/bin/zsh
EOF

# --- contacts.txt -----------------------------------------------------
cat > lab1/contacts.txt <<'EOF'
CyberX contact list  (exported from the old POS, do not trust the formatting)
----------------------------------------------------------------------
Marta Lindqvist   Ops            marta@cyberx.example        +49 89 4411023
Martin Brandl     Web            martin.brandl@cyberx.example  089/4411024
Lea Huber         Roastery       lea.huber@cyberx.example     +49 89 4411025
Tom Vogt          Roastery       tom(at)cyberx.example         0151 2349876
Sam Okafor        (left)         sam@cyberx.example            -
Bean Brothers GmbH  supplier     orders@beanbrothers.example   +49 911 554490
Kaffee Kontor     supplier       info@kaffee-kontor.example    0049 40 3491100
Highland Imports  supplier       sales@highland-imports.co.example   +44 20 7946 0958
Milk & More       supplier       hello@milkandmore             +49 8131 449
Pack-It           packaging      service@pack-it.example       +49 (0)89 99 49 49
Rosa Print        print shop     rosa@print                    089 49 49 12
CleanCo           cleaning       office@cleanco.example, billing@cleanco.example  +49 89 7712049
Elektro Maier     electrician    maier.elektro@mail.example    0171-4491234
IT emergency      external       @helpdesk.example             +49 800 4900490
Landlord          building       hausverwaltung@immo-sued.example  +49 89 300049
Barista temp pool staffing       jobs@barista-pool.example     +43 1 4900 2210
Old router        network        admin@192.168.1.1             -
Insurance         policy CX-49   claims@versicherung.example   +49 89 4949 0
Water filter      service        filter.service@aqua.example   (+49) 89 2349
Coffee machine    service        support@la-macchina.it.example  +39 02 4911 333
Marta (private)   do not share   m.lindqvist@web.example       +49 170 4492001
Bakery Wolf       croissants     wolf.backt@                   089 7749
Tax advisor       accounting     kanzlei.berg@steuer.example   +49 89 4900 4949
EOF

# --- playground.txt ---------------------------------------------------
cat > lab1/playground.txt <<'EOF'
2026
12345
12a45
 42
42
007
3.14
-17
1e5

colour
color
colr
gray
grey
greay
cat
cart
caat
ct
coffee
cofee
coffffee
Coffee
COFFEE
espresso
expresso
192.168.1.1
192x168y1z1
999.999.999.999
10.0.0.254
2026-11-02
02.11.2026
11/02/2026
tea or coffee
coffee, then tea
the cat sat on the mat
concatenate
#comment line
   # indented comment
key=value
key = value
ERROR disk full
error: disk full
Error Disk Full
$HOME is a variable
price: 12.50 EUR
price: 12,50 EUR
price: EUR 12.5
EOF
sed -i 's/^42$/42 /' lab1/playground.txt          # a trailing space on purpose

# =====================================================================
# LAB 2
# =====================================================================

cat > lab2/brewbot.conf <<'EOF'
# BrewBot configuration  (v2, after the move to the new server)
# Edited by Sam, 2026-03-14

[server]
shop_name=CyberX Coffee Roasters
listen_port=80800
   # the old port was 8000, I think
max_orders_per_minute=120

[logging]
log_level=debug
log_file=/srv/brewbot/logs/brewbot.log

# where do alerts go?
[alerts]
alert_email=sam@cyberx.example
backup_email=sam@cyberx.example
TEMP_HACK=1
currency=EUR
EOF
sed -i '13s/^$/    /' lab2/brewbot.conf                # a whitespace-only line on purpose

# inventory.csv: Windows line endings, semicolons, decimal commas, German dates
{
  printf 'sku;product;stock_kg;price_per_kg;last_delivery\r\n'
  gen 314 "$LCG"'
  BEGIN{
    n=split("Espresso Blend|Ethiopia Yirgacheffe|Colombia Huila|Brazil Cerrado|Kenya AA|Decaf House|Guatemala Antigua|Sumatra Mandheling|Costa Rica Tarrazu|Peru Organic|Rwanda Bourbon|India Monsooned Malabar|Honduras Marcala|Nicaragua Jinotega|Mexico Chiapas|Panama Boquete|Yemen Mocha|Burundi Kayanza|Tanzania Peaberry|Vietnam Robusta",P,"|")
    for(i=1;i<=n;i++){
      kg=sprintf("%.1f",r(900)/10+1); pr=sprintf("%.2f",(1800+r(4200))/100)
      sub(/\./,",",kg); sub(/\./,",",pr)
      d=1+r(28); mo=9+r(3); if(mo==11 && d>2) d=d%2+1
      printf "CX-%03d;%s;%s;%s;%02d.%02d.2026\r\n",i,P[i],kg,pr,d,mo
    }
  }'
} > lab2/inventory.csv

# sales.csv
gen 99 "$LCG"'
BEGIN{
  split("Espresso Blend,Ethiopia Yirgacheffe,Colombia Huila,Brazil Cerrado,Kenya AA,Decaf House,Cold Brew Pack,Guatemala Antigua",P,",")
  split("8.50,14.90,12.50,10.90,16.90,11.50,9.90,13.50",PR,",")
  split("Munich,Augsburg,Nuremberg,Regensburg,Passau,Ingolstadt",C,",")
  pw[1]=7;pw[2]=2;pw[3]=3;pw[4]=4;pw[5]=2;pw[6]=2;pw[7]=3;pw[8]=2; pt=25
  cw[1]=9;cw[2]=4;cw[3]=5;cw[4]=2;cw[5]=1;cw[6]=2; ct=23
  print "order_id,date,city,product,qty,unit_price"
  for(i=1;i<=800;i++){
    x=r(pt); s=0; for(p=1;p<=8;p++){ s+=pw[p]; if(x<s) break }
    x=r(ct); s=0; for(c=1;c<=6;c++){ s+=cw[c]; if(x<s) break }
    q=1+r(4); if(p==5 && r(3)==0) q+=4
    d=sprintf("2026-%s",(i<=114)?"10-26":(i<=230)?"10-27":(i<=340)?"10-28":(i<=455)?"10-29":(i<=600)?"10-30":(i<=720)?"10-31":"11-01")
    if(i==133||i==402) printf "%d,%s,%s,Mug, large,1,12.00\n",7000+i,d,C[c]
    else if(i==517)    printf "%d,%s,%s,%s,%d\n",7000+i,d,C[c],P[p],q
    else if(i==688)    printf "%d,%s,%s,Gift Card, 25 EUR,1,25.00\n",7000+i,d,C[c]
    else printf "%d,%s,%s,%s,%d,%s\n",7000+i,d,C[c],P[p],q,PR[p]
  }
}' > lab2/sales.csv

cat > lab2/fees.csv <<'EOF'
city,delivery_fee
Munich,2.90
Augsburg,4.50
Nuremberg,5.90
Regensburg,5.90
Passau,7.50
Ingolstadt,4.90
EOF

cat > lab2/shifts.txt <<'EOF'
# barista shifts, week 44 (26 Oct - 1 Nov 2026)
# name     day   start  end
anna       Mon   06:30  13:00
ben        Mon   12:30  19:00
martaj     Mon   07:00  15:30
anna       Tue   06:30  13:00
chiara     Tue   12:00  19:00
martaj     Tue   07:00  12:00
ben        Wed   06:30  14:30
chiara     Wed   13:00  19:00
anna       Wed   10:00  16:30
martaj     Thu   06:30  15:00
ben        Thu   12:30  19:00
deniz      Thu   08:00  12:30
anna       Fri   06:30  14:00
chiara     Fri   11:30  19:00
deniz      Fri   07:00  11:00
martaj     Sat   08:00  16:30
ben        Sat   08:00  13:30
chiara     Sat   12:00  18:00
anna       Sun   09:00  14:30
deniz      Sun   09:00  17:00
EOF

echo
echo "Filtering labs ready in $LAB"
echo "Next:  cd ~/filters && cat README.txt"
