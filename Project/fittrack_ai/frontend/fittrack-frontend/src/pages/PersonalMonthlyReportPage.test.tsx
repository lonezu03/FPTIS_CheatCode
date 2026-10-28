import {afterEach,beforeEach,describe,expect,it,vi} from 'vitest';
import {cleanup,fireEvent,render,screen} from '@testing-library/react';
import {QueryClient,QueryClientProvider} from '@tanstack/react-query';
import {useAuthStore} from '@/store/auth.store';
import {getPersonalMonthlyReport} from '@/api/personal-report.api';
import PersonalMonthlyReportPage from './PersonalMonthlyReportPage';
vi.mock('@/api/personal-report.api',()=>({getPersonalMonthlyReport:vi.fn()}));
beforeEach(()=>{useAuthStore.setState({user:{userId:'u',email:'u@example.test',fullName:'User',role:'USER',fitnessEnabled:true,healthEnabled:false,lunchEnabled:false,chatbotEnabled:false,todoEnabled:false,scheduleEnabled:false,quoteEnabled:false,financeEnabled:false,journalEnabled:false,passwordChangeRequired:false}});vi.mocked(getPersonalMonthlyReport).mockResolvedValue({month:'2026-09-01',through:'2026-09-30',timezone:'Asia/Ho_Chi_Minh',sections:['TRAINING'],training:{sessions:1,trainingDays:1,workingSets:3,volumeKgReps:600},nutrition:null,habits:null,finance:null,focus:null,disclaimer:'Không gồm nội dung nhật ký riêng.'});});
afterEach(()=>{cleanup();vi.restoreAllMocks();});
describe('monthly report privacy and explicit export',()=>{
 it('only offers permitted sections and does not query before selection',()=>{render(<QueryClientProvider client={new QueryClient()}><PersonalMonthlyReportPage/></QueryClientProvider>);expect(screen.queryByRole('checkbox',{name:'Thu chi cá nhân'})).not.toBeInTheDocument();expect(screen.queryByRole('checkbox',{name:'Dinh dưỡng'})).not.toBeInTheDocument();expect(getPersonalMonthlyReport).not.toHaveBeenCalled();expect(screen.getByRole('button',{name:'In / lưu PDF'})).toBeDisabled();});
 it('loads only explicit sections and prints only after preview confirmation action',async()=>{const print=vi.spyOn(window,'print').mockImplementation(()=>{});render(<QueryClientProvider client={new QueryClient({defaultOptions:{queries:{retry:false}}})}><PersonalMonthlyReportPage/></QueryClientProvider>);fireEvent.click(screen.getByRole('checkbox',{name:'Luyện tập'}));fireEvent.click(screen.getByRole('button',{name:'Xem báo cáo'}));expect(await screen.findByText('Luyện tập thực tế')).toBeInTheDocument();expect(getPersonalMonthlyReport).toHaveBeenCalledWith(expect.stringMatching(/^\d{4}-\d{2}-01$/),['TRAINING']);expect(print).not.toHaveBeenCalled();fireEvent.click(screen.getByRole('button',{name:'In / lưu PDF'}));expect(print).toHaveBeenCalledTimes(1);});
});
