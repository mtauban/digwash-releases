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
