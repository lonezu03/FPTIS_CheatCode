/** Split rather than rename completed sets. Replacement load must be reviewed. */
export function substituteUnfinished<T extends { key:string;exerciseId:string;originalExerciseId?:string;replacementKind?:'MANUAL'|'ALTERNATIVE'|null;sets: { completed:boolean;weight:number;key:string }[] }>(groups:T[],key:string,exerciseId:string,newKey:()=>string,provenance=true):T[]{
 return groups.flatMap(group=>{
  if(group.key!==key||group.exerciseId===exerciseId)return [group];
  const completed=group.sets.filter(s=>s.completed),remaining=group.sets.filter(s=>!s.completed);
  if(!remaining.length)return [group];
  const replacement={...group,key:newKey(),exerciseId,originalExerciseId:group.originalExerciseId??group.exerciseId,replacementKind:(!provenance||group.replacementKind==='MANUAL'?'MANUAL':'ALTERNATIVE') as 'MANUAL'|'ALTERNATIVE',sets:remaining.map(s=>({...s,key:newKey(),weight:0,completed:false}))};
  return completed.length?[{...group,sets:completed},replacement]:[replacement];
 });
}
