#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# VitalScan (Bit2sky) happy-path smoke test.
# Exercises: email-OTP login -> auth'd call -> add to cart -> add family member
# + address -> fetch slots -> create booking -> assert snapshot/slot/cart in DB.
#
# Requires: the API up on :5001 in Development with Auth__EchoEmailOtp=true
#           (see FABLE_E2E_TEST_PROMPT.txt for the exact run command),
#           Postgres container `bit2sky-pg`, Redis container `redis`, python3.
# Usage:    bash smoke_test.sh          (exit 0 = all pass, 1 = failures)
# ---------------------------------------------------------------------------
set -uo pipefail

API="${API:-http://localhost:5001/api/v1}"
DOCKER="/Applications/Docker.app/Contents/Resources/bin/docker"; command -v "$DOCKER" >/dev/null 2>&1 || DOCKER="docker"
CT=(-H "Content-Type: application/json" -H "X-App-Source: flutter_android")
EMAIL="smoke_$$_$(od -An -N2 -tu2 < /dev/urandom | tr -d ' ')@example.com"

PASS=0; FAIL=0
ok(){  printf '  \033[32mPASS\033[0m %s\n' "$1"; PASS=$((PASS+1)); }
bad(){ printf '  \033[31mFAIL\033[0m %s\n' "$1"; FAIL=$((FAIL+1)); }
step(){ printf '\n\033[1m== %s ==\033[0m\n' "$1"; }
# jval '<json>' data.0.id  -> prints the value (supports numeric array indices)
jval(){ python3 -c "import sys,json
try: d=json.load(sys.stdin)
except Exception: print(''); sys.exit()
for k in sys.argv[1].split('.'):
    if isinstance(d,list) and k.isdigit(): d=d[int(k)] if int(k)<len(d) else None
    elif isinstance(d,dict): d=d.get(k)
    else: d=None
    if d is None: break
print(d if d is not None else '')" "$1" 2>/dev/null; }
# jlen '<json>' data.items -> prints the length of the array at that path
jlen(){ python3 -c "import sys,json
try: d=json.load(sys.stdin)
except Exception: print(0); sys.exit()
for k in sys.argv[1].split('.'):
    if isinstance(d,list) and k.isdigit(): d=d[int(k)] if int(k)<len(d) else None
    elif isinstance(d,dict): d=d.get(k)
    else: d=None
    if d is None: break
print(len(d) if isinstance(d,list) else 0)" "$1" 2>/dev/null; }
psql1(){ "$DOCKER" exec bit2sky-pg psql -U postgres -d bit2sky -tAc "$1" 2>/dev/null | tr -d '[:space:]'; }

TOMORROW=$(date -v+1d +%Y-%m-%d 2>/dev/null || date -d "+1 day" +%Y-%m-%d)

# --- 0. Clean rate limits so OTP send isn't throttled -----------------------
"$DOCKER" exec redis redis-cli FLUSHALL >/dev/null 2>&1 && echo "redis flushed" || echo "warn: could not flush redis"

# --- 1. API health ----------------------------------------------------------
step "API health"
code=$(curl -s -o /dev/null -w '%{http_code}' -m8 "${CT[@]}" "$API/config/branding")
[ "$code" = "200" ] && ok "GET /config/branding -> 200" || { bad "API not healthy (HTTP $code) — is it running on :5001?"; echo; echo "PASS=$PASS FAIL=$FAIL"; exit 1; }

# --- 2. Email OTP login -----------------------------------------------------
step "Email-OTP login ($EMAIL)"
SEND=$(curl -s -m8 "${CT[@]}" -X POST "$API/auth/email/otp/send" -d "{\"email\":\"$EMAIL\"}")
SID=$(echo "$SEND" | jval data.sessionId)
OTP=$(echo "$SEND" | jval data.devOtp)
[ -n "$SID" ] && ok "send-otp returned sessionId" || bad "send-otp failed: $SEND"
[ -n "$OTP" ] && ok "devOtp echoed (Auth__EchoEmailOtp on)" || bad "no devOtp — set Auth__EchoEmailOtp=true"
VER=$(curl -s -m8 "${CT[@]}" -X POST "$API/auth/email/otp/verify" -d "{\"sessionId\":\"$SID\",\"otp\":\"$OTP\",\"deviceInfo\":\"smoke\"}")
TOK=$(echo "$VER" | jval data.accessToken)
[ -n "$TOK" ] && ok "verify returned a JWT" || { bad "verify failed: $VER"; echo; echo "PASS=$PASS FAIL=$FAIL"; exit 1; }
AUTH=(-H "Authorization: Bearer $TOK")

# --- 3. Authenticated call (JWT regression) ---------------------------------
step "Authenticated /users/me (JWT key regression)"
code=$(curl -s -o /dev/null -w '%{http_code}' -m8 "${CT[@]}" "${AUTH[@]}" "$API/users/me")
[ "$code" = "200" ] && ok "/users/me -> 200 (not 401)" || bad "/users/me -> HTTP $code (JWT sign/validate mismatch?)"

# --- 4. New user persisted (Email set, Mobile NULL) -------------------------
step "User row created by email login"
row=$(psql1 "SELECT COALESCE(\"Mobile\",'<null>') FROM core.users WHERE \"Email\"='$EMAIL';")
[ "$row" = "<null>" ] && ok "core.users row exists with Mobile NULL" || bad "expected user w/ NULL mobile, got: '$row'"

# --- 5. Add to cart (INSERT regression) -------------------------------------
step "Add test to cart"
TID=$(curl -s -m8 "${CT[@]}" "$API/tests" | jval data.0.id)
[ -n "$TID" ] && ok "fetched a test id" || bad "GET /tests returned no tests"
ADD=$(curl -s -m8 "${CT[@]}" "${AUTH[@]}" -X POST "$API/cart/items" -d "{\"testId\":\"$TID\"}")
succ=$(echo "$ADD" | jval success); items=$(echo "$ADD" | jlen data.items)
[ "$succ" = "True" ] && ok "POST /cart/items succeeded (INSERT, not phantom 0-rows)" || bad "cart add failed: $ADD"
[ "$items" -ge 1 ] 2>/dev/null && ok "cart has $items item(s)" || bad "cart item count unexpected: $items"

# --- 6. Add family member (medical fields required) -------------------------
step "Add family member"
FAM=$(curl -s -m8 "${CT[@]}" "${AUTH[@]}" -X POST "$API/users/me/family" \
  -d '{"name":"Smoke Child","relationship":"Son","gender":"Male","dateOfBirth":"2015-05-05","bloodGroup":"OPositive"}')
FID=$(echo "$FAM" | jval data.id)
[ -n "$FID" ] && ok "family member created" || bad "family add failed: $FAM"
# negative: missing gender/DOB must be rejected
neg=$(curl -s -o /dev/null -w '%{http_code}' -m8 "${CT[@]}" "${AUTH[@]}" -X POST "$API/users/me/family" -d '{"name":"NoDob","relationship":"Son"}')
[ "$neg" = "400" ] || [ "$neg" = "422" ] && ok "family without gender/DOB rejected (HTTP $neg)" || bad "expected 400/422 for missing gender/DOB, got $neg"

# --- 7. Add address ---------------------------------------------------------
step "Add address"
ADDR=$(curl -s -m8 "${CT[@]}" "${AUTH[@]}" -X POST "$API/users/me/addresses" \
  -d '{"type":"Home","line1":"12 Test Lane","city":"Navi Mumbai","state":"Maharashtra","pincode":"400703"}')
AID=$(echo "$ADDR" | jval data.id)
[ -n "$AID" ] && ok "address created" || bad "address add failed: $ADDR"

# --- 8. Fetch slots ---------------------------------------------------------
step "Fetch collection slots for $TOMORROW"
SLOTS=$(curl -s -m8 "${CT[@]}" "$API/slots?date=$TOMORROW")
# first AVAILABLE slot — repeated runs fill earlier seats
SLOTID=$(echo "$SLOTS" | python3 -c "import sys,json
try: d=json.load(sys.stdin)['data'] or []
except Exception: d=[]
print(next((s['id'] for s in d if s.get('available')), ''))")
[ -n "$SLOTID" ] && ok "slots returned; picked $SLOTID" || bad "GET /slots returned none: $SLOTS"
BOOKED_BEFORE=$(psql1 "SELECT \"Booked\" FROM booking.slots WHERE \"Id\"='$SLOTID';")

# --- 9. Create booking ------------------------------------------------------
step "Create booking (patient -> address -> slot)"
BOOK=$(curl -s -m8 "${CT[@]}" "${AUTH[@]}" -X POST "$API/bookings" \
  -d "{\"scheduledDate\":\"$TOMORROW\",\"slotId\":\"$SLOTID\",\"addressId\":\"$AID\",\"familyMemberId\":\"$FID\"}")
BID=$(echo "$BOOK" | jval data.bookingId)
BNUM=$(echo "$BOOK" | jval data.bookingNumber)
[ -n "$BID" ] && ok "booking created ($BNUM)" || { bad "booking failed: $BOOK"; }

if [ -n "$BID" ]; then
  # snapshot
  pname=$(psql1 "SELECT COALESCE(\"PatientName\",'<null>') FROM booking.bookings WHERE \"Id\"='$BID';")
  [ "$pname" = "SmokeChild" ] && ok "patient snapshot saved (PatientName='Smoke Child')" || bad "PatientName snapshot missing/wrong: '$pname'"
  # slot reserved
  BOOKED_AFTER=$(psql1 "SELECT \"Booked\" FROM booking.slots WHERE \"Id\"='$SLOTID';")
  [ "${BOOKED_AFTER:-0}" -gt "${BOOKED_BEFORE:-0}" ] 2>/dev/null && ok "slot Booked incremented ($BOOKED_BEFORE -> $BOOKED_AFTER)" || bad "slot not reserved ($BOOKED_BEFORE -> $BOOKED_AFTER)"
  # cart cleared
  left=$(curl -s -m8 "${CT[@]}" "${AUTH[@]}" "$API/cart" | jlen data.items)
  [ "${left:-0}" -eq 0 ] 2>/dev/null && ok "cart cleared after checkout" || bad "cart not cleared ($left items remain)"
fi

# --- 10. IDOR: booking with someone else's address must be rejected ---------
step "IDOR guard (booking with a foreign addressId)"
OTHER=$(psql1 "SELECT a.\"Id\" FROM core.addresses a JOIN core.users u ON u.\"Id\"=a.\"UserId\" WHERE u.\"Email\"<>'$EMAIL' LIMIT 1;")
if [ -n "$OTHER" ]; then
  curl -s -m8 "${CT[@]}" "${AUTH[@]}" -X POST "$API/cart/items" -d "{\"testId\":\"$TID\"}" >/dev/null
  idor=$(curl -s -o /dev/null -w '%{http_code}' -m8 "${CT[@]}" "${AUTH[@]}" -X POST "$API/bookings" \
    -d "{\"scheduledDate\":\"$TOMORROW\",\"slotId\":\"$SLOTID\",\"addressId\":\"$OTHER\",\"familyMemberId\":\"$FID\"}")
  { [ "$idor" = "400" ] || [ "$idor" = "403" ]; } && ok "foreign addressId rejected (HTTP $idor)" || bad "IDOR: foreign addressId accepted (HTTP $idor)"
else
  echo "  (skipped — no other user's address in DB to test with)"
fi

# --- COD booking: created directly as Confirmed (P0b) -----------------------
step "COD booking (pay on sample collection)"
DAY2=$(date -v+2d +%Y-%m-%d 2>/dev/null || date -d "+2 days" +%Y-%m-%d)
CODSLOT=$(curl -s -m8 "${CT[@]}" "$API/slots?date=$DAY2" | jval data.0.id)
curl -s -m8 "${CT[@]}" "${AUTH[@]}" -X POST "$API/cart/items" -d "{\"testId\":\"$TID\"}" >/dev/null
CODBOOK=$(curl -s -m8 "${CT[@]}" "${AUTH[@]}" -X POST "$API/bookings" \
  -d "{\"scheduledDate\":\"$DAY2\",\"slotId\":\"$CODSLOT\",\"addressId\":\"$AID\",\"paymentMethod\":\"cod\"}")
CODID=$(echo "$CODBOOK" | jval data.bookingId)
[ -n "$CODID" ] && ok "cod booking created" || bad "cod create failed: $CODBOOK"
cod_status=$(psql1 "SELECT \"Status\" FROM booking.bookings WHERE \"Id\"='$CODID';")
[ "$cod_status" = "1" ] || [ "$cod_status" = "Confirmed" ] && ok "cod booking Confirmed at create" || bad "cod booking status=$cod_status (want Confirmed)"
cod_method=$(psql1 "SELECT p.\"Method\" FROM commerce.payments p WHERE p.\"BookingId\"='$CODID';")
{ [ "$cod_method" = "3" ] || [ "$cod_method" = "CashOnCollection" ]; } && ok "payment method CashOnCollection" || bad "payment method=$cod_method"

# --- Reschedule (P0c): move the COD booking to a second slot ----------------
step "Reschedule"
DAY3=$(date -v+3d +%Y-%m-%d 2>/dev/null || date -d "+3 days" +%Y-%m-%d)
SLOT2=$(curl -s -m8 "${CT[@]}" "$API/slots?date=$DAY3" | jval data.1.id)
if [ -n "$SLOT2" ]; then
  RES=$(curl -s -m8 "${CT[@]}" "${AUTH[@]}" -X POST "$API/bookings/$CODID/reschedule" \
    -d "{\"scheduledDate\":\"$DAY3\",\"slotId\":\"$SLOT2\"}")
  succ=$(echo "$RES" | jval success)
  [ "$succ" = "True" ] || [ "$succ" = "true" ] && ok "reschedule 200" || bad "reschedule failed: $RES"
  rc=$(psql1 "SELECT \"RescheduleCount\" FROM booking.bookings WHERE \"Id\"='$CODID';")
  [ "$rc" = "1" ] && ok "RescheduleCount=1" || bad "RescheduleCount=$rc (want 1)"
  s2b=$(psql1 "SELECT \"Booked\" FROM booking.slots WHERE \"Id\"='$SLOT2';")
  [ "$s2b" -ge 1 ] 2>/dev/null && ok "new slot seat reserved (Booked=$s2b)" || bad "new slot Booked=$s2b"
  # limit: second reschedule OK (max=2), third must 409
  curl -s -m8 -o /dev/null "${CT[@]}" "${AUTH[@]}" -X POST "$API/bookings/$CODID/reschedule" -d "{\"scheduledDate\":\"$DAY3\"}"
  lim=$(curl -s -o /dev/null -w '%{http_code}' -m8 "${CT[@]}" "${AUTH[@]}" -X POST "$API/bookings/$CODID/reschedule" -d "{\"scheduledDate\":\"$DAY3\"}")
  [ "$lim" = "409" ] && ok "reschedule limit enforced (409)" || bad "3rd reschedule HTTP $lim (want 409)"
else
  echo "  (skipped — no second slot available on $DAY3)"
fi

# --- Summary ----------------------------------------------------------------
printf '\n\033[1m========================================\033[0m\n'
printf 'RESULT:  \033[32m%d passed\033[0m,  \033[31m%d failed\033[0m\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] && { echo "SMOKE TEST GREEN ✅"; exit 0; } || { echo "SMOKE TEST HAS FAILURES ❌"; exit 1; }
