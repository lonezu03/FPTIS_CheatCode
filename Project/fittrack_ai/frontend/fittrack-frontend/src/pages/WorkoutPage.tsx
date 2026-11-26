import WorkoutWorkspace from "@/features/workout/WorkoutWorkspace";
import { useAuthStore } from "@/store/auth.store";

export default function WorkoutPage() {
  const owner = useAuthStore((state) => state.user?.userId ?? "");
  // Đổi tài khoản thì dựng lại toàn bộ để bản nháp buổi tập không lẫn giữa người dùng.
  return <WorkoutWorkspace key={owner} owner={owner} />;
}
