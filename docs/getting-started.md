# Getting started

## What you need

- Jello: `jelloc` and `jello` on your `PATH`.
- A C compiler, to build hush's native library: `cc` on macOS and Linux, or llvm-mingw's `clang`
  on Windows (run `build.sh` from Git Bash there).

RNNoise and its model come with hush, in `jdll/rnnoise/`, so there is nothing else to install.

## Install

Add hush to the `dependencies` of your project's `jello.json`:

```json
{
  "name": "call",
  "version": "0.1.0",
  "dependencies": {
    "hush": {"github": "Lazarus404/hush", "tag": "0.1.0"}
  }
}
```

Fetch it, then build its native library, `hush.jdll`:

```sh
jelloc deps.get
packages/hush/build.sh
```

`build.sh` finds Jello's C headers through `JELLO_ROOT`, if you set it, or else beside the
`jello` on your `PATH`. Set `CC` to choose another compiler. The library lands in
`packages/hush/jdll/`, where `jelloc run` and `jelloc test` look for it. The first build compiles
RNNoise's model, tens of megabytes of tables, and takes a few seconds; later builds reuse it.

## A first denoise

Put this in `src/Main.jello`:

```jello
import { denoise, frameSize } from hush.Denoise;
import { pack, unpack } from hush.Samples;

// A second of a hum with hiss on it, at the scale of 16-bit PCM.
let noisy = Array.new<F32>(48000);
let i = 0;
while (i < noisy.len()) {
  let hum = 3000.0 * Math.sin((i as F64) * 0.02);
  let hiss = 500.0 * Math.sin((i as F64) * 2.3);
  noisy[i] = (hum + hiss) as F32;
  i++;
}

let clean = unpack(denoise(pack(noisy)));
`${clean.len()} samples, ${clean.len() / frameSize} frames`
```

and run it:

```sh
$ jelloc run
48000 samples, 100 frames
```

`denoise` takes PCM, Bytes of 32-bit float samples, and gives back PCM of the same length.
`pack` and `unpack` turn an `Array<F32>` into PCM and back. A real program reads its audio from
a file or a microphone instead; [Audio for hush](samples.md) says what form it must take.

## Next

[Audio for hush](samples.md) covers the sample rate, the scale and the byte layout hush expects.
