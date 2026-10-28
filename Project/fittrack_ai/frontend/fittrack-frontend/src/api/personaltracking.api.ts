import api from './axios';
export type TrackingSection = 'goals' | 'habits' | 'recovery';
export type GoalPhase = {title:string;targetDate:string;target:number};
export type TrackingEntry = {id:string;kind:string;title:string;note?:string;metric?:string;unit?:string;baseline?:number;target?:number;startDate:string;targetDate?:string;weekdays:number[];sleepStart?:string;sleepEnd?:string;quality?:number;fatigue?:number;soreness?:number;archived:boolean;version:number;phases:GoalPhase[]};
export type TrackingCheckin = {id:string;day:string;status:string;value?:number;note?:string;evidence?:string};
export type TrackingPage<T> = {content:T[];page:number;totalPages:number;totalElements:number};
export const trackingPath=(section:TrackingSection,kind='BODY')=>section==='habits'?'/todos/habits':section==='recovery'?'/health-management/tracking/recovery':kind==='WORKOUT'?'/workouts/goals':'/health-management/tracking/goals';
export const personalTrackingApi={
 list:async(path:string,page=0,archived=false)=>(await api.get<TrackingPage<TrackingEntry>>(path,{params:{page,size:12,archived}})).data,
 save:async(path:string,value:Partial<TrackingEntry>)=>(await (value.id?api.patch<TrackingEntry>(`${path}/${value.id}`,value):api.post<TrackingEntry>(path,value))).data,
 archive:async(path:string,value:TrackingEntry)=>api.delete(`${path}/${value.id}`,{params:{version:value.version}}),
 history:async(path:string,id:string,from:string,to:string)=>(await api.get<TrackingCheckin[]>(`${path}/${id}/checkins`,{params:{from,to}})).data,
 checkin:async(path:string,id:string,day:string,value:Partial<TrackingCheckin>)=>(await api.put<TrackingCheckin>(`${path}/${id}/checkins/${day}`,value)).data,
};
