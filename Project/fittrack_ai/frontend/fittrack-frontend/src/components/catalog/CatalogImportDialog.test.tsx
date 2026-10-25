import { cleanup, fireEvent, render, screen, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { CatalogImportDialog } from './CatalogImportDialog';
import { commitCatalogImport, previewCatalogImport } from '@/api/catalog-import.api';
vi.mock('@/api/catalog-import.api', async importOriginal => ({ ...await importOriginal<typeof import('@/api/catalog-import.api')>(), previewCatalogImport: vi.fn(), commitCatalogImport: vi.fn(), catalogImportHistory: vi.fn().mockResolvedValue([]) }));
vi.mock('sonner', () => ({ toast: { success: vi.fn(), error: vi.fn() } }));
afterEach(() => { cleanup(); vi.clearAllMocks(); });
function setup() { return render(<QueryClientProvider client={new QueryClient({ defaultOptions: { queries: { retry: false } } })}><CatalogImportDialog kind="EXERCISE" open onOpenChange={vi.fn()} onImported={vi.fn()} /></QueryClientProvider>); }
describe('catalog import safety', () => {
  it('requires explicit confirmation and keeps duplicate rows skipped', async () => {
    const batch = { id: 'batch', kind: 'EXERCISE' as const, createdAt: '', committedAt: null, rows: [
      { number: 2, values: { name: 'Squat' }, before: {}, errors: [], warnings: [], suggestedAction: 'CREATE' as const, resultId: null },
      { number: 3, values: { name: 'Duplicate' }, before: {}, errors: [], warnings: ['Có thể trùng'], suggestedAction: 'SKIP' as const, resultId: null },
    ] };
    vi.mocked(previewCatalogImport).mockResolvedValue(batch); vi.mocked(commitCatalogImport).mockResolvedValue({ ...batch, committedAt: '2026-10-25' });
    setup(); fireEvent.change(screen.getByLabelText('Hoặc dán bảng từ Excel / Google Sheets'), { target: { value: 'name\nmón' } }); fireEvent.click(screen.getByRole('button', { name: 'Kiểm tra và xem trước' }));
    await screen.findByText('Dòng 2: Squat');
    const confirm = screen.getByRole('button', { name: 'Xác nhận nhập 1 dòng' }); expect(confirm).toBeDisabled(); expect(screen.getByLabelText('Thao tác dòng 3')).toHaveValue('SKIP');
    fireEvent.click(screen.getByRole('checkbox')); fireEvent.click(confirm);
    await waitFor(() => expect(commitCatalogImport).toHaveBeenCalledWith('batch', [ { number: 2, action: 'CREATE', clearFields: [] }, { number: 3, action: 'SKIP', clearFields: [] } ]));
  });
  it('rejects an oversized file before sending it', () => {
    setup(); const input = screen.getByLabelText('Chọn file'); fireEvent.change(input, { target: { files: [new File([new Uint8Array(2_000_001)], 'large.csv')] } });
    expect(previewCatalogImport).not.toHaveBeenCalled(); expect(screen.getByRole('button', { name: 'Kiểm tra và xem trước' })).toBeDisabled();
  });
});
