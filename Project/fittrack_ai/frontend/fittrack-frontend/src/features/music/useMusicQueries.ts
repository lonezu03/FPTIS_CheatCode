import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";

import { createMusicSession, deleteMusicSession, getMusicSessions, getMusicSummary, type MusicSessionInput } from "@/api/music.api";
import { getApiErrorMessage } from "@/lib/format";

export const MUSIC_QUERY_ROOT = "music";
export const RECENT_SESSIONS_SIZE = 10;

export function useMusicSummary() {
  return useQuery({ queryKey: [MUSIC_QUERY_ROOT, "summary"], queryFn: getMusicSummary });
}

export function useRecentMusicSessions(size = RECENT_SESSIONS_SIZE) {
  return useQuery({
    queryKey: [MUSIC_QUERY_ROOT, "sessions", { page: 0, size }],
    queryFn: () => getMusicSessions({ page: 0, size }),
  });
}

/** Creates a session, refreshes summary and lists. Errors (e.g. 400 "minutes: …") show as a toast. */
export function useLogMusicSession() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (input: MusicSessionInput) => createMusicSession(input),
    onSuccess: (session) => {
      toast.success(`Đã ghi ${session.minutes} phút luyện tập.`);
      void client.invalidateQueries({ queryKey: [MUSIC_QUERY_ROOT] });
    },
    onError: (error) => toast.error(getApiErrorMessage(error, "Không ghi được buổi tập.")),
  });
}

export function useDeleteMusicSession() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => deleteMusicSession(id),
    onSuccess: () => {
      toast.success("Đã xóa buổi tập.");
      void client.invalidateQueries({ queryKey: [MUSIC_QUERY_ROOT] });
    },
    onError: (error) => toast.error(getApiErrorMessage(error, "Không xóa được buổi tập.")),
  });
}
