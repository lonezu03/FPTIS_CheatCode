import PageHeader from "@/components/PageHeader";
import MetronomePanel from "@/features/music/MetronomePanel";
import { SectionCard } from "@/features/music/MusicParts";
import TunerPanel from "@/features/music/TunerPanel";
import { useMetronome } from "@/features/music/useMetronome";

export default function MusicToolsPage() {
  const metronome = useMetronome({ bpm: 60, beatsPerBar: 4 });
  return (
    <div className="space-y-6">
      <PageHeader title="Máy đếm nhịp & lên dây" description="Dùng chung cho ghi-ta và sáo. Âm thanh và micro tự tắt khi rời trang." />
      <div className="grid gap-6 lg:grid-cols-2">
        <SectionCard title="Máy đếm nhịp" description="40–208 BPM. Gõ nhịp: bấm đều theo bài hát để lấy tốc độ.">
          <MetronomePanel metronome={metronome} />
        </SectionCard>
        <SectionCard title="Lên dây / kiểm tra cao độ" description="Ghi-ta: E2 A2 D3 G3 B3 E4. Sáo: nốt gần nhất và độ lệch cent.">
          <TunerPanel initialMode="guitar" allowModeSwitch />
        </SectionCard>
      </div>
    </div>
  );
}
