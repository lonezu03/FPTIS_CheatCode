import {cleanup,fireEvent,render,screen,waitFor} from '@testing-library/react';
import {QueryClient,QueryClientProvider} from '@tanstack/react-query';
import {afterEach,beforeEach,describe,expect,it,vi} from 'vitest';
import SavingsGoalsPage from './SavingsGoalsPage';
import {savingsApi as api,type SavingsGoal} from '../api/savings.api';
vi.mock('../api/savings.api',()=>({savingsApi:{list:vi.fn(),save:vi.fn(),archive:vi.fn(),history:vi.fn(),record:vi.fn()}}));
const goal:SavingsGoal={id:'g',title:'Du lịch',target:1000,progress:100,currencyCode:'VND',archived:false,version:0};
function show(){return render(<QueryClientProvider client={new QueryClient({defaultOptions:{queries:{retry:false},mutations:{retry:false}}})}><SavingsGoalsPage/></QueryClientProvider>);}
afterEach(cleanup);
beforeEach(()=>{vi.clearAllMocks();vi.mocked(api.list).mockResolvedValue({content:[goal],page:0,totalPages:1,totalElements:1});vi.mocked(api.history).mockResolvedValue({content:[],page:0,totalPages:0,totalElements:0});});
describe('virtual savings',()=>{
 it('shows virtual-only warning and safe amount maximum',async()=>{
  show();await screen.findByText('Du lịch');expect(screen.getByText(/KHÔNG khóa tiền/)).toBeInTheDocument();fireEvent.click(screen.getByRole('button',{name:'+ Tạo mục tiêu'}));expect(screen.getByLabelText('Số tiền đích')).toHaveAttribute('max','1000000000000');expect(api.save).not.toHaveBeenCalled();
 });
 it('retains operation id and form values after uncertain network failure',async()=>{
  vi.mocked(api.record).mockRejectedValueOnce({isAxiosError:true,response:{data:{message:'Máy chủ chưa phản hồi'}}}).mockResolvedValueOnce({id:'o',operationId:'result',type:'ADD',amount:10,currencyCode:'VND',createdAt:'2026-10-27T12:00:00'});
  show();fireEvent.click(await screen.findByRole('button',{name:'Ghi nhận / lịch sử'}));const amount=screen.getByLabelText('Số tiền (VND)');fireEvent.change(amount,{target:{value:'10'}});fireEvent.click(screen.getByRole('button',{name:'Xác nhận ghi nhận — không chuyển tiền thật'}));await screen.findByText('Máy chủ chưa phản hồi');expect(amount).toHaveValue(10);fireEvent.click(screen.getByRole('button',{name:'Xác nhận ghi nhận — không chuyển tiền thật'}));await waitFor(()=>expect(api.record).toHaveBeenCalledTimes(2));expect(vi.mocked(api.record).mock.calls[0][1].operationId).toBe(vi.mocked(api.record).mock.calls[1][1].operationId);
 });
});
