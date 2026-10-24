# Reference

hush has two modules, `hush.Denoise` and `hush.Samples`, apart from `hush.Meta`.

```jello
import { Denoiser, denoise, frameSize, frameBytes, sampleRate } from hush.Denoise;
import { pack, unpack } from hush.Samples;
```

PCM is Bytes of 32-bit float samples, mono at 48 kHz, four bytes a sample, least significant
first, at the scale of 16-bit PCM; see [Audio for hush](samples.md).

## hush.Denoise

| Name | Type | What it is |
|------|------|------------|
| `Denoiser` | prototype | an RNNoise denoiser; made with `new Denoiser()` |
| `frameSize` | `I32` | 480, the samples in a frame |
| `frameBytes` | `I32` | 1920, the bytes of a frame of PCM |
| `sampleRate` | `I32` | 48000, the sample rate a denoiser expects, in hertz |
| `denoise(pcm: Bytes)` | `Bytes` | denoises a whole recording with a denoiser of its own |

### Denoiser

| Method | Result | Does |
|--------|--------|------|
| `new Denoiser()` | | a denoiser that has heard nothing yet |
| `close()` | `Null` | frees the denoiser now; a closed denoiser traps when used |
| `frame(pcm: Bytes)` | `Bytes` | denoises exactly one frame; throws for any other length |
| `process(pcm: Bytes)` | `Bytes` | denoises PCM of any length, a frame at a time; throws for a partial sample |
| `processSamples(samples: Array<F32>)` | `Array<F32>` | as `process`, for samples |
| `voiceProbability()` | `F32` | how likely the last frame was to be speech, from 0 to 1; 0 before any |

A last frame that is not whole is denoised as if silence followed it. Errors throw Bytes such
as `Denoiser.frame: a frame is 1920 bytes, not 400`.

[Denoising](denoising.md) gives the details.

## hush.Samples

| Function | Result | Does |
|----------|--------|------|
| `pack(samples: Array<F32>)` | `Bytes` | the samples as PCM |
| `unpack(pcm: Bytes)` | `Array<F32>` | the samples of PCM; throws for a partial sample |

## hush.Meta

| Function | Result |
|----------|--------|
| `version()` | `"0.1.0"` |
