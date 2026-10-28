import api from './axios';
export type ReportSection='TRAINING'|'NUTRITION'|'HABITS'|'FINANCE'|'FOCUS';
export type PersonalMonthlyReport={month:string;through:string;timezone:string;sections:ReportSection[];disclaimer:string;
 training:{sessions:number;trainingDays:number;workingSets:number;volumeKgReps:number|null}|null;
 nutrition:{qualifyingDays:number;partialDays:number;unloggedDays:number;observedDays:number;coveragePercent:number;averageCalories:number|null;averageProtein:number|null;averageCarbs:number|null;averageFat:number|null}|null;
 habits:{habitCount:number;done:number;eligibleDays:number;completionRate:number|null;historyVerified:boolean}|null;
 finance:{currencyCode:string;income:string;expense:string;net:string}[]|null;
 focus:{category:string;completedSessions:number;focusSeconds:number}[]|null;};
export const getPersonalMonthlyReport=async(month:string,sections:ReportSection[]):Promise<PersonalMonthlyReport>=>(await api.get('/personal-reports/monthly',{params:{month,sections:sections.join(',')}})).data;
