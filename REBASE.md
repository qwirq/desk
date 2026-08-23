# Rebasing qwirq-desk to a new upstream tag

The whole reason this is a build repo: moving to a new RustDesk release is a settings change, not
a merge.

1. Pick the new upstream stable tag (rustdesk/rustdesk releases). Update `PINNED_TAG` + `PINNED_SHA`.
2. Verify the two constants still live where `customize.sh` expects them:
   `curl -s https://raw.githubusercontent.com/rustdesk/hbb_common/<submodule-sha>/src/config.rs | grep -nE 'RENDEZVOUS_SERVERS|RS_PUB_KEY'`
   (hbb_common is a SUBMODULE — its sha is pinned by the upstream tag, not the same as the app sha.)
   If they moved, update the regexes in `customize.sh`. The script fails the build loudly on a
   miss, so a silent phone-home is not possible.
3. Re-verify the updater-off step against the new tag (marked in customize.sh step 2/3).
4. Dispatch `build-windows.yml` with the new tag. Babysit the first build after any tag jump:
   Flutter version and vcpkg baseline are the usual breakage.
5. Smoke: the built client connects through remote.qwirq.com; a build with the customization
   REVERTED must connect to nothing (proves the fallback is actually gone, not just overridden).

Cadence: quarterly, or immediately on an upstream security release.
