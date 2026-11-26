import type { ElementType } from "react";
import {
  Apple,
  BellRing,
  BookHeart,
  CalendarDays,
  Carrot,
  ChefHat,
  ClipboardList,
  Dumbbell,
  FileBarChart,
  FileText,
  GitCompareArrows,
  Goal,
  Guitar,
  HeartPulse,
  LayoutDashboard,
  Library,
  ListTodo,
  Music,
  MessageSquareQuote,
  Moon,
  PiggyBank,
  Quote,
  Receipt,
  Refrigerator,
  Repeat,
  Scale,
  Share2,
  ShieldCheck,
  Soup,
  Sparkles,
  Target,
  Timer,
  Trophy,
  User,
  Wind,
  UserCog,
  UsersRound,
  WalletCards,
  Workflow,
} from "lucide-react";
import type { AuthUser } from "@/store/auth.store";
import { canUseFeature, type FeaturePermission } from "@/lib/feature-access";

export type NavItem = {
  to: string;
  label: string;
  icon: ElementType;
  /** Extra search terms (unaccented or accented) so users find a module by what it does. */
  keywords?: string;
  adminOnly?: boolean;
  highlight?: boolean;
  feature?: FeaturePermission;
  /** Additional visibility rule; never an authorization boundary (the API enforces access). */
  visible?: (user: AuthUser | null) => boolean;
};

export type NavGroup = {
  id: string;
  label: string;
  icon: ElementType;
  /** Show sibling pages as tabs above the page content. */
  tabs?: boolean;
  items: NavItem[];
};

export const navGroups: NavGroup[] = [
  {
    id: "daily",
    label: "Hằng ngày",
    icon: LayoutDashboard,
    items: [
      { to: "/dashboard", label: "Tổng quan", icon: LayoutDashboard, keywords: "trang chu home hom nay dashboard" },
      { to: "/lunch", label: "Đặt cơm", icon: Soup, highlight: true, feature: "lunchEnabled", keywords: "com trua menu lunch order an trua quy no" },
    ],
  },
  {
    id: "work",
    label: "Công việc & thời gian",
    icon: ListTodo,
    tabs: true,
    items: [
      { to: "/todos", label: "Việc cần làm", icon: ListTodo, feature: "todoEnabled", keywords: "todo task cong viec nhiem vu" },
      { to: "/habits", label: "Thói quen", icon: Repeat, feature: "todoEnabled", keywords: "habit heatmap thoi quen hang ngay" },
      { to: "/focus", label: "Tập trung", icon: Timer, feature: "todoEnabled", keywords: "pomodoro focus dong ho hen gio" },
      { to: "/schedule", label: "Thời khóa biểu", icon: CalendarDays, feature: "scheduleEnabled", keywords: "lich schedule nhac viec calendar" },
    ],
  },
  {
    id: "training",
    label: "Luyện tập",
    icon: Dumbbell,
    tabs: true,
    items: [
      { to: "/workouts", label: "Buổi tập", icon: Dumbbell, feature: "fitnessEnabled", keywords: "workout gym tap luyen session" },
      { to: "/workout-plans", label: "Giáo án", icon: ClipboardList, feature: "fitnessEnabled", keywords: "plan lich tap chuong trinh" },
      { to: "/exercises", label: "Kho bài tập", icon: Library, feature: "fitnessEnabled", keywords: "exercise bai tap thu vien" },
      { to: "/training-goals", label: "Mục tiêu luyện tập", icon: Target, feature: "fitnessEnabled", keywords: "goal pr muc tieu tap" },
      { to: "/training-comparison", label: "So sánh luyện tập", icon: GitCompareArrows, feature: "fitnessEnabled", keywords: "compare so sanh tien bo giai doan" },
      { to: "/achievements", label: "Thành tích", icon: Trophy, feature: "fitnessEnabled", keywords: "achievement huy hieu badge" },
    ],
  },
  {
    id: "nutrition",
    label: "Dinh dưỡng",
    icon: Apple,
    tabs: true,
    items: [
      { to: "/nutrition", label: "Nhật ký ăn uống", icon: Apple, feature: "healthEnabled", keywords: "nutrition calo bua an an uong macro" },
      { to: "/meal-planning", label: "Thực đơn & danh sách mua", icon: ChefHat, feature: "healthEnabled", keywords: "meal plan thuc don di cho shopping" },
      { to: "/pantry", label: "Tủ thực phẩm", icon: Refrigerator, feature: "healthEnabled", keywords: "pantry tu lanh han su dung het han" },
      {
        to: "/purchase-prices",
        label: "Giá mua & chi phí",
        icon: Receipt,
        feature: "healthEnabled",
        visible: (user) => canUseFeature(user, "financeEnabled"),
        keywords: "gia mua chi phi thuc don price",
      },
      { to: "/foods", label: "Kho thực phẩm", icon: Carrot, feature: "healthEnabled", keywords: "food thuc pham mon an database" },
    ],
  },
  {
    id: "health",
    label: "Sức khỏe & cơ thể",
    icon: HeartPulse,
    tabs: true,
    items: [
      { to: "/health", label: "Sức khỏe toàn diện", icon: HeartPulse, feature: "healthEnabled", keywords: "health diem suc khoe goi y" },
      { to: "/body", label: "Chỉ số cơ thể", icon: Scale, feature: "healthEnabled", keywords: "can nang body bmi so do vong eo" },
      { to: "/personal-goals", label: "Mục tiêu sức khỏe", icon: Goal, feature: "healthEnabled", keywords: "goal muc tieu giam can" },
      { to: "/recovery", label: "Giấc ngủ & phục hồi", icon: Moon, feature: "healthEnabled", keywords: "sleep ngu phuc hoi recovery" },
      { to: "/reports/weekly", label: "Báo cáo tuần", icon: FileBarChart, feature: "healthEnabled", keywords: "report bao cao tuan weekly" },
    ],
  },
  {
    id: "finance",
    label: "Tài chính",
    icon: WalletCards,
    tabs: true,
    items: [
      { to: "/finance", label: "Thu chi & ngân sách", icon: WalletCards, feature: "financeEnabled", keywords: "finance tien vi thu chi budget giao dich" },
      { to: "/finance/savings", label: "Mục tiêu tiết kiệm", icon: PiggyBank, feature: "financeEnabled", keywords: "saving tiet kiem heo dat" },
      { to: "/finance/shared", label: "Chi tiêu chung", icon: UsersRound, feature: "financeEnabled", keywords: "shared chia tien nhom cong no" },
    ],
  },
  {
    id: "mind",
    label: "Tinh thần",
    icon: Sparkles,
    tabs: true,
    items: [
      { to: "/journal", label: "Nhật ký", icon: BookHeart, feature: "journalEnabled", keywords: "journal nhat ky cam xuc viet" },
      { to: "/quotes", label: "Câu nói", icon: Quote, feature: "quoteEnabled", keywords: "quote cau noi trich dan dong luc" },
    ],
  },
  {
    id: "music",
    label: "Âm nhạc",
    icon: Music,
    tabs: true,
    items: [
      { to: "/music", label: "Luyện tập hôm nay", icon: Music, keywords: "am nhac nhac music luyen dan tap dan hang ngay chuoi streak" },
      { to: "/music/guitar", label: "Ghi-ta", icon: Guitar, keywords: "guitar ghi ta ghita dan hop am chord spider tiet tau quat cha" },
      { to: "/music/flute", label: "Sáo trúc C5", icon: Wind, keywords: "sao truc sao do flute the bam ngan dai not nhac" },
      { to: "/music/tools", label: "Đếm nhịp & lên dây", icon: Timer, keywords: "metronome dem nhip tuner chinh day len day cao do nhac cu dan sao" },
    ],
  },
  {
    id: "personal",
    label: "Cá nhân",
    icon: User,
    items: [
      { to: "/profile", label: "Hồ sơ cá nhân", icon: User, keywords: "profile tai khoan mat khau email cai dat" },
      {
        to: "/reports/monthly",
        label: "Báo cáo tháng",
        icon: FileText,
        visible: (user) => (["fitnessEnabled", "healthEnabled", "todoEnabled", "financeEnabled"] as const).some((flag) => canUseFeature(user, flag)),
        keywords: "report bao cao thang pdf in",
      },
      {
        to: "/template-sharing",
        label: "Chia sẻ bản mẫu",
        icon: Share2,
        visible: (user) => canUseFeature(user, "fitnessEnabled") || canUseFeature(user, "healthEnabled"),
        keywords: "share template chia se mau",
      },
    ],
  },
  {
    id: "admin",
    label: "Quản trị",
    icon: ShieldCheck,
    tabs: true,
    items: [
      { to: "/admin/lunch", label: "Điều phối cơm", icon: ShieldCheck, adminOnly: true, keywords: "admin com menu dieu phoi quy" },
      { to: "/admin/users", label: "Quản lý tài khoản", icon: UserCog, adminOnly: true, keywords: "admin user tai khoan phan quyen" },
      { to: "/admin/notifications", label: "Gửi thông báo", icon: BellRing, adminOnly: true, keywords: "admin notification thong bao" },
      { to: "/admin/notification-playbooks", label: "Kịch bản thông báo", icon: Workflow, adminOnly: true, keywords: "admin playbook notification kich ban" },
      { to: "/admin/journal-prompts", label: "Câu hỏi nhật ký", icon: MessageSquareQuote, adminOnly: true, keywords: "admin journal prompt cau hoi" },
    ],
  },
];

export function visibleNavGroups(user: AuthUser | null, isAdmin: boolean, groups: NavGroup[] = navGroups): NavGroup[] {
  return groups
    .map((group) => ({
      ...group,
      items: group.items.filter(
        (item) =>
          (!item.adminOnly || isAdmin) &&
          (!item.feature || canUseFeature(user, item.feature)) &&
          (!item.visible || item.visible(user)),
      ),
    }))
    .filter((group) => group.items.length > 0);
}

/** Lowercase and strip Vietnamese diacritics so "tai chinh" matches "Tài chính". */
export function normalizeSearch(text: string): string {
  return text
    .toLowerCase()
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .replace(/đ/g, "d")
    .replace(/\s+/g, " ")
    .trim();
}

export type NavMatch = { item: NavItem; group: NavGroup };

/** Every query word must appear in the label, group or keywords. Label-prefix matches rank first. */
export function searchNav(groups: NavGroup[], query: string): NavMatch[] {
  const q = normalizeSearch(query);
  if (!q) return groups.flatMap((group) => group.items.map((item) => ({ item, group })));
  const words = q.split(" ");
  const scored: { match: NavMatch; score: number; order: number }[] = [];
  let order = 0;
  for (const group of groups) {
    for (const item of group.items) {
      const label = normalizeSearch(item.label);
      const haystack = `${label} ${normalizeSearch(group.label)} ${normalizeSearch(item.keywords ?? "")}`;
      if (words.every((word) => haystack.includes(word))) {
        const score = label.startsWith(q) ? 0 : label.includes(q) ? 1 : 2;
        scored.push({ match: { item, group }, score, order: order++ });
      }
    }
  }
  return scored.sort((a, b) => a.score - b.score || a.order - b.order).map((entry) => entry.match);
}

/** Longest matching route wins, so /finance/savings is not reported as /finance. */
export function findActive(groups: NavGroup[], pathname: string): NavMatch | null {
  let best: NavMatch | null = null;
  for (const group of groups) {
    for (const item of group.items) {
      if ((pathname === item.to || pathname.startsWith(`${item.to}/`)) && (!best || item.to.length > best.item.to.length)) {
        best = { item, group };
      }
    }
  }
  return best;
}
