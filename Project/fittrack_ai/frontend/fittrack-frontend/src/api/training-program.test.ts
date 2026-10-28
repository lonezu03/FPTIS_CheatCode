import {beforeEach,describe,it,expect,vi} from 'vitest';
import api from './axios';
import {trainingCycles,saveCycle,scheduleTraining,completeTraining} from './training-program.api';
vi.mock('./axios',()=>({default:{get:vi.fn(),post:vi.fn(),put:vi.fn(),delete:vi.fn()}}));
describe('training programs shared contracts',()=>{
 beforeEach(()=>vi.clearAllMocks());
 it('pages cycles and sends manual weeks/version unchanged',async()=>{
  vi.mocked(api.get).mockResolvedValue({data:{content:[]}});
  await trainingCycles(2);expect(api.get).toHaveBeenCalledWith('/workout-plans/cycles',{params:{page:2,size:12}});
  vi.mocked(api.put).mockResolvedValue({data:{}});
  const p={id:'c',version:3,name:'Cycle',weeks:[{number:1,deload:true,targetSessions:2,targetNote:'Giữ tải'}]};
  await saveCycle(p);expect(api.put).toHaveBeenCalledWith('/workout-plans/cycles/c',p);
 });
 it('scheduling never posts workout history, completion calls occurrence endpoint',async()=>{
  vi.mocked(api.post).mockResolvedValue({data:{}});
  await scheduleTraining({planId:'p',dayId:'d',startAt:'2026-11-01T18:00:00',repeatWeeks:4});
  expect(api.post).toHaveBeenCalledTimes(1);
  expect(vi.mocked(api.post).mock.calls[0][0]).toBe('/workout-plans/appointments');
  const session={sessionDate:'2026-11-01',durationMinutes:30,note:'Actual',sets:[]};
  await completeTraining('a',session);expect(api.post).toHaveBeenLastCalledWith('/workout-plans/appointments/a/complete',{session});
 });
});
