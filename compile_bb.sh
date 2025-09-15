#!/bin/bash
set -e

echo "Building bb v0.87.0 with LLVM 18..."

wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | sudo apt-key add -
sudo add-apt-repository "deb http://apt.llvm.org/jammy/ llvm-toolchain-jammy-18 main"
sudo apt update
sudo apt install -y \
    build-essential \
    ninja-build \
    libssl-dev \
    pkg-config \
    clang-18 \
    libc++-18-dev \
    libc++abi-18-dev \
    libomp-18-dev

wget -qO - https://apt.kitware.com/keys/kitware-archive-latest.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null
echo 'deb https://apt.kitware.com/ubuntu/ jammy main' | sudo tee /etc/apt/sources.list.d/kitware.list >/dev/null
sudo apt update
sudo apt install -y cmake

rm -rf aztec-packages-0.87.0* v0.87.0.tar.gz
wget https://github.com/AztecProtocol/aztec-packages/archive/refs/tags/v0.87.0.tar.gz
tar -xzf v0.87.0.tar.gz
cd aztec-packages-0.87.0/barretenberg/cpp

export CC=clang-18
export CXX=clang++-18

mkdir -p build
cd build

cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER=clang-18 \
    -DCMAKE_CXX_COMPILER=clang++-18 \
    -DTESTING=OFF \
    -DBENCHMARK=OFF \
    -DFUZZING=OFF \
    -GNinja

ninja bb

./bin/bb --version
mkdir ~/.bb
cp ./bin/bb ~/.bb/
