import { useMemo, useState, type ElementType } from "react";
import { useNavigate } from "react-router-dom";
import {
  Apple,
  BellRing,
  Bot,
  CalendarDays,
  CheckCircle2,
  ChevronLeft,
  ChevronRight,
  Dumbbell,
  LayoutDashboard,
  ListChecks,
  ShieldCheck,
  Soup,
  UserRound,
} from "lucide-react";

import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { canUseFeature, type FeaturePermission } from "@/lib/feature-access";
import type { AuthUser } from "@/store/auth.store";

type GuideVisual =
  | "navigation"
  | "lunch"
  | "todo"
  | "schedule"
  | "fitness"
  | "health"
  | "assistant"
  | "notifications"
  | "profile"
  | "admin";

type GuideStep = {
  title: string;
  description: string;
  action: string;
  visual: GuideVisual;
  focusLabel: string;
  route?: string;
};

type GuideModule = {
  id: string;
  title: string;
  summary: string;
  icon: ElementType;
  feature?: FeaturePermission;
  adminOnly?: boolean;
  steps: GuideStep[];
};

const guideModules: GuideModule[] = [
  {
    id: "overview",
    title: "Bắt đầu với FitTrack",
    summary: "Nhận biết menu, quyền và màn hình tổng quan.",
    icon: LayoutDashboard,
    steps: [
      {
        title: "Chọn chức năng từ thanh điều hướng",
        description:
          "Menu chỉ hiển thị những module tài khoản đã được cấp. Nếu thiếu một mục cần dùng, hãy gửi yêu cầu cho quản trị viên thay vì dùng tài khoản khác.",
        action: "Nhấn tên hoặc biểu tượng của module để mở màn hình.",
        visual: "navigation",
        focusLabel: "Chọn module tại đây",
        route: "/dashboard",
      },
      {
        title: "Đọc nhanh tình trạng hôm nay",
        description:
          "Tổng quan ưu tiên dữ liệu thuộc quyền của bạn: đơn cơm, việc cần làm, buổi tập hoặc sức khỏe. Thẻ không có dữ liệu sẽ hướng dẫn bước cần làm tiếp theo.",
        action: "Nhấn vào thẻ gợi ý để đi đến chức năng liên quan.",
        visual: "health",
        focusLabel: "Thẻ tổng quan",
        route: "/dashboard",
      },
    ],
  },
  {
    id: "lunch",
    title: "Đặt cơm",
    summary: "Chọn menu, tạo nhiều phần và theo dõi quỹ/công nợ.",
    icon: Soup,
    feature: "lunchEnabled",
    steps: [
      {
        title: "Chọn đúng menu và người nhận",
        description:
          "Nếu hôm nay có nhiều quán, hãy chọn menu trước. Mỗi phần có thể đặt cho bạn hoặc đồng nghiệp; người nhận là người bị trừ quỹ hoặc ghi công nợ.",
        action: "Kiểm tra tên menu và người nhận trước khi chọn món.",
        visual: "lunch",
        focusLabel: "Menu & người nhận",
        route: "/lunch",
      },
      {
        title: "Chọn đủ món cho từng phần",
        description:
          "Cơm thường cần đúng 2 món phía trên dấu + và có thể chọn trùng món. Món đơn chỉ chọn 1 món phía dưới dấu +. Món thêm được cộng đúng theo giá niêm yết.",
        action: "Chọn món rồi nhấn “Thêm phần vào giỏ”.",
        visual: "lunch",
        focusLabel: "Vùng chọn món",
        route: "/lunch",
      },
      {
        title: "Kiểm tra giỏ và xác nhận",
        description:
          "Bạn có thể thêm nhiều phần rồi đặt cùng lúc. Thiếu quỹ không chặn đặt món; hệ thống dùng quỹ còn lại trước và ghi phần thiếu vào công nợ của người nhận.",
        action: "Đọc lại người nhận, món, món thêm và tổng tiền trước khi đặt.",
        visual: "lunch",
        focusLabel: "Giỏ đặt cơm",
        route: "/lunch",
      },
    ],
  },
  {
    id: "todos",
    title: "Việc cần làm",
    summary: "Tạo việc, hạn chót, nhắc nhở và checklist.",
    icon: ListChecks,
    feature: "todoEnabled",
    steps: [
      {
        title: "Tạo việc với thời gian rõ ràng",
        description:
          "Ngày bắt đầu, hạn chót, thời lượng dự kiến và giờ nhắc là các giá trị độc lập. Điền đúng giúp màn Hôm nay và Quá hạn phân loại chính xác.",
        action: "Nhập nội dung, thời gian, danh mục rồi lưu việc.",
        visual: "todo",
        focusLabel: "Thông tin thời gian",
        route: "/todos",
      },
      {
        title: "Theo dõi việc lặp lại và việc con",
        description:
          "Checklist giúp chia nhỏ công việc. Khi hoàn thành một việc lặp lại, lần hiện tại vẫn được lưu và hệ thống tạo lần kế tiếp theo quy tắc đã chọn.",
        action: "Đánh dấu từng việc con, sau đó hoàn thành hoặc bỏ qua lần này.",
        visual: "todo",
        focusLabel: "Checklist tiến độ",
        route: "/todos",
      },
    ],
  },
  {
    id: "schedule",
    title: "Thời khóa biểu",
    summary: "Xem lịch ngày/tuần/tháng và lịch hẹn.",
    icon: CalendarDays,
    feature: "scheduleEnabled",
    steps: [
      {
        title: "Chọn góc nhìn phù hợp",
        description:
          "Lịch hiển thị cả sự kiện và việc cần làm có thời gian. Chế độ Ngày phù hợp để theo giờ, Tuần/Tháng để cân đối lịch, Danh sách để rà soát nhanh.",
        action: "Đổi chế độ xem và dùng nút trước/sau để chuyển mốc thời gian.",
        visual: "schedule",
        focusLabel: "Bộ chọn chế độ",
        route: "/schedule",
      },
      {
        title: "Tạo sự kiện, không tạo trùng Todo",
        description:
          "Thời khóa biểu quản lý cuộc hẹn/sự kiện. Việc cần làm có giờ sẽ tự xuất hiện trên lịch, nên không cần tạo lại thành sự kiện.",
        action: "Nhấn tạo sự kiện, đặt giờ bắt đầu/kết thúc và nhắc trước.",
        visual: "schedule",
        focusLabel: "Sự kiện trên lịch",
        route: "/schedule",
      },
    ],
  },
  {
    id: "fitness",
    title: "Rèn luyện",
    summary: "Kho bài tập, giáo án và ghi nhận buổi tập.",
    icon: Dumbbell,
    feature: "fitnessEnabled",
    steps: [
      {
        title: "Chọn bài tập có đủ hướng dẫn",
        description:
          "Kho bài tập cho biết nhóm cơ, dụng cụ, mô tả và ảnh minh họa. Bài do người dùng thêm cần quản trị viên duyệt trước khi dùng chung.",
        action: "Mở bài tập để đọc kỹ kỹ thuật và ảnh trước khi đưa vào giáo án.",
        visual: "fitness",
        focusLabel: "Chi tiết bài tập",
        route: "/exercises",
      },
      {
        title: "Tạo giáo án theo từng ngày",
        description:
          "Mỗi ngày tập có danh sách bài, số hiệp, lần lặp, mức tạ và RIR. Ảnh cùng ghi chú kỹ thuật giúp bạn kiểm tra đúng bài trước khi lưu.",
        action: "Thêm ngày, chọn bài và đặt mục tiêu cho từng bài.",
        visual: "fitness",
        focusLabel: "Mục tiêu bài tập",
        route: "/workout-plans",
      },
      {
        title: "Ghi lại buổi tập thực tế",
        description:
          "Dữ liệu thực tế có thể khác giáo án. Hãy ghi từng hiệp đã hoàn thành để lịch sử, thành tích và báo cáo phản ánh đúng tiến độ.",
        action: "Bắt đầu buổi tập, cập nhật từng hiệp rồi hoàn thành buổi.",
        visual: "fitness",
        focusLabel: "Hiệp đang tập",
        route: "/workouts",
      },
    ],
  },
  {
    id: "health",
    title: "Sức khỏe & dinh dưỡng",
    summary: "Nhật ký ăn, chỉ số cơ thể và báo cáo tuần.",
    icon: Apple,
    feature: "healthEnabled",
    steps: [
      {
        title: "Ghi đúng lượng thực phẩm",
        description:
          "Chọn khẩu phần, gram hoặc ml. Gram/ml chỉ chính xác khi thực phẩm có khối lượng khẩu phần. Món tự thêm phải được duyệt trước khi dùng chung.",
        action: "Thêm món vào đúng bữa, nhập số lượng và kiểm tra dinh dưỡng.",
        visual: "health",
        focusLabel: "Bữa ăn & số lượng",
        route: "/nutrition",
      },
      {
        title: "Xác nhận chất lượng nhật ký",
        description:
          "Ngày có món ăn mặc định là Chưa đủ. Chỉ ngày đã xác nhận Hoàn tất hoặc Nhịn ăn mới được dùng cho điểm sức khỏe, thành tích và khuyến nghị.",
        action: "Cuối ngày, rà soát các bữa rồi xác nhận trạng thái nhật ký.",
        visual: "health",
        focusLabel: "Trạng thái ngày",
        route: "/nutrition",
      },
      {
        title: "Đọc xu hướng thay vì một con số",
        description:
          "Chỉ số cơ thể và báo cáo tuần cần dữ liệu đều đặn. Dữ liệu thiếu sẽ được ghi là chưa đủ, không bị hiểu nhầm thành lượng tiêu thụ bằng 0.",
        action: "Cập nhật chỉ số định kỳ và xem mức độ tin cậy trong báo cáo.",
        visual: "health",
        focusLabel: "Xu hướng & độ tin cậy",
        route: "/health",
      },
    ],
  },
  {
    id: "assistant",
    title: "Trợ lý FitTrack PT",
    summary: "Hỏi đáp và yêu cầu hỗ trợ trong phạm vi được cấp.",
    icon: Bot,
    feature: "chatbotEnabled",
    steps: [
      {
        title: "Mô tả mục tiêu đủ rõ",
        description:
          "Nêu mục tiêu, thời gian, hạn chế và dữ liệu liên quan. Trợ lý dùng thông tin FitTrack để gợi ý nhưng không thay thế bác sĩ hoặc chuyên gia dinh dưỡng.",
        action: "Mở FitTrack PT ở góc màn hình và gửi một yêu cầu cụ thể.",
        visual: "assistant",
        focusLabel: "Nội dung trao đổi",
      },
      {
        title: "Kiểm tra trước khi xác nhận hành động",
        description:
          "Khi trợ lý đề xuất tạo buổi tập, bữa ăn hoặc đặt món, hãy đọc lại nội dung và xác nhận. Bạn vẫn chịu trách nhiệm với lựa chọn cuối cùng.",
        action: "Đối chiếu ngày, số lượng và người nhận trước khi đồng ý.",
        visual: "assistant",
        focusLabel: "Nút xác nhận",
      },
    ],
  },
  {
    id: "notifications",
    title: "Thông báo",
    summary: "Theo dõi cập nhật và mở đúng nội dung cần xử lý.",
    icon: BellRing,
    steps: [
      {
        title: "Mở trung tâm thông báo",
        description:
          "Biểu tượng chuông hiển thị số tin chưa đọc. Thông báo có thể dẫn tới menu mới, thanh toán, lời nhắc, yêu cầu quyền hoặc nội dung quản trị.",
        action: "Nhấn chuông, đọc nội dung rồi mở liên kết đi kèm nếu có.",
        visual: "notifications",
        focusLabel: "Chuông thông báo",
      },
      {
        title: "Kiểm soát email và thông báo thiết bị",
        description:
          "Bạn có thể bật/tắt email thông thường trong hồ sơ. OTP quên mật khẩu vẫn được gửi vì đây là thông báo bảo mật quan trọng.",
        action: "Mở hồ sơ để điều chỉnh tùy chọn nhận email.",
        visual: "profile",
        focusLabel: "Tùy chọn nhận tin",
        route: "/profile",
      },
    ],
  },
  {
    id: "profile",
    title: "Hồ sơ cá nhân",
    summary: "Cập nhật thông tin và kiểm tra quyền tài khoản.",
    icon: UserRound,
    steps: [
      {
        title: "Kiểm tra quyền đang được cấp",
        description:
          "Hồ sơ cho biết tài khoản có thể dùng Đặt cơm, Rèn luyện, Sức khỏe, Todo, Lịch và Chatbot hay không. Việc ẩn menu không thay thế kiểm tra quyền ở máy chủ.",
        action: "Mở hồ sơ và liên hệ quản trị viên nếu quyền chưa đúng nhu cầu.",
        visual: "profile",
        focusLabel: "Danh sách quyền",
        route: "/profile",
      },
    ],
  },
  {
    id: "admin",
    title: "Quản trị hệ thống",
    summary: "Tài khoản, menu cơm và thông báo công ty.",
    icon: ShieldCheck,
    adminOnly: true,
    steps: [
      {
        title: "Cấp quyền theo đúng nhu cầu",
        description:
          "Tài khoản mới chỉ có Đặt cơm. Admin có thể bật từng module độc lập, khóa tài khoản hoặc đổi vai trò; mọi API vẫn kiểm tra quyền ở backend.",
        action: "Tìm đúng người dùng, kiểm tra trạng thái rồi lưu các quyền cần cấp.",
        visual: "admin",
        focusLabel: "Công tắc phân quyền",
        route: "/admin/users",
      },
      {
        title: "Điều phối menu cơm hằng ngày",
        description:
          "Import menu, kiểm tra món/giá/ảnh, mở nhận đơn, gửi thông báo, tổng hợp và chốt. Nếu nhập sai, chỉnh hoặc xóa menu trước khi có đơn liên quan.",
        action: "Kiểm tra ngày, quán, giờ chốt và danh sách món trước khi thông báo.",
        visual: "lunch",
        focusLabel: "Quy trình menu",
        route: "/admin/lunch",
      },
      {
        title: "Gửi thông báo đúng đối tượng",
        description:
          "Thông báo cá nhân hoặc nhạy cảm nên chọn người nhận cụ thể. Chỉ dùng gửi toàn bộ khi nội dung thật sự áp dụng cho mọi tài khoản đang hoạt động.",
        action: "Chọn đối tượng, xem lại nội dung và thời điểm trước khi gửi.",
        visual: "admin",
        focusLabel: "Nhóm người nhận",
        route: "/admin/notifications",
      },
    ],
  },
];

export function UserGuideDialog({
  open,
  onOpenChange,
  user,
  isAdmin,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  user: AuthUser | null;
  isAdmin: boolean;
}) {
  const navigate = useNavigate();
  const availableModules = useMemo(
    () =>
      guideModules.filter(
        (module) =>
          (!module.adminOnly || isAdmin) &&
          (!module.feature || canUseFeature(user, module.feature)),
      ),
    [isAdmin, user],
  );
  const [selectedId, setSelectedId] = useState("overview");
  const [stepIndex, setStepIndex] = useState(0);
  const selectedModule =
    availableModules.find((module) => module.id === selectedId) ?? availableModules[0];
  const step = selectedModule.steps[Math.min(stepIndex, selectedModule.steps.length - 1)];

  const selectModule = (id: string) => {
    setSelectedId(id);
    setStepIndex(0);
  };

  const openFeature = () => {
    if (!step.route) return;
    onOpenChange(false);
    navigate(step.route);
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[min(92vh,820px)] gap-0 overflow-hidden p-0 sm:max-w-[min(1100px,calc(100vw-2rem))] sm:p-0">
        <DialogHeader className="border-b bg-gradient-to-r from-emerald-50 via-white to-teal-50 px-5 py-5 pr-14 sm:px-7">
          <DialogTitle className="text-xl font-bold text-[#0c2821]">Hướng dẫn sử dụng FitTrack</DialogTitle>
          <DialogDescription>
            Nội dung bên dưới được cá nhân hóa theo quyền hiện có của tài khoản.
          </DialogDescription>
        </DialogHeader>

        <div className="grid min-h-0 flex-1 md:grid-cols-[18rem_minmax(0,1fr)]">
          <aside className="max-h-44 overflow-x-auto border-b bg-slate-50/80 p-3 md:max-h-none md:overflow-y-auto md:border-b-0 md:border-r md:p-4">
            <div className="flex gap-2 md:flex-col">
              {availableModules.map((module) => {
                const Icon = module.icon;
                const active = module.id === selectedModule.id;
                return (
                  <button
                    key={module.id}
                    type="button"
                    onClick={() => selectModule(module.id)}
                    className={[
                      "flex min-w-56 items-start gap-3 rounded-xl border p-3 text-left transition md:min-w-0",
                      active
                        ? "border-emerald-300 bg-white text-emerald-950 shadow-sm ring-2 ring-emerald-100"
                        : "border-transparent text-slate-600 hover:border-slate-200 hover:bg-white",
                    ].join(" ")}
                    aria-current={active ? "step" : undefined}
                  >
                    <span className={[
                      "grid size-9 shrink-0 place-items-center rounded-xl",
                      active ? "bg-emerald-100 text-emerald-800" : "bg-slate-200/70 text-slate-600",
                    ].join(" ")}>
                      <Icon className="size-4.5" />
                    </span>
                    <span>
                      <span className="block text-sm font-bold">{module.title}</span>
                      <span className="mt-0.5 block text-xs leading-4 text-muted-foreground">{module.summary}</span>
                    </span>
                  </button>
                );
              })}
            </div>
          </aside>

          <section className="min-h-0 overflow-y-auto p-5 sm:p-7">
            <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
              <div>
                <p className="text-xs font-bold uppercase tracking-[0.16em] text-emerald-700">
                  {selectedModule.title} · Bước {stepIndex + 1}/{selectedModule.steps.length}
                </p>
                <h2 className="mt-1 text-xl font-bold tracking-tight text-slate-950 sm:text-2xl">{step.title}</h2>
              </div>
              <div className="flex gap-1" aria-label="Tiến độ hướng dẫn">
                {selectedModule.steps.map((item, index) => (
                  <button
                    key={item.title}
                    type="button"
                    onClick={() => setStepIndex(index)}
                    className={[
                      "h-2.5 rounded-full transition-all",
                      index === stepIndex ? "w-8 bg-emerald-600" : "w-2.5 bg-slate-200 hover:bg-slate-300",
                    ].join(" ")}
                    aria-label={`Mở bước ${index + 1}`}
                  />
                ))}
              </div>
            </div>

            <GuideIllustration visual={step.visual} focusLabel={step.focusLabel} />

            <div className="mt-5 grid gap-3 sm:grid-cols-[minmax(0,1fr)_minmax(15rem,.7fr)]">
              <p className="leading-6 text-slate-600">{step.description}</p>
              <div className="flex gap-2 rounded-xl border border-emerald-200 bg-emerald-50 p-3 text-sm text-emerald-950">
                <CheckCircle2 className="mt-0.5 size-4 shrink-0 text-emerald-700" />
                <span><strong>Thao tác:</strong> {step.action}</span>
              </div>
            </div>

            <div className="mt-6 flex flex-wrap items-center justify-between gap-3 border-t pt-4">
              <Button
                type="button"
                variant="outline"
                onClick={() => setStepIndex((current) => Math.max(0, current - 1))}
                disabled={stepIndex === 0}
              >
                <ChevronLeft /> Bước trước
              </Button>
              <div className="flex gap-2">
                {step.route && (
                  <Button type="button" variant="outline" onClick={openFeature}>
                    Mở chức năng
                  </Button>
                )}
                {stepIndex < selectedModule.steps.length - 1 ? (
                  <Button type="button" onClick={() => setStepIndex((current) => current + 1)}>
                    Bước tiếp <ChevronRight />
                  </Button>
                ) : (
                  <Button type="button" onClick={() => onOpenChange(false)}>
                    Đã hiểu
                  </Button>
                )}
              </div>
            </div>
          </section>
        </div>
      </DialogContent>
    </Dialog>
  );
}

function GuideIllustration({ visual, focusLabel }: { visual: GuideVisual; focusLabel: string }) {
  return (
    <div
      className="relative h-64 overflow-hidden rounded-2xl border border-slate-200 bg-gradient-to-br from-slate-100 to-emerald-50 p-4 shadow-inner sm:h-72 sm:p-6"
      role="img"
      aria-label={`Minh họa: ${focusLabel}`}
    >
      <span className="absolute left-4 top-3 z-20 rounded-full bg-white/90 px-2.5 py-1 text-[0.65rem] font-bold uppercase tracking-wider text-slate-500 shadow-sm">
        Ảnh minh họa
      </span>
      <div className="mx-auto mt-7 h-[calc(100%-2rem)] max-w-2xl overflow-hidden rounded-xl border bg-white shadow-lg">
        <div className="flex h-8 items-center gap-1.5 border-b bg-slate-50 px-3">
          <span className="size-2 rounded-full bg-rose-300" />
          <span className="size-2 rounded-full bg-amber-300" />
          <span className="size-2 rounded-full bg-emerald-300" />
          <span className="ml-3 h-2 w-28 rounded bg-slate-200" />
        </div>
        <MockScreen visual={visual} />
      </div>

      <div className="pointer-events-none absolute bottom-[15%] right-[8%] z-20 rounded-full border-4 border-amber-400 bg-amber-100/35 px-5 py-3 shadow-[0_0_0_6px_rgba(251,191,36,.18)] motion-safe:animate-pulse sm:right-[12%]">
        <span className="sr-only">Vùng cần chú ý</span>
      </div>
      <svg className="pointer-events-none absolute inset-0 z-30 size-full" viewBox="0 0 800 300" preserveAspectRatio="none" aria-hidden="true">
        <defs>
          <marker id={`guide-arrow-${visual}`} markerWidth="10" markerHeight="10" refX="8" refY="4" orient="auto" markerUnits="strokeWidth">
            <path d="M0,0 L0,8 L9,4 z" fill="#d97706" />
          </marker>
        </defs>
        <path
          d="M 690 48 C 650 75, 690 150, 650 220"
          fill="none"
          stroke="#d97706"
          strokeWidth="4"
          strokeLinecap="round"
          strokeDasharray="8 7"
          markerEnd={`url(#guide-arrow-${visual})`}
        />
      </svg>
      <span className="absolute right-4 top-10 z-40 max-w-40 rounded-xl bg-amber-500 px-3 py-2 text-center text-xs font-bold text-white shadow-lg sm:right-7">
        {focusLabel}
      </span>
    </div>
  );
}

function MockScreen({ visual }: { visual: GuideVisual }) {
  if (visual === "navigation") {
    return (
      <div className="grid h-full grid-cols-[32%_1fr]">
        <div className="space-y-2 bg-[#0c2821] p-3">
          <div className="mb-4 h-3 w-20 rounded bg-emerald-300/80" />
          {["Tổng quan", "Đặt cơm", "Việc cần làm", "Rèn luyện"].map((label, index) => (
            <div key={label} className={`rounded-lg px-2 py-2 text-[0.65rem] ${index === 1 ? "bg-white font-bold text-emerald-950" : "bg-white/5 text-white/70"}`}>
              {label}
            </div>
          ))}
        </div>
        <div className="space-y-3 p-4">
          <div className="h-4 w-28 rounded bg-slate-800" />
          <div className="grid grid-cols-2 gap-3"><div className="h-20 rounded-lg bg-emerald-50" /><div className="h-20 rounded-lg bg-slate-100" /></div>
        </div>
      </div>
    );
  }

  if (visual === "lunch") {
    return (
      <div className="grid h-full grid-cols-[1fr_36%] gap-3 p-4">
        <div className="space-y-2">
          <div className="flex gap-2"><div className="h-7 flex-1 rounded-lg bg-emerald-100" /><div className="h-7 flex-1 rounded-lg bg-slate-100" /></div>
          <div className="grid grid-cols-2 gap-2">{[1, 2, 3, 4].map((item) => <div key={item} className="flex h-10 items-center gap-2 rounded-lg border px-2"><span className="size-3 rounded-full border-2 border-emerald-500" /><span className="h-2 flex-1 rounded bg-slate-200" /></div>)}</div>
        </div>
        <div className="rounded-lg bg-emerald-50 p-3"><div className="mb-2 text-[0.65rem] font-bold text-emerald-900">Giỏ đặt cơm</div><div className="h-14 rounded border bg-white" /><div className="mt-3 h-8 rounded-lg bg-emerald-600" /></div>
      </div>
    );
  }

  if (visual === "todo") {
    return <MockList title="Việc hôm nay" icon="✓" rows={["Chuẩn bị báo cáo", "Gọi khách hàng", "Đi tập 18:00"]} />;
  }
  if (visual === "schedule") {
    return (
      <div className="p-4"><div className="mb-3 flex gap-2">{["Ngày", "Tuần", "Tháng"].map((item, index) => <span key={item} className={`rounded-full px-3 py-1 text-[0.6rem] ${index === 1 ? "bg-emerald-600 text-white" : "bg-slate-100"}`}>{item}</span>)}</div><div className="grid grid-cols-5 gap-1">{Array.from({ length: 20 }, (_, index) => <div key={index} className={`h-7 rounded border ${index === 8 || index === 13 ? "bg-emerald-100" : "bg-white"}`} />)}</div></div>
    );
  }
  if (visual === "fitness") {
    return (
      <div className="grid h-full grid-cols-[34%_1fr] gap-3 p-4"><div className="grid place-items-center rounded-xl bg-emerald-100 text-4xl">🏋️</div><div className="space-y-2"><div className="h-4 w-32 rounded bg-slate-700" /><div className="flex gap-2"><span className="rounded-full bg-emerald-100 px-2 py-1 text-[0.55rem]">Nhóm cơ: Lưng</span><span className="rounded-full bg-slate-100 px-2 py-1 text-[0.55rem]">Dụng cụ: Tạ</span></div><div className="h-2 w-full rounded bg-slate-200" /><div className="h-2 w-5/6 rounded bg-slate-200" /><div className="mt-3 grid grid-cols-4 gap-2">{["3 hiệp", "10 lần", "20 kg", "RIR 2"].map((item) => <div key={item} className="rounded-lg border p-2 text-center text-[0.55rem]">{item}</div>)}</div></div></div>
    );
  }
  if (visual === "health") {
    return (
      <div className="p-4"><div className="grid grid-cols-3 gap-2">{["1.850 kcal", "102 g đạm", "1,8 lít nước"].map((item) => <div key={item} className="rounded-lg bg-emerald-50 p-3 text-center text-[0.6rem] font-bold text-emerald-900">{item}</div>)}</div><div className="mt-4 flex h-20 items-end gap-2 rounded-lg bg-slate-50 px-4 pt-3">{[35, 60, 48, 75, 66, 88, 70].map((height, index) => <div key={index} className="flex-1 rounded-t bg-emerald-400" style={{ height: `${height}%` }} />)}</div></div>
    );
  }
  if (visual === "assistant") {
    return <div className="space-y-3 p-4"><div className="mr-20 rounded-xl rounded-tl-sm bg-slate-100 p-3 text-[0.6rem]">Hãy giúp tôi lập kế hoạch tập 3 buổi.</div><div className="ml-14 rounded-xl rounded-tr-sm bg-emerald-100 p-3 text-[0.6rem]">Tôi đã chuẩn bị gợi ý. Bạn kiểm tra trước khi xác nhận nhé.</div><div className="ml-auto h-8 w-28 rounded-lg bg-emerald-600" /></div>;
  }
  if (visual === "notifications") {
    return <MockList title="Thông báo" icon="🔔" rows={["Menu trưa đã được mở", "Nhắc lịch lúc 15:00", "Yêu cầu quyền mới"]} />;
  }
  if (visual === "profile") {
    return <MockList title="Quyền tài khoản" icon="●" rows={["Đặt cơm · Đã bật", "Rèn luyện · Đã bật", "Sức khỏe · Chưa bật"]} />;
  }
  return <MockList title="Quản lý người dùng" icon="⚙" rows={["Nguyễn Văn A · Đặt cơm", "Trần Thị B · Rèn luyện", "Lê Văn C · Sức khỏe"]} />;
}

function MockList({ title, icon, rows }: { title: string; icon: string; rows: string[] }) {
  return (
    <div className="p-4">
      <div className="mb-3 text-xs font-bold text-slate-800">{title}</div>
      <div className="space-y-2">
        {rows.map((row, index) => (
          <div key={row} className="flex items-center gap-3 rounded-lg border bg-white p-2.5">
            <span className={`grid size-6 place-items-center rounded-full text-[0.6rem] ${index === 0 ? "bg-emerald-100 text-emerald-800" : "bg-slate-100"}`}>{icon}</span>
            <span className="text-[0.62rem] text-slate-700">{row}</span>
          </div>
        ))}
      </div>
    </div>
  );
}
