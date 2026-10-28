import {cleanup,fireEvent,render,screen,waitFor,act} from '@testing-library/react';
import {QueryClient,QueryClientProvider} from '@tanstack/react-query';
import {afterEach,beforeEach,describe,expect,it,vi} from 'vitest';
import PersonalTrackingPage from './PersonalTrackingPage';
import {personalTrackingApi as api,type TrackingEntry,type TrackingCheckin} from '../api/personaltracking.api';
vi.mock('../api/personaltracking.api',async()=>{const actual=await vi.importActual('../api/personaltracking.api');return {...actual,personalTrackingApi:{list:vi.fn(),save:vi.fn(),archive:vi.fn(),history:vi.fn(),checkin:vi.fn()}};});
vi.mock('@/components/HabitHeatmap',()=>({default:()=>null}));
const entry=(id:string):TrackingEntry=>({id,kind:'HABIT',title:`Thói quen ${id}`,startDate:'2020-01-01',weekdays:[],archived:false,version:0,phases:[]});
const check=(id:string,note:string):TrackingCheckin=>({id,day:'2026-10-27',status:'DONE',note});
function show(){return render(<QueryClientProvider client={new QueryClient({defaultOptions:{queries:{retry:false},mutations:{retry:false}}})}><PersonalTrackingPage section="habits"/></QueryClientProvider>);}
afterEach(cleanup);
beforeEach(()=>{vi.clearAllMocks();vi.mocked(api.list).mockResolvedValue({content:[entry('a'),entry('b')],page:0,totalPages:1,totalElements:2});vi.mocked(api.history).mockResolvedValue([]);});
describe('personal tracking',()=>{
 it('drops late history response after selecting another habit',async()=>{
  let finish!:(value:TrackingCheckin[])=>void;
  vi.mocked(api.history).mockImplementation(async(_p,id)=>id==='a'?await new Promise<TrackingCheckin[]>(resolve=>{finish=resolve;}):[check('b','Kết quả B')]);
  show();const buttons=await screen.findAllByRole('button',{name:'Ghi nhận / lịch sử'});fireEvent.click(buttons[0]);fireEvent.click(buttons[1]);await screen.findByText(/Kết quả B/);await act(async()=>finish([check('a','Kết quả cũ A')]));expect(screen.queryByText(/Kết quả cũ A/)).not.toBeInTheDocument();expect(screen.getByText(/Kết quả B/)).toBeInTheDocument();
 });
 it('habit checkin uses distinct habits endpoint and explicit DONE without creating Todo',async()=>{
  vi.mocked(api.checkin).mockResolvedValue(check('a',''));show();fireEvent.click((await screen.findAllByRole('button',{name:'Ghi nhận / lịch sử'}))[0]);fireEvent.click(screen.getByRole('button',{name:'Đã thực hiện'}));await waitFor(()=>expect(api.checkin).toHaveBeenCalledOnce());expect(vi.mocked(api.checkin).mock.calls[0][0]).toBe('/todos/habits');expect(vi.mocked(api.checkin).mock.calls[0][3]).toMatchObject({status:'DONE'});expect(api.save).not.toHaveBeenCalled();
 });
});
