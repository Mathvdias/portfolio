#!/bin/bash
set -e

echo "🦀 Building MathOS Engine Wasm..."

cargo build --target wasm32-unknown-unknown --release

echo "📦 Copying to Flutter assets..."
mkdir -p ../../web/assets/wasm
cp target/wasm32-unknown-unknown/release/mathos_engine.wasm ../../web/assets/wasm/

echo "✅ Done!"
