#!/usr/bin/env bash
# Protocol conformance check for izanami-916.github.io/protocol.html
# vs the live ask rail. Re-runnable, read-only, no payment.
#
# Requests made: GET/HEAD only, plus at most ONE unpaid POST to
# https://izanami.tail0750b9.ts.net/api/ask to observe the 402.
# No paid request, no tx submission, no destructive request.
# Run inside the live window 00:00-04:00 UTC for the POST check;
# outside it the endpoint is down by design and the POST check is
# expected to fail to connect (that is not drift).
set -u
LIVE="https://izanami.tail0750b9.ts.net"
SITE="https://izanami-916.github.io"
PAYTO="66NggFgVscQLi7oJ8HZm39naWxUPpveLibNo3hDXBqm7"
USDC_MINT="EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
echo "== audit run: $(date -u +%Y-%m-%dT%H:%M:%SZ) =="
echo "--- protocol page ---"
curl -s -m 20 -o /tmp/iz_protocol.html -w "GET %{url_effective} -> %{http_code} %{size_download} bytes\n" "$SITE/protocol.html"
grep -c "66NggFgVscQLi7oJ8HZm39naWxUPpveLibNo3hDXBqm7" /tmp/iz_protocol.html | xargs echo "payTo mentions in protocol.html:"
echo "--- live vitals ---"
curl -s -m 20 "$LIVE/vitals.json" | tee /tmp/iz_vitals.json; echo
echo "--- live ask.json vs published ask.json (URL fields) ---"
curl -s -m 20 "$LIVE/api/ask.json" -o /tmp/iz_ask_live.json
curl -s -m 20 "$SITE/api/ask.json" -o /tmp/iz_ask_site.json
diff /tmp/iz_ask_site.json /tmp/iz_ask_live.json || true
echo "--- live ask endpoint (no payment) ---"
curl -s -m 20 -o /tmp/iz_ask_get.txt -w "GET $LIVE/api/ask -> %{http_code}\n" "$LIVE/api/ask"
cat /tmp/iz_ask_get.txt; echo
echo "--- manual rail terms (GET only) ---"
curl -s -m 20 -o /tmp/iz_manual.txt -w "GET $LIVE/api/manual -> %{http_code}\n" "$LIVE/api/manual"
cat /tmp/iz_manual.txt; echo
echo "--- answers index ---"
curl -s -m 20 "$LIVE/answers.html" -o /tmp/iz_answers.html -w "GET $LIVE/answers.html -> %{http_code}\n"
grep -o "a/[A-Za-z0-9_-]*\.html" /tmp/iz_answers.html | sort -u
grep -o "explorer.solana.com[^\"' <]*" /tmp/iz_answers.html | sort -u
FIRST_ANSWER=$(grep -o "a/[A-Za-z0-9_-]*\.html" /tmp/iz_answers.html | sort -u | head -n 1)
if [ -n "$FIRST_ANSWER" ]; then
  echo "--- first answer page: $FIRST_ANSWER ---"
  curl -s -m 20 "$LIVE/$FIRST_ANSWER" -o /tmp/iz_answer1.html -w "GET -> %{http_code}\n"
  grep -o "explorer.solana.com[^\"' <]*" /tmp/iz_answer1.html | head -n 2
fi
echo "--- on-chain wallet (public Solana RPC, read-only) ---"
curl -s -m 20 -X POST https://api.mainnet-beta.solana.com -H 'Content-Type: application/json' \
  -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getBalance\",\"params\":[\"$PAYTO\"]}"
echo
curl -s -m 20 -X POST https://api.mainnet-beta.solana.com -H 'Content-Type: application/json' \
  -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getAccountInfo\",\"params\":[\"$PAYTO\"]}"
echo
curl -s -m 20 -X POST https://api.mainnet-beta.solana.com -H 'Content-Type: application/json' \
  -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getTokenAccountsByOwner\",\"params\":[\"$PAYTO\",{\"mint\":\"$USDC_MINT\"},{\"encoding\":\"jsonParsed\"}]}"
echo
echo "--- THE ONE unpaid POST (observe the 402) ---"
curl -s -m 25 -D /tmp/iz_post.headers -X POST "$LIVE/api/ask" \
  -H 'Content-Type: application/json' -d '{}' -o /tmp/iz_post.body \
  -w "POST $LIVE/api/ask -> %{http_code} in %{time_total}s (exit %{exitcode})\n" || true
echo "response headers:"; cat /tmp/iz_post.headers 2>/dev/null
echo "response body:"; cat /tmp/iz_post.body 2>/dev/null; echo
echo "== done: $(date -u +%Y-%m-%dT%H:%M:%SZ) =="
echo "Expected per protocol.html: POST without payment -> 402 with"
echo "PAYMENT-REQUIRED header (x402-exact) and terms in the body."
echo "In the audit run this returned 402 in 1.58s at 03:23:46 UTC."
echo "Timeouts were seen earlier in the same window (01:05 UTC) and"
echo "are transient: retry a timeout before concluding anything."
