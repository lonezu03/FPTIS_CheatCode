import {afterEach,beforeEach,describe,expect,it,vi} from 'vitest';
import {cleanup,fireEvent,render,screen,waitFor} from '@testing-library/react';
import {QueryClient,QueryClientProvider} from '@tanstack/react-query';
import FocusPage from './FocusPage';
import {getActiveFocus,getFocusHistory,startFocus,actFocus} from '@/api/focus.api';
import {getTodoPage} from '@/api/todo.api';
vi.mock('@/api/focus.api',()=>({getActiveFocus:vi.fn(),getFocusHistory:vi.fn(),startFocus:vi.fn(),actFocus:vi.fn()}));
vi.mock('@/api/todo.api',()=>({getTodoPage:vi.fn()}));
beforeEach(()=>{vi.mocked(getActiveFocus).mockResolvedValue(null);vi.mocked(getFocusHistory).mockResolvedValue({content:[],totalPages:0,page:0,size:15,totalElements:0,first:true,last:true});vi.mocked(getTodoPage).mockResolvedValue({content:[],totalPages:0,number:0,size:15,totalElements:0,counts:{today:0,overdue:0,upcoming:0,done:0,all:0}});});
afterEach(()=>{cleanup();vi.restoreAllMocks();});
function show(){render(<QueryClientProvider client={new QueryClient({defaultOptions:{queries:{retry:false},mutations:{retry:false}}})}><FocusPage/></QueryClientProvider>);}
describe('focus timer explicit writes',()=>{
 it('opening never starts a timer and uncertain retry keeps same operation id',async()=>{vi.mocked(startFocus).mockRejectedValue(new Error('Mất mạng'));show();await screen.findByLabelText('Tên phiên');expect(startFocus).not.toHaveBeenCalled();fireEvent.change(screen.getByLabelText('Tên phiên'),{target:{value:'Ôn tập'}});fireEvent.click(screen.getByRole('button',{name:'Bắt đầu'}));await screen.findByRole('alert');const first=vi.mocked(startFocus).mock.calls[0][0];fireEvent.click(screen.getByRole('button',{name:'Bắt đầu'}));await waitFor(()=>expect(startFocus).toHaveBeenCalledTimes(2));expect(vi.mocked(startFocus).mock.calls[1][0].operationId).toBe(first.operationId);expect(screen.getByLabelText('Tên phiên')).toHaveValue('Ôn tập');});
 it('restores paused session and cancel requires confirmation',async()=>{vi.mocked(getActiveFocus).mockResolvedValue({id:'f',todoId:null,title:'Phiên đã lưu',category:'STUDY',mode:'FOCUS',state:'PAUSED',plannedSeconds:1500,elapsedSeconds:60,createdAt:'2026-10-28T10:00:00',runningSince:null,endedAt:null,serverNow:'2026-10-28T10:01:00',reviewRequired:false,version:2});vi.spyOn(window,'confirm').mockReturnValue(false);show();expect(await screen.findByText('Phiên đã lưu')).toBeInTheDocument();expect(screen.getByRole('button',{name:'Tiếp tục'})).toBeInTheDocument();fireEvent.click(screen.getByRole('button',{name:'Hủy phiên'}));expect(actFocus).not.toHaveBeenCalled();});
});
