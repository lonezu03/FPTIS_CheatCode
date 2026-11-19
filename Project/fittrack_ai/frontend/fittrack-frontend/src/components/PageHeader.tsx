type PageHeaderProps = {
  title: string;
  description?: string;
};

export default function PageHeader({ title, description }: PageHeaderProps) {
  return (
    <div className="space-y-1.5">
      <h1 className="text-2xl font-semibold tracking-[-0.035em] text-foreground md:text-[2rem]">{title}</h1>
      {description && <p className="max-w-3xl text-sm leading-6 text-muted-foreground md:text-[0.95rem]">{description}</p>}
    </div>
  );
}
