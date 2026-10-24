# Denoising

## Denoisers

A `Denoiser` holds an RNNoise state: what it has heard of the audio so far, which it uses to
tell speech from noise. Make one with `new Denoiser()`, and give it the audio in order.

```jello
import { Denoiser } from hush.Denoise;
import { pack } from hush.Samples;

let d = new Denoiser();
let clean = d.process(pack(Array.new<F32>(960)));   // two frames of silence
d.close();
clean.len()
```

When you are done with a denoiser, you may `close` it to free its state at once. You need not:
a denoiser nobody holds is freed when the garbage collector finds it. Using a denoiser after
closing it is a bug, and stops the program with the trap `TYPE_MISMATCH`; closing it twice does
nothing.

## Frames

RNNoise works on *frames* of 480 samples, 10 ms at 48 kHz. `hush.Denoise` exports the numbers:

| Constant | Value |
|----------|-------|
| `frameSize` | 480, the samples in a frame |
| `frameBytes` | 1920, the bytes of a frame of PCM |
| `sampleRate` | 48000, in hertz |

`frame(pcm)` denoises exactly one frame, and throws for PCM of any other length. It suits audio
that arrives a frame at a time, as from a sound card set to 10 ms buffers.

`process(pcm)` takes PCM of any length and denoises it a frame at a time, giving back PCM of the
same length. If the last frame is not whole, it is denoised as if silence followed it, and the
silence is dropped. PCM that is not a whole number of samples throws.

`processSamples(samples)` does what `process` does, for an `Array<F32>`.

## Streams

A denoiser remembers what it has heard, so one stream of audio goes through one denoiser, in
order, and two streams need two denoisers. Feeding a stream in pieces gives the same result as
feeding it whole, as long as each piece but the last is a whole number of frames:

```jello
import { Denoiser, denoise, frameBytes } from hush.Denoise;
import { pack } from hush.Samples;

let tone = Array.new<F32>(1440);
let i = 0;
while (i < tone.len()) { tone[i] = (4000.0 * Math.sin((i as F64) * 0.03)) as F32; i++; }
let pcm = pack(tone);

let d = new Denoiser();
let first = d.process(pcm.substring(0, frameBytes));
let rest = d.process(pcm.substring(frameBytes, pcm.len()));
first + rest == denoise(pcm)
```

A piece that ends partway through a frame would be finished with silence the stream never had.
Keep what is left over and send it with the next piece instead.

## Whole recordings

`denoise(pcm)` denoises a recording with a denoiser of its own, made for the call and closed
after it. It is `process` on a fresh denoiser.

## Is someone speaking?

As well as denoising, RNNoise judges how likely it is that each frame holds speech.
`voiceProbability()` gives that for the last frame the denoiser denoised, from 0 to 1, and 0
before it has denoised any. To follow it frame by frame, denoise a frame at a time:

```jello
import { Denoiser, frameBytes } from hush.Denoise;
import { pack } from hush.Samples;

let d = new Denoiser();
let pcm = pack(Array.new<F32>(4800));
let speech = 0;
let at = 0;
while (at < pcm.len()) {
  d.frame(pcm.substring(at, at + frameBytes));
  if (d.voiceProbability() > 0.5f32) { speech++; }
  at += frameBytes;
}
`${speech} of 10 frames are speech`
```

## Speed

RNNoise is quick: on a recent processor a frame takes well under a millisecond, a small
fraction of the 10 ms it lasts, so one process keeps up with many streams. Each call to `frame` or `process` runs on one of
Jello's threads for waiting work, so a long recording does not hold up the program's other
processes while it is denoised.

## Next

[How it works](architecture.md) covers the native library, handles and threads.
