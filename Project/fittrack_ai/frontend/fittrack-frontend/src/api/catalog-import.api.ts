import api from './axios';
export type CatalogKind = 'EXERCISE' | 'FOOD';
export type ImportAction = 'CREATE' | 'UPDATE' | 'SKIP';
export type ImportRow = { number: number; values: Record<string, string>; before: Record<string, string>; after?: Record<string, string>; errors: string[]; warnings: string[]; suggestedAction: ImportAction; resultId: string | null };
export type ImportBatch = { id: string; kind: CatalogKind; createdAt: string; committedAt: string | null; rows: ImportRow[] };
export type ImportBatchSummary = Omit<ImportBatch, 'rows'> & { rowCount: number; importedCount: number; errorCount: number };
export type ImportSelection = { number: number; action: ImportAction; clearFields: string[] };
export const catalogImportColumns: Record<CatalogKind, string[]> = {
  EXERCISE: ['id', 'name', 'muscleGroup', 'equipment', 'description', 'imageUrl'],
  FOOD: ['id', 'name', 'unit', 'basis', 'servingSizeGrams', 'calories', 'protein', 'carbs', 'fat', 'fiber', 'sugar', 'sodium', 'potassium', 'calcium', 'iron', 'vitaminC', 'water', 'barcode', 'dataSourceType', 'dataSourceName', 'imageUrl'],
};
export const previewCatalogImport = async (kind: CatalogKind, file: File | null, text: string, mapping: Record<string, string>) => {
  const body = new FormData(); if (file) body.append('file', file); else body.append('text', text); body.append('mapping', JSON.stringify(mapping));
  return (await api.post<ImportBatch>(`/catalog-imports/${kind}/preview`, body)).data;
};
export const commitCatalogImport = async (id: string, selections: ImportSelection[]) => (await api.post<ImportBatch>(`/catalog-imports/${id}/commit`, { selections })).data;
export const catalogImportHistory = async (kind: CatalogKind) => (await api.get<ImportBatchSummary[]>('/catalog-imports', { params: { kind } })).data;
export const downloadCatalogFile = async (path: string, filename: string) => {
  const response = await api.get<Blob>(`/catalog-imports/${path}`, { responseType: 'blob' });
  const url = URL.createObjectURL(response.data); const link = document.createElement('a'); link.href = url; link.download = filename; link.click(); setTimeout(() => URL.revokeObjectURL(url), 1000);
};
