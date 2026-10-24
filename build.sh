#!/usr/bin/env bash
# Builds jdll/hush.jdll, the native library, for this machine.
#
# The Jello headers come from $JELLO_ROOT/include, else from beside the `jello` on PATH: the
# include/ of an installed Jello, or vm/src/include in a checkout of Jello's repository. CC
# chooses the C compiler (cc by default; llvm-mingw's clang on Windows), and CFLAGS adds flags.
# RNNoise, its model included, is vendored in jdll/rnnoise, so nothing else is needed.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

die() {
  echo "build.sh: $*" >&2
  exit 1
}

include_dir() {
  local jello candidate
  if [[ -n "${JELLO_ROOT:-}" ]]; then
    echo "$JELLO_ROOT/include"
    return
  fi
  jello="$(command -v jello)" || die "jello is not on PATH; set JELLO_ROOT to Jello's root"
  for candidate in "$(dirname "$jello")/../include" "$(dirname "$jello")/../src/include"; do
    if [[ -f "$candidate/jello/jdll.h" ]]; then
      echo "$candidate"
      return
    fi
  done
  die "cannot find jello/jdll.h beside $jello; set JELLO_ROOT to Jello's root"
}

INCLUDE="$(include_dir)"
CC="${CC:-cc}"
LIBS=()
case "$(uname -s)" in
  Darwin) SHARED=(-bundle) ;;
  MINGW* | MSYS* | CYGWIN*) SHARED=(-shared) ;;
  *) SHARED=(-fPIC -shared) LIBS=(-lm) ;;
esac

# RNNoise is vendored as its authors wrote it, so its warnings are not ours to fix. Its model,
# rnnoise_data.c, is tens of megabytes of tables: it needs no optimising, and each object is
# rebuilt only when its source is newer. Objects are kept apart for each compiler and flags.
RNNOISE="$ROOT/jdll/rnnoise"
OBJ="$ROOT/build/obj/$(printf '%s' "$CC ${CFLAGS:-}" | cksum | cut -d' ' -f1)"
mkdir -p "$OBJ"
objects=()
for src in denoise rnn pitch kiss_fft celt_lpc nnet nnet_default parse_lpcnet_weights \
  rnnoise_tables rnnoise_data; do
  if [[ "$src" == rnnoise_data ]]; then
    file="$RNNOISE/rnnoise_data.c" opt=-O0
  else
    file="$RNNOISE/src/$src.c" opt=-O2
  fi
  [[ -f "$file" ]] || die "missing $file"
  object="$OBJ/$src.o"
  if [[ ! -f "$object" || "$file" -nt "$object" ]]; then
    # shellcheck disable=SC2086
    "$CC" -std=c11 "$opt" -w -fPIC -DRNNOISE_BUILD ${CFLAGS:-} -I"$RNNOISE/include" \
      -I"$RNNOISE/src" -I"$RNNOISE" -c "$file" -o "$object"
  fi
  objects+=("$object")
done

# shellcheck disable=SC2086
"$CC" -std=c11 -O2 -Wall -Wextra ${CFLAGS:-} "${SHARED[@]}" -I"$INCLUDE" \
  "$ROOT/jdll/hush.c" "${objects[@]}" ${LIBS[@]+"${LIBS[@]}"} -o "$ROOT/jdll/hush.jdll"
echo "built jdll/hush.jdll"
