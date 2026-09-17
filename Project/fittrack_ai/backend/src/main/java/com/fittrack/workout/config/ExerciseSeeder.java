package com.fittrack.workout.config;

import com.fittrack.workout.entity.Exercise;
import com.fittrack.workout.repository.ExerciseRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

@Component
@RequiredArgsConstructor
public class ExerciseSeeder implements CommandLineRunner {

    private final ExerciseRepository exerciseRepository;

    @Override
    public void run(String... args) {
        Map<String, Exercise> systemExercises = exerciseRepository.findAll().stream()
                .filter(exercise -> exercise.getSubmittedBy() == null)
                .filter(exercise -> !Boolean.TRUE.equals(exercise.getCustom()))
                .collect(Collectors.toMap(
                        exercise -> normalize(exercise.getName()),
                        Function.identity(),
                        (first, ignored) -> first
                ));

        List<Exercise> values = EXERCISES.stream().map(seed -> {
            Exercise exercise = systemExercises.getOrDefault(
                    normalize(seed.name()),
                    Exercise.builder().name(seed.name()).build()
            );
            exercise.setName(seed.name());
            exercise.setMuscleGroup(seed.muscleGroup());
            exercise.setEquipment(seed.equipment());
            exercise.setDescription(seed.description());
            exercise.setCustom(false);
            exercise.setActive(true);
            exercise.setApprovalStatus("APPROVED");
            // Deliberately preserve imageUrl so admins can curate images manually.
            return exercise;
        }).toList();

        exerciseRepository.saveAll(values);
    }

    private String normalize(String value) {
        return value == null ? "" : value.trim().toLowerCase(Locale.ROOT);
    }

    private record SeedExercise(String name, String muscleGroup, String equipment, String description) {}

    private static final List<SeedExercise> EXERCISES = List.of(
            new SeedExercise("Barbell Bench Press", "Chest", "Barbell + Flat Bench", "Nằm chắc trên ghế phẳng, kéo bả vai về sau, hạ thanh đòn có kiểm soát xuống giữa ngực rồi đẩy lên; giữ cổ tay thẳng và chân bám sàn."),
            new SeedExercise("Incline Barbell Bench Press", "Chest", "Barbell + Incline Bench", "Đặt ghế nghiêng khoảng 20–35 độ, giữ bả vai cố định và hạ thanh về phần ngực trên trước khi đẩy lên."),
            new SeedExercise("Dumbbell Bench Press", "Chest", "Dumbbell + Flat Bench", "Nằm ghế phẳng, giữ tạ hai bên ngực, đẩy lên theo vòng cung nhẹ và không va hai quả tạ ở đỉnh."),
            new SeedExercise("Incline Dumbbell Bench Press", "Chest", "Dumbbell + Incline Bench", "Ghế nghiêng 20–35 độ, khuỷu tay thấp hơn vai một chút; hạ tạ chậm và đẩy bằng ngực trên."),
            new SeedExercise("Chest Press Machine", "Chest", "Chest Press Machine", "Chỉnh ghế để tay cầm ngang giữa ngực, giữ lưng áp đệm và đẩy máy mà không khóa cứng khuỷu tay."),
            new SeedExercise("Pec Deck Fly", "Chest", "Pec Deck Machine", "Giữ ngực mở và khuỷu hơi cong, khép hai tay bằng cơ ngực rồi trở lại chậm đến khi ngực được kéo giãn vừa phải."),
            new SeedExercise("Cable Crossover", "Chest", "Cable Machine", "Đứng giữa hai ròng rọc, thân hơi nghiêng, kéo hai tay khép trước ngực và kiểm soát pha mở tay."),
            new SeedExercise("Smith Machine Bench Press", "Chest", "Smith Machine + Flat Bench", "Căn ghế để thanh đi xuống giữa ngực, mở chốt an toàn và thực hiện đường đẩy ổn định trong khung Smith."),
            new SeedExercise("Smith Machine Incline Bench Press", "Chest", "Smith Machine + Incline Bench", "Căn ghế nghiêng dưới thanh Smith, hạ thanh về ngực trên và dùng chốt an toàn ở độ cao phù hợp."),

            new SeedExercise("Lat Pulldown", "Back", "Lat Pulldown Machine", "Kéo thanh về phần ngực trên bằng cách hạ vai và kéo khuỷu xuống; không ngả người quá mức hoặc kéo sau gáy."),
            new SeedExercise("Seated Cable Row", "Back", "Cable Machine", "Giữ cột sống trung lập, kéo tay cầm về bụng và ép bả vai; thả tay có kiểm soát mà không cuộn lưng."),
            new SeedExercise("Chest Supported Row Machine", "Back", "Row Machine", "Áp ngực vào đệm, kéo tay cầm về thân bằng lưng giữa và tránh nhấc ngực khỏi đệm."),
            new SeedExercise("One-Arm Dumbbell Row", "Back", "Dumbbell + Flat Bench", "Chống một tay và gối lên ghế, giữ lưng phẳng rồi kéo tạ về hông; tránh xoay thân."),
            new SeedExercise("Barbell Bent-Over Row", "Back", "Barbell", "Gập hông với lưng trung lập, kéo thanh về bụng dưới và giữ thân ổn định trong toàn bộ hiệp."),
            new SeedExercise("T-Bar Row Machine", "Back", "T-Bar Row Machine", "Giữ ngực trên đệm nếu có, kéo tay cầm về thân và hạ tạ chậm để cơ xô được kéo giãn."),
            new SeedExercise("Assisted Pull-Up Machine", "Back", "Assisted Pull-Up Machine", "Chọn mức trợ lực phù hợp, bắt đầu bằng hạ vai rồi kéo ngực về thanh; không đung đưa người."),
            new SeedExercise("Straight-Arm Cable Pulldown", "Back", "Cable Machine", "Giữ khuỷu hơi cong cố định, kéo thanh từ ngang vai xuống đùi bằng cơ xô và không gập người quá nhiều."),
            new SeedExercise("Back Extension Machine", "Back", "Back Extension Machine", "Căn trục máy gần hông, duỗi thân đến vị trí trung lập và tránh ngửa lưng quá mức."),

            new SeedExercise("Barbell Back Squat", "Legs", "Barbell + Squat Rack", "Đặt thanh chắc trên lưng trên, siết thân, ngồi xuống theo hướng đầu gối cùng chiều mũi chân rồi đứng lên bằng toàn bàn chân."),
            new SeedExercise("Smith Machine Squat", "Legs", "Smith Machine", "Đặt chân hơi trước thanh, mở chốt an toàn, hạ hông có kiểm soát và đẩy lên mà không khóa gối."),
            new SeedExercise("Leg Press Machine", "Legs", "Leg Press Machine", "Đặt bàn chân chắc trên bàn đạp, hạ đến khi hông vẫn áp ghế và đẩy lên mà không khóa cứng đầu gối."),
            new SeedExercise("Hack Squat Machine", "Legs", "Hack Squat Machine", "Giữ lưng và vai áp đệm, hạ người sâu trong tầm kiểm soát rồi đẩy qua giữa bàn chân."),
            new SeedExercise("Leg Extension Machine", "Quadriceps", "Leg Extension Machine", "Căn trục máy với khớp gối, duỗi gối có kiểm soát và không đá tạ bằng quán tính."),
            new SeedExercise("Seated Leg Curl Machine", "Hamstrings", "Leg Curl Machine", "Căn trục máy với đầu gối, cố định đùi dưới đệm và gập gối hết tầm không nhấc hông."),
            new SeedExercise("Lying Leg Curl Machine", "Hamstrings", "Leg Curl Machine", "Giữ hông áp đệm, kéo gót về mông và hạ tạ chậm; tránh ưỡn lưng để lấy đà."),
            new SeedExercise("Romanian Deadlift", "Hamstrings", "Barbell", "Đẩy hông ra sau với gối hơi cong, giữ thanh gần chân và dừng khi gân kheo căng mà lưng vẫn trung lập."),
            new SeedExercise("Dumbbell Romanian Deadlift", "Hamstrings", "Dumbbell", "Giữ hai tạ sát đùi, gập hông ra sau và đứng lên bằng cách siết mông; không biến thành động tác ngồi xổm."),
            new SeedExercise("Hip Thrust Machine", "Glutes", "Hip Thrust Machine", "Đặt đệm đúng nếp hông, thu cằm nhẹ và nâng hông đến khi thân song song sàn mà không ưỡn lưng."),
            new SeedExercise("Smith Machine Hip Thrust", "Glutes", "Smith Machine + Flat Bench", "Tựa bả vai lên ghế, đặt đệm bảo vệ trên thanh và nâng hông bằng cơ mông; dùng chốt an toàn."),
            new SeedExercise("Standing Calf Raise Machine", "Calves", "Calf Raise Machine", "Giữ gối gần thẳng, hạ gót sâu có kiểm soát rồi nhón hết tầm bằng cơ bắp chân."),
            new SeedExercise("Seated Calf Raise Machine", "Calves", "Calf Raise Machine", "Giữ đùi dưới đệm, hạ gót chậm và nhón cao; tránh nảy tạ ở đáy động tác."),
            new SeedExercise("Hip Abduction Machine", "Glutes", "Hip Abduction Machine", "Giữ thân ổn định, mở hai gối bằng cơ mông ngoài và khép lại chậm không để chồng tạ va mạnh."),
            new SeedExercise("Hip Adduction Machine", "Adductors", "Hip Adduction Machine", "Ngồi chắc trên ghế, khép hai đùi trong tầm thoải mái và trở lại có kiểm soát."),

            new SeedExercise("Seated Dumbbell Shoulder Press", "Shoulders", "Dumbbell + Adjustable Bench", "Dựng ghế gần thẳng, giữ lưng áp đệm và đẩy tạ qua đầu; không ưỡn lưng để lấy đà."),
            new SeedExercise("Shoulder Press Machine", "Shoulders", "Shoulder Press Machine", "Chỉnh ghế để tay cầm gần ngang vai, giữ thân áp đệm và đẩy lên trong tầm không đau."),
            new SeedExercise("Smith Machine Shoulder Press", "Shoulders", "Smith Machine + Adjustable Bench", "Căn ghế dưới thanh, hạ thanh về phía trước mặt đến gần cằm và sử dụng chốt an toàn."),
            new SeedExercise("Dumbbell Lateral Raise", "Shoulders", "Dumbbell", "Giữ khuỷu hơi cong, nâng tạ sang hai bên đến gần ngang vai và hạ chậm; không nhún người."),
            new SeedExercise("Cable Lateral Raise", "Shoulders", "Cable Machine", "Đứng cạnh ròng rọc thấp, nâng tay sang bên với lực căng liên tục và giữ vai không nhún lên."),
            new SeedExercise("Reverse Pec Deck", "Shoulders", "Pec Deck Machine", "Áp ngực vào đệm, mở tay ra sau bằng vai sau và lưng trên; tránh dùng quán tính."),

            new SeedExercise("Barbell Biceps Curl", "Biceps", "Barbell", "Giữ khuỷu sát thân, cuốn thanh bằng cơ tay trước và hạ chậm; tránh ngả lưng lấy đà."),
            new SeedExercise("Dumbbell Biceps Curl", "Biceps", "Dumbbell", "Giữ cánh tay trên ổn định, cuốn tạ và xoay lòng bàn tay lên; kiểm soát toàn bộ pha hạ."),
            new SeedExercise("Preacher Curl Machine", "Biceps", "Preacher Curl Machine", "Áp cánh tay lên đệm, cuốn tay cầm mà không nhấc khuỷu và không duỗi khóa khớp ở đáy."),
            new SeedExercise("Cable Biceps Curl", "Biceps", "Cable Machine", "Đứng chắc trước ròng rọc thấp, giữ khuỷu cố định và cuốn tay cầm với lực căng liên tục."),
            new SeedExercise("Triceps Pushdown", "Triceps", "Cable Machine", "Giữ khuỷu sát thân, duỗi cẳng tay xuống hết tầm và trở lại chậm mà không đưa vai ra trước."),
            new SeedExercise("Overhead Cable Triceps Extension", "Triceps", "Cable Machine", "Quay lưng với ròng rọc, giữ khuỷu hướng trước và duỗi tay qua đầu mà không ưỡn lưng."),
            new SeedExercise("Assisted Dip Machine", "Triceps", "Assisted Dip Machine", "Giữ vai hạ xuống, khuỷu hướng sau và hạ người trong tầm vai thoải mái trước khi đẩy lên."),

            new SeedExercise("Ab Crunch Machine", "Core", "Abdominal Machine", "Căn trục máy phù hợp, cuộn lồng ngực về xương chậu bằng cơ bụng và trở lại chậm; không kéo bằng tay."),
            new SeedExercise("Cable Crunch", "Core", "Cable Machine", "Quỳ trước ròng rọc cao, giữ hông tương đối cố định và cuộn thân bằng cơ bụng thay vì kéo tay."),
            new SeedExercise("Captain's Chair Knee Raise", "Core", "Captain's Chair", "Ép lưng vào đệm, nâng gối bằng cách cuộn xương chậu và hạ chân chậm không đung đưa.")
    );
}
