import api from './axios';
export type ScheduleItem = { id:string; title:string; description:string|null; category:'PERSONAL'|'WORK'|'HEALTH'|'STUDY'|'MEAL'; startAt:string; endAt:string|null; repeatRule:'NONE'|'DAILY'|'WEEKLY'; daysOfWeek:string|null; reminderMinutes:number; reminderEnabled:boolean; enabled:boolean; lastRemindedAt:string|null; createdAt:string };
export type SchedulePayload = { title:string; description?:string; category?:ScheduleItem['category']; startAt:string; endAt?:string|null; repeatRule?:ScheduleItem['repeatRule']; daysOfWeek?:string|null; reminderMinutes?:number; reminderEnabled?:boolean; enabled?:boolean };
export const getSchedule = async () => (await api.get<ScheduleItem[]>('/schedule')).data;
export const createSchedule = async (payload:SchedulePayload) => (await api.post<ScheduleItem>('/schedule', payload)).data;
export const deleteSchedule = async (id:string) => { await api.delete(`/schedule/${id}`); };
