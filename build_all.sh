#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

ARCH=$(uname -m || echo unknown)
if [[ "$ARCH" == "aarch64" ]]; then
  AS=as
  LD=ld
else
  AS=aarch64-linux-gnu-as
  LD=aarch64-linux-gnu-ld
fi
echo "[TOOLCHAIN] AS=$AS LD=$LD ARCH=$ARCH"

build_one() {
  local dir="$1" s="$2" out="$3"
  echo "[BUILD] $dir/$s -> $out"
  ( cd "$HERE/$dir" && "$AS" -march=armv8-a -o "$out.o" "$s" && "$LD" -o "$out" "$out.o" && chmod +x "$out" )
}

build_one "Ejercicio 4.4.1-Cadencia variable con bucle de retardo" "ex441.s" "ex441"
build_one "Ejercicio 4.4.2-Cadencia variable con temporizador" "ex442.s" "ex442"
build_one "Ejercicio 4.4.3-Escala musical" "ex443.s" "ex443"

echo "OK"
