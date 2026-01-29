#!/bin/bash
set -e

# Install dependencies using Homebrew
echo "Installing dependencies..."
brew install cmake qt@6 boost jpeg libpng libtiff

# Set up environment variables for Qt6
export PATH="/opt/homebrew/opt/qt@6/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/qt@6/lib"
export CPPFLAGS="-I/opt/homebrew/opt/qt@6/include"

# Create build directory
mkdir -p build
cd build

# Configure with CMake
echo "Configuring..."
cmake .. \
    -DCMAKE_PREFIX_PATH="/opt/homebrew/opt/qt@6" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=17

# Build
echo "Building..."
make -j$(sysctl -n hw.ncpu)

# Bundle
echo "Bundling..."
if [ -d "scantailor.app" ]; then
    macdeployqt scantailor.app -dmg
    echo "Scan Tailor.dmg created."
else
    echo "Error: scantailor.app not found. Build might have failed or not produced a bundle."
    exit 1
fi

echo "Done."
