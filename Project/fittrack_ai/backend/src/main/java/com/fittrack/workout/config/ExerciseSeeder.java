package com.fittrack.workout.config;

import com.fittrack.workout.entity.Exercise;
import com.fittrack.workout.repository.ExerciseRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class ExerciseSeeder implements CommandLineRunner {

    private final ExerciseRepository exerciseRepository;

    @Override
    public void run(String... args) {
        if (exerciseRepository.count() > 0) return;

        exerciseRepository.save(Exercise.builder()
                .name("Dumbbell Shoulder Press")
                .muscleGroup("Shoulder")
                .equipment("Dumbbell")
                .description("Press dumbbells overhead while seated or standing.")
                .build());

        exerciseRepository.save(Exercise.builder()
                .name("Dumbbell Squat")
                .muscleGroup("Legs")
                .equipment("Dumbbell")
                .description("Squat while holding dumbbell at chest.")
                .build());

        exerciseRepository.save(Exercise.builder()
                .name("Pull Up")
                .muscleGroup("Back")
                .equipment("Pull-up Bar")
                .description("Bodyweight vertical pulling movement.")
                .build());
    }
}