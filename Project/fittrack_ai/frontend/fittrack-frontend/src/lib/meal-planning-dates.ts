export function planningDateText(d: Date) { return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`; }
export function mondayOf(value: string) { const d = new Date(`${value}T12:00:00`); d.setDate(d.getDate() - (d.getDay() + 6) % 7); return planningDateText(d); }
export function planningPlus(value: string, days: number) { const d = new Date(`${value}T12:00:00`); d.setDate(d.getDate() + days); return planningDateText(d); }
