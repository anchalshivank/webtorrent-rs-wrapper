#!/bin/bash

# Clean the project
cargo clean

# Build the WebAssembly target using wasm-pack
wasm-pack build --target web

# Serve the project using Python's HTTP server
python3 -m http.server 8080
