# Audio for hush

RNNoise was trained on one kind of audio, and hush passes it straight through, so audio must
arrive in that form:

| | |
|---|---|
| Sample rate | 48000 Hz (`sampleRate`) |
| Channels | one: mono |
| Samples | 32-bit floats, `F32` |
| Scale | that of 16-bit PCM: from -32768 to 32767 |
| Bytes | four a sample, least significant byte first |

Audio at another rate must be resampled first, and stereo mixed down to mono. Audio scaled from
-1 to 1, as many libraries give it, must be multiplied by 32768 first, and divided by it after:
at that scale RNNoise takes nearly everything for silence.

hush calls such Bytes *PCM*. PCM goes to the native library in one piece, where an array would
first be packed a sample at a time, so PCM is the faster form, and the one to keep audio in when
it arrives as bytes.

## hush.Samples

`hush.Samples` turns an `Array<F32>` into PCM and back:

```jello
import { pack, unpack } from hush.Samples;

let pcm = pack([0.5f32, -1200.0f32, 32767.0f32]);   // 12 bytes
let samples = unpack(pcm);                           // [0.5, -1200.0, 32767.0]
`${pcm.len()} ${samples[1]}`
```

`unpack` throws when the PCM is not a whole number of samples, a length that is not a multiple
of four.

Jello's own `Bytes` functions read and write the same layout one sample at a time:
`pcm.readF32Le(4 * i)` is sample `i`, and `Bytes.writeF32Le(buffer, 4 * i, sample)` writes it
into a `ByteBuffer`.

## 16-bit audio

Audio often arrives as 16-bit integers, two bytes a sample, least significant first, as in most
WAV files. Their values are already at the right scale, so each needs only to become a float:

```jello
import { denoise } from hush.Denoise;

// PCM of F32 samples from 16-bit samples.
let fromI16 = fn(data: Bytes): Bytes {
  let n = data.len() / 2;
  let buffer = Bytes.new(n * 4);
  let i = 0;
  while (i < n) {
    let v = data.readU16Le(2 * i);
    Bytes.writeF32Le(buffer, 4 * i, (v >= 32768 ? v - 65536 : v) as F32);
    i++;
  }
  buffer.toString()
};

let clean = denoise(fromI16("\x10\x00\xf0\xff"));   // the samples 16 and -16
clean.len()
```

## Next

[Denoising](denoising.md) covers denoisers, frames and streams.
