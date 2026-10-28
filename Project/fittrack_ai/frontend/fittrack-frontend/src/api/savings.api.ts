import api from './axios';
import type {TrackingPage} from './personaltracking.api';
export type SavingsGoal={id:string;title:string;target:number;progress:number;currencyCode:string;targetDate?:string;note?:string;archived:boolean;version:number};
export type SavingsOperation={id:string;operationId:string;type:'ADD'|'RELEASE';amount:number;currencyCode:string;note?:string;createdAt:string};
export const savingsApi={
 list:async(page=0,archived=false)=>(await api.get<TrackingPage<SavingsGoal>>('/finance/savings',{params:{page,size:12,archived}})).data,
 save:async(g:Partial<SavingsGoal>)=>(await(g.id?api.patch<SavingsGoal>(`/finance/savings/${g.id}`,g):api.post<SavingsGoal>('/finance/savings',g))).data,
 archive:(g:SavingsGoal)=>api.delete(`/finance/savings/${g.id}`,{params:{version:g.version}}),
 history:async(id:string,page=0)=>(await api.get<TrackingPage<SavingsOperation>>(`/finance/savings/${id}/operations`,{params:{page,size:15}})).data,
 record:async(id:string,o:Omit<SavingsOperation,'id'|'createdAt'>)=>(await api.post<SavingsOperation>(`/finance/savings/${id}/operations`,o)).data,
};
