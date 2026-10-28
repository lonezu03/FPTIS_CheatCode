import {describe,it,expect} from 'vitest';
import {substituteUnfinished} from './workoutSubstitution';
describe('safe live substitution',()=>{
 it('preserves completed original sets and resets remaining weights',()=>{
  const groups=[{key:'a',exerciseId:'old',sets:[{key:'1',completed:true,weight:60},{key:'2',completed:false,weight:60}]}];
  const result=substituteUnfinished(groups,'a','new',()=>Math.random().toString());
  expect(result[0]).toEqual({...groups[0],sets:[groups[0].sets[0]]});
  expect(result[1].exerciseId).toBe('new');expect(result[1]).toMatchObject({originalExerciseId:'old'});expect(result[1].sets[0].weight).toBe(0);expect(result[1].sets[0].completed).toBe(false);
  expect(groups[0].sets).toHaveLength(2);
 });
 it('does not replace completed groups',()=>{const groups=[{key:'a',exerciseId:'old',sets:[{key:'1',completed:true,weight:60}]}];expect(substituteUnfinished(groups,'a','new',()=>'' )).toEqual(groups);});
 it('manual dropdown replacement preserves original provenance across repeated changes',()=>{const result=substituteUnfinished([{key:'b',exerciseId:'second',originalExerciseId:'planned',replacementKind:'ALTERNATIVE' as const,sets:[{key:'1',completed:false,weight:60}]}],'b','third',()=> 'next',false);expect(result[0]).toMatchObject({exerciseId:'third',originalExerciseId:'planned',replacementKind:'MANUAL'});expect(result[0].sets[0].weight).toBe(0);});
});
