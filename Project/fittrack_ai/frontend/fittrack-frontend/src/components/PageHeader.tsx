type PageHeaderProps = {
  title: string;
  description?: string;
};

export default function PageHeader({ title, description }: PageHeaderProps) {
  return (
    <div className="space-y-1.5">
      <div className="mb-2 flex items-center gap-2 text-[0.68rem] font-semibold uppercase tracking-[0.16em] text-emerald-700">
        <span className="h-px w-5 bg-emerald-500" />
        FitTrack workspace
      </div>
      <h1 className="text-2xl font-semibold tracking-[-0.035em] text-foreground md:text-[2rem]">{title}</h1>

      {description && <p className="max-w-3xl text-sm leading-6 text-muted-foreground md:text-[0.95rem]">{description}</p>}
    </div>
  );
}
