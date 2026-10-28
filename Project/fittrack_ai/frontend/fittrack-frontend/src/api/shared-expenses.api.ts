import api from './axios';
import type { TrackingPage } from './personaltracking.api';
export type SharedGroup = {id:string;ownerId:string;name:string;description?:string;archived:boolean;version:number;myStatus:string};
export type SharedMember = {userId:string;name:string;status:string;acceptedAt?:string;balance:number};
export type SharedDetail = {group:SharedGroup;members:SharedMember[];historyPolicy:string};
export type SharedInvitation = {groupId:string;groupName:string;invitedBy:string;invitedAt:string;version:number};
export type SharedSplit = {userId:string;amount:number};
export type SharedExpense = {id:string;creatorId:string;payerId:string;title:string;amount:number;spentOn:string;note?:string;splits:SharedSplit[];voided:boolean;version:number};
export type SharedExpenseInput = {version:number;title:string;payerId:string;amount:number;spentOn:string;note?:string;splitMode:'EQUAL'|'CUSTOM';splits:SharedSplit[]};
export type SharedSettlement = {id:string;initiatorId:string;debtorId:string;creditorId:string;amount:number;status:string;note?:string;createdAt:string;version:number};
export type SharedAudit = {id:string;actorId:string;action:string;detail:string;createdAt:string};
export type SharedReceipt = {id:string;action:string};
const base='/finance/shared';
export const sharedExpensesApi={
 groups:async(page=0)=>(await api.get<TrackingPage<SharedGroup>>(`${base}/groups`,{params:{page,size:12}})).data,
 invitations:async(page=0)=>(await api.get<TrackingPage<SharedInvitation>>(`${base}/invitations`,{params:{page,size:12}})).data,
 detail:async(id:string)=>(await api.get<SharedDetail>(`${base}/groups/${id}`)).data,
 expenses:async(id:string,page=0)=>(await api.get<TrackingPage<SharedExpense>>(`${base}/groups/${id}/expenses`,{params:{page,size:15}})).data,
 settlements:async(id:string,page=0)=>(await api.get<TrackingPage<SharedSettlement>>(`${base}/groups/${id}/settlements`,{params:{page,size:15}})).data,
 audit:async(id:string,page=0)=>(await api.get<TrackingPage<SharedAudit>>(`${base}/groups/${id}/audit`,{params:{page,size:15}})).data,
 saveGroup:async(id:string|undefined,payload:{operationId:string;version?:number;name:string;description?:string;archived:boolean})=>(await(id?api.patch<SharedReceipt>(`${base}/groups/${id}`,payload):api.post<SharedReceipt>(`${base}/groups`,payload))).data,
 member:async(id:string,payload:{operationId:string;version:number;email?:string;action:'INVITE'|'REMOVE'|'ACCEPT'|'DECLINE'})=>(await api.post<SharedReceipt>(`${base}/groups/${id}/members`,payload)).data,
 preview:async(id:string,payload:SharedExpenseInput)=>(await api.post<SharedSplit[]>(`${base}/groups/${id}/expenses/preview`,payload)).data,
 saveExpense:async(id:string,expenseId:string|undefined,payload:SharedExpenseInput&{operationId:string})=>(await(expenseId?api.patch<SharedReceipt>(`${base}/groups/${id}/expenses/${expenseId}`,payload):api.post<SharedReceipt>(`${base}/groups/${id}/expenses`,payload))).data,
 voidExpense:async(id:string,e:SharedExpense,payload:{operationId:string;reason:string})=>(await api.post<SharedReceipt>(`${base}/groups/${id}/expenses/${e.id}/void`,{...payload,version:e.version})).data,
 requestSettlement:async(id:string,payload:{operationId:string;version:number;debtorId:string;creditorId:string;amount:number;note?:string})=>(await api.post<SharedReceipt>(`${base}/groups/${id}/settlements`,payload)).data,
 resolveSettlement:async(id:string,s:SharedSettlement,confirm:boolean,operationId:string)=>(await api.post<SharedReceipt>(`${base}/groups/${id}/settlements/${s.id}/${confirm?'confirm':'reject'}`,{operationId,version:s.version})).data,
};
