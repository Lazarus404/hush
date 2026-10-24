# How it works

hush has two halves:

```text
 your program
      |
 hush.Denoise        Jello: the Denoiser prototype, the frame constants, and the
 hush.Samples               checks that throw on PCM of the wrong length
      |
 hush.jdll           C: the denoiser handle, and the loop over frames
      |
 RNNoise             C: the noise suppressor and its model, vendored in jdll/rnnoise
```

## The native library

`hush.jdll` is a Jello native library, built from `jdll/hush.c` and RNNoise by `build.sh`.
`hush.Denoise` loads its functions and gives each a Jello type, and the `Denoiser` prototype
wraps them in methods. A program never sees the natives themselves.

RNNoise's model, the weights of its neural network, is compiled into the library from
`jdll/rnnoise/rnnoise_data.c`, so there is no model file to find at run time.

PCM crosses into the library as Bytes. The library copies each frame into a buffer of floats,
denoises it, and copies the result out, so PCM need not be aligned and a short last frame can be
padded with silence.

## Handles and memory

A denoiser's native side, its RNNoise state, is a *native handle*, held by the `Denoiser` in its
`handle` field. To Jello the handle has an abstract type: it can only be passed back to hush's
natives.

The garbage collector frees a denoiser's native side once nothing holds the `Denoiser`.
`close()` frees it at once instead, which is worth doing when a program opens and closes many
denoisers. Using a denoiser after closing it is a bug, and the program stops with the trap
`TYPE_MISMATCH`; closing it twice does nothing.

## Threads and processes

Denoising is marked as a blocking call: while a denoiser works, the process that called it
waits, and its scheduler runs other processes. So a long recording can be denoised without
holding up the rest of the program.

RNNoise keeps no lock, so a denoiser belongs to the process that made it. Sending one to another
process, or capturing one in a function another process runs, stops the program with the trap
`UNSENDABLE`. To denoise in another process, make the denoiser there, and send it the PCM.
