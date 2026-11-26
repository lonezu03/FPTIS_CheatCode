import type { Chord } from "./guitar-data";

const STRING_GAP = 22;
const FRET_GAP = 28;
const LEFT = 22;
const TOP = 34;
const FRETS = 4;

/**
 * Standard chord box: strings vertical (6 on the left), nut on top,
 * × = do not play, ○ = open string, dots carry the finger number.
 */
export default function ChordDiagram({ chord, size = 150 }: { chord: Chord; size?: number }) {
  const width = LEFT * 2 + STRING_GAP * 5;
  const height = TOP + FRET_GAP * FRETS + 26;
  const x = (stringIndex: number) => LEFT + stringIndex * STRING_GAP;
  const y = (fret: number) => TOP + (fret - 0.5) * FRET_GAP;
  const barre = chord.barre;
  const description = chord.frets
    .map((fret, index) => `dây ${6 - index}: ${fret < 0 ? "không đánh" : fret === 0 ? "buông" : `ngăn ${fret} ngón ${chord.fingers[index]}`}`)
    .join(", ");

  return (
    <svg
      viewBox={`0 0 ${width} ${height}`}
      width={size}
      height={(size * height) / width}
      role="img"
      aria-label={`Hợp âm ${chord.name}: ${description}`}
      className="text-foreground"
    >
      {/* Nut and frets */}
      <rect x={x(0)} y={TOP - 4} width={STRING_GAP * 5} height={5} rx={1.5} fill="currentColor" />
      {Array.from({ length: FRETS }, (_, index) => (
        <line key={index} x1={x(0)} x2={x(5)} y1={TOP + (index + 1) * FRET_GAP} y2={TOP + (index + 1) * FRET_GAP} stroke="currentColor" strokeOpacity={0.35} strokeWidth={1.5} />
      ))}
      {/* Strings: thicker for bass */}
      {[0, 1, 2, 3, 4, 5].map((index) => (
        <line key={index} x1={x(index)} x2={x(index)} y1={TOP} y2={TOP + FRETS * FRET_GAP} stroke="currentColor" strokeOpacity={0.6} strokeWidth={2.2 - index * 0.25} />
      ))}
      {/* Open / muted markers */}
      {chord.frets.map((fret, index) =>
        fret === 0 ? (
          <circle key={index} cx={x(index)} cy={TOP - 16} r={5.5} fill="none" stroke="currentColor" strokeWidth={1.6} />
        ) : fret < 0 ? (
          <text key={index} x={x(index)} y={TOP - 11} textAnchor="middle" fontSize={14} fontWeight={600} fill="#dc2626">
            ×
          </text>
        ) : null,
      )}
      {barre && (
        <rect
          x={x(6 - barre.toString) - 8}
          y={y(barre.fret) - 8}
          width={x(6 - barre.fromString) - x(6 - barre.toString) + 16}
          height={16}
          rx={8}
          className="fill-emerald-600"
        />
      )}
      {chord.frets.map((fret, index) =>
        fret > 0 ? (
          <g key={index}>
            <circle cx={x(index)} cy={y(fret)} r={8.5} className="fill-emerald-600" />
            <text x={x(index)} y={y(fret) + 4} textAnchor="middle" fontSize={11} fontWeight={700} fill="#fff">
              {chord.fingers[index]}
            </text>
          </g>
        ) : null,
      )}
      {/* String numbers under the box */}
      {[6, 5, 4, 3, 2, 1].map((string, index) => (
        <text key={string} x={x(index)} y={TOP + FRETS * FRET_GAP + 16} textAnchor="middle" fontSize={9} fill="currentColor" fillOpacity={0.5}>
          {string}
        </text>
      ))}
    </svg>
  );
}
