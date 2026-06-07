type PageHeaderProps = {
  title: string;
  description?: string;
};

export default function PageHeader({ title, description }: PageHeaderProps) {
  return (
    <div className="space-y-0.5 md:space-y-1">
      <h1 className="text-xl font-bold tracking-tight md:text-3xl">{title}</h1>

      {description && <p className="text-xs text-muted-foreground md:text-base">{description}</p>}
    </div>
  );
}
