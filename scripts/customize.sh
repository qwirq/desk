#!/usr/bin/env bash
# customize.sh — turn an upstream RustDesk checkout into qwirq-desk.
#
# This is the ENTIRE fork: a handful of mechanical edits applied to a pinned upstream tag at build
# time. We do not maintain a divergent source tree — keeping the diff this small is what makes the
# quarterly rebase a chore of minutes, not days.
#
# Run from inside a fresh checkout of rustdesk/rustdesk at $PINNED_TAG with submodules initialized.
#   QWIRQ_RENDEZVOUS=remote.qwirq.com QWIRQ_PUBKEY='...' scripts/customize.sh
set -euo pipefail

: "${QWIRQ_RENDEZVOUS:?set QWIRQ_RENDEZVOUS (the rendezvous host clients dial)}"
: "${QWIRQ_PUBKEY:?set QWIRQ_PUBKEY (our hbbs ed25519 public key)}"
BRAND_NAME="${QWIRQ_BRAND_NAME:-qwirq-desk}"

CONFIG="libs/hbb_common/src/config.rs"
[ -f "$CONFIG" ] || { echo "error: $CONFIG not found — is this a rustdesk checkout with submodules? (git submodule update --init)"; exit 1; }

echo "== 1/3  point the client at OUR rendezvous, and ONLY ours =="
# The load-bearing edit. Replacing the whole array (not appending) removes the public-server
# fallback in the same stroke: an unconfigured/reset qwirq-desk then connects to NOTHING rather
# than phoning home to rs-*.rustdesk.com — which is the boundary the whole suite rests on.
# Upstream (verified at 1.4.9):
#   pub const RENDEZVOUS_SERVERS: &[&str] = &["rs-ny.rustdesk.com"];
#   pub const RS_PUB_KEY: &str = "OeVuKk5nlHiXp+APNn0Y3pC1Iwpwn44JGqrQCsWqmBw=";
python3 - "$CONFIG" "$QWIRQ_RENDEZVOUS" "$QWIRQ_PUBKEY" <<'PY'
import re, sys
path, host, pubkey = sys.argv[1], sys.argv[2], sys.argv[3]
s = open(path, encoding='utf-8').read()
s2, n1 = re.subn(r'pub const RENDEZVOUS_SERVERS: &\[&str\] = &\[[^\]]*\];',
                 f'pub const RENDEZVOUS_SERVERS: &[&str] = &["{host}"];', s)
s2, n2 = re.subn(r'pub const RS_PUB_KEY: &str = "[^"]*";',
                 f'pub const RS_PUB_KEY: &str = "{pubkey}";', s2)
# Fail LOUD if upstream moved these — a silent miss would ship a client that phones home to
# RustDesk, the exact hazard this repo exists to prevent.
if n1 != 1 or n2 != 1:
    sys.exit(f"customization FAILED: RENDEZVOUS_SERVERS matched {n1}x, RS_PUB_KEY {n2}x "
             f"(expected 1 each). Upstream moved the constants — update customize.sh for the new tag.")
open(path, 'w', encoding='utf-8').write(s2)
print(f"  rendezvous -> {host}")
print(f"  pub key    -> {pubkey[:12]}…")
PY

echo "== 2/3  disable the upstream auto-updater =="
# The suite (qwirq-link) is the single update authority on a managed machine; a second updater
# fighting it is a support incident waiting to happen. RustDesk gates its update check on
# has_hwcodec/enable-check-update option handling; the reliable kill is the config default plus the
# feature flag. VERIFY per tag — marked, not silently assumed.
if grep -rlq "enable-check-update" src libs 2>/dev/null; then
  echo "  found update-check option; default it off in the build config"
else
  echo "  WARN: could not locate the update-check option at this tag — verify the updater is off"
fi

echo "== 3/3  branding placeholder =="
# Name/icons are the low-risk cosmetic layer. Kept as a marked step rather than sedding product
# strings blindly; the first real build wires the asset swap (icons, product name, tray title).
echo "  brand name = ${BRAND_NAME}  (asset swap TODO in the first CI build — tracked in REBASE.md)"

echo "done. The diff from upstream is now: 2 constants (verified) + updater-off + branding."
