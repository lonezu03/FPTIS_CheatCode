import { Activity, Dumbbell, HeartPulse, Sparkles } from "lucide-react";

export default function WellnessHeroArt() {
  return (
    <div className="relative mx-auto h-52 w-full max-w-[25rem] select-none lg:mx-0 lg:h-56" aria-hidden="true">
      <div className="absolute inset-x-8 bottom-1 h-16 rounded-[50%] bg-black/25 blur-2xl" />
      <div className="absolute inset-0 overflow-hidden rounded-[2rem] border border-white/10 bg-white/[0.055] backdrop-blur-sm">
        <div className="absolute -right-12 -top-16 size-44 rounded-full bg-emerald-300/20 blur-2xl" />
        <div className="absolute -bottom-20 -left-12 size-48 rounded-full bg-amber-200/15 blur-2xl" />

        <svg viewBox="0 0 400 224" className="absolute inset-0 h-full w-full" fill="none">
          <defs>
            <linearGradient id="hero-orbit" x1="82" y1="31" x2="325" y2="203" gradientUnits="userSpaceOnUse">
              <stop stopColor="#A7F3D0" stopOpacity=".78" />
              <stop offset="1" stopColor="#6EE7B7" stopOpacity=".05" />
            </linearGradient>
            <linearGradient id="hero-card" x1="132" y1="39" x2="281" y2="188" gradientUnits="userSpaceOnUse">
              <stop stopColor="#F0FDF4" />
              <stop offset="1" stopColor="#D1FAE5" />
            </linearGradient>
          </defs>
          <path d="M39 145C69 63 151 19 235 36c69 14 113 70 127 132" stroke="url(#hero-orbit)" strokeWidth="2" strokeDasharray="5 8" />
          <path d="M55 175c62 22 125 16 184-18 39-22 74-26 108-17" stroke="#A7F3D0" strokeOpacity=".18" strokeWidth="20" strokeLinecap="round" />
          <g transform="rotate(-5 207 113)">
            <rect x="127" y="38" width="160" height="154" rx="32" fill="url(#hero-card)" />
            <rect x="146" y="58" width="122" height="48" rx="18" fill="#0F3D32" />
            <path d="M162 87l12-11 12 7 14-16 14 13 17-20 21 13" stroke="#6EE7B7" strokeWidth="4" strokeLinecap="round" strokeLinejoin="round" />
            <circle cx="162" cy="87" r="3" fill="#FDE68A" />
            <rect x="146" y="120" width="51" height="52" rx="17" fill="#fff" />
            <rect x="207" y="120" width="61" height="52" rx="17" fill="#A7F3D0" />
            <path d="M161 148h21M166 140v16M177 140v16" stroke="#047857" strokeWidth="4" strokeLinecap="round" />
            <path d="M224 151c8-17 17-18 27-12-2 12-10 20-24 20" stroke="#065F46" strokeWidth="4" strokeLinecap="round" strokeLinejoin="round" />
          </g>
          <circle cx="80" cy="72" r="24" fill="#FDE68A" />
          <path d="M70 72h20M75 65v14M85 65v14" stroke="#0C2821" strokeWidth="4" strokeLinecap="round" />
          <circle cx="329" cy="80" r="18" fill="#A7F3D0" />
          <path d="M320 81l6 6 12-15" stroke="#065F46" strokeWidth="4" strokeLinecap="round" strokeLinejoin="round" />
        </svg>

        <div className="absolute left-4 top-4 flex items-center gap-2 rounded-full border border-white/10 bg-[#082019]/80 px-3 py-2 text-xs font-medium text-emerald-100 shadow-lg backdrop-blur">
          <Activity className="size-3.5 text-emerald-300" /> Nhịp sống hôm nay
        </div>
        <div className="absolute bottom-4 left-4 flex items-center gap-2 rounded-2xl bg-white px-3 py-2 text-[#0c2821] shadow-xl">
          <span className="grid size-8 place-items-center rounded-xl bg-emerald-100"><Dumbbell className="size-4 text-emerald-800" /></span>
          <span><b className="block text-xs">Tiến bộ từng ngày</b><small className="text-[10px] text-slate-500">Bền vững hơn hoàn hảo</small></span>
        </div>
        <div className="absolute bottom-5 right-4 grid size-10 place-items-center rounded-2xl border border-white/15 bg-white/10 text-emerald-200 backdrop-blur">
          <HeartPulse className="size-5" />
        </div>
        <Sparkles className="absolute right-6 top-5 size-5 text-amber-200/80" />
      </div>
    </div>
  );
}
