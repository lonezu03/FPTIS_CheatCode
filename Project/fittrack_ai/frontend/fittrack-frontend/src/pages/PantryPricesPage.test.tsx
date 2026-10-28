import { cleanup,fireEvent,render,screen,waitFor } from '@testing-library/react';
import { QueryClient,QueryClientProvider } from '@tanstack/react-query';
import { afterEach,describe,expect,it,vi } from 'vitest';
import PantryPage from './PantryPage';
import PurchasePricesPage from './PurchasePricesPage';
import { useAuthStore,type AuthUser } from '@/store/auth.store';
import { listPurchasePrices,getWeekCost } from '@/api/purchase-prices.api';
import { operatePantry } from '@/api/pantry.api';
vi.mock('@/api/pantry.api',()=>({
 listPantry:vi.fn().mockResolvedValue({content:[{id:'batch',version:4,foodId:'rice',foodName:'Gạo thử',location:'Tủ bếp',unit:'GRAM',quantity:500,expiresOn:null,note:null,active:true}],totalElements:1,totalPages:1,last:true}),
 pantrySuggestions:vi.fn().mockResolvedValue([]),pantryHistory:vi.fn().mockResolvedValue({content:[],last:true}),createPantry:vi.fn(),editPantry:vi.fn(),operatePantry:vi.fn().mockResolvedValue({}),
}));
vi.mock('@/api/purchase-prices.api',()=>({
 listPurchasePrices:vi.fn().mockResolvedValue({content:[],totalElements:0,totalPages:0,last:true}),
 getWeekCost:vi.fn().mockResolvedValue({knownSubtotal:10000,pricedLines:1,totalLines:2,coverage:50,items:[{foodId:'rice',foodName:'Gạo',amount:1,unit:'SERVING',estimatedCost:10000,priceDate:'2026-10-01',store:'Chợ'},{foodId:'milk',foodName:'Sữa',amount:1,unit:'SERVING',estimatedCost:null,priceDate:null,reason:'Chưa có giá tương thích'}]}),
 savePurchasePrice:vi.fn(),archivePurchasePrice:vi.fn(),
}));
vi.mock('@/api/nutrition.api',()=>({searchNutritionFoods:vi.fn().mockResolvedValue({content:[],last:true})}));
const user=(health:boolean,finance:boolean)=>({userId:'user',role:'USER',healthEnabled:health,financeEnabled:finance} as AuthUser);
function mount(page:React.ReactNode){return render(<QueryClientProvider client={new QueryClient({defaultOptions:{queries:{retry:false},mutations:{retry:false}}})}>{page}</QueryClientProvider>);}
describe('Pantry and purchase prices',()=>{
 afterEach(()=>{cleanup();vi.clearAllMocks();useAuthStore.setState({user:null});});
 it('requires both module permissions before fetching purchase prices or costs',()=>{
  useAuthStore.setState({user:user(true,false)});mount(<PurchasePricesPage/>);
  expect(screen.getByText(/Cần đồng thời quyền Dinh dưỡng và Tài chính/)).toBeInTheDocument();expect(listPurchasePrices).not.toHaveBeenCalled();expect(getWeekCost).not.toHaveBeenCalled();
 });
 it('shows missing cost as unknown and reports partial coverage',async()=>{
  useAuthStore.setState({user:user(true,true)});mount(<PurchasePricesPage/>);
  expect(await screen.findByText('Chưa biết chi phí')).toBeInTheDocument();expect(screen.getByText(/Bao phủ 1\/2 dòng \(50%\)/)).toBeInTheDocument();expect(screen.getByText(/Tạm tính phần có giá/)).toHaveTextContent('10.000 đ');
 });
 it('does not write stock on read and sends selected batch version on explicit consumption',async()=>{
  mount(<PantryPage/>);await screen.findByText('Gạo thử');expect(operatePantry).not.toHaveBeenCalled();
  fireEvent.click(screen.getByRole('button',{name:'Nhập / dùng / hủy'}));
  fireEvent.change(screen.getByRole('spinbutton',{name:'Số lượng thay đổi (g)'}),{target:{value:'100'}});
  fireEvent.click(screen.getByRole('button',{name:'Xác nhận lưu'}));
  await waitFor(()=>expect(operatePantry).toHaveBeenCalledWith('batch',expect.objectContaining({version:4,type:'CONSUME',amount:100,operationId:expect.any(String)})));
 });
});
