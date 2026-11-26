import { cleanup, render, screen } from "@testing-library/react";
import { afterEach, describe, expect, it } from "vitest";
import { Input } from "@/components/ui/input";
import FormField from "./FormField";

describe("FormField", () => {
  afterEach(cleanup);

  it("gắn nhãn, đơn vị và hướng dẫn với ô nhập", () => {
    render(
      <FormField
        label="Cân nặng"
        htmlFor="weight"
        unit="kg"
        hint="Cân vào buổi sáng sau khi thức dậy."
        required
      >
        <input id="weight" />
      </FormField>,
    );

    expect(screen.getByLabelText(/Cân nặng/)).toBeInTheDocument();
    expect(screen.getByText("kg")).toBeInTheDocument();
    expect(screen.getByText("Cân vào buổi sáng sau khi thức dậy.")).toBeInTheDocument();
  });
  it("tự gắn nhãn và hướng dẫn khi không truyền htmlFor", () => {
    render(
      <FormField label="Từ ngày" hint="Ngày bắt đầu." required>
        <Input type="date" />
      </FormField>,
    );

    const input = screen.getByLabelText(/Từ ngày/);
    expect(input).toHaveAccessibleName("Từ ngày");
    expect(input).toHaveAttribute("type", "date");
    expect(input).toHaveAccessibleDescription("Ngày bắt đầu.");
    expect(input).toBeRequired();
  });
});
