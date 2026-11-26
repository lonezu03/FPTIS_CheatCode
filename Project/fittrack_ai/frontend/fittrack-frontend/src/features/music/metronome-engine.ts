/**
 * Web Audio metronome with lookahead scheduling ("A tale of two clocks"):
 * a coarse JS timer wakes up every 25 ms and schedules every click that falls in
 * the next 100 ms on the precise AudioContext clock, so tempo never drifts with
 * UI work. Visual beats are emitted when the audio clock reaches each click.
 */

export const MIN_BPM = 40;
export const MAX_BPM = 208;
export const BEATS_PER_BAR_OPTIONS = [2, 3, 4] as const;
export type BeatsPerBar = (typeof BEATS_PER_BAR_OPTIONS)[number];

export function clampBpm(bpm: number): number {
  if (!Number.isFinite(bpm)) return 60;
  return Math.min(MAX_BPM, Math.max(MIN_BPM, Math.round(bpm)));
}

/** Seconds between two ticks (beats divided by the subdivision). */
export function tickInterval(bpm: number, subdivision = 1): number {
  return 60 / clampBpm(bpm) / subdivision;
}

export type Tick = {
  /** Running tick counter since start. */
  index: number;
  /** Beat in bar, 0-based. */
  beat: number;
  /** Sub-tick within the beat, 0-based. */
  sub: number;
  accent: boolean;
};

export function tickAt(index: number, beatsPerBar: number, subdivision: number): Tick {
  const ticksPerBar = beatsPerBar * subdivision;
  const inBar = ((index % ticksPerBar) + ticksPerBar) % ticksPerBar;
  const beat = Math.floor(inBar / subdivision);
  const sub = inBar % subdivision;
  return { index, beat, sub, accent: beat === 0 && sub === 0 };
}

/** Tap tempo: average of the last intervals; a pause longer than `resetMs` starts over. */
export const TAP_RESET_MS = 2000;

export function tapTempo(taps: number[], resetMs = TAP_RESET_MS): { taps: number[]; bpm: number | null } {
  const kept: number[] = [];
  for (const time of taps) {
    if (kept.length && time - kept[kept.length - 1] > resetMs) kept.length = 0;
    kept.push(time);
  }
  const recent = kept.slice(-5);
  if (recent.length < 2) return { taps: recent, bpm: null };
  const average = (recent[recent.length - 1] - recent[0]) / (recent.length - 1);
  return { taps: recent, bpm: average > 0 ? clampBpm(60_000 / average) : null };
}

type AudioContextCtor = typeof AudioContext;

export function getAudioContextCtor(): AudioContextCtor | null {
  if (typeof window === "undefined") return null;
  const legacy = (window as unknown as { webkitAudioContext?: AudioContextCtor }).webkitAudioContext;
  return window.AudioContext ?? legacy ?? null;
}

export type MetronomeSettings = { bpm: number; beatsPerBar: number; subdivision: number; accent: boolean; volume: number };

export class MetronomeEngine {
  private context: AudioContext | null = null;
  private timer: number | null = null;
  private frame: number | null = null;
  private nextTime = 0;
  private nextIndex = 0;
  private queue: { tick: Tick; time: number }[] = [];
  private settings: MetronomeSettings;
  private readonly onTick: (tick: Tick) => void;

  static readonly LOOKAHEAD_MS = 25;
  static readonly SCHEDULE_AHEAD_S = 0.1;

  constructor(settings: MetronomeSettings, onTick: (tick: Tick) => void) {
    this.settings = settings;
    this.onTick = onTick;
  }

  get running(): boolean {
    return this.timer !== null;
  }

  update(settings: Partial<MetronomeSettings>) {
    this.settings = { ...this.settings, ...settings };
  }

  async start(): Promise<void> {
    if (this.running) return;
    const Ctor = getAudioContextCtor();
    if (!Ctor) throw new Error("Trình duyệt không hỗ trợ âm thanh Web Audio.");
    this.context ??= new Ctor();
    if (this.context.state === "suspended") await this.context.resume();
    this.nextIndex = 0;
    this.queue = [];
    this.nextTime = this.context.currentTime + 0.06;
    this.timer = window.setInterval(() => this.schedule(), MetronomeEngine.LOOKAHEAD_MS);
    this.schedule();
    this.draw();
  }

  stop() {
    if (this.timer !== null) window.clearInterval(this.timer);
    if (this.frame !== null) window.cancelAnimationFrame(this.frame);
    this.timer = null;
    this.frame = null;
    this.queue = [];
  }

  async dispose() {
    this.stop();
    const context = this.context;
    this.context = null;
    if (context && context.state !== "closed") await context.close().catch(() => undefined);
  }

  /** A short blip on the audio clock (also used for timer end signals). */
  static beep(context: AudioContext, time: number, frequency: number, gainValue: number, length = 0.05) {
    const oscillator = context.createOscillator();
    const gain = context.createGain();
    oscillator.frequency.value = frequency;
    gain.gain.setValueAtTime(0.0001, time);
    gain.gain.exponentialRampToValueAtTime(Math.max(0.0002, gainValue), time + 0.002);
    gain.gain.exponentialRampToValueAtTime(0.0001, time + length);
    oscillator.connect(gain).connect(context.destination);
    oscillator.start(time);
    oscillator.stop(time + length + 0.02);
  }

  private schedule() {
    const context = this.context;
    if (!context) return;
    const { bpm, beatsPerBar, subdivision, accent, volume } = this.settings;
    while (this.nextTime < context.currentTime + MetronomeEngine.SCHEDULE_AHEAD_S) {
      const tick = tickAt(this.nextIndex, beatsPerBar, subdivision);
      const strong = accent && tick.accent;
      const frequency = strong ? 1600 : tick.sub === 0 ? 1000 : 700;
      const gain = volume * (strong ? 1 : tick.sub === 0 ? 0.7 : 0.35);
      MetronomeEngine.beep(context, this.nextTime, frequency, gain);
      this.queue.push({ tick, time: this.nextTime });
      this.nextTime += tickInterval(bpm, subdivision);
      this.nextIndex += 1;
    }
  }

  private draw = () => {
    const context = this.context;
    if (!context || this.timer === null) return;
    let latest: Tick | null = null;
    while (this.queue.length && this.queue[0].time <= context.currentTime) {
      latest = this.queue.shift()!.tick;
    }
    if (latest) this.onTick(latest);
    this.frame = window.requestAnimationFrame(this.draw);
  };
}
