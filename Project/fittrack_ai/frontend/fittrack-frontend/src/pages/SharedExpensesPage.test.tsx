import {render,screen,fireEvent,waitFor,cleanup} from '@testing-library/react';
import {QueryClient,QueryClientProvider} from '@tanstack/react-query';
import {afterEach,beforeEach,describe,expect,it,vi} from 'vitest';
import SharedExpensesPage from './SharedExpensesPage';
import {sharedExpensesApi as api} from '@/api/shared-expenses.api';
vi.mock('@/store/auth.store',()=>({useAuthStore:(select:(s:unknown)=>unknown)=>select({user:{userId:'me',role:'ADMIN'}})}));
vi.mock('@/api/shared-expenses.api',()=>({sharedExpensesApi:{groups:vi.fn(),invitations:vi.fn(),detail:vi.fn(),expenses:vi.fn(),settlements:vi.fn(),audit:vi.fn(),preview:vi.fn(),saveExpense:vi.fn(),member:vi.fn(),saveGroup:vi.fn()}}));
const page=<T,>(content:T[])=>({content,page:0,totalPages:content.length?1:0,totalElements:content.length});
const group={id:'g',ownerId:'someone-else',name:'Nhóm du lịch',archived:false,version:4,myStatus:'ACTIVE'};
const members=[{userId:'me',name:'Tôi',status:'ACTIVE',acceptedAt:'2026-10-28',balance:-50},{userId:'someone-else',name:'Bạn',status:'ACTIVE',acceptedAt:'2026-10-28',balance:50}];
function mount(){return render(<QueryClientProvider client={new QueryClient({defaultOptions:{queries:{retry:false}}})}><SharedExpensesPage/></QueryClientProvider>);}
afterEach(cleanup);
beforeEach(()=>{vi.clearAllMocks();vi.mocked(api.groups).mockResolvedValue(page([group]));vi.mocked(api.invitations).mockResolvedValue(page([]));vi.mocked(api.detail).mockResolvedValue({group,members,historyPolicy:'Không chuyển tiền thật.'});vi.mocked(api.expenses).mockResolvedValue(page([]));vi.mocked(api.settlements).mockResolvedValue(page([]));vi.mocked(api.audit).mockResolvedValue(page([]));});
describe('Chi tiêu chung responsive flows',()=>{
 it('does not grant group owner controls merely because actor is ADMIN',async()=>{mount();fireEvent.click(await screen.findByRole('button',{name:/Nhóm du lịch/}));await screen.findByRole('heading',{name:'Nhóm du lịch'});expect(screen.queryByRole('button',{name:'Sửa / lưu trữ nhóm'})).toBeNull();expect(screen.queryByRole('button',{name:'Gửi lời mời trong ứng dụng'})).toBeNull();expect(screen.getByRole('button',{name:'+ Thêm khoản chi'})).toBeDefined();});
 it('shows exact backend preview before allowing submit and preserves form after failure',async()=>{
  vi.mocked(api.preview).mockResolvedValue([{userId:'me',amount:51},{userId:'someone-else',amount:50}]);vi.mocked(api.saveExpense).mockRejectedValue(new Error('offline'));
  mount();fireEvent.click(await screen.findByRole('button',{name:/Nhóm du lịch/}));fireEvent.click(await screen.findByRole('button',{name:'+ Thêm khoản chi'}));
  fireEvent.change(screen.getByLabelText('Nội dung'),{target:{value:'Ăn chung'}});fireEvent.change(screen.getByLabelText('Số tiền (đồng nguyên)'),{target:{value:'101'}});
  expect((screen.getByRole('button',{name:'Xác nhận lưu khoản chi'}) as HTMLButtonElement).disabled).toBe(true);
  fireEvent.click(screen.getByRole('button',{name:'Xem trước số tiền từng người'}));await waitFor(()=>expect((screen.getByRole('button',{name:'Xác nhận lưu khoản chi'}) as HTMLButtonElement).disabled).toBe(false));
  fireEvent.click(screen.getByRole('button',{name:'Xác nhận lưu khoản chi'}));await screen.findByRole('alert');expect((screen.getByLabelText('Nội dung') as HTMLInputElement).value).toBe('Ăn chung');
  const first=vi.mocked(api.saveExpense).mock.calls[0][2].operationId;fireEvent.click(screen.getByRole('button',{name:'Xác nhận lưu khoản chi'}));await waitFor(()=>expect(api.saveExpense).toHaveBeenCalledTimes(2));expect(vi.mocked(api.saveExpense).mock.calls[1][2].operationId).toBe(first);
 });
 it('former members have history and settlement access but no new expense button',async()=>{vi.mocked(api.detail).mockResolvedValue({group:{...group,myStatus:'REMOVED'},members,historyPolicy:'Giữ lịch sử.'});mount();fireEvent.click(await screen.findByRole('button',{name:/Nhóm du lịch/}));await screen.findByText('Giữ lịch sử.');expect(screen.queryByRole('button',{name:'+ Thêm khoản chi'})).toBeNull();expect(screen.getByRole('heading',{name:'Đối soát đã trả tiền'})).toBeDefined();});
});
