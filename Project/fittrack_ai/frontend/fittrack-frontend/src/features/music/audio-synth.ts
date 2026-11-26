import { getAudioContextCtor } from "./metronome-engine";
import { midiToFrequency } from "./music-theory";

let shared: AudioContext | null = null;

function context(): AudioContext | null {
  const Ctor = getAudioContextCtor();
  if (!Ctor) return null;
  if (!shared || shared.state === "closed") shared = new Ctor();
  if (shared.state === "suspended") void shared.resume();
  return shared;
}

/** Plucked-string approximation: a strum from low to high string. */
export function playStrum(midiNotes: number[], stagger = 0.035) {
  const ctx = context();
  if (!ctx) return;
  const start = ctx.currentTime + 0.03;
  midiNotes.forEach((midi, index) => {
    const time = start + index * stagger;
    const oscillator = ctx.createOscillator();
    const filter = ctx.createBiquadFilter();
    const gain = ctx.createGain();
    oscillator.type = "triangle";
    oscillator.frequency.value = midiToFrequency(midi);
    filter.type = "lowpass";
    filter.frequency.setValueAtTime(3000, time);
    filter.frequency.exponentialRampToValueAtTime(600, time + 1.2);
    gain.gain.setValueAtTime(0.0001, time);
    gain.gain.exponentialRampToValueAtTime(0.18, time + 0.005);
    gain.gain.exponentialRampToValueAtTime(0.0001, time + 2);
    oscillator.connect(filter).connect(gain).connect(ctx.destination);
    oscillator.start(time);
    oscillator.stop(time + 2.05);
  });
}

/** Soft sustained reference tone (for flute notes). */
export function playTone(frequency: number, seconds = 1.5) {
  const ctx = context();
  if (!ctx) return;
  const time = ctx.currentTime + 0.03;
  const oscillator = ctx.createOscillator();
  const gain = ctx.createGain();
  oscillator.type = "sine";
  oscillator.frequency.value = frequency;
  gain.gain.setValueAtTime(0.0001, time);
  gain.gain.exponentialRampToValueAtTime(0.25, time + 0.08);
  gain.gain.setValueAtTime(0.25, time + seconds - 0.2);
  gain.gain.exponentialRampToValueAtTime(0.0001, time + seconds);
  oscillator.connect(gain).connect(ctx.destination);
  oscillator.start(time);
  oscillator.stop(time + seconds + 0.05);
}
