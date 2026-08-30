import api from './axios';
export type ScheduleItem = { id:string; title:string; description:string|null; category:'PERSONAL'|'WORK'|'HEALTH'|'STUDY'|'MEAL'; startAt:string; endAt:string|null; repeatRule:'NONE'|'DAILY'|'WEEKLY'|'MONTHLY'|'YEARLY'; repeatInterval:number; repeatEndAt:string|null; daysOfWeek:string|null; reminderMinutes:number; reminderEnabled:boolean; enabled:boolean; lastRemindedAt:string|null; createdAt:string };
export type SchedulePayload = { title:string; description?:string|null; category?:ScheduleItem['category']; startAt:string; endAt?:string|null; repeatRule?:ScheduleItem['repeatRule']; repeatInterval?:number; repeatEndAt?:string|null; daysOfWeek?:string|null; reminderMinutes?:number; reminderEnabled?:boolean; enabled?:boolean };
export type CalendarEntry = { occurrenceId:string; sourceType:'TODO'|'EVENT'; sourceId:string; title:string; description:string|null; category:string; startAt:string; endAt:string|null; status:string; recurring:boolean };
export const getSchedule = async () => (await api.get<ScheduleItem[]>('/schedule')).data;
export const createSchedule = async (payload:SchedulePayload) => (await api.post<ScheduleItem>('/schedule', payload)).data;
export const updateSchedule = async (id:string,payload:SchedulePayload) => (await api.patch<ScheduleItem>(`/schedule/${id}`, payload)).data;
export const getCalendar = async (from:string,to:string) => (await api.get<CalendarEntry[]>('/schedule/calendar',{params:{from,to}})).data;
export const deleteSchedule = async (id:string) => { await api.delete(`/schedule/${id}`); };
