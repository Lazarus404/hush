#!/usr/bin/env bash
# Copies RNNoise into jdll/rnnoise/, to upgrade it: run it with a clone of
# https://github.com/xiph/rnnoise in which upstream's ./download_model.sh has fetched the model.
# The clone is /tmp/rnnoise-src unless given. Then run ./test.sh.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${1:-/tmp/rnnoise-src}"
DEST="$ROOT/jdll/rnnoise"

die() {
  echo "vendor_rnnoise_sources.sh: $*" >&2
  exit 1
}

[[ -d "$SRC/src" ]] || die "no RNNoise clone at $SRC; usage: $0 [path-to-rnnoise-clone]"
[[ -f "$SRC/src/rnnoise_data.c" ]] || die "$SRC has no model; run its ./download_model.sh first"

mkdir -p "$DEST/include" "$DEST/src/x86"
cp "$SRC/include/rnnoise.h" "$DEST/include/"
cp "$SRC/COPYING" "$DEST/"
cp "$SRC/model_version" "$DEST/"
cp "$SRC/src/rnnoise_data.c" "$SRC/src/rnnoise_data.h" "$DEST/"

for f in denoise.c rnn.c pitch.c kiss_fft.c celt_lpc.c nnet.c nnet_default.c \
  parse_lpcnet_weights.c rnnoise_tables.c; do
  cp "$SRC/src/$f" "$DEST/src/"
done

for f in arch.h celt_lpc.h common.h cpu_support.h denoise.h _kiss_fft_guts.h \
  kiss_fft.h nnet.h nnet_arch.h opus_types.h pitch.h rnn.h vec.h vec_avx.h vec_neon.h; do
  cp "$SRC/src/$f" "$DEST/src/"
done

cp "$SRC/src/x86/"* "$DEST/src/x86/"
echo "copied RNNoise from $SRC into jdll/rnnoise"
