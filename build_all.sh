#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

build_one() {
  local dir="$1" s="$2" out="$3"
  echo "[BUILD] $dir/$s -> $out"
  ( cd "$HERE/$dir" && as -o "$out.o" "$s" && ld -o "$out" "$out.o" && chmod +x "$out" )
}

build_one "Ejercicio 4.4.1-Cadencia variable con bucle de retardo" "ex441.s" "ex441"
build_one "Ejercicio 4.4.2-Cadencia variable con temporizador" "ex442.s" "ex442"
build_one "Ejercicio 4.4.3-Escala musical" "ex443.s" "ex443"

echo "OK"
