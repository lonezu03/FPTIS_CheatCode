import {render,screen,cleanup} from '@testing-library/react';
import {QueryClient,QueryClientProvider} from '@tanstack/react-query';
import {it,expect,vi,afterEach} from 'vitest';
import api from '@/api/axios';
import HabitHeatmap from './HabitHeatmap';
vi.mock('@/api/axios',()=>({default:{get:vi.fn()}}));
afterEach(cleanup);
it('labels unknown history and pending today without inventing a completion rate',async()=>{
 vi.mocked(api.get).mockResolvedValue({data:{cells:[{day:'2026-10-27',status:'UNKNOWN',scheduled:false},{day:'2026-10-28',status:'PENDING',scheduled:true}],done:0,eligibleDays:0,currentStreak:0,longestStreak:0,completionRate:null,historyVerified:false}});
 render(<QueryClientProvider client={new QueryClient({defaultOptions:{queries:{retry:false}}})}><HabitHeatmap id="a" from="2026-10-27" to="2026-10-28" revision=""/></QueryClientProvider>);
 expect(await screen.findByText(/Một phần lịch cũ chưa xác minh/)).toBeInTheDocument();expect(screen.getByLabelText('2026-10-28: Hôm nay chưa xong')).toBeInTheDocument();expect(screen.getByText(/Chưa đủ dữ liệu/)).toBeInTheDocument();
});
