import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import FormField from "./FormField";

describe("FormField", () => {
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
});
