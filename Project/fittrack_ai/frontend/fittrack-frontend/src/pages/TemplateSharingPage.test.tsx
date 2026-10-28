import {afterEach,beforeEach,describe,expect,it,vi} from 'vitest';
import {cleanup,fireEvent,render,screen,waitFor} from '@testing-library/react';
import {QueryClient,QueryClientProvider} from '@tanstack/react-query';
import {useAuthStore} from '../store/auth.store';
import TemplateSharingPage from './TemplateSharingPage';
import {acceptTemplateShare,createTemplateShare,listTemplateShares,previewTemplateShare} from '../api/template-sharing.api';
import {getWorkoutPlansPage} from '../api/workout-plan.api';
vi.mock('../api/template-sharing.api',()=>({
 listTemplateShares:vi.fn().mockResolvedValue({content:[{id:'share',kind:'WORKOUT_PLAN',title:'Giáo án của bạn',ownerName:'Bạn A',recipientName:'Tôi',active:true,expiresAt:'2030-01-01T00:00:00',copiedAt:null,version:0}],totalPages:1}),
 previewTemplateShare:vi.fn().mockResolvedValue({share:{id:'share',kind:'WORKOUT_PLAN',title:'Giáo án của bạn',active:true},template:{name:'Giáo án của bạn',days:[{name:'Ngày đẩy',exercises:[{exerciseId:'press',targetSets:3,targetReps:10,targetWeight:20}]}]},itemNames:{press:'Đẩy ngực'},unavailableItems:[]}),
 createTemplateShare:vi.fn().mockResolvedValue({}),acceptTemplateShare:vi.fn().mockResolvedValue({id:'copy'}),revokeTemplateShare:vi.fn(),
}));
vi.mock('../api/workout-plan.api',()=>({getWorkoutPlansPage:vi.fn().mockResolvedValue({content:[{id:'plan',name:'Mẫu tập'}],totalPages:1})}));
vi.mock('../api/nutrition.api',()=>({getNutritionConvenience:vi.fn().mockResolvedValue({savedMeals:[],recipes:[]})}));
afterEach(()=>{cleanup();vi.clearAllMocks();vi.restoreAllMocks();});
beforeEach(()=>{
 vi.mocked(listTemplateShares).mockResolvedValue({content:[{id:'share',kind:'WORKOUT_PLAN',title:'Giáo án của bạn',ownerName:'Bạn A',recipientName:'Tôi',active:true,createdAt:'2026-10-27T00:00:00',expiresAt:'2030-01-01T00:00:00',copiedAt:null,version:0}],totalPages:1,page:0,size:12,totalElements:1,first:true,last:true});
 vi.mocked(getWorkoutPlansPage).mockResolvedValue({content:[{id:'plan',name:'Mẫu tập',description:'',days:[],createdAt:'2026-10-27T00:00:00'}],totalPages:1,page:0,size:20,totalElements:1,first:true,last:true});
 vi.mocked(previewTemplateShare).mockResolvedValue({share:{id:'share',kind:'WORKOUT_PLAN',title:'Giáo án của bạn',active:true,ownerName:'Bạn A',recipientName:'Tôi',createdAt:'2026-10-27T00:00:00',expiresAt:'2030-01-01T00:00:00',copiedAt:null,version:0},template:{name:'Giáo án của bạn',days:[{name:'Ngày đẩy',exercises:[{exerciseId:'press',targetSets:3,targetReps:10,targetWeight:20}]}]},itemNames:{press:'Đẩy ngực'},unavailableItems:[]});
 vi.mocked(createTemplateShare).mockResolvedValue({});
});
function show(flags={fitnessEnabled:true,healthEnabled:false}){
 useAuthStore.setState({user:{userId:'u',email:'u@example.test',fullName:'User',role:'USER',lunchEnabled:false,chatbotEnabled:false,todoEnabled:false,scheduleEnabled:false,quoteEnabled:false,financeEnabled:false,journalEnabled:false,passwordChangeRequired:false,...flags}});
 render(<QueryClientProvider client={new QueryClient({defaultOptions:{queries:{retry:false}}})}><TemplateSharingPage/></QueryClientProvider>);
}
describe('explicit private share-copy',()=>{
 it('does not expose sharing without either permission',()=>{show({fitnessEnabled:false,healthEnabled:false});expect(screen.getByText(/chưa có quyền chia sẻ/)).toBeInTheDocument();expect(screen.queryByRole('button',{name:'Gửi bản mẫu'})).not.toBeInTheDocument();});
 it('preview displays exercise names and never copies without confirmation',async()=>{show();fireEvent.click(await screen.findByRole('button',{name:'Xem mẫu'}));expect(await screen.findByText(/Đẩy ngực · 3 hiệp/)).toBeInTheDocument();expect(acceptTemplateShare).not.toHaveBeenCalled();vi.spyOn(window,'confirm').mockReturnValue(false);fireEvent.click(screen.getByRole('button',{name:'Sao chép vào tài khoản của tôi'}));expect(acceptTemplateShare).not.toHaveBeenCalled();});
 it('requires explicit selected recipient and send confirmation',async()=>{show();await screen.findByRole('option',{name:'Mẫu tập'});fireEvent.change(screen.getByLabelText('Bản mẫu của bạn'),{target:{value:'plan'}});fireEvent.change(screen.getByLabelText('Email tài khoản người nhận'),{target:{value:'a@example.test'}});vi.spyOn(window,'confirm').mockReturnValue(true);fireEvent.click(screen.getByRole('button',{name:'Gửi bản mẫu'}));await waitFor(()=>expect(createTemplateShare).toHaveBeenCalledWith(expect.objectContaining({kind:'WORKOUT_PLAN',sourceId:'plan',recipientEmail:'a@example.test',operationId:expect.any(String)})));});
});
