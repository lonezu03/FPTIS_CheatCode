package com.fittrack.nutrition.config;

import com.fittrack.nutrition.entity.Food;
import com.fittrack.nutrition.repository.FoodRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

@Component
@RequiredArgsConstructor
public class FoodSeeder implements CommandLineRunner {

    private final FoodRepository foodRepository;

    @Override
    public void run(String... args) {
        Map<String, Food> existingFoods = foodRepository.findAll().stream()
                .collect(Collectors.toMap(
                        food -> normalizeName(food.getName()),
                        Function.identity(),
                        (first, ignored) -> first
                ));

        List<Food> foods = FOODS.stream()
                .map(seed -> {
                    Food food = existingFoods.getOrDefault(normalizeName(seed.name()), Food.builder().name(seed.name()).build());

                    food.setCalories(seed.calories());
                    food.setProtein(seed.protein());
                    food.setCarbs(seed.carbs());
                    food.setFat(seed.fat());
                    food.setUnit(seed.unit());
                    food.setCustom(false);
                    food.setActive(true);

                    return food;
                })
                .toList();

        foodRepository.saveAll(foods);
    }

    private String normalizeName(String name) {
        return name == null ? "" : name.trim().toLowerCase();
    }

    private record SeedFood(String name, String unit, Double calories, Double protein, Double carbs, Double fat) {
    }

    private static final List<SeedFood> FOODS = List.of(
            new SeedFood("Cơm trắng chín", "100g", 130.0, 2.7, 28.0, 0.3),
            new SeedFood("Cơm gạo lứt chín", "100g", 111.0, 2.6, 23.0, 0.9),
            new SeedFood("Bún tươi", "100g", 110.0, 1.7, 25.7, 0.2),
            new SeedFood("Phở/bánh phở tươi", "100g", 143.0, 2.5, 31.0, 0.4),
            new SeedFood("Mì trứng/mì vàng chín", "100g", 138.0, 4.5, 25.0, 2.1),
            new SeedFood("Miến dong chín", "100g", 100.0, 0.2, 24.0, 0.1),
            new SeedFood("Bánh mì trắng", "100g", 265.0, 9.0, 49.0, 3.2),
            new SeedFood("Khoai lang luộc", "100g", 86.0, 1.6, 20.1, 0.1),
            new SeedFood("Khoai tây luộc", "100g", 87.0, 1.9, 20.1, 0.1),
            new SeedFood("Bắp/ngô luộc", "100g", 96.0, 3.4, 21.0, 1.5),
            new SeedFood("Yến mạch cán dẹt", "100g", 389.0, 16.9, 66.3, 6.9),
            new SeedFood("Ức gà không da chín", "100g", 165.0, 31.0, 0.0, 3.6),
            new SeedFood("Đùi gà có da chín", "100g", 215.0, 18.0, 0.0, 15.0),
            new SeedFood("Thịt heo nạc chín", "100g", 242.0, 27.0, 0.0, 14.0),
            new SeedFood("Thịt heo ba chỉ chín", "100g", 518.0, 9.3, 0.0, 53.0),
            new SeedFood("Sườn heo nướng", "100g", 290.0, 20.0, 0.0, 23.0),
            new SeedFood("Thịt bò nạc chín", "100g", 250.0, 26.0, 0.0, 15.0),
            new SeedFood("Cá basa/cá tra chín", "100g", 150.0, 18.0, 0.0, 8.0),
            new SeedFood("Cá hồi chín", "100g", 208.0, 20.0, 0.0, 13.0),
            new SeedFood("Cá ngừ chín", "100g", 132.0, 28.0, 0.0, 1.3),
            new SeedFood("Tôm luộc", "100g", 99.0, 24.0, 0.2, 0.3),
            new SeedFood("Mực luộc/hấp", "100g", 92.0, 15.6, 3.1, 1.4),
            new SeedFood("Trứng gà", "1 quả (~50g)", 70.0, 6.0, 0.6, 5.0),
            new SeedFood("Lòng trắng trứng", "100g", 52.0, 10.9, 0.7, 0.2),
            new SeedFood("Đậu hũ trắng", "100g", 76.0, 8.0, 1.9, 4.8),
            new SeedFood("Đậu hũ chiên", "100g", 271.0, 17.0, 8.0, 20.0),
            new SeedFood("Đậu xanh nấu chín", "100g", 105.0, 7.0, 19.0, 0.4),
            new SeedFood("Đậu phộng rang", "100g", 567.0, 25.8, 16.1, 49.2),
            new SeedFood("Rau cải thìa luộc", "100g", 13.0, 1.5, 2.2, 0.2),
            new SeedFood("Rau muống luộc", "100g", 19.0, 2.6, 3.1, 0.2),
            new SeedFood("Bông cải xanh luộc", "100g", 35.0, 2.4, 7.2, 0.4),
            new SeedFood("Cà rốt luộc", "100g", 35.0, 0.8, 8.2, 0.2),
            new SeedFood("Dưa leo", "100g", 15.0, 0.7, 3.6, 0.1),
            new SeedFood("Cà chua", "100g", 18.0, 0.9, 3.9, 0.2),
            new SeedFood("Bắp cải luộc", "100g", 23.0, 1.3, 5.5, 0.1),
            new SeedFood("Nấm rơm/nấm tươi", "100g", 22.0, 3.1, 3.3, 0.3),
            new SeedFood("Chuối", "100g", 89.0, 1.1, 22.8, 0.3),
            new SeedFood("Táo", "100g", 52.0, 0.3, 13.8, 0.2),
            new SeedFood("Cam", "100g", 47.0, 0.9, 11.8, 0.1),
            new SeedFood("Xoài chín", "100g", 60.0, 0.8, 15.0, 0.4),
            new SeedFood("Dưa hấu", "100g", 30.0, 0.6, 7.6, 0.2),
            new SeedFood("Bơ", "100g", 160.0, 2.0, 8.5, 14.7),
            new SeedFood("Dừa tươi nước", "100ml", 19.0, 0.7, 3.7, 0.2),
            new SeedFood("Sữa tươi không đường", "100ml", 62.0, 3.2, 4.8, 3.3),
            new SeedFood("Sữa chua không đường", "100g", 61.0, 3.5, 4.7, 3.3),
            new SeedFood("Sữa chua Hy Lạp", "100g", 59.0, 10.0, 3.6, 0.4),
            new SeedFood("Whey protein", "1 muỗng (~30g)", 120.0, 24.0, 3.0, 2.0),
            new SeedFood("Cơm tấm sườn", "1 đĩa", 650.0, 30.0, 82.0, 22.0),
            new SeedFood("Cơm tấm sườn bì chả", "1 đĩa", 850.0, 42.0, 92.0, 35.0),
            new SeedFood("Cơm sườn trứng", "1 đĩa", 800.0, 38.0, 85.0, 34.0),
            new SeedFood("Cơm gà xối mỡ", "1 phần", 900.0, 40.0, 90.0, 42.0),
            new SeedFood("Cơm gà luộc", "1 phần", 620.0, 38.0, 78.0, 18.0),
            new SeedFood("Cơm chiên dương châu", "1 đĩa", 700.0, 20.0, 95.0, 25.0),
            new SeedFood("Cơm bò lúc lắc", "1 phần", 780.0, 38.0, 88.0, 30.0),
            new SeedFood("Cơm thịt kho trứng", "1 phần", 750.0, 34.0, 82.0, 32.0),
            new SeedFood("Cơm cá kho", "1 phần", 600.0, 32.0, 80.0, 16.0),
            new SeedFood("Cơm ức gà áp chảo", "1 phần", 520.0, 42.0, 70.0, 8.0),
            new SeedFood("Cơm trứng chiên", "1 phần", 580.0, 18.0, 80.0, 20.0),
            new SeedFood("Cơm chay đậu hũ", "1 phần", 560.0, 20.0, 82.0, 16.0),
            new SeedFood("Phở bò", "1 tô", 550.0, 32.0, 75.0, 14.0),
            new SeedFood("Phở gà", "1 tô", 480.0, 30.0, 68.0, 10.0),
            new SeedFood("Bún bò Huế", "1 tô", 700.0, 35.0, 80.0, 28.0),
            new SeedFood("Bún riêu", "1 tô", 550.0, 24.0, 70.0, 18.0),
            new SeedFood("Bún thịt nướng", "1 tô", 650.0, 30.0, 85.0, 22.0),
            new SeedFood("Bún chả", "1 phần", 720.0, 35.0, 88.0, 26.0),
            new SeedFood("Bánh canh cua", "1 tô", 620.0, 28.0, 82.0, 20.0),
            new SeedFood("Hủ tiếu Nam Vang", "1 tô", 600.0, 32.0, 78.0, 16.0),
            new SeedFood("Mì Quảng", "1 tô", 650.0, 32.0, 75.0, 25.0),
            new SeedFood("Mì gói thường", "1 gói", 350.0, 7.0, 50.0, 14.0),
            new SeedFood("Mì gói + 1 trứng", "1 tô", 420.0, 13.0, 51.0, 19.0),
            new SeedFood("Mì gói + 2 trứng", "1 tô", 490.0, 19.0, 52.0, 24.0),
            new SeedFood("Cháo trắng", "1 tô", 180.0, 4.0, 39.0, 0.5),
            new SeedFood("Cháo gà", "1 tô", 350.0, 22.0, 45.0, 9.0),
            new SeedFood("Cháo lòng", "1 tô", 520.0, 25.0, 58.0, 22.0),
            new SeedFood("Bánh mì thịt", "1 ổ", 500.0, 20.0, 65.0, 18.0),
            new SeedFood("Bánh mì ốp la", "1 ổ", 550.0, 22.0, 62.0, 24.0),
            new SeedFood("Bánh mì chả cá", "1 ổ", 520.0, 22.0, 62.0, 20.0),
            new SeedFood("Xôi mặn", "1 hộp", 650.0, 22.0, 95.0, 22.0),
            new SeedFood("Xôi gà", "1 hộp", 700.0, 35.0, 90.0, 22.0),
            new SeedFood("Xôi đậu xanh", "1 gói", 500.0, 12.0, 95.0, 8.0),
            new SeedFood("Bánh bao nhân thịt", "1 cái", 320.0, 12.0, 45.0, 10.0),
            new SeedFood("Bánh cuốn", "1 phần", 480.0, 18.0, 75.0, 12.0),
            new SeedFood("Gỏi cuốn tôm thịt", "1 cuốn", 95.0, 5.0, 14.0, 2.0),
            new SeedFood("Chả giò/nem rán", "1 cuốn", 150.0, 5.0, 13.0, 9.0),
            new SeedFood("Bánh xèo", "1 cái", 430.0, 17.0, 45.0, 22.0),
            new SeedFood("Bánh khọt", "1 phần 8 cái", 550.0, 20.0, 60.0, 26.0),
            new SeedFood("Bột chiên", "1 đĩa", 700.0, 20.0, 85.0, 32.0),
            new SeedFood("Nui xào bò", "1 đĩa", 750.0, 35.0, 90.0, 28.0),
            new SeedFood("Mì xào bò", "1 đĩa", 800.0, 35.0, 95.0, 32.0),
            new SeedFood("Gà rán", "1 miếng", 320.0, 20.0, 16.0, 20.0),
            new SeedFood("Khoai tây chiên", "100g", 312.0, 3.4, 41.0, 15.0),
            new SeedFood("Pizza", "1 miếng", 285.0, 12.0, 36.0, 10.0),
            new SeedFood("Hamburger bò", "1 cái", 520.0, 25.0, 45.0, 28.0),
            new SeedFood("Cà phê sữa đá", "1 ly", 180.0, 3.0, 30.0, 5.0),
            new SeedFood("Trà sữa size M", "1 ly", 450.0, 6.0, 70.0, 16.0),
            new SeedFood("Nước mía", "1 ly 500ml", 250.0, 0.0, 65.0, 0.0),
            new SeedFood("Pepsi/Coca thường", "330ml", 139.0, 0.0, 35.0, 0.0),
            new SeedFood("Sinh tố bơ", "1 ly", 450.0, 6.0, 55.0, 24.0),
            new SeedFood("Sữa đậu nành có đường", "250ml", 140.0, 7.0, 20.0, 4.0)
    );
}
