import { render, screen } from "@testing-library/react";
import { describe, it, expect } from "vitest";
import App from "./App";

describe("App", () => {
  it("renders Rewards App heading", () => {
    render(<App />);
    expect(screen.getByText(/Rewards App/i)).toBeInTheDocument();
  });
});
