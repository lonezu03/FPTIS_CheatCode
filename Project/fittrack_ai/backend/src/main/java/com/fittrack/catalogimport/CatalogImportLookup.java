package com.fittrack.catalogimport;

import jakarta.persistence.EntityManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;
import java.util.*;

/** Scalar projections deliberately exclude potentially multi-megabyte embedded images. */
@Repository @RequiredArgsConstructor
public class CatalogImportLookup {
    private final EntityManager em;
    public List<Map<String,String>> duplicateRows(String kind,int offset,int size) {
        List<String> columns="FOOD".equals(kind)?List.of("id","name","unit","servingSizeGrams","barcode"):List.of("id","name","muscleGroup","equipment");
        return rows(kind,columns,offset,size,false);
    }
    public List<Map<String,String>> exportRows(String kind,List<String> columns,int offset,int size) {
        return rows(kind,columns,offset,size,true);
    }
    private List<Map<String,String>> rows(String kind,List<String> columns,int offset,int size,boolean approvedOnly) {
        String entity="FOOD".equals(kind)?"Food":"Exercise";
        String fields=columns.stream().map(c->switch(c){case "basis"->"'PER_SERVING'";case "imageUrl"->"''";default->"e."+c;}).collect(java.util.stream.Collectors.joining(","));
        var query=em.createQuery("select "+fields+" from "+entity+" e"+(approvedOnly?" where e.active=true and e.approvalStatus='APPROVED'":"")+" order by e.id",Object[].class).setFirstResult(offset).setMaxResults(size);
        List<Map<String,String>> output=new ArrayList<>();for(Object[] row:query.getResultList()){Map<String,String> values=new LinkedHashMap<>();for(int i=0;i<columns.size();i++)values.put(columns.get(i),row[i]==null?"":String.valueOf(row[i]));output.add(values);}return output;
    }
}
