import PageHeader from "@/components/PageHeader";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import FluteChart from "@/features/music/FluteChart";
import { FLUTE_TIPS } from "@/features/music/flute-data";
import FluteSongs from "@/features/music/FluteSongs";
import LongTones from "@/features/music/LongTones";
import { SectionCard, TipsList } from "@/features/music/MusicParts";
import NoteReadingDrill from "@/features/music/NoteReadingDrill";
import ScaleDrill from "@/features/music/ScaleDrill";
import TunerPanel from "@/features/music/TunerPanel";
import { useTabParam } from "@/features/music/useTabParam";

const TABS = ["fingering", "long-tones", "scale", "reading", "songs", "tuner", "tips"] as const;

export default function MusicFlutePage() {
  const [tab, setTab] = useTabParam(TABS, "fingering");

  return (
    <div className="space-y-6">
      <PageHeader title="Sáo trúc C5" description="Thế bấm sáo Đô 6 lỗ, ngân dài, thang âm và đọc nốt. Tiếng sáo đẹp đến từ hơi thở đều." />
      <Tabs value={tab} onValueChange={setTab} className="gap-4">
        <TabsList className="flex w-full max-w-full justify-start overflow-x-auto [&>button]:shrink-0">
          <TabsTrigger value="fingering">Thế bấm</TabsTrigger>
          <TabsTrigger value="long-tones">Ngân dài</TabsTrigger>
          <TabsTrigger value="scale">Thang âm</TabsTrigger>
          <TabsTrigger value="reading">Đọc nốt</TabsTrigger>
          <TabsTrigger value="songs">Bài dễ</TabsTrigger>
          <TabsTrigger value="tuner">Kiểm tra cao độ</TabsTrigger>
          <TabsTrigger value="tips">Mẹo</TabsTrigger>
        </TabsList>
        <TabsContent value="fingering">
          <FluteChart />
        </TabsContent>
        <TabsContent value="long-tones">
          <LongTones />
        </TabsContent>
        <TabsContent value="scale">
          <ScaleDrill />
        </TabsContent>
        <TabsContent value="reading">
          <NoteReadingDrill />
        </TabsContent>
        <TabsContent value="songs">
          <FluteSongs />
        </TabsContent>
        <TabsContent value="tuner">
          <SectionCard title="Kiểm tra cao độ" description="Thổi một nốt, app hiện nốt gần nhất và lệch bao nhiêu cent. Đô (C5) chuẩn = 523,25 Hz.">
            <TunerPanel initialMode="flute" />
          </SectionCard>
        </TabsContent>
        <TabsContent value="tips">
          <TipsList tips={FLUTE_TIPS} />
        </TabsContent>
      </Tabs>
    </div>
  );
}
