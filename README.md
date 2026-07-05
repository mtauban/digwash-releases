# DigWash — Releases

Official download host for **DigWash** binaries.

DigWash is developed in a private repository; this repository exists solely to
host release artifacts and their checksums. There is no source code here.

## Downloads

Head to the [Releases page](../../releases) and pick the latest version.

Each release ships, per platform:

| Artifact | What it is |
|---|---|
| `DigWash_<version>_<arch>.dmg` | Desktop app (GUI) for macOS |
| `digwash-<version>-macos-<arch>.tar.gz` | Standalone command-line tool for macOS |
| `SHA256SUMS` | Checksums for all artifacts of the release |

**Beta (Canopus):** macOS only — Apple Silicon (`arm64`/`aarch64`) and Intel
(`x86_64`). Linux and Windows builds will come later.

## Installing on macOS (required for the beta)

Beta builds are **not yet signed or notarized**, so macOS quarantines them on
download. Gatekeeper's "Open Anyway" only unblocks the app itself — not the
bundled helpers it needs (the app would launch but fail with
`No such file or directory (os error 2)` when talking to its `digwash` and
`libav` components). Remove the quarantine flag instead:

**Desktop app (DMG):**

1. Open the DMG and drag `DigWash.app` into `/Applications`.
2. In Terminal:

   ```sh
   xattr -dr com.apple.quarantine /Applications/DigWash.app
   ```

3. Launch DigWash normally.

**Command-line tool (tar.gz):**

```sh
tar -xzf digwash-<version>-macos-<arch>.tar.gz
xattr -dr com.apple.quarantine <extracted-directory>
```

(If you downloaded with `curl` and extracted with `tar` in Terminal, there is
no quarantine flag and the `xattr` step is a no-op.)

Because you are bypassing Gatekeeper, verify the checksum first (below).
Signed and notarized builds are planned; this step will then disappear.

## Verifying a download

```sh
shasum -a 256 -c SHA256SUMS --ignore-missing
```

## License

DigWash is proprietary software. Use of the binaries is governed by the
End User License Agreement (EULA) included with each release. Redistribution
of the artifacts is not permitted.

## Feedback

Beta feedback channels are listed inside the app and on the download page.
Issues opened here should concern **downloads only** (broken link, checksum
mismatch, damaged archive) — product bugs go through the beta feedback channel.
