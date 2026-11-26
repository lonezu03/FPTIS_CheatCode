import * as React from "react"

/*
 * Radix chỉ trả focus về DialogTrigger. Nhiều hộp thoại trong app mở bằng state (không có
 * Trigger), nên khi đóng focus rơi về <body> (WCAG 2.4.3). Hook này ghi lại phần tử đã mở hộp
 * thoại và trả focus về đó khi đóng, trừ khi phần tử đã bị gỡ khỏi trang.
 *
 * Ô nhập có autoFocus trong hộp thoại nhận focus trước khi Radix chạy onOpenAutoFocus (hoặc
 * Radix bỏ qua sự kiện này), nên giữ thêm vài phần tử được focus gần nhất để tìm lại phần tử
 * nằm ngoài hộp thoại.
 */
const recentFocus: HTMLElement[] = []

if (typeof document !== "undefined") {
  document.addEventListener(
    "focusin",
    (event) => {
      const target = event.target
      if (!(target instanceof HTMLElement)) return
      const index = recentFocus.indexOf(target)
      if (index >= 0) recentFocus.splice(index, 1)
      recentFocus.unshift(target)
      recentFocus.length = Math.min(recentFocus.length, 8)
    },
    true
  )
}

function findOpener(container: EventTarget | null): HTMLElement | null {
  const inside = (el: Element) => container instanceof Node && container.contains(el)
  const active = document.activeElement
  if (active instanceof HTMLElement && active !== document.body && !inside(active)) return active
  return recentFocus.find((el) => el.isConnected && el !== document.body && !inside(el)) ?? null
}

export function useReturnFocus(
  onOpenAutoFocus?: (event: Event) => void,
  onCloseAutoFocus?: (event: Event) => void
) {
  const openerRef = React.useRef<HTMLElement | null>(null)
  return {
    onOpenAutoFocus: (event: Event) => {
      openerRef.current = findOpener(event.currentTarget ?? event.target)
      onOpenAutoFocus?.(event)
    },
    onCloseAutoFocus: (event: Event) => {
      onCloseAutoFocus?.(event)
      // Radix bỏ qua onOpenAutoFocus khi focus đã nằm trong hộp thoại (ô autoFocus); khi đó tìm
      // lại phần tử mở từ lịch sử focus. Phần tử trong hộp thoại đã bị gỡ nên tự bị loại.
      const opener = openerRef.current ?? findOpener(event.currentTarget ?? event.target)
      openerRef.current = null
      if (event.defaultPrevented) return
      if (opener && opener.isConnected) {
        event.preventDefault()
        opener.focus({ preventScroll: true })
      }
    },
  }
}
