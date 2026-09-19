#!/bin/bash
set -e

echo "🦀 Building MathOS Engine Wasm..."

cargo build --target wasm32-unknown-unknown --release

echo "📦 Copying to Flutter assets..."
# The app loads assets/wasm/ (declared in pubspec.yaml); web/assets/wasm/ is the copy served as-is.
mkdir -p ../../assets/wasm ../../web/assets/wasm
cp target/wasm32-unknown-unknown/release/mathos_engine.wasm ../../assets/wasm/
cp target/wasm32-unknown-unknown/release/mathos_engine.wasm ../../web/assets/wasm/

echo "✅ Done!"
