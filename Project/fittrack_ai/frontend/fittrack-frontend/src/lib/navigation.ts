import type { ElementType } from "react";
import {
  Apple,
  Bell,
  BellRing,
  BookHeart,
  CalendarDays,
  Carrot,
  ChefHat,
  CircleHelp,
  ClipboardList,
  Dumbbell,
  FileBarChart,
  FileText,
  GitCompareArrows,
  Goal,
  Guitar,
  HeartPulse,
  KeyRound,
  LayoutDashboard,
  Library,
  ListTodo,
  LogOut,
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
  /**
   * Extra search terms (unaccented or accented) so users find a module by what it does:
   * synonyms, English words, common spellings. Put the most characteristic terms first;
   * earlier keywords rank slightly higher when two pages match equally.
   */
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
      { to: "/dashboard", label: "Tổng quan", icon: LayoutDashboard, keywords: "hom nay trang chu home dashboard tong hop man hinh chinh" },
      {
        to: "/lunch",
        label: "Đặt cơm",
        icon: Soup,
        highlight: true,
        feature: "lunchEnabled",
        keywords: "com trua an trua menu thuc don com goi mon order lunch suat com thanh toan qr chuyen khoan quy no tien com",
      },
    ],
  },
  {
    id: "work",
    label: "Công việc & thời gian",
    icon: ListTodo,
    tabs: true,
    items: [
      { to: "/todos", label: "Việc cần làm", icon: ListTodo, feature: "todoEnabled", keywords: "todo to do list task nhiem vu cong viec nhac viec deadline han chot checklist ghi chu viec" },
      { to: "/habits", label: "Thói quen", icon: Repeat, feature: "todoEnabled", keywords: "habit thoi quen hang ngay heatmap chuoi ngay streak" },
      { to: "/focus", label: "Tập trung", icon: Timer, feature: "todoEnabled", keywords: "pomodoro focus tap trung hen gio bam gio dem nguoc dong ho timer" },
      { to: "/schedule", label: "Thời khóa biểu", icon: CalendarDays, feature: "scheduleEnabled", keywords: "lich lich hoc lich hen tkb calendar su kien schedule nhac lich thoi gian bieu" },
    ],
  },
  {
    id: "training",
    label: "Luyện tập",
    icon: Dumbbell,
    tabs: true,
    items: [
      { to: "/workouts", label: "Buổi tập", icon: Dumbbell, feature: "fitnessEnabled", keywords: "tap gym workout session tap luyen the duc the hinh chay bo cardio ghi buoi tap" },
      { to: "/workout-plans", label: "Giáo án", icon: ClipboardList, feature: "fitnessEnabled", keywords: "lich tap giao an plan chuong trinh tap ke hoach tap routine" },
      { to: "/exercises", label: "Kho bài tập", icon: Library, feature: "fitnessEnabled", keywords: "bai tap exercise thu vien dong tac" },
      { to: "/training-goals", label: "Mục tiêu luyện tập", icon: Target, feature: "fitnessEnabled", keywords: "ky luc pr muc tieu tap goal personal record" },
      { to: "/training-comparison", label: "So sánh luyện tập", icon: GitCompareArrows, feature: "fitnessEnabled", keywords: "so sanh compare tien bo giai doan thong ke tap" },
      { to: "/achievements", label: "Thành tích", icon: Trophy, feature: "fitnessEnabled", keywords: "huy hieu thanh tich achievement badge phan thuong" },
    ],
  },
  {
    id: "nutrition",
    label: "Dinh dưỡng",
    icon: Apple,
    tabs: true,
    items: [
      {
        to: "/nutrition",
        label: "Nhật ký ăn uống",
        icon: Apple,
        feature: "healthEnabled",
        keywords: "an uong calo calories kcal bua an protein dam macro uong nuoc nutrition ghi bua an",
      },
      { to: "/meal-planning", label: "Thực đơn & danh sách mua", icon: ChefHat, feature: "healthEnabled", keywords: "thuc don di cho danh sach mua meal plan shopping list ke hoach an" },
      { to: "/pantry", label: "Tủ thực phẩm", icon: Refrigerator, feature: "healthEnabled", keywords: "tu lanh het han han su dung pantry kho do an ton kho" },
      {
        to: "/purchase-prices",
        label: "Giá mua & chi phí",
        icon: Receipt,
        feature: "healthEnabled",
        visible: (user) => canUseFeature(user, "financeEnabled"),
        keywords: "gia mua chi phi an uong gia thuc pham price",
      },
      { to: "/foods", label: "Kho thực phẩm", icon: Carrot, feature: "healthEnabled", keywords: "mon an thuc pham food database dinh duong mon" },
    ],
  },
  {
    id: "health",
    label: "Sức khỏe & cơ thể",
    icon: HeartPulse,
    tabs: true,
    items: [
      { to: "/health", label: "Sức khỏe toàn diện", icon: HeartPulse, keywords: "suc khoe health diem suc khoe goi y nhac uong nuoc nhac nho", feature: "healthEnabled" },
      { to: "/body", label: "Chỉ số cơ thể", icon: Scale, feature: "healthEnabled", keywords: "can nang bmi vong eo so do weight body chi so co the anh tien do" },
      { to: "/personal-goals", label: "Mục tiêu sức khỏe", icon: Goal, feature: "healthEnabled", keywords: "giam can tang can muc tieu goal" },
      { to: "/recovery", label: "Giấc ngủ & phục hồi", icon: Moon, feature: "healthEnabled", keywords: "ngu giac ngu sleep phuc hoi recovery nghi ngoi" },
      { to: "/reports/weekly", label: "Báo cáo tuần", icon: FileBarChart, feature: "healthEnabled", keywords: "bao cao tuan weekly report tong ket tuan" },
    ],
  },
  {
    id: "finance",
    label: "Tài chính",
    icon: WalletCards,
    tabs: true,
    items: [
      {
        to: "/finance",
        label: "Thu chi & ngân sách",
        icon: WalletCards,
        feature: "financeEnabled",
        keywords: "tien chi tieu thu chi ngan sach giao dich vi money finance budget luong thu nhap chi phi so thu chi dinh ky",
      },
      { to: "/finance/savings", label: "Mục tiêu tiết kiệm", icon: PiggyBank, feature: "financeEnabled", keywords: "tiet kiem heo dat saving de danh quy" },
      { to: "/finance/shared", label: "Chi tiêu chung", icon: UsersRound, feature: "financeEnabled", keywords: "chia tien cong no no nhau chi tieu nhom shared" },
    ],
  },
  {
    id: "mind",
    label: "Tinh thần",
    icon: Sparkles,
    tabs: true,
    items: [
      { to: "/journal", label: "Nhật ký", icon: BookHeart, feature: "journalEnabled", keywords: "nhat ky nhat ki journal diary tam trang cam xuc viet" },
      { to: "/quotes", label: "Câu nói", icon: Quote, feature: "quoteEnabled", keywords: "cau noi trich dan dong luc quote danh ngon" },
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
      { to: "/profile", label: "Hồ sơ cá nhân", icon: User, keywords: "ho so cai dat tai khoan profile settings thong tin chieu cao email" },
      {
        to: "/reports/monthly",
        label: "Báo cáo tháng",
        icon: FileText,
        visible: (user) => (["fitnessEnabled", "healthEnabled", "todoEnabled", "financeEnabled"] as const).some((flag) => canUseFeature(user, flag)),
        keywords: "bao cao thang xuat pdf in report tong ket thang",
      },
      {
        to: "/template-sharing",
        label: "Chia sẻ bản mẫu",
        icon: Share2,
        visible: (user) => canUseFeature(user, "fitnessEnabled") || canUseFeature(user, "healthEnabled"),
        keywords: "chia se mau template share",
      },
    ],
  },
  {
    id: "admin",
    label: "Quản trị",
    icon: ShieldCheck,
    tabs: true,
    items: [
      { to: "/admin/lunch", label: "Điều phối cơm", icon: ShieldCheck, adminOnly: true, keywords: "dieu phoi admin quy com menu" },
      { to: "/admin/users", label: "Quản lý tài khoản", icon: UserCog, adminOnly: true, keywords: "phan quyen nguoi dung user admin tai khoan thanh vien" },
      { to: "/admin/notifications", label: "Gửi thông báo", icon: BellRing, adminOnly: true, keywords: "gui thong bao admin notification" },
      { to: "/admin/notification-playbooks", label: "Kịch bản thông báo", icon: Workflow, adminOnly: true, keywords: "kich ban playbook admin notification tu dong" },
      { to: "/admin/journal-prompts", label: "Câu hỏi nhật ký", icon: MessageSquareQuote, adminOnly: true, keywords: "admin journal prompt cau hoi" },
    ],
  },
];

/** Actions that are not pages of their own but users look for by name in search. */
export type NavCommandId = "logout" | "help" | "change-password" | "notifications";

export type NavCommand = {
  id: NavCommandId;
  label: string;
  icon: ElementType;
  keywords: string;
  /** Route for commands that simply open a page; the others are handled by the caller. */
  to?: string;
};

export const navCommands: NavCommand[] = [
  { id: "logout", label: "Đăng xuất", icon: LogOut, keywords: "dang xuat thoat logout sign out log out" },
  { id: "change-password", label: "Đổi mật khẩu", icon: KeyRound, keywords: "mat khau doi mat khau password bao mat", to: "/change-password" },
  { id: "help", label: "Hướng dẫn sử dụng", icon: CircleHelp, keywords: "huong dan tro giup help cach dung guide" },
  { id: "notifications", label: "Thông báo qua email", icon: Bell, keywords: "thong bao nhac nho email notification bat tat cai dat", to: "/profile" },
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

/**
 * Lowercase, strip Vietnamese diacritics (đ → d), turn punctuation into spaces and
 * collapse whitespace, so "  Tài   CHÍNH!! " matches "Tài chính".
 */
export function normalizeSearch(text: string): string {
  return text
    .toLowerCase()
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .replace(/đ/g, "d")
    .replace(/[^a-z0-9]+/g, " ")
    .trim();
}

export type NavMatch = { item: NavItem; group: NavGroup };
export type SearchResult = ({ kind: "page" } & NavMatch) | { kind: "command"; command: NavCommand };

/** Filler words people type around the real term ("mở trang đặt cơm", "quản lý chi tiêu"). */
const STOP_WORDS = new Set(["xem", "mo", "vao", "trang", "man", "hinh", "chuc", "cua", "toi", "minh", "quan", "ly", "theo", "doi", "cac", "nhung", "va", "o", "de", "cho", "phan", "muc", "tim"]);

type Field = { tokens: string[]; compact: string; text: string; weight: number; ordered: boolean };
type Candidate = { result: SearchResult; label: string; fields: Field[]; order: number };

const field = (text: string, weight: number, ordered = false): Field => {
  const normalized = normalizeSearch(text);
  return { tokens: normalized ? normalized.split(" ") : [], compact: normalized.replace(/ /g, ""), text: normalized, weight, ordered };
};

/** Optimal-string-alignment distance (Levenshtein plus adjacent swaps), capped for speed. */
function editDistance(a: string, b: string, max: number): number {
  if (Math.abs(a.length - b.length) > max) return max + 1;
  const rows: number[][] = Array.from({ length: a.length + 1 }, (_, i) => [i, ...Array<number>(b.length).fill(0)]);
  for (let j = 1; j <= b.length; j++) rows[0][j] = j;
  for (let i = 1; i <= a.length; i++) {
    for (let j = 1; j <= b.length; j++) {
      const cost = a[i - 1] === b[j - 1] ? 0 : 1;
      rows[i][j] = Math.min(rows[i - 1][j] + 1, rows[i][j - 1] + 1, rows[i - 1][j - 1] + cost);
      if (i > 1 && j > 1 && a[i - 1] === b[j - 2] && a[i - 2] === b[j - 1]) rows[i][j] = Math.min(rows[i][j], rows[i - 2][j - 2] + 1);
    }
  }
  return rows[a.length][b.length];
}

/** Lower is better; null when the word does not match this field. */
function wordScore(word: string, target: Field, typos: boolean): number | null {
  let best: number | null = null;
  const consider = (kind: number, index: number) => {
    const score = kind * 3 + target.weight + (target.ordered ? Math.min(index, 20) * 0.02 : 0);
    if (best === null || score < best) best = score;
  };
  target.tokens.forEach((token, index) => {
    if (token === word) consider(0, index);
    else if (token.startsWith(word)) consider(1, index);
  });
  // Words typed without spaces ("datcom", "thoiquen") or the middle of a word.
  if (best === null && word.length >= 4 && target.compact.includes(word)) consider(2, 0);
  if (best === null && typos && word.length >= 4) {
    const max = word.length >= 7 ? 2 : 1;
    target.tokens.forEach((token, index) => {
      const close = editDistance(word, token, max) <= max || (token.length > word.length && editDistance(word, token.slice(0, word.length), max) <= max);
      if (close) consider(3, index);
    });
  }
  return best;
}

const TYPO_SCORE = 9;

function scoreCandidate(candidate: Candidate, words: string[], typos: boolean): { score: number; matched: number; fuzzy: number } {
  let score = 0;
  let matched = 0;
  let fuzzy = 0;
  for (const word of words) {
    let best: number | null = null;
    for (const target of candidate.fields) {
      const value = wordScore(word, target, typos);
      if (value !== null && (best === null || value < best)) best = value;
    }
    if (best === null) score += 100;
    else {
      score += best;
      matched += 1;
      if (best >= TYPO_SCORE) fuzzy += 1;
    }
  }
  // Whole-phrase bonuses: the label itself, then a keyword phrase.
  const phrase = words.join(" ");
  if (candidate.label === phrase) score -= 6;
  else if (candidate.label.startsWith(phrase)) score -= 4;
  else if (` ${candidate.label} `.includes(` ${phrase} `)) score -= 3;
  else if (words.length > 1 && candidate.fields.some((target) => ` ${target.text} `.includes(` ${phrase} `))) score -= 2;
  return { score, matched, fuzzy };
}

function rank(candidates: Candidate[], query: string): SearchResult[] {
  const allWords = normalizeSearch(query).split(" ").filter(Boolean);
  if (!allWords.length) return candidates.map((candidate) => candidate.result);
  const content = allWords.filter((word) => !STOP_WORDS.has(word));
  const words = content.length ? content : allWords;

  const pick = (terms: string[], typos: boolean, minMatched: number) =>
    candidates
      .map((candidate) => ({ candidate, ...scoreCandidate(candidate, terms, typos) }))
      .filter((entry) => entry.matched >= minMatched)
      .sort((a, b) => b.matched - a.matched || a.fuzzy - b.fuzzy || a.score - b.score || a.candidate.order - b.candidate.order);

  // Strictest first: every word as typed, then without filler words, then with typo tolerance.
  const tiers: [string[], boolean][] = [
    [allWords, false],
    [words, false],
    [words, true],
  ];
  for (const [terms, typos] of tiers) {
    const found = pick(terms, typos, terms.length);
    if (found.length) return found.map((entry) => entry.candidate.result);
  }
  // Last resort for longer queries: pages matching most of the words.
  if (words.length >= 2) {
    const partial = pick(words, true, Math.ceil(words.length / 2));
    const most = partial[0]?.matched ?? 0;
    return partial.filter((entry) => entry.matched === most).map((entry) => entry.candidate.result);
  }
  return [];
}

function pageCandidates(groups: NavGroup[]): Candidate[] {
  let order = 0;
  return groups.flatMap((group) =>
    group.items.map((item) => ({
      result: { kind: "page" as const, item, group },
      label: normalizeSearch(item.label),
      fields: [field(item.label, 0), field(item.keywords ?? "", 1, true), field(group.label, 2)],
      order: order++,
    })),
  );
}

function commandCandidates(commands: NavCommand[], offset: number): Candidate[] {
  return commands.map((command, index) => ({
    result: { kind: "command" as const, command },
    label: normalizeSearch(command.label),
    fields: [field(command.label, 0), field(command.keywords, 1, true)],
    order: offset + index,
  }));
}

/**
 * Find pages by label, group or keywords. Ignores accents, case, punctuation and filler
 * words; matches word prefixes ("pomodor"), words typed together ("datcom") and, when
 * nothing else matches, small typos ("guiter").
 */
export function searchNav(groups: NavGroup[], query: string): NavMatch[] {
  return rank(pageCandidates(groups), query).flatMap((result) => (result.kind === "page" ? [{ item: result.item, group: result.group }] : []));
}

/** Pages and commands (logout, help, change password…) ranked together. Empty query returns pages only. */
export function searchAll(groups: NavGroup[], query: string, commands: NavCommand[] = navCommands): SearchResult[] {
  const pages = pageCandidates(groups);
  if (!normalizeSearch(query)) return pages.map((candidate) => candidate.result);
  return rank([...pages, ...commandCandidates(commands, pages.length)], query);
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
