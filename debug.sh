#!/bin/bash

# Clean up any previous build artifacts
rm -rf pkg/ target/

# Build with extra verbose output
RUST_BACKTRACE=1 wasm-pack build --target web --no-typescript --verbose

# If the above fails, check for temporary files that might contain errors
echo "Looking for temporary or generated files..."
find . -name "*.json" -type f -mtime -1 -exec cat {} \; -exec echo "---" \;

# Check if wasm-opt is installed and working
echo "Checking wasm-opt..."
wasm-opt --version || echo "wasm-opt might not be installed properly"

# Try alternative build method
echo "Trying alternative build method..."
cargo build --target wasm32-unknown-unknown --release
if [ $? -eq 0 ]; then
  echo "Cargo build succeeded. Trying wasm-bindgen..."
  wasm-bindgen --target web --out-dir ./pkg ./target/wasm32-unknown-unknown/release/webtorrent_rs_wrapper.wasm
  if [ $? -eq 0 ]; then
    echo "wasm-bindgen succeeded. Final files are in ./pkg/"
  else
    echo "wasm-bindgen failed."
  fi
else
  echo "Cargo build failed."
fi