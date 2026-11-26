import PageHeader from "@/components/PageHeader";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import ChordLibrary from "@/features/music/ChordLibrary";
import FingerExercises from "@/features/music/FingerExercises";
import { GUITAR_TIPS } from "@/features/music/guitar-data";
import { SectionCard, TipsList } from "@/features/music/MusicParts";
import OneMinuteChanges from "@/features/music/OneMinuteChanges";
import StrummingPatterns from "@/features/music/StrummingPatterns";
import TunerPanel from "@/features/music/TunerPanel";
import { useMusicSummary } from "@/features/music/useMusicQueries";
import { useTabParam } from "@/features/music/useTabParam";

const TABS = ["chords", "fingers", "one-minute", "strum", "tuner", "tips"] as const;

export default function MusicGuitarPage() {
  const [tab, setTab] = useTabParam(TABS, "chords");
  // Records are optional here: the exercises work even when the summary fails.
  const summary = useMusicSummary();

  return (
    <div className="space-y-6">
      <PageHeader title="Ghi-ta" description="Hợp âm cơ bản, bài tập ngón và tiết tấu cho người mới. Mỗi bài chỉ cần vài phút mỗi ngày." />
      {/* Inactive tabs unmount, so the metronome and microphone stop when switching. */}
      <Tabs value={tab} onValueChange={setTab} className="gap-4">
        <TabsList className="flex w-full max-w-full justify-start overflow-x-auto [&>button]:shrink-0">
          <TabsTrigger value="chords">Hợp âm</TabsTrigger>
          <TabsTrigger value="fingers">Bài tập ngón</TabsTrigger>
          <TabsTrigger value="one-minute">Đổi hợp âm 1 phút</TabsTrigger>
          <TabsTrigger value="strum">Tiết tấu</TabsTrigger>
          <TabsTrigger value="tuner">Lên dây</TabsTrigger>
          <TabsTrigger value="tips">Mẹo</TabsTrigger>
        </TabsList>
        <TabsContent value="chords">
          <ChordLibrary />
        </TabsContent>
        <TabsContent value="fingers">
          <FingerExercises />
        </TabsContent>
        <TabsContent value="one-minute">
          <OneMinuteChanges best={summary.data?.bestBpmByExercise ?? []} />
        </TabsContent>
        <TabsContent value="strum">
          <StrummingPatterns />
        </TabsContent>
        <TabsContent value="tuner">
          <SectionCard title="Lên dây" description="Chuẩn: E2 A2 D3 G3 B3 E4 (dây 6 → 1). Gảy từng dây buông, chỉnh tới khi kim vào giữa.">
            <TunerPanel initialMode="guitar" />
          </SectionCard>
        </TabsContent>
        <TabsContent value="tips">
          <TipsList tips={GUITAR_TIPS} />
        </TabsContent>
      </Tabs>
    </div>
  );
}
