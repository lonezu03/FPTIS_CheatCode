import { useCallback, useEffect, useRef, useState } from "react";
import { getAudioContextCtor } from "./metronome-engine";
import { nearestNote, type NearestNote } from "./music-theory";
import { detectPitch, median } from "./pitch-detection";

export type TunerStatus = "idle" | "starting" | "listening" | "error";

export type TunerReading = NearestNote & { frequency: number };

export type TunerRange = { minFrequency: number; maxFrequency: number };

export const GUITAR_RANGE: TunerRange = { minFrequency: 70, maxFrequency: 1000 };
export const FLUTE_RANGE: TunerRange = { minFrequency: 400, maxFrequency: 2200 };

const ANALYSIS_INTERVAL_MS = 60;
const SMOOTHING = 5;
/** Drop the reading after this long without a clear pitch. */
const HOLD_MS = 600;

/** Explains a getUserMedia failure in plain Vietnamese. */
export function microphoneErrorMessage(error: unknown): string {
  const name = error instanceof DOMException || error instanceof Error ? error.name : "";
  switch (name) {
    case "NotAllowedError":
    case "PermissionDeniedError":
    case "SecurityError":
      return "Bạn chưa cho phép dùng micro. Bấm biểu tượng ổ khóa cạnh địa chỉ trang, cho phép Micro rồi thử lại.";
    case "NotFoundError":
    case "DevicesNotFoundError":
      return "Không tìm thấy micro. Hãy cắm tai nghe có micro hoặc dùng điện thoại.";
    case "NotReadableError":
    case "TrackStartError":
      return "Micro đang bị ứng dụng khác dùng (Zoom, Teams…). Đóng ứng dụng đó rồi thử lại.";
    default:
      return "Không mở được micro. Hãy thử lại hoặc dùng trình duyệt khác.";
  }
}

export function microphoneSupported(): boolean {
  return typeof navigator !== "undefined" && !!navigator.mediaDevices?.getUserMedia && typeof window !== "undefined" && window.isSecureContext !== false;
}

/**
 * Microphone pitch tracker. The microphone is released on stop(), when the page
 * is hidden and when the component unmounts.
 */
export function useTuner(range: TunerRange, onReading?: (reading: TunerReading | null) => void) {
  const [status, setStatus] = useState<TunerStatus>("idle");
  const [error, setError] = useState<string | null>(null);
  const [reading, setReading] = useState<TunerReading | null>(null);
  const resources = useRef<{ stream: MediaStream; context: AudioContext; timer: number } | null>(null);
  const rangeRef = useRef(range);
  const onReadingRef = useRef(onReading);
  const startingRef = useRef(false);

  useEffect(() => {
    rangeRef.current = range;
    onReadingRef.current = onReading;
  }, [range, onReading]);

  const release = useCallback(() => {
    const current = resources.current;
    resources.current = null;
    if (!current) return;
    window.clearInterval(current.timer);
    current.stream.getTracks().forEach((track) => track.stop());
    if (current.context.state !== "closed") void current.context.close().catch(() => undefined);
  }, []);

  const stop = useCallback(() => {
    release();
    setReading(null);
    setStatus("idle");
  }, [release]);

  const start = useCallback(async () => {
    if (resources.current || startingRef.current) return;
    setError(null);
    const Ctor = getAudioContextCtor();
    if (!microphoneSupported() || !Ctor) {
      setStatus("error");
      setError("Trình duyệt này không cho dùng micro. Hãy mở trang bằng https trên Chrome, Edge hoặc Safari mới.");
      return;
    }
    startingRef.current = true;
    setStatus("starting");
    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        audio: { echoCancellation: false, noiseSuppression: false, autoGainControl: false },
      });
      const context = new Ctor();
      if (context.state === "suspended") await context.resume();
      const analyser = context.createAnalyser();
      analyser.fftSize = 4096;
      context.createMediaStreamSource(stream).connect(analyser);
      const buffer = new Float32Array(analyser.fftSize);
      const recent: number[] = [];
      let lastHeard = 0;
      const timer = window.setInterval(() => {
        analyser.getFloatTimeDomainData(buffer);
        const result = detectPitch(buffer, context.sampleRate, rangeRef.current);
        const now = performance.now();
        if (result) {
          // A jump of more than a semitone from the running median restarts smoothing.
          const current = median(recent);
          if (current && Math.abs(12 * Math.log2(result.frequency / current)) > 1) recent.length = 0;
          recent.push(result.frequency);
          if (recent.length > SMOOTHING) recent.shift();
          const frequency = median(recent)!;
          lastHeard = now;
          const next = { ...nearestNote(frequency), frequency };
          setReading(next);
          onReadingRef.current?.(next);
        } else if (now - lastHeard > HOLD_MS) {
          recent.length = 0;
          setReading(null);
          onReadingRef.current?.(null);
        }
      }, ANALYSIS_INTERVAL_MS);
      resources.current = { stream, context, timer };
      setStatus("listening");
    } catch (cause) {
      release();
      setStatus("error");
      setError(microphoneErrorMessage(cause));
    } finally {
      startingRef.current = false;
    }
  }, [release]);

  // Free the microphone when the tab goes to the background or the page closes.
  useEffect(() => {
    const onHidden = () => {
      if (document.visibilityState === "hidden" && resources.current) stop();
    };
    document.addEventListener("visibilitychange", onHidden);
    return () => {
      document.removeEventListener("visibilitychange", onHidden);
      release();
    };
  }, [release, stop]);

  return { status, error, reading, start, stop, listening: status === "listening" };
}
