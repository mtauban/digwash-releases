#!/bin/sh
set -e

# Prompts on /dev/tty (not stdin, which is consumed by `curl | sh`) so this
# still works piped. If no controlling terminal is available at all, refuses
# to guess and aborts instead of silently overwriting an existing install.
confirm() {
  if ! (: < /dev/tty) 2>/dev/null; then
    echo "  -> No interactive terminal available to confirm; aborting rather than overwriting silently."
    return 1
  fi
  printf '%s [y/N] ' "$1" > /dev/tty
  read -r REPLY < /dev/tty
  case "$REPLY" in
    y|Y|yes|Yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

REPO="mtauban/digwash-releases"
# NOTE: /releases/latest 404s because every DigWash release so far is a
# prerelease (beta) and that endpoint excludes prereleases. per_page=1 on the
# plain list endpoint returns the newest release (prerelease or not) instead.
API_URL="https://api.github.com/repos/${REPO}/releases?per_page=1"

echo "Detecting platform..."

OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
  Darwin)
    PLATFORM="macos"
    case "$ARCH" in
      arm64) PATTERN="macOS-Apple-Silicon.dmg" ;;
      x86_64) PATTERN="macOS-Intel.dmg" ;;
      *)
        echo "Unsupported Mac architecture: $ARCH"
        exit 1
        ;;
    esac
    ;;
  Linux)
    PLATFORM="linux"
    case "$ARCH" in
      x86_64) PATTERN="Linux-x64.AppImage" ;;
      *)
        echo "Unsupported Linux architecture: $ARCH (only x86_64 beta builds are published)."
        echo "  Check available assets at: https://github.com/${REPO}/releases/latest"
        exit 1
        ;;
    esac
    ;;
  *)
    echo "Unsupported OS: $OS. Please download manually from:"
    echo "  https://github.com/${REPO}/releases/latest"
    exit 1
    ;;
esac

echo "  -> OS: $OS, Arch: $ARCH"
echo "  -> Looking for asset matching: $PATTERN"

echo "Fetching latest release metadata..."
RELEASE_JSON="$(curl -fsSL "$API_URL")"

# Extract the matching asset's browser_download_url.
# Avoids a jq dependency by using grep/sed - works on stock macOS and most
# Linux distros. Matching on a trailing-quote anchor keeps this resilient to
# versioned filenames (e.g. DigWash-Desktop-0.1.0-macOS-Apple-Silicon.dmg)
# without picking up the similarly-named CLI .tar.gz assets.
DOWNLOAD_URL="$(echo "$RELEASE_JSON" \
  | grep '"browser_download_url"' \
  | grep "${PATTERN}\"" \
  | head -n1 \
  | sed -E 's/.*"browser_download_url": "([^"]+)".*/\1/')"

if [ -z "$DOWNLOAD_URL" ]; then
  echo "Could not find a matching asset for pattern: $PATTERN"
  echo "  Check available assets at: https://github.com/${REPO}/releases/latest"
  exit 1
fi

SUMS_URL="$(echo "$RELEASE_JSON" \
  | grep '"browser_download_url"' \
  | grep 'SHA256SUMS"' \
  | head -n1 \
  | sed -E 's/.*"browser_download_url": "([^"]+)".*/\1/')"

FILENAME="$(basename "$DOWNLOAD_URL")"
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT
TMP_FILE="${WORKDIR}/${FILENAME}"

echo "Downloading: $FILENAME"
curl -fsSL "$DOWNLOAD_URL" -o "$TMP_FILE"

if [ -n "$SUMS_URL" ]; then
  echo "Verifying checksum..."
  curl -fsSL "$SUMS_URL" -o "${WORKDIR}/SHA256SUMS"
  EXPECTED_SHA="$(grep " ${FILENAME}\$" "${WORKDIR}/SHA256SUMS" | awk '{print $1}')"
  if [ -z "$EXPECTED_SHA" ]; then
    echo "  -> Warning: no checksum entry found for ${FILENAME}, skipping verification."
  else
    ACTUAL_SHA="$(shasum -a 256 "$TMP_FILE" | awk '{print $1}')"
    if [ "$ACTUAL_SHA" != "$EXPECTED_SHA" ]; then
      echo "Checksum mismatch for ${FILENAME}!"
      echo "  expected: $EXPECTED_SHA"
      echo "  actual:   $ACTUAL_SHA"
      echo "The download may be corrupted or tampered with. Aborting."
      exit 1
    fi
    echo "  -> Checksum OK."
  fi
else
  echo "  -> Warning: no SHA256SUMS asset found for this release, skipping verification."
fi

if [ "$PLATFORM" = "macos" ]; then
  echo "Mounting DMG..."
  # -plist + plutil is far more reliable than parsing hdiutil's default text
  # output, which shifts shape depending on EULA prompts / volume count. The
  # mountable entry isn't always system-entities[0] (other entries describe
  # the GUID partition scheme, unmountable containers, etc.), so grep for
  # whichever entry actually has a mount-point instead of hardcoding an index.
  MOUNT_POINT="$(hdiutil attach "$TMP_FILE" -nobrowse -plist \
    | plutil -p - \
    | grep '"mount-point"' \
    | head -n1 \
    | sed -E 's/.*"mount-point" => "(.*)"/\1/')"

  APP_PATH="$(find "$MOUNT_POINT" -maxdepth 1 -name "*.app" | head -n1)"

  if [ -z "$APP_PATH" ]; then
    echo "No .app bundle found in DMG"
    hdiutil detach "$MOUNT_POINT" >/dev/null 2>&1 || true
    exit 1
  fi

  APP_NAME="$(basename "$APP_PATH")"
  INSTALLED_APP="/Applications/${APP_NAME}"

  if [ -d "$INSTALLED_APP" ]; then
    INSTALLED_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "${INSTALLED_APP}/Contents/Info.plist" 2>/dev/null || echo "unknown")"
    NEW_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "${APP_PATH}/Contents/Info.plist" 2>/dev/null || echo "unknown")"
    echo "Found an existing install: ${APP_NAME} (version ${INSTALLED_VERSION})"
    if ! confirm "Update it to version ${NEW_VERSION}?"; then
      echo "Leaving the existing install untouched."
      hdiutil detach "$MOUNT_POINT" >/dev/null 2>&1 || true
      exit 0
    fi
    echo "Quitting the running app (if any) before updating..."
    osascript -e "tell application \"${APP_NAME%.app}\" to quit" >/dev/null 2>&1 || true
    pkill -f "${INSTALLED_APP}/Contents/MacOS/" >/dev/null 2>&1 || true
  fi

  echo "Installing ${APP_NAME} to /Applications..."
  rm -rf "$INSTALLED_APP"
  cp -R "$APP_PATH" /Applications/

  echo "Cleaning up..."
  hdiutil detach "$MOUNT_POINT" >/dev/null 2>&1

  echo "Removing quarantine (beta build, not yet notarized)..."
  xattr -dr com.apple.quarantine "/Applications/${APP_NAME}" 2>/dev/null || true

  echo "Launching ${APP_NAME}..."
  open "/Applications/${APP_NAME}"
elif [ "$PLATFORM" = "linux" ]; then
  DEST_DIR="${HOME}/Applications"
  DEST="${DEST_DIR}/DigWash.AppImage"

  if [ -e "$DEST" ]; then
    echo "Found an existing install: ${DEST}"
    if ! confirm "Update it with the latest beta?"; then
      echo "Leaving the existing install untouched."
      exit 0
    fi
    pkill -f "$DEST" >/dev/null 2>&1 || true
  fi

  echo "Installing to ${DEST}..."
  mkdir -p "$DEST_DIR"
  cp "$TMP_FILE" "$DEST"
  chmod +x "$DEST"

  echo "Launching DigWash..."
  nohup "$DEST" >/dev/null 2>&1 &
  disown >/dev/null 2>&1 || true
fi

echo "Done! (${PLATFORM})"
