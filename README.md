# hush

**hush** takes the noise out of speech in Jello programs: hiss, hum, fans and keyboards, in real time. It suits voice calls, recordings and anything that listens to people talking. Underneath is [RNNoise](https://github.com/xiph/rnnoise), a small neural network for noise suppression, which hush wraps in a `Denoiser` with Jello methods.

**Version:** 0.1.0

```jello
import { Denoiser, denoise } from hush.Denoise;
import { pack, unpack } from hush.Samples;

let noisy = pack([120.0f32, -80.0f32, 45.0f32]);    // PCM: F32 samples, 48 kHz mono
let clean = denoise(noisy);                         // the same length, without the noise

let d = new Denoiser();                             // for a stream, one denoiser throughout
let frame = d.frame(pack(Array.new<F32>(480)));     // a frame is 480 samples, 10 ms
let speaking = d.voiceProbability() > 0.5f32;
unpack(clean)                                       // back to an Array<F32>
```

## Install

Add hush to your project's `jello.json`:

```json
"dependencies": {
  "hush": {"github": "Lazarus404/hush", "tag": "0.1.0"}
}
```

Then fetch it and build its native library, which needs a C compiler:

```sh
jelloc deps.get
packages/hush/build.sh
```

`jelloc run` and `jelloc test` find the library in `packages/hush/jdll/` on their own. RNNoise and its model come with hush, so there is nothing else to install.

## What you get

| In `hush.Denoise` | Does |
|-------------------|------|
| `new Denoiser()` | a denoiser, with RNNoise's built-in model |
| `frame(pcm)` | denoises exactly one frame, `frameBytes` of PCM |
| `process(pcm)` | denoises PCM of any length, a frame at a time |
| `processSamples(samples)` | the same, for an `Array<F32>` |
| `voiceProbability()` | how likely it is that the last frame held speech, from 0 to 1 |
| `close()` | frees the denoiser now, rather than when it is collected |
| `denoise(pcm)` | denoises a whole recording with a denoiser of its own |
| `frameSize`, `frameBytes`, `sampleRate` | 480 samples, 1920 bytes, 48000 Hz |

| In `hush.Samples` | Does |
|-------------------|------|
| `pack(samples)` | an `Array<F32>` as PCM Bytes |
| `unpack(pcm)` | PCM Bytes as an `Array<F32>` |

Audio is mono at 48 kHz, as 32-bit floats at the scale of 16-bit PCM, from -32768 to 32767;
see [Audio for hush](docs/samples.md).

## Documentation

The [guide](docs/README.md) starts at the beginning and covers everything:

| Guide | Covers |
|-------|--------|
| [Getting started](docs/getting-started.md) | Installing, building and a first denoise |
| [Audio for hush](docs/samples.md) | The format hush takes, and `hush.Samples` |
| [Denoising](docs/denoising.md) | Denoisers, frames, streams and voice activity |
| [How it works](docs/architecture.md) | The native library, handles and threads |
| [Reference](docs/modules.md) | Every type, constant and method |
| [Testing](docs/testing.md) | Running the tests |

## Development

```sh
./build.sh      # builds jdll/hush.jdll
./test.sh       # builds, then runs the unit tests, the examples and the programs
```

Both need Jello's `jelloc` and `jello` on `PATH`. The examples in `examples/` run as tests, so they always work as written. `scripts/vendor_rnnoise_sources.sh` copies a newer RNNoise into `jdll/rnnoise/`.

## Licence

The hush library is under the BSD 3-Clause licence. RNNoise, vendored with its model in
`jdll/rnnoise/`, is copyright Jean-Marc Valin, Amazon, Mozilla, the Xiph.Org Foundation and Mark Borgerding, under its own BSD licence; see [jdll/rnnoise/COPYING](jdll/rnnoise/COPYING).
