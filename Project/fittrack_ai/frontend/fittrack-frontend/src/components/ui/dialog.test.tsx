import { useState } from "react";
import { afterEach, describe, expect, it } from "vitest";
import { cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react";
import { Dialog, DialogContent, DialogDescription, DialogTitle } from "./dialog";

function StateOpenedDialog({ autoFocusInput = false }: { autoFocusInput?: boolean }) {
  const [open, setOpen] = useState(false);
  return (
    <>
      <button type="button" onClick={() => setOpen(true)}>Mở hộp thoại</button>
      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent>
          <DialogTitle>Tiêu đề</DialogTitle>
          <DialogDescription>Mô tả</DialogDescription>
          {autoFocusInput && <input aria-label="Từ khóa" autoFocus />}
        </DialogContent>
      </Dialog>
    </>
  );
}

afterEach(cleanup);

describe("DialogContent", () => {
  it.each([false, true])("trả focus về nút đã mở khi đóng hộp thoại mở bằng state (autoFocus=%s)", async (autoFocusInput) => {
    render(<StateOpenedDialog autoFocusInput={autoFocusInput} />);
    const opener = screen.getByRole("button", { name: "Mở hộp thoại" });
    opener.focus();
    fireEvent.click(opener);
    const dialog = await screen.findByRole("dialog");

    fireEvent.keyDown(dialog, { key: "Escape" });

    await waitFor(() => expect(screen.queryByRole("dialog")).not.toBeInTheDocument());
    expect(opener).toHaveFocus();
  });

  it("nút đóng có nhãn tiếng Việt", async () => {
    render(<StateOpenedDialog />);
    fireEvent.click(screen.getByRole("button", { name: "Mở hộp thoại" }));
    expect(await screen.findByRole("button", { name: "Đóng" })).toBeInTheDocument();
  });
});
