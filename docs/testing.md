# Testing

```sh
./test.sh
```

`test.sh` builds `jdll/hush.jdll`, fetches the test dependency,
[degust](https://github.com/Lazarus404/degust), if `packages/` lacks it, and runs `jelloc test`.
That compiles every test into one binary and runs:

- **the unit tests**, in `tests/hush/`, on `std.testing`: `Denoise.test.jello` for denoisers,
  frames, streams and errors, and `Samples.test.jello` for packing samples;
- **the golden tests**, in `tests/hush/Golden.test.jello`, which check a fixed recording against
  `golden_input_960.f32` and its denoised form against `golden_denoise_960.f32`, beside the test;
- **the examples**, every program in `examples/`, which degust compiles and runs, checking each
  prints what its `// expect:` lines say, with the JIT and without;
- **the programs** in `tests/programs/`, for what a unit test cannot check, such as a closed
  denoiser stopping the program with a trap.

Compilers and processors round RNNoise's arithmetic a little differently, so the denoised golden
file is compared sample by sample, allowing a difference of up to 0.001.

Arguments to `test.sh` before a `--` go to the test binary, and those after it to the tests:

```sh
./test.sh -v                      # every test's result, not only failures
./test.sh --run hush/Denoise      # only the denoiser's unit tests
./test.sh --run Programs          # only the examples and programs
./test.sh -- --update             # rewrite the golden files, after changing RNNoise
```

To add an example, write a program in `examples/` that starts with `// expect:` lines giving its
output; it is a test from then on.
