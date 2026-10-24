/* SPDX-License-Identifier: BSD-3-Clause */

/**
 * @file hush.c
 * @brief Speech denoising for Jello, on RNNoise.
 *
 * A denoiser is a handle whose payload holds an RNNoise state. Audio crosses the border as
 * Bytes of little-endian F32 samples, mono at 48 kHz, at the scale of 16-bit PCM; RNNoise
 * takes them a frame of 480 samples at a time.
 *
 * An RNNoise state keeps no lock, so the handle class has no `retain`: a denoiser stays in the
 * process that made it.
 */

#include <jello/jdll.h>

#include "rnnoise/include/rnnoise.h"

#include <stdlib.h>
#include <string.h>

// The samples in a frame, as RNNoise takes them.
#define FRAME_SAMPLES 480

// The bytes of a frame of F32 samples.
#define FRAME_BYTES (FRAME_SAMPLES * (uint32_t)sizeof(float))

// An RNNoise state and the voice probability of its last frame; `rn` is NULL once closed.
typedef struct hush_denoiser {
  DenoiseState* rn;
  float voice;
} hush_denoiser;

// Frees a denoiser's payload, when no handle holds it any more.
static void hush_finalize(void* payload) {
  hush_denoiser* d = payload;
  if (d->rn) rnnoise_destroy(d->rn);
  free(d);
}

static const jello_jdll_handle_class DENOISER = {"hush denoiser", hush_finalize, NULL};

// The open denoiser of argument 0, or NULL once the call has failed.
static hush_denoiser* arg_denoiser(jdlo_ctx* c) {
  hush_denoiser* d = jdl_arg_handle(c, 0, &DENOISER);
  if (d && !d->rn) {
    jdl_fail(c, "the denoiser is closed");
    return NULL;
  }
  return d;
}

// The samples in a frame.
static void hush_frame_size(jdlo_ctx* c) {
  jdl_return_i32(c, rnnoise_get_frame_size());
}

// A new denoiser, with RNNoise's built-in model.
static void hush_new(jdlo_ctx* c) {
  if (rnnoise_get_frame_size() != FRAME_SAMPLES) {
    jdl_fail(c, "RNNoise's frame is not 480 samples");
    return;
  }
  hush_denoiser* d = calloc(1, sizeof *d);
  if (d) d->rn = rnnoise_create(NULL);
  if (!d || !d->rn) {
    free(d);
    jdl_fail(c, "out of memory");
    return;
  }
  jdl_return_handle(c, &DENOISER, d, sizeof *d + (size_t)rnnoise_get_size());
}

// Frees a denoiser's RNNoise state now, rather than when its handle is collected.
static void hush_close(jdlo_ctx* c) {
  hush_denoiser* d = jdl_arg_handle(c, 0, &DENOISER);
  if (d && d->rn) {
    rnnoise_destroy(d->rn);
    d->rn = NULL;
  }
}

/**
 * Denoises PCM, any whole number of samples, a frame at a time; the result has the same length.
 * A last frame that is not whole is denoised with silence after it, which is then dropped.
 */
static void hush_process(jdlo_ctx* c) {
  hush_denoiser* d = arg_denoiser(c);
  if (!d) return;
  const uint8_t* data = jdl_arg_bytes_data(c, 1);
  uint32_t len = jdl_arg_bytes_len(c, 1);
  if (len % sizeof(float) != 0) {
    jdl_fail(c, "the PCM is not a whole number of F32 samples");
    return;
  }
  uint8_t* out = malloc(len ? len : 1);
  if (!out) {
    jdl_fail(c, "out of memory");
    return;
  }
  // The Bytes may not be aligned for floats, so each frame is copied in and out.
  float in_frame[FRAME_SAMPLES];
  float out_frame[FRAME_SAMPLES];
  for (uint32_t at = 0; at < len; at += FRAME_BYTES) {
    uint32_t n = len - at < FRAME_BYTES ? len - at : FRAME_BYTES;
    memset(in_frame, 0, sizeof in_frame);
    memcpy(in_frame, data + at, n);
    d->voice = rnnoise_process_frame(d->rn, out_frame, in_frame);
    memcpy(out + at, out_frame, n);
  }
  jdl_return_bytes_copy(c, out, len);
  free(out);
}

// The probability, from 0 to 1, that the last frame denoised held speech; 0 before any.
static void hush_voice(jdlo_ctx* c) {
  hush_denoiser* d = arg_denoiser(c);
  if (d) jdl_return_f32(c, d->voice);
}

static const jello_jdll_export EXPORTS[] = {
    {"frame_size", hush_frame_size, JELLO_T_I32, 0, {0}, 0},
    {"denoiser_new", hush_new, JELLO_T_DYNAMIC, 0, {0}, 0},
    {"denoiser_close", hush_close, JELLO_T_VOID, 1, {JELLO_T_DYNAMIC}, 0},
    {"denoiser_process", hush_process, JELLO_T_BYTES, 2, {JELLO_T_DYNAMIC, JELLO_T_BYTES},
     JELLO_JDLL_BLOCKING},
    {"denoiser_voice", hush_voice, JELLO_T_F32, 1, {JELLO_T_DYNAMIC}, 0},
};

JELLO_JDLL_LIBRARY(hush, EXPORTS);
