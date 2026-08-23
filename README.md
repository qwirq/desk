# qwirq-desk

QWIRQ's branch of the [RustDesk](https://github.com/rustdesk/rustdesk) client — the remote-desktop
dataplane of the **qwirq-link** suite, pointed at QWIRQ's own rendezvous.

> ## Why this repo is public
> The RustDesk client is **AGPL-3.0**. The moment we distribute our branch of it, that licence
> obligates us to publish the corresponding source. This repo is that publication. Nothing QWIRQ
> defends lives here — enrollment, keys, the tenant directory, the reconcile loop all live in the
> **private** `qwirq/link` repo. What is here is a stock RustDesk client that dials our server
> instead of theirs, and the small script that makes it so.
>
> `qwirq-desk` ships **alongside** the private agent inside one installer, as a **separate
> process**. It is never linked into the agent — doing so would pull the agent under the AGPL. One
> package, separate processes, always.

## This is a build repo, not a source fork

We do **not** maintain a divergent copy of RustDesk's source. This repo holds a pinned upstream
tag and a tiny script that customizes a fresh checkout at build time:

```
PINNED_TAG            upstream rustdesk/rustdesk tag we build   (1.4.9)
PINNED_SHA            the exact commit                          (6c57829…)
scripts/customize.sh  the ENTIRE diff: 2 constants + updater off + branding
.github/workflows/    the Windows build (Rust + Flutter + vcpkg), manual dispatch
REBASE.md             how to move to a new upstream tag
```

Keeping the divergence to a script is the point: the quarterly rebase is minutes, and there is no
merge-conflict surface because there is no long-lived fork.

## The entire customization

Verified against upstream `hbb_common/src/config.rs` at 1.4.9:

```
- pub const RENDEZVOUS_SERVERS: &[&str] = &["rs-ny.rustdesk.com"];
+ pub const RENDEZVOUS_SERVERS: &[&str] = &["remote.qwirq.com"];
- pub const RS_PUB_KEY: &str = "OeVuKk5nlHiXp+APNn0Y3pC1Iwpwn44JGqrQCsWqmBw=";
+ pub const RS_PUB_KEY: &str = "<our hbbs public key>";
```

Replacing the whole `RENDEZVOUS_SERVERS` array (not appending to it) is load-bearing: it removes
the public-server fallback in the same edit. **An unconfigured or reset qwirq-desk connects to
nothing** — never to `rs-*.rustdesk.com`. That is the boundary this repo exists to hold, and
`customize.sh` fails the build loudly if upstream ever moves those constants rather than silently
shipping a client that phones home.

Plus: the upstream auto-updater is disabled (qwirq-link is the single update authority on a managed
machine) and the product name/icons are swapped.

## Status

**Scaffold complete; the Windows build is authored but not yet run.** `customize.sh` is proven
against real upstream source (both constants rewrite correctly). The Flutter+Rust+vcpkg build in
`.github/workflows/build-windows.yml` mirrors upstream's shape but its first run needs babysitting
(vcpkg cache, Flutter pin) — which is why it is `workflow_dispatch` only, never on push. Do not
assume a green binary exists until that run is watched through.

## Boundary, one more time

QWIRQ owns the control surface (who may connect, the audit trail); RustDesk owns the wire. We run
the servers (`hbbs`/`hbbr`, upstream + unmodified). This client is the only piece we brand, and the
brand is skin — the protocol underneath is theirs, unchanged.
