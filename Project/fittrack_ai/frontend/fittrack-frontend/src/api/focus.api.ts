import api from './axios';
import type {PageResponse} from './pagination';
export type FocusSession={id:string;todoId:string|null;title:string;category:string;mode:'FOCUS'|'BREAK';state:'RUNNING'|'PAUSED'|'COMPLETED'|'CANCELLED';plannedSeconds:number;elapsedSeconds:number;createdAt:string;runningSince:string|null;endedAt:string|null;serverNow:string;reviewRequired:boolean;version:number};
export const getActiveFocus=async():Promise<FocusSession|null>=>(await api.get('/todos/focus/active')).data||null;
export const getFocusHistory=async(from:string,to:string,page:number):Promise<PageResponse<FocusSession>>=>(await api.get('/todos/focus',{params:{from,to,page,size:15}})).data;
export const startFocus=async(body:{operationId:string;todoId?:string;title?:string;mode:string;minutes:number}):Promise<FocusSession>=>(await api.post('/todos/focus',body)).data;
export const actFocus=async(id:string,body:{operationId:string;version:number;action:'PAUSE'|'RESUME'|'FINISH'|'CANCEL'}):Promise<FocusSession>=>(await api.post(`/todos/focus/${id}/actions`,body)).data;
