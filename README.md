+# DigWash — Downloads

This repository is the official download shelf for DigWash. The app is developed
in a private repository; there is no source code here.

## Which file should I download?

Go to the [latest release](../../releases/latest), expand **Assets**, and choose a
file whose name starts with **`DigWash-Desktop`**:

| Your computer | Download |
|---|---|
| Mac with an Apple M1, M2, M3, M4, or M5 chip | `DigWash-Desktop-…-macOS-Apple-Silicon.dmg` |
| Older Mac with an Intel processor | `DigWash-Desktop-…-macOS-Intel.dmg` |
| Windows PC | `DigWash-Desktop-…-Windows-x64-Setup.exe` |
| Linux PC | `DigWash-Desktop-…-Linux-x64.AppImage` |

Not sure which Mac you have? Open the Apple menu → **About This Mac**. If it says
**Chip: Apple M…**, choose Apple Silicon. If it says **Processor: Intel…**, choose
Intel.

### Current beta.2 names

The older beta.2 release still uses technical filenames:

- Apple Silicon: `DigWash_0.1.0_aarch64.dmg`
- Intel Mac: `DigWash_0.1.0_x86_64.dmg`

### What are the CLI archives?

Files beginning with **`DigWash-CLI`** (or the older lowercase `digwash-`
names) are command-line editions for people who deliberately want to use
Terminal. The `.tar.gz` and `.zip` files are not installers.

**If you just want to use DigWash, ignore the CLI archives and download the
Desktop file for your computer.**

`SHA256SUMS` is a technical integrity-check file. Most users can ignore it.

## Quick install (macOS & Linux)

If you'd rather skip the manual steps below, this script detects your platform,
downloads the right beta asset, verifies it against `SHA256SUMS`, and installs
it for you:

```sh
curl -fsSL https://raw.githubusercontent.com/mtauban/digwash-releases/main/install.sh | sh
```

On macOS it also removes the quarantine flag (see below for why that's needed
during beta). Always fine to read [`install.sh`](install.sh) before piping it
to `sh` — that's true of any curl-pipe-to-shell installer.

## Installing on macOS (beta)

The beta is not yet signed or notarized, so macOS quarantines the app and its
bundled audio tools.

1. Open the downloaded `.dmg`.
2. Drag **DigWash.app** into **Applications**.
3. Open **Terminal** (Applications → Utilities → Terminal).
4. Paste this command and press Return:

   ```sh
   xattr -dr com.apple.quarantine /Applications/DigWash.app
   ```

5. Open DigWash from Applications.

This workaround disappears once releases are signed and notarized.

## Installing on Windows

Download the file ending in `Windows-x64-Setup.exe`, open it, and follow the
installer.

## Installing on Linux

Download the `.AppImage`, make it executable in your file manager's Properties
window (or `chmod +x` it in a terminal), then open it.

## Verify a download (optional)

Advanced users can download `SHA256SUMS` and run:

```sh
shasum -a 256 -c SHA256SUMS --ignore-missing
```

## License and feedback

DigWash is proprietary software. Use is governed by the EULA included with each
release; redistribution is not permitted.

Beta feedback links are inside the app and on the DigWash download page. Issues
opened here should concern downloads only—broken links, checksum mismatches, or
damaged files.

