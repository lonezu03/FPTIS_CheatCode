import { useCallback, useEffect, useRef, useState } from "react";
import { clampBpm, MetronomeEngine, tapTempo, type Tick } from "./metronome-engine";

export type MetronomeOptions = { bpm?: number; beatsPerBar?: number; subdivision?: number };

export type MetronomeControls = ReturnType<typeof useMetronome>;

/** React wrapper around MetronomeEngine. Audio stops when the component unmounts. */
export function useMetronome(initial: MetronomeOptions = {}) {
  const [bpm, setBpmState] = useState(clampBpm(initial.bpm ?? 60));
  const [beatsPerBar, setBeatsPerBar] = useState(initial.beatsPerBar ?? 4);
  const [subdivision, setSubdivision] = useState(initial.subdivision ?? 1);
  const [accent, setAccent] = useState(true);
  const [running, setRunning] = useState(false);
  const [tick, setTick] = useState<Tick | null>(null);
  const [error, setError] = useState<string | null>(null);
  const engineRef = useRef<MetronomeEngine | null>(null);
  const tapsRef = useRef<number[]>([]);
  const settings = { bpm, beatsPerBar, subdivision, accent, volume: 0.6 };
  const settingsRef = useRef(settings);

  useEffect(() => {
    settingsRef.current = { bpm, beatsPerBar, subdivision, accent, volume: 0.6 };
    engineRef.current?.update(settingsRef.current);
  }, [bpm, beatsPerBar, subdivision, accent]);

  useEffect(
    () => () => {
      void engineRef.current?.dispose();
      engineRef.current = null;
    },
    [],
  );

  const start = useCallback(async () => {
    setError(null);
    try {
      engineRef.current ??= new MetronomeEngine(settingsRef.current, setTick);
      engineRef.current.update(settingsRef.current);
      await engineRef.current.start();
      setRunning(true);
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : "Không phát được âm thanh.");
      setRunning(false);
    }
  }, []);

  const stop = useCallback(() => {
    engineRef.current?.stop();
    setRunning(false);
    setTick(null);
  }, []);

  const toggle = useCallback(() => (engineRef.current?.running ? stop() : void start()), [start, stop]);

  const setBpm = useCallback((value: number) => setBpmState(clampBpm(value)), []);

  const tap = useCallback(() => {
    const result = tapTempo([...tapsRef.current, performance.now()]);
    tapsRef.current = result.taps;
    if (result.bpm) setBpmState(result.bpm);
    return result.bpm;
  }, []);

  return { bpm, setBpm, beatsPerBar, setBeatsPerBar, subdivision, setSubdivision, accent, setAccent, running, start, stop, toggle, tick, tap, error };
}
