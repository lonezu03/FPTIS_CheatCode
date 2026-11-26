/**
 * Monophonic pitch detection with the normalised square difference function
 * (McLeod Pitch Method). Robust against the octave errors that a plain
 * autocorrelation peak pick makes on guitar strings rich in harmonics.
 */

export type PitchOptions = {
  minFrequency?: number;
  maxFrequency?: number;
  /** Below this RMS the buffer is treated as silence. */
  minRms?: number;
  /** A peak must reach this fraction of the highest peak to be chosen (MPM "k"). */
  peakThreshold?: number;
  /** Minimum clarity (0..1) of the chosen peak. */
  minClarity?: number;
};

export type PitchResult = { frequency: number; clarity: number; rms: number };

export const DEFAULT_PITCH_OPTIONS: Required<PitchOptions> = {
  minFrequency: 70,
  maxFrequency: 2200,
  minRms: 0.01,
  peakThreshold: 0.9,
  minClarity: 0.8,
};

export function rms(buffer: ArrayLike<number>): number {
  let sum = 0;
  for (let i = 0; i < buffer.length; i++) sum += buffer[i] * buffer[i];
  return Math.sqrt(sum / Math.max(1, buffer.length));
}

export function detectPitch(buffer: Float32Array, sampleRate: number, options: PitchOptions = {}): PitchResult | null {
  const opts = { ...DEFAULT_PITCH_OPTIONS, ...options };
  const level = rms(buffer);
  if (level < opts.minRms) return null;

  const size = buffer.length;
  const minLag = Math.max(2, Math.floor(sampleRate / opts.maxFrequency));
  const maxLag = Math.min(Math.floor(size / 2), Math.ceil(sampleRate / opts.minFrequency));
  if (maxLag <= minLag + 2) return null;

  // NSDF n(τ) = 2·Σ x[i]x[i+τ] / Σ (x[i]² + x[i+τ]²), values in [-1, 1].
  const nsdf = new Float32Array(maxLag + 2);
  for (let lag = 0; lag < nsdf.length; lag++) {
    let acf = 0;
    let energy = 0;
    for (let i = 0; i + lag < size; i++) {
      const a = buffer[i];
      const b = buffer[i + lag];
      acf += a * b;
      energy += a * a + b * b;
    }
    nsdf[lag] = energy > 0 ? (2 * acf) / energy : 0;
  }

  // Key maxima: the highest point between each positive-going and negative-going zero crossing.
  const peaks: number[] = [];
  let lag = 1;
  while (lag < nsdf.length - 1 && nsdf[lag] > 0) lag++; // skip the lag-0 lobe
  while (lag < nsdf.length - 1) {
    while (lag < nsdf.length - 1 && nsdf[lag] <= 0) lag++;
    let best = -1;
    while (lag < nsdf.length - 1 && nsdf[lag] > 0) {
      if (best < 0 || nsdf[lag] > nsdf[best]) best = lag;
      lag++;
    }
    if (best > 0 && best >= minLag && best <= maxLag) peaks.push(best);
  }
  if (peaks.length === 0) return null;

  const highest = Math.max(...peaks.map((index) => nsdf[index]));
  const chosen = peaks.find((index) => nsdf[index] >= opts.peakThreshold * highest) ?? peaks[0];

  // Parabolic interpolation around the chosen lag for sub-sample accuracy.
  const left = nsdf[chosen - 1];
  const middle = nsdf[chosen];
  const right = nsdf[chosen + 1];
  const denominator = left - 2 * middle + right;
  const shift = denominator !== 0 ? (0.5 * (left - right)) / denominator : 0;
  const period = chosen + shift;
  const clarity = Math.min(1, middle - 0.25 * (left - right) * shift);

  if (clarity < opts.minClarity || period <= 0) return null;
  const frequency = sampleRate / period;
  if (frequency < opts.minFrequency || frequency > opts.maxFrequency) return null;
  return { frequency, clarity, rms: level };
}

/** Median of the last readings to keep the needle steady. */
export function median(values: number[]): number | null {
  if (values.length === 0) return null;
  const sorted = [...values].sort((a, b) => a - b);
  const middle = Math.floor(sorted.length / 2);
  return sorted.length % 2 ? sorted[middle] : (sorted[middle - 1] + sorted[middle]) / 2;
}
