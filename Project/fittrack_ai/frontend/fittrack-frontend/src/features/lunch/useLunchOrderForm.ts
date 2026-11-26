import { useEffect, useMemo, useState } from "react";
import { toast } from "sonner";

import type {
  LunchOrder,
  LunchOrderBatchInput,
  LunchOrderUpdateInput,
  LunchPerson,
  LunchSelectionType,
  LunchTodayResponse,
} from "@/api/lunch.api";
import {
  createCartPortionId,
  createCartRequestId,
  findExtraItems,
  findMainItems,
  portionTotal,
  portionValidationError,
  removeOneExtra,
  requiredItemCount,
  resolveAvailableMenus,
  sumExtraPrice,
  sumNutrition,
  toggleNoteSuggestion,
  type CartPortion,
} from "./lunch-utils";

/** Trạng thái tạo/sửa phần ăn, chọn menu và giỏ đặt cơm. */
export function useLunchOrderForm(today: LunchTodayResponse | undefined, people: LunchPerson[]) {
  const [selectionType, setSelectionType] = useState<LunchSelectionType>("COMBO");
  const [selectedItemIds, setSelectedItemIds] = useState<string[]>([]);
  const [selectedExtraItemIds, setSelectedExtraItemIds] = useState<string[]>([]);
  const [selectedMenuId, setSelectedMenuId] = useState<string | null>(null);
  const [beneficiaryUserId, setBeneficiaryUserId] = useState("");
  const [note, setNote] = useState("");
  const [cartPortions, setCartPortions] = useState<CartPortion[]>([]);
  const [cartRequestId, setCartRequestId] = useState<string | null>(null);
  const [editingOrder, setEditingOrder] = useState<LunchOrder | null>(null);

  const availableMenus = useMemo(() => resolveAvailableMenus(today), [today]);
  // Menu đang chọn biến mất (hoặc lần đầu tải) thì chuyển sang menu đầu tiên và xóa giỏ.
  useEffect(() => {
    const nextId = availableMenus.some((item) => item.id === selectedMenuId)
      ? selectedMenuId
      : availableMenus[0]?.id ?? null;
    if (nextId !== selectedMenuId) {
      const timer = window.setTimeout(() => {
        setSelectedMenuId(nextId);
        setSelectedItemIds([]);
        setSelectedExtraItemIds([]);
        setCartPortions([]);
        setCartRequestId(null);
      }, 0);
      return () => window.clearTimeout(timer);
    }
  }, [availableMenus, selectedMenuId]);

  const menu = availableMenus.find((item) => item.id === selectedMenuId) ?? null;
  const selectedItems = useMemo(() => findMainItems(menu, selectedItemIds), [menu, selectedItemIds]);
  const selectedExtraItems = useMemo(() => findExtraItems(menu, selectedExtraItemIds), [menu, selectedExtraItemIds]);
  const selectedBeneficiary = people.find((person) => person.id === beneficiaryUserId);
  const selectedNutrition = sumNutrition(selectedItems);
  const extrasTotal = sumExtraPrice(selectedExtraItems);
  const currentPortionTotal = (menu?.price ?? 0) + extrasTotal;
  const walletBalance = today?.walletBalance ?? 0;
  const insufficientBalance = !!menu && !beneficiaryUserId && walletBalance < currentPortionTotal;
  const cartTotal = cartPortions.reduce((total, portion) => total + portionTotal(menu, portion), 0);
  const itemsReady = selectedItemIds.length === requiredItemCount(selectionType);

  function resetOrderForm() {
    setSelectionType("COMBO");
    setSelectedItemIds([]);
    setSelectedExtraItemIds([]);
    setBeneficiaryUserId("");
    setNote("");
    setEditingOrder(null);
  }

  function clearCart() {
    setCartPortions([]);
    setCartRequestId(null);
  }

  function selectMenu(menuId: string) {
    if (menuId === selectedMenuId) return;
    setSelectedMenuId(menuId);
    resetOrderForm();
    clearCart();
  }

  function startEditing(order: LunchOrder) {
    setEditingOrder(order);
    setSelectionType(order.selectionType);
    setSelectedItemIds(order.items.filter((item) => item.type !== "EXTRA").map((item) => item.id));
    setSelectedExtraItemIds(order.items.filter((item) => item.type === "EXTRA").map((item) => item.id));
    setBeneficiaryUserId("");
    setNote(order.note ?? "");
    window.scrollTo({ top: 0, behavior: "smooth" });
  }

  function validationError() {
    return portionValidationError({ menu, today, selectionType, selectedCount: selectedItemIds.length });
  }

  function updatePayload(): LunchOrderUpdateInput {
    return { selectionType, itemIds: selectedItemIds, extraItemIds: selectedExtraItemIds, note: note.trim() };
  }

  function addCurrentPortionToCart() {
    setCartPortions((current) => [
      ...current,
      {
        id: createCartPortionId(),
        beneficiaryUserId: beneficiaryUserId || undefined,
        selectionType,
        itemIds: selectedItemIds,
        extraItemIds: selectedExtraItemIds,
        note: note.trim(),
      },
    ]);
    setCartRequestId(null);
    toast.success("Đã thêm phần ăn vào giỏ. Bạn có thể chọn thêm phần khác hoặc đặt tất cả cùng lúc.");
    resetOrderForm();
  }

  function removeCartPortion(portionId: string) {
    setCartPortions((current) => current.filter((item) => item.id !== portionId));
    setCartRequestId(null);
  }

  /** Dữ liệu gửi giỏ; giữ cùng `clientRequestId` khi gửi lại để tránh ghi nợ trùng. */
  function checkoutPayload(): LunchOrderBatchInput | null {
    if (!menu || cartPortions.length === 0) return null;
    const clientRequestId = cartRequestId ?? createCartRequestId();
    if (!cartRequestId) setCartRequestId(clientRequestId);
    return {
      menuId: menu.id,
      clientRequestId,
      portions: cartPortions.map((portion) => ({
        beneficiaryUserId: portion.beneficiaryUserId,
        selectionType: portion.selectionType,
        itemIds: portion.itemIds,
        extraItemIds: portion.extraItemIds,
        note: portion.note,
      })),
    };
  }

  return {
    availableMenus,
    menu,
    selectionType,
    setSelectionType,
    selectedItemIds,
    setSelectedItemIds,
    selectedExtraItemIds,
    addExtra: (itemId: string) => setSelectedExtraItemIds((current) => [...current, itemId]),
    removeExtra: (itemId: string) => setSelectedExtraItemIds((current) => removeOneExtra(current, itemId)),
    beneficiaryUserId,
    setBeneficiaryUserId,
    note,
    setNote,
    toggleNoteSuggestion: (suggestion: string) => setNote(toggleNoteSuggestion(note, suggestion)),
    editingOrder,
    cartPortions,
    selectedItems,
    selectedBeneficiary,
    selectedNutrition,
    extrasTotal,
    currentPortionTotal,
    insufficientBalance,
    cartTotal,
    itemsReady,
    resetOrderForm,
    clearCart,
    selectMenu,
    startEditing,
    validationError,
    updatePayload,
    addCurrentPortionToCart,
    removeCartPortion,
    checkoutPayload,
  };
}

export type LunchOrderForm = ReturnType<typeof useLunchOrderForm>;
