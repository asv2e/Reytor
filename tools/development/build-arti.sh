#!/bin/zsh

set -euo pipefail

export PATH="$HOME/.cargo/bin:$PATH"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

CRATE_DIR="$REPO_ROOT/support/arti-ffi"
OUTPUT_LIB="$REPO_ROOT/browser/Reynard/Tor/libarti_ffi.a"

TARGET_DIR="$CRATE_DIR/target"
DEPLOYMENT_TARGET="13.0"

# Unlike support/idevice, arti-ffi is our own crate (it just depends on
# arti-client from crates.io) - no submodule to check out.

RUST_TARGET="aarch64-apple-ios"
DEPLOYMENT_FLAG="-miphoneos-version-min=${DEPLOYMENT_TARGET}"

if ! rustup target list | grep -q "^$RUST_TARGET (installed)"; then
	rustup target add "$RUST_TARGET"
fi

export IPHONEOS_DEPLOYMENT_TARGET="$DEPLOYMENT_TARGET"
if [ -n "${RUSTFLAGS:-}" ]; then
  export RUSTFLAGS="${RUSTFLAGS} -C link-arg=${DEPLOYMENT_FLAG}"
else
  export RUSTFLAGS="-C link-arg=${DEPLOYMENT_FLAG}"
fi
export TARGET_DIR

mkdir -p "$(dirname "$OUTPUT_LIB")"
cd "$CRATE_DIR"

# arti-client pulls in rustls/ring, which builds some C/asm - make sure a
# recent Xcode command-line toolchain is selected (xcode-select -p).
cargo build --release --target "$RUST_TARGET"
cp "$TARGET_DIR/$RUST_TARGET/release/libarti_ffi.a" "$OUTPUT_LIB"

echo "Built $OUTPUT_LIB"
echo "This is a device-only (arm64) build. For Simulator, additionally build"
echo "for aarch64-apple-ios-sim / x86_64-apple-ios-sim and lipo the results"
echo "into a single library, or ship separate libs per destination."
