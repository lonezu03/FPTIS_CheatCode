import { useMemo, useState } from "react";

import type { ImportLunchMenuInput, LunchMenu } from "@/api/lunch.api";
import { getDefaultLunchCutoff, parseLunchMenu } from "@/lib/format";
import { DEFAULT_PRICE, menuToRawText } from "./admin-lunch-utils";

/** Form state of "Nhập menu mới" / "Sửa menu đã import". */
export function useMenuEditor() {
  const defaultCutoff = getDefaultLunchCutoff();
  const defaultMenuDate = defaultCutoff.slice(0, 10);

  const [menuDate, setMenuDate] = useState(defaultMenuDate);
  const [orderLabel, setOrderLabel] = useState("");
  const [vendorName, setVendorName] = useState("");
  const [cutoffAt, setCutoffAt] = useState(defaultCutoff);
  const [price, setPrice] = useState(DEFAULT_PRICE);
  const [rawMenuText, setRawMenuText] = useState("");
  const [editingMenuId, setEditingMenuId] = useState<string | null>(null);

  const parsedMenu = useMemo(() => parseLunchMenu(rawMenuText), [rawMenuText]);

  function startEditing(menu: LunchMenu) {
    setEditingMenuId(menu.id);
    setMenuDate(menu.menuDate);
    setOrderLabel(menu.orderLabel);
    setVendorName(menu.vendorName);
    setCutoffAt(menu.cutoffAt.slice(0, 16));
    setPrice(menu.price);
    setRawMenuText(menuToRawText(menu));
    window.scrollTo({ top: 0, behavior: "smooth" });
  }

  function reset() {
    setEditingMenuId(null);
    setMenuDate(defaultMenuDate);
    setOrderLabel("");
    setVendorName("");
    setCutoffAt(defaultCutoff);
    setPrice(DEFAULT_PRICE);
    setRawMenuText("");
  }

  function payload(): ImportLunchMenuInput {
    return {
      menuDate,
      orderLabel: orderLabel.trim(),
      vendorName: vendorName.trim(),
      cutoffAt,
      price,
      rawMenuText: rawMenuText.trim(),
    };
  }

  return {
    menuDate,
    orderLabel,
    vendorName,
    cutoffAt,
    price,
    rawMenuText,
    editingMenuId,
    parsedMenu,
    // Picking a sale date moves the cutoff to 10:30 of that day.
    changeMenuDate: (value: string) => { setMenuDate(value); setCutoffAt(`${value}T10:30`); },
    setCutoffAt,
    setOrderLabel,
    setVendorName,
    setPrice,
    setRawMenuText,
    setEditingMenuId,
    startEditing,
    reset,
    payload,
  };
}

export type MenuEditorState = ReturnType<typeof useMenuEditor>;
