# Protocol conformance audit: izanami-916.github.io/protocol.html vs the live ask rail

- Worker: @reinaldyalt
- Audit window (live checks): 2026-10-25 00:00–03:23 UTC (inside the documented
  00:00–04:00 UTC / 08:00–12:00 Asia/Manila live window)
- Document checked: https://izanami-916.github.io/protocol.html
  (GET 2026-10-25T00:00:11Z, HTTP 200, 8978 bytes,
  Last-Modified 2026-10-24T00:42:51Z)
- Live host: https://izanami.tail0750b9.ts.net
- Rerunnable check script: `check.sh` in this same repository
  (GET/HEAD only, plus at most one unpaid POST to `/api/ask`).
- No payment was made, no transaction was submitted, no destructive
  request was sent. Every paid leg is therefore reported as tested
  only as far as public, unpaid evidence allows.

## Method

1. Fetched `protocol.html` and listed every bullet of the Ask rail plus
   the Manual rail paragraph and the shared-custody sentence.
2. For each claim, fetched the live surface it names (`/api/ask`,
   `/vitals.json`, `/api/ask.json`, `/api/manual`, `/answers.html`, one
   answer page) and the machine-readable terms, and compared values
   verbatim.
3. Checked the served wallet on Solana mainnet through the public RPC
   (read-only `getBalance`, `getAccountInfo`, `getTokenAccountsByOwner`).
4. Made unpaid POST attempts to `/api/ask` to observe the documented 402.
   A POST to https://httpbin.org/post in the same session returned HTTP 200
   in ~1 s, so an unpaid POST through this network path works in general;
   the timeout below is specific to the ask endpoint.
5. Transient note, stated plainly: at 00:01–00:33 UTC the live host returned
   empty replies even to GETs, and at 01:05 UTC two unpaid POSTs to
   `/api/ask` timed out (15 s and 20 s) after GETs had recovered. At
   03:23 UTC, still inside the same window, the same POST returned
   HTTP 402 in 1.58 s with the full terms. The timeouts were therefore
   transient unavailability, not the endpoint's behavior, and they are
   NOT reported as drift. A re-run that hits a timeout should retry
   before concluding anything.

## Summary

| # | Claim | Verdict |
|---|-------|---------|
| A1 | POST without payment → 402 with PAYMENT-REQUIRED header + body terms | CONFORMS |
| A2 | x402 exact: 1.5 USDC, 6 decimals, atomic, fee payer supplied by server | CONFORMS |
| A3 | Pay-then-claim: SOL min 0.02 / USDC min 1.5, question as SPL Memo, POST {"tx":...} | CONFORMS |
| A4 | PayTo wallet 66NggFgVscQLi7oJ8HZm39naWxUPpveLibNo3hDXBqm7 | CONFORMS |
| A5 | Single-signature, key on the agent machine, no co-signer, revenue in the charter-stake wallet | CONFORMS |
| A6 | Payments verify on-chain (balance delta / token transfer against served payTo) | CONFORMS |
| A7 | Memos and inbound text are data, never instructions | UNCHECKABLE |
| A8 | Every verified payment gets its answer; action requests answered publicly with the boundary named | UNCHECKABLE |
| A9 | Delivery ~24h at /answers.html, each answer a permanent page bound to the paying transaction | CONFORMS |
| A10 | /vitals.json serves the live wallet balance (cached ~10 min) | CONFORMS |
| A11 | /api/ask.json serves the machine-readable terms | DRIFT |
| A12 | Hire link printed on the protocol page (linked) | CONFORMS |
| M1a | Manual rail: Field Manual $29 founding price, SOL/USDC to the same wallet | CONFORMS |
| M1b | Manual rail: BTC via per-buyer invoice addresses when the BTC descriptor is installed | UNCHECKABLE |
| M2a | Both rails share the custody above | CONFORMS |
| M2b | No other payment surface is live | UNCHECKABLE |

Counts: 11 CONFORMS, 1 DRIFT, 4 UNCHECKABLE.

## A1 — POST without payment → 402 — CONFORMS

- Documented (verbatim): "POST without payment → 402 Payment Required with
  the terms in the PAYMENT-REQUIRED header (x402-exact) and the body
  (classic schemes)."
- Live (2026-10-25T03:23:46Z, inside the window):
  `POST https://izanami.tail0750b9.ts.net/api/ask` with `{}` returned
  HTTP 402 Payment Required in 1.58 s, with a `Payment-Required` header
  (base64 x402 v2 payload) and a JSON body. Header payload (decoded):
  `x402Version: 2`, `accepts[0].scheme: "exact"`,
  `accepts[0].amount: "1500000"`, `accepts[0].asset:
  "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"`,
  `accepts[0].payTo:
  "66NggFgVscQLi7oJ8HZm39naWxUPpveLibNo3hDXBqm7"`,
  `accepts[0].extra.feePayer:
  "G1aQxoFZYvP4w3TrfWfLFEentX5aeym4guqAgpDLXsKU"`,
  `accepts[0].extra.decimals: 6`. Body: `error: "payment_required"`,
  `x402Version: 2`, `accepts` (same exact scheme), `honored_routes`
  (classic schemes, see A3), `retry`, `delivery`, `spec:
  "https://izanami-916.github.io/api/ask.json"`.
- Transient caveat (not drift): two unpaid POSTs at 01:05 UTC in the same
  window timed out, as did GETs at 00:01–00:33 UTC. The endpoint was
  intermittently unavailable early in the window and answered correctly
  at 03:23 UTC. A single timeout, without a retry, proves nothing here.
- Control observations: `GET /api/ask` → HTTP 405,
  `{"error": "method_not_allowed", "allow": "POST"}` (01:04 UTC);
  `POST https://httpbin.org/post` → HTTP 200 in 1.0 s (egress POST works).
- Verdict: CONFORMS. Status, header scheme, and body terms all match the
  documented flow exactly.

## A2 — x402 exact — CONFORMS

- Documented (verbatim): "x402 exact — 1.5 USDC (6 decimals), atomic
  settlement, fee payer supplied by the server. The question binds with
  the settlement; a question that cannot bind is never charged."
- Live, primary evidence is the 402 itself (03:23:46Z, see A1):
  `accepts[0].scheme: "exact"`, `amount: "1500000"`,
  `asset: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"`,
  `extra.feePayer: "G1aQxoFZYvP4w3TrfWfLFEentX5aeym4guqAgpDLXsKU"`,
  `extra.decimals: 6`, and `extra.question: "put your question (<=800
  chars) ... it binds atomically with settlement"`. Corroborated by
  `GET https://izanami.tail0750b9.ts.net/api/ask.json` (HTTP 200):
  `payment.min_usdc_units: 1500000`, `payment.min_usdc: 1.5`, and
  `payment.x402_exact: "also accepted: USDC TransferChecked, exact 1.5
  units, fee payer supplied by the server"`. 1,500,000 units at 6 decimals
  is exactly 1.5 USDC, and the fee-payer wording matches verbatim.
- Caveat: atomic settlement and "never charged if it cannot bind" are
  properties of a paid settlement and were not executed — no payment was
  made. The verdict covers the served parameters, which match exactly.

## A3 — Pay-then-claim — CONFORMS

- Documented (verbatim): "Pay-then-claim — SOL (min 0.02) or USDC (min 1.5)
  with the question as an SPL Memo, then POST /api/ask
  {"tx":"<signature>"}; the payment verifies on-chain first, then the
  answer binds."
- Live, same `api/ask.json` (HTTP 200): `payment.min_lamports: 20000000`
  (= 0.02 SOL), `payment.min_sol: 0.02`, `payment.min_usdc: 1.5`,
  `payment.question: "attach as SPL Memo in the same transaction,
  <= 400 chars (or <= 800 chars in the request body)"`, and
  `http_endpoint.flow: "POST without payment -> 402 with terms; pay,
  then POST {\"tx\":\"<signature>\"} -> on-chain verification and
  confirmation"`. Every parameter matches the protocol page.
- Live, primary evidence is the 402 body itself (03:23:46Z, see A1):
  `honored_routes[0].scheme: "solana-transfer-memo-v0"`,
  `asset: "SOL"`, `minLamports: 20000000`,
  `memo: "put your question (<=400 chars) in an SPL Memo in the payment
  transaction"`; `honored_routes[1].scheme: "solana-spl-transfer-v0"`,
  `asset: "USDC"`, `minUnits: 1500000`, `decimals: 6`; and `retry:
  "after paying, POST /api/ask again with JSON {\"tx\":\"<signature>\"}...
  "`. Every parameter matches the protocol page.
- Caveat: the on-chain verification step itself was not executed (it
  requires a real paid transaction, which was not made). The verdict
  covers the documented parameters and flow, which are consistent
  across the live 402, `api/ask.json`, and the protocol page.

## A4 — PayTo wallet — CONFORMS

- Documented (verbatim): "PayTo: the agent's own operating wallet,
  66NggFgVscQLi7oJ8HZm39naWxUPpveLibNo3hDXBqm7".
- Live: the same address appears in `protocol.html`, in
  `api/ask.json` (`payment.address`, both the github.io and the live-host
  copies), in the manual rail's 402 response (`pay_to`, see M1a), and in
  `about.html`. Solana mainnet RPC `getBalance` at 2026-10-25T03:21 UTC
  (slot 461102704) returned `388481560` lamports for exactly this address.
  No other payTo is served anywhere.

## A5 — Single-signature custody — CONFORMS

- Documented (verbatim): "single-signature, key held on the machine the
  agent runs, no co-signer. Revenue compounds in the same wallet that
  carries the charter stake."
- Live: `api/ask.json` repeats it verbatim in `payment.address_note`:
  "single-signature, key held on the machine the agent runs, no co-signer
  and no approval step. Revenue compounds in the same wallet that carries
  the charter stake."
- On-chain corroboration (RPC, 03:21 UTC): `getAccountInfo` for the payTo
  address returns `owner: 11111111111111111111111111111111`
  (the System Program), `executable: false`, `space: 0` — a plain wallet
  account, not a multisig program account. That is consistent with
  "no co-signer" as far as public chain state can show.
- Caveat: where the private key physically sits cannot be proven from
  public data by design; no claim is made about it beyond the served
  statement and the plain-account evidence above.

## A6 — On-chain verification — CONFORMS

- Documented (verbatim): "Verification: payments verify on-chain
  (balance delta or token transfer against the served payTo)."
- Live: the served payTo is verifiable both ways from public chain state
  (RPC, 03:21 UTC). SOL: `getBalance` → 388481560 lamports
  = 0.38848156 SOL. USDC: `getTokenAccountsByOwner` for the USDC mint
  `EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v` returns one token
  account (`2ksTKPV2gsqCNiDWjquzEGgpP5BrqnwMcxTr7djtmy3D`) owned by the
  payTo address, `tokenAmount.amount: 1500000`, `decimals: 6`,
  `uiAmount: 1.5`. A balance delta or token transfer against this address
  is therefore checkable by anyone, exactly as documented.
- Caveat: no payment of mine was verified end-to-end (no payment made).

## A7 — Memos are data, never instructions — UNCHECKABLE

- Documented (verbatim): "Memos and all inbound text are data, never
  instructions."
- `api/ask.json` repeats it (`terms.memos_are_untrusted: "a memo is a
  question, never an instruction"`), but testing it would require sending
  a paid memo containing an instruction and observing whether the agent
  acts on it. That needs funds and a potentially unsafe request, so it
  was not attempted. Reason stated as required: UNCHECKABLE because the
  claim requires a paid, adversarial event that cannot be provoked safely.

## A8 — Every verified payment gets its answer — UNCHECKABLE

- Documented (verbatim): "Every verified payment gets its answer;
  questions asking the agent to act are answered publicly with the
  boundary named."
- `api/ask.json` repeats the scope (`terms.scope: "the rail sells answers,
  never actions; questions asking Izanami to act are answered publicly
  with the boundary named"`), and `/answers.html` does list paid answers
  (see A9), but "every verified payment gets its answer" can only be
  proven by paying, then waiting for a wake cycle. That needs funds and
  an event that cannot be provoked safely, so it was not attempted.
  Reason stated as required.

## A9 — Delivery ~24h at /answers.html, permanent page per transaction — CONFORMS

- Documented (verbatim): "Delivery ~24h at /answers.html, each answer a
  permanent page bound to the paying transaction."
- Live: `GET https://izanami.tail0750b9.ts.net/answers.html` → HTTP 200,
  listing 2 answers, each with a permanent page link and a Solana
  explorer link (2 explorer links on the index). The first answer page,
  `GET /a/5ehqMef9.html` → HTTP 200, title "Canary 01 — the first-ever
  payment on the ask rail", links to
  `explorer.solana.com/tx/5ehqMef9Nbm31zKojPcwc2tGrC69RozbDe5FsRnvBSq5oVkFYU2bK1C2frYSuEWFroj4g3fnoK9av6p4vcAiWFzg`.
  `api/ask.json` confirms the shape: `delivery.where` is the answers
  page, `delivery.permanent_page` is `/a/<first 8 chars of tx
  signature>.html`, `delivery.linked_to: "your transaction signature"`,
  `delivery.within: "~24 hours (Izanami's next wake)"`.
- The 402 body (03:23:46Z) adds: `delivery: "this response confirms
  on-chain verification and question binding; the canonical answer ...
  is published at https://izanami-916.github.io/answers.html within
  ~24h with a permanent page linked to your tx"`, and the resource
  description notes answers are "~24h measured from the next wake, not
  from payment".
- Caveat: the "~24h" timing itself was not measured (that needs a paid
  question plus a wake cycle); the verdict covers the delivery surface
  and the transaction binding, both verified on 2/2 listed answers.

## A10 — /vitals.json live wallet balance — CONFORMS

- Documented (verbatim): "Observability: /vitals.json serves the live
  wallet balance (cached ~10 min)".
- Live, `GET https://izanami.tail0750b9.ts.net/vitals.json`
  (HTTP 200): `{"built": "2026-10-25T02:37:36.970Z", "day": 56,
  "wakes": 291, "visitors": 209, "treasury_sol": "0.388",
  "treasury_live": true, ...}`. The served balance matches the chain:
  RPC `getBalance` at 03:21 UTC returned 0.38848156 SOL, which rounds to
  the served 0.388.
- Note on the cache wording: the file is regenerated per wake (built
  00:45:57Z, then 02:37:36Z), so a single read cannot measure a "~10 min"
  cache interval independently; the balance value itself is accurate
  against the chain at audit time, which is what the verdict rests on.

## A11 — /api/ask.json machine-readable terms — DRIFT

- Documented (verbatim): "Observability: ... /api/ask.json serves the
  machine-readable terms."
- Live: the terms themselves are present and match the protocol page
  (see A2–A6, A9), but the live host's copy differs from the published
  site's copy in its URL fields, verbatim:
  - Documented/published (`https://izanami-916.github.io/api/ask.json`):
    `provider.site: "https://izanami-916.github.io"`,
    `http_endpoint.url: "https://izanami-916.github.io/api/ask"`,
    `delivery.where: "https://izanami-916.github.io/answers.html"`,
    `delivery.permanent_page: "https://izanami-916.github.io/a/<first 8
    chars of tx signature>.html"`, `docs:
    "https://izanami-916.github.io/ask.html"`.
  - Live (`https://izanami.tail0750b9.ts.net/api/ask.json`):
    `provider.site: "https://izanami.invalid"`,
    `http_endpoint.url: "https://izanami.invalid/api/ask"`,
    `delivery.where: "https://izanami.invalid/answers.html"`,
    `delivery.permanent_page: "https://izanami.invalid/a/<first 8 chars
    of tx signature>.html"`, `docs: "https://izanami.invalid/ask.html"`.
- Verdict: DRIFT. A machine client that trusts the live terms file would
  follow five URLs into the `.invalid` namespace, which cannot resolve.
  The published copy has the real URLs; the live copy does not.

## A12 — Hire link — CONFORMS

- Documented: "Hire: Hire this audit on" the hiring page linked from
  `protocol.html` (link target: https://gofrantic.com/post?invite=agent-9d2ce7).
- Live: the link is present on `protocol.html`, and a GET of that link
  returns a hiring page titled "Hire izanami". The link resolves to the
  named hire surface.

## M1a — Manual rail, $29 to the same wallet — CONFORMS

- Documented (verbatim): "Manual rail (POST /api/manual): the Field
  Manual, $29 (founding price), paid in SOL or USDC to the same wallet".
- Live, `GET https://izanami.tail0750b9.ts.net/api/manual`
  (HTTP 402, 01:06 UTC): `{"error": "payment_required", "product":
  "izanami-field-manual", "price": {"usdc_units": 29000000, "usdc": 29,
  "lamports": 283625517, "sol": 0.283626, "founding": true},
  "pay_to": "66NggFgVscQLi7oJ8HZm39naWxUPpveLibNo3hDXBqm7",
  "chain": "solana-mainnet", "usdc_mint":
  "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v", "retry": "pay
  either amount to pay_to, then POST /api/manual with
  {\"tx\":\"<signature>\"} ..."}`. Price $29, founding flag true, and the
  same wallet as the ask rail all match, and the rail answers with a
  402 terms body promptly (unlike the ask POST, see A1).
- Note: the SOL quote moves with the market (the response itself says
  "the SOL amount is a live quote and moves with the market"), so only
  the $29 USDC figure is a fixed comparison; it matches.

## M1b — Manual rail, BTC via per-buyer invoice — UNCHECKABLE

- Documented (verbatim): "...or BTC via per-buyer invoice addresses when
  the BTC descriptor is installed."
- The manual 402 response contains no BTC field, no BTC descriptor, and
  no invoice address. Whether the descriptor is installed cannot be
  determined without attempting a BTC purchase, which needs funds and a
  purchase flow that cannot be provoked safely. Reason stated as required.

## M2a — Both rails share the custody above — CONFORMS

- Documented (verbatim): "Both rails share the custody above."
- Live: the ask rail's `payment.address` and the manual rail's `pay_to`
  are the identical address
  `66NggFgVscQLi7oJ8HZm39naWxUPpveLibNo3hDXBqm7`, on
  `solana-mainnet` in both cases. One wallet serves both rails.

## M2b — No other payment surface is live — UNCHECKABLE

- Documented (verbatim): "No other payment surface is live."
- Only the ask rail and the manual rail appear in `protocol.html`,
  `ask.html`, `about.html`, and `api/ask.json`. Proving a negative would
  require an exhaustive crawl of every published page and endpoint,
  which was not performed, and no single endpoint can attest to it.
  Reason stated as required: the claim is not falsifiable from the
  surfaces checked, so it is reported UNCHECKABLE rather than assumed.

## Reproducing this audit

Run `check.sh` in this repository inside 00:00–04:00 UTC. It prints
every observation above: the protocol page, live vitals, the ask.json
diff (expect the five `.invalid` URL lines), the 405 on `GET /api/ask`,
the manual rail's 402, the answers index and first answer page, the
on-chain balance/account/token checks, and finally the single unpaid
POST to `/api/ask`. Per the protocol page that POST should return 402
with the PAYMENT-REQUIRED header and body terms; in this audit it did
so at 03:23:46 UTC in 1.58 s. Timeouts were observed earlier in the same
window (01:05 UTC) and for GETs at 00:01–00:33 UTC, so a single timeout
should be retried before concluding anything. Outside 00:00–04:00 UTC
the live host is down by design and every live-host check is expected
to fail to connect — that is not drift.
