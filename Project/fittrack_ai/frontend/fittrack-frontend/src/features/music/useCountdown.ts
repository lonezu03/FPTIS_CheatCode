import { useCallback, useEffect, useRef, useState } from "react";
import { getAudioContextCtor, MetronomeEngine } from "./metronome-engine";

/** Three short beeps to signal the end of a timed step. */
export function playDoneSignal() {
  const Ctor = getAudioContextCtor();
  if (!Ctor) return;
  try {
    const context = new Ctor();
    const now = context.currentTime + 0.05;
    [0, 0.18, 0.36].forEach((offset) => MetronomeEngine.beep(context, now + offset, 880, 0.4, 0.12));
    window.setTimeout(() => void context.close().catch(() => undefined), 1000);
  } catch {
    // Sound is a bonus; the visual state already shows the end.
  }
}

/**
 * Wall-clock countdown (keeps correct time even if the tab throttles timers).
 * `onDone` fires once when it reaches zero.
 */
export function useCountdown(onDone?: () => void) {
  const [total, setTotal] = useState(0);
  const [remaining, setRemaining] = useState(0);
  const [running, setRunning] = useState(false);
  const endAt = useRef(0);
  const leftRef = useRef(0);
  const doneRef = useRef(onDone);

  useEffect(() => {
    doneRef.current = onDone;
  }, [onDone]);

  useEffect(() => {
    if (!running) return;
    const timer = window.setInterval(() => {
      const left = Math.max(0, (endAt.current - Date.now()) / 1000);
      leftRef.current = left;
      setRemaining(left);
      if (left <= 0) {
        setRunning(false);
        doneRef.current?.();
      }
    }, 200);
    return () => window.clearInterval(timer);
  }, [running]);

  const start = useCallback((seconds: number) => {
    endAt.current = Date.now() + seconds * 1000;
    leftRef.current = seconds;
    setTotal(seconds);
    setRemaining(seconds);
    setRunning(true);
  }, []);

  const pause = useCallback(() => {
    setRunning(false);
    leftRef.current = Math.max(0, (endAt.current - Date.now()) / 1000);
    setRemaining(leftRef.current);
  }, []);

  const resume = useCallback(() => {
    endAt.current = Date.now() + leftRef.current * 1000;
    setRunning(true);
  }, []);

  const reset = useCallback(() => {
    setRunning(false);
    setRemaining(0);
    setTotal(0);
  }, []);

  return { total, remaining, running, elapsed: Math.max(0, total - remaining), start, pause, resume, reset };
}

/** Count-up stopwatch used for long tones. */
export function useStopwatch() {
  const [seconds, setSeconds] = useState(0);
  const [running, setRunning] = useState(false);
  const startedAt = useRef(0);

  useEffect(() => {
    if (!running) return;
    const timer = window.setInterval(() => setSeconds((Date.now() - startedAt.current) / 1000), 100);
    return () => window.clearInterval(timer);
  }, [running]);

  const start = useCallback(() => {
    startedAt.current = Date.now();
    setSeconds(0);
    setRunning(true);
  }, []);

  const stop = useCallback(() => {
    const held = (Date.now() - startedAt.current) / 1000;
    setSeconds(held);
    setRunning(false);
    return held;
  }, []);

  return { seconds, running, start, stop };
}
