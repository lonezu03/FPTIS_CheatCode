package com.fittrack.nutrition.pantry;
import com.fittrack.nutrition.entity.Food;
import java.math.*;
import java.util.*;
/** Never infer density: the catalog's serving amount represents grams OR ml, never both. */
public final class PantryQuantity {
 private PantryQuantity(){}
 public static boolean volume(Food food){return food.getUnit()!=null&&food.getUnit().toLowerCase(Locale.ROOT).matches(".*(?:ml|lít|litre|liter).*" );}
 public static void validate(Food food,String unit){
  if(!Set.of("SERVING","GRAM","ML").contains(unit))throw new IllegalArgumentException("Đơn vị không hợp lệ");
  if(!unit.equals("SERVING")&&(volume(food)!=unit.equals("ML")))throw new IllegalArgumentException("Không thể suy đổi gram và ml; chọn đúng đơn vị thực phẩm");
 }
 public static BigDecimal convert(Food food,BigDecimal amount,String from,String to){
  validate(food,from);validate(food,to); if(from.equals(to))return amount;
  if(food.getServingSizeGrams()==null||!Double.isFinite(food.getServingSizeGrams())||food.getServingSizeGrams()<=0)return null;
  BigDecimal factor=BigDecimal.valueOf(food.getServingSizeGrams());
  if(from.equals("SERVING"))return amount.multiply(factor);
  if(to.equals("SERVING"))return amount.divide(factor,9,RoundingMode.HALF_UP);
  return null;
 }
}
