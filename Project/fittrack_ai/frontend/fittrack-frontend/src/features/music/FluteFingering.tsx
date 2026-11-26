import { useId } from "react";
import { cn } from "@/lib/utils";
import type { FluteNote } from "./flute-data";

/**
 * Horizontal bamboo flute: mouth hole (lỗ thổi) on the left, finger holes 1 → 6
 * to the right. Filled hole = covered (bịt), empty = open (mở).
 */
export default function FluteFingering({ note, compact = false, className }: { note: FluteNote; compact?: boolean; className?: string }) {
  const gradientId = `bamboo-${useId().replace(/[^a-zA-Z0-9_-]/g, "")}`;
  const width = 340;
  const height = compact ? 64 : 78;
  const mid = 32;
  const holeX = (hole: number) => 118 + (hole - 1) * 34;
  const label = note.covered.map((covered, index) => `lỗ ${index + 1} ${covered ? "bịt" : "mở"}`).join(", ");

  return (
    <svg viewBox={`0 0 ${width} ${height}`} role="img" aria-label={`Thế bấm ${note.solfege}: ${label}`} className={cn("h-auto w-full max-w-[340px]", className)}>
      <defs>
        <linearGradient id={gradientId} x1="0" x2="0" y1="0" y2="1">
          <stop offset="0" stopColor="#f3dca4" />
          <stop offset="0.55" stopColor="#e2bf74" />
          <stop offset="1" stopColor="#c99a4b" />
        </linearGradient>
      </defs>
      <rect x={6} y={mid - 14} width={width - 12} height={28} rx={14} fill={`url(#${gradientId})`} stroke="#a87a35" strokeWidth={1.2} />
      {/* Bamboo nodes */}
      <rect x={82} y={mid - 14} width={4} height={28} fill="#b68840" opacity={0.6} />
      <rect x={width - 40} y={mid - 14} width={4} height={28} fill="#b68840" opacity={0.6} />
      {/* Mouth hole */}
      <ellipse cx={50} cy={mid} rx={8} ry={6} fill="#3f2a10" />
      <text x={50} y={mid + 28} textAnchor="middle" fontSize={10} fill="currentColor" fillOpacity={0.6}>
        lỗ thổi
      </text>
      {note.covered.map((covered, index) => (
        <g key={index}>
          <circle cx={holeX(index + 1)} cy={mid} r={9} fill={covered ? "#1f2937" : "#fff8e6"} stroke="#3f2a10" strokeWidth={2} />
          <text x={holeX(index + 1)} y={mid + 28} textAnchor="middle" fontSize={11} fontWeight={600} fill="currentColor" fillOpacity={0.75}>
            {index + 1}
          </text>
        </g>
      ))}
    </svg>
  );
}
