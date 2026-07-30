import api from "./axios";

export type LunchSelectionType = "COMBO" | "SINGLE";
export type LunchItemType = "REGULAR" | "SPECIAL";
export type LunchMenuStatus = "OPEN" | "CLOSED" | string;
export type LunchOrderStatus = "ACTIVE" | "CANCELLED" | string;
export type LunchPaymentStatus = "PAID_FUND" | "PAID_EXTERNAL" | "UNPAID" | string;

export type LunchMenuItem = {
  id: string;
  name: string;
  type: LunchItemType;
  sortOrder: number;
  imageUrl?: string | null;
  calories?: number | null;
  protein?: number | null;
  carbs?: number | null;
  fat?: number | null;
  averageRating: number;
  reviewCount: number;
};

export type LunchDishReview = {
  id: string;
  orderId: string;
  menuItemId: string;
  dishName: string;
  reviewer: LunchOrderParty;
  rating: number;
  comment?: string | null;
  createdAt: string;
  updatedAt: string;
};

export type LunchMenu = {
  id: string;
  menuDate: string;
  orderLabel: string;
  vendorName: string;
  cutoffAt: string;
  price: number;
  status: LunchMenuStatus;
  acceptingOrders: boolean;
  summarized: boolean;
  regularItems: LunchMenuItem[];
  specialItems: LunchMenuItem[];
  totalOrders: number;
  unpaidOrders: number;
};

export type LunchPerson = {
  id: string;
  fullName: string;
  email: string;
  walletBalance?: number;
  unpaidOrders?: number;
};

export type LunchOrderParty = {
  id: string;
  fullName: string;
  email?: string;
};

export type LunchOrder = {
  id: string;
  menuId: string;
  menuDate: string;
  beneficiary: LunchOrderParty;
  payer: LunchOrderParty | null;
  orderedBy: LunchOrderParty;
  selectionType: LunchSelectionType;
  items: LunchMenuItem[];
  note: string | null;
  displayText: string;
  price: number;
  paymentStatus: LunchPaymentStatus;
  status: LunchOrderStatus;
  createdAt: string;
  reviews: LunchDishReview[];
};

export type LunchTodayResponse = {
  menu: LunchMenu | null;
  walletBalance: number;
  outstandingDebt: number;
  canOrder: boolean;
  blockReason: string | null;
  myMealOrder: LunchOrder | null;
  ordersPlacedByMe: LunchOrder[];
};

export type LunchWalletTransaction = {
  id: string;
  type: string;
  amount: number;
  balanceAfter?: number | null;
  note?: string | null;
  relatedOrderId?: string | null;
  createdAt: string;
  createdBy?: LunchOrderParty | null;
};

export type LunchOrderInput = {
  menuId: string;
  beneficiaryUserId?: string;
  selectionType: LunchSelectionType;
  itemIds: string[];
  note: string;
};

export type LunchOrderUpdateInput = {
  selectionType: LunchSelectionType;
  itemIds: string[];
  note: string;
};

export type ImportLunchMenuInput = {
  menuDate: string;
  orderLabel: string;
  vendorName: string;
  cutoffAt: string;
  price: number;
  rawMenuText: string;
};

export type LunchDishCount = {
  dishName: string;
  count: number;
};

export type LunchSummary = {
  totalOrders: number;
  paidFundOrders: number;
  paidExternalOrders: number;
  unpaidOrders: number;
  totalAmount: number;
  orderText: string;
  dishCounts: LunchDishCount[];
};

export type LunchMember = {
  id: string;
  fullName: string;
  email: string;
  walletBalance: number;
  outstandingDebt: number;
  unpaidOrders: number;
};

export type LunchPaymentSettings = {
  qrImageUrl?: string | null;
  bankName?: string | null;
  accountName?: string | null;
  accountNumber?: string | null;
  instructions?: string | null;
  updatedAt?: string | null;
};

export type LunchPaymentRequestType = "FUND_TOP_UP" | "DEBT_PAYMENT";
export type LunchPaymentRequestStatus = "PENDING" | "APPROVED" | "REJECTED";

export type LunchPaymentRequest = {
  id: string;
  user: LunchOrderParty;
  type: LunchPaymentRequestType;
  amount: number;
  status: LunchPaymentRequestStatus;
  note?: string | null;
  reviewedBy?: LunchOrderParty | null;
  reviewNote?: string | null;
  createdAt: string;
  reviewedAt?: string | null;
};

export type LunchNotification = {
  id: string;
  type: string;
  title: string;
  message: string;
  referenceType?: string | null;
  referenceId?: string | null;
  createdAt: string;
  readAt?: string | null;
};

export type LunchNotificationList = {
  unreadCount: number;
  notifications: LunchNotification[];
};

export type LunchTopUpInput = {
  userId: string;
  amount: number;
  note: string;
};

export const lunchKeys = {
  all: ["lunch"] as const,
  today: () => [...lunchKeys.all, "today"] as const,
  people: () => [...lunchKeys.all, "people"] as const,
  history: () => [...lunchKeys.all, "orders", "history"] as const,
  transactions: () => [...lunchKeys.all, "wallet", "transactions"] as const,
  admin: () => [...lunchKeys.all, "admin"] as const,
  adminMenus: (from: string, to: string) => [...lunchKeys.admin(), "menus", from, to] as const,
  adminOrders: (menuId: string) => [...lunchKeys.admin(), "menus", menuId, "orders"] as const,
  adminMembers: () => [...lunchKeys.admin(), "members"] as const,
  paymentSettings: () => [...lunchKeys.all, "payment-settings"] as const,
  paymentRequests: () => [...lunchKeys.all, "payment-requests"] as const,
  adminPaymentRequests: () => [...lunchKeys.admin(), "payment-requests"] as const,
  notifications: () => [...lunchKeys.all, "notifications"] as const,
};

export async function getTodayLunch(): Promise<LunchTodayResponse> {
  const response = await api.get<LunchTodayResponse>("/lunch/today");
  return response.data;
}

export async function getLunchPeople(): Promise<LunchPerson[]> {
  const response = await api.get<LunchPerson[]>("/lunch/people");
  return response.data;
}

export async function getLunchWalletTransactions(): Promise<LunchWalletTransaction[]> {
  const response = await api.get<LunchWalletTransaction[]>("/lunch/wallet/transactions");
  return response.data;
}

export async function getLunchOrderHistory(): Promise<LunchOrder[]> {
  const response = await api.get<LunchOrder[]>("/lunch/orders/history");
  return response.data;
}

export async function createLunchOrder(payload: LunchOrderInput): Promise<LunchOrder> {
  const response = await api.post<LunchOrder>("/lunch/orders", payload);
  return response.data;
}

export async function updateLunchOrder(orderId: string, payload: LunchOrderUpdateInput): Promise<LunchOrder> {
  const response = await api.put<LunchOrder>(`/lunch/orders/${orderId}`, payload);
  return response.data;
}

export async function deleteLunchOrder(orderId: string): Promise<void> {
  await api.delete(`/lunch/orders/${orderId}`);
}

export async function getAdminLunchMenus(from: string, to: string): Promise<LunchMenu[]> {
  const response = await api.get<LunchMenu[]>("/lunch/admin/menus", {
    params: { from, to },
  });
  return response.data;
}

export async function importLunchMenu(payload: ImportLunchMenuInput): Promise<LunchMenu> {
  const response = await api.post<LunchMenu>("/lunch/admin/menus/import", payload);
  return response.data;
}

export async function getAdminLunchOrders(menuId: string): Promise<LunchOrder[]> {
  const response = await api.get<LunchOrder[]>(`/lunch/admin/menus/${menuId}/orders`);
  return response.data;
}

export async function summarizeLunchMenu(menuId: string): Promise<LunchSummary> {
  const response = await api.post<LunchSummary>(`/lunch/admin/menus/${menuId}/summarize`);
  return response.data;
}

export async function closeLunchMenu(menuId: string): Promise<LunchMenu> {
  const response = await api.post<LunchMenu>(`/lunch/admin/menus/${menuId}/close`);
  return response.data;
}

export async function reopenLunchMenu(menuId: string): Promise<LunchMenu> {
  const response = await api.post<LunchMenu>(`/lunch/admin/menus/${menuId}/reopen`);
  return response.data;
}

export async function getAdminLunchMembers(): Promise<LunchMember[]> {
  const response = await api.get<LunchMember[]>("/lunch/admin/members");
  return response.data;
}

export async function topUpLunchFund(payload: LunchTopUpInput): Promise<LunchWalletTransaction> {
  const response = await api.post<LunchWalletTransaction>("/lunch/admin/funds/top-up", payload);
  return response.data;
}

export async function confirmLunchExternalPayment(orderId: string): Promise<LunchOrder> {
  const response = await api.post<LunchOrder>(`/lunch/admin/orders/${orderId}/confirm-external`);
  return response.data;
}

export async function updateLunchMenuItem(
  itemId: string,
  payload: {
    name?: string;
    imageUrl?: string | null;
    calories?: number | null;
    protein?: number | null;
    carbs?: number | null;
    fat?: number | null;
  },
): Promise<LunchMenuItem> {
  const response = await api.put<LunchMenuItem>(`/lunch/admin/menu-items/${itemId}`, payload);
  return response.data;
}

export async function reviewLunchDish(
  orderId: string,
  payload: { menuItemId: string; rating: number; comment: string },
): Promise<LunchDishReview> {
  const response = await api.put<LunchDishReview>(`/lunch/orders/${orderId}/reviews`, payload);
  return response.data;
}

export async function getLunchDishReviews(menuItemId: string): Promise<LunchDishReview[]> {
  const response = await api.get<LunchDishReview[]>(`/lunch/menu-items/${menuItemId}/reviews`);
  return response.data;
}

export async function getLunchPaymentSettings(): Promise<LunchPaymentSettings> {
  const response = await api.get<LunchPaymentSettings>("/lunch/payment-settings");
  return response.data;
}

export async function updateLunchPaymentSettings(payload: LunchPaymentSettings): Promise<LunchPaymentSettings> {
  const response = await api.put<LunchPaymentSettings>("/lunch/admin/payment-settings", payload);
  return response.data;
}

export async function createLunchPaymentRequest(payload: {
  type: LunchPaymentRequestType;
  amount: number;
  note: string;
}): Promise<LunchPaymentRequest> {
  const response = await api.post<LunchPaymentRequest>("/lunch/payment-requests", payload);
  return response.data;
}

export async function getMyLunchPaymentRequests(): Promise<LunchPaymentRequest[]> {
  const response = await api.get<LunchPaymentRequest[]>("/lunch/payment-requests/mine");
  return response.data;
}

export async function getAdminLunchPaymentRequests(): Promise<LunchPaymentRequest[]> {
  const response = await api.get<LunchPaymentRequest[]>("/lunch/admin/payment-requests");
  return response.data;
}

export async function approveLunchPaymentRequest(id: string, note = ""): Promise<LunchPaymentRequest> {
  const response = await api.post<LunchPaymentRequest>(`/lunch/admin/payment-requests/${id}/approve`, { note });
  return response.data;
}

export async function rejectLunchPaymentRequest(id: string, note: string): Promise<LunchPaymentRequest> {
  const response = await api.post<LunchPaymentRequest>(`/lunch/admin/payment-requests/${id}/reject`, { note });
  return response.data;
}

export async function getLunchNotifications(): Promise<LunchNotificationList> {
  const response = await api.get<LunchNotificationList>("/notifications");
  return response.data;
}

export async function markLunchNotificationRead(id: string): Promise<void> {
  await api.patch(`/notifications/${id}/read`);
}

export async function markAllLunchNotificationsRead(): Promise<void> {
  await api.post("/notifications/read-all");
}
