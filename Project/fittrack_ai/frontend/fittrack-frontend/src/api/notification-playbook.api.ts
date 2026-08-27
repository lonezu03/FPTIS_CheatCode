import api from './axios';
export type NotificationPlaybook = { id:string; name:string; category:'WELLNESS'|'MEAL'|'SLEEP'|'PRODUCTIVITY'; mode:'FIXED'|'RANDOM'; triggerTime:string; daysOfWeek:string; messages:string; conditionType:'ANY'|'MEALS_LT'|'PROTEIN_GT'|'NO_MEAL'; threshold:number|null; enabled:boolean; lastTriggeredDate:string|null; createdAt:string };
export type NotificationPlaybookPayload = Omit<NotificationPlaybook, 'id'|'lastTriggeredDate'|'createdAt'>;
export const getNotificationPlaybooks = async () => (await api.get<NotificationPlaybook[]>('/admin/notification-playbooks')).data;
export const createNotificationPlaybook = async (payload:NotificationPlaybookPayload) => (await api.post<NotificationPlaybook>('/admin/notification-playbooks', payload)).data;
export const updateNotificationPlaybook = async (id:string, payload:NotificationPlaybookPayload) => (await api.patch<NotificationPlaybook>(`/admin/notification-playbooks/${id}`, payload)).data;
export const deleteNotificationPlaybook = async (id:string) => { await api.delete(`/admin/notification-playbooks/${id}`); };
