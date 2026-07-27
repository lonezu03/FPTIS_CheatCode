package com.fittrack.lunch.service;

import com.fittrack.common.exception.ConflictException;
import com.fittrack.common.exception.ResourceNotFoundException;
import com.fittrack.lunch.dto.LunchDtos.DishReviewRequest;
import com.fittrack.lunch.dto.LunchDtos.DishReviewResponse;
import com.fittrack.lunch.entity.*;
import com.fittrack.lunch.mapper.LunchMapper;
import com.fittrack.lunch.repository.LunchDishReviewRepository;
import com.fittrack.lunch.repository.LunchOrderRepository;
import com.fittrack.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Objects;

@Service
@RequiredArgsConstructor
public class LunchReviewService {

    private final LunchOrderRepository orderRepository;
    private final LunchDishReviewRepository reviewRepository;
    private final LunchMapper mapper;
    private final LunchTextFormatter textFormatter;

    @Transactional
    public DishReviewResponse review(User actor, String orderId, DishReviewRequest request) {
        LunchOrder order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy đơn đặt món"));
        if (order.getStatus() != LunchOrderStatus.ACTIVE) {
            throw new ConflictException("Không thể đánh giá đơn đã hủy");
        }
        if (!Objects.equals(order.getBeneficiary().getId(), actor.getId())) {
            throw new org.springframework.security.access.AccessDeniedException(
                    "Chỉ người nhận phần ăn mới có thể đánh giá"
            );
        }

        LunchMenuItem menuItem = order.getItems().stream()
                .map(LunchOrderItem::getMenuItem)
                .filter(item -> Objects.equals(item.getId(), request.menuItemId()))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Món này không thuộc đơn đã đặt"));

        LunchDishReview review = reviewRepository.findByOrderAndMenuItem(order, menuItem)
                .orElseGet(() -> LunchDishReview.builder()
                        .order(order)
                        .menuItem(menuItem)
                        .reviewer(actor)
                        .build());
        review.setRating(request.rating());
        review.setComment(textFormatter.sanitizeNote(request.comment()));
        return mapper.toReviewResponse(reviewRepository.save(review));
    }

    @Transactional(readOnly = true)
    public List<DishReviewResponse> getDishReviews(String menuItemId) {
        return reviewRepository.findByMenuItem_IdAndOrder_StatusOrderByCreatedAtDesc(
                        menuItemId,
                        LunchOrderStatus.ACTIVE
                )
                .stream()
                .map(mapper::toReviewResponse)
                .toList();
    }
}
