defmodule LiveFlow.Components.MinimapTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  alias LiveFlow.{Components, Node, State}

  defp viewport_rect(html) do
    [_, style] = Regex.run(~r/class="lf-minimap-viewport"\s+style="([^"]+)"/, html)

    for [_, k, v] <- Regex.scan(~r/(left|top|width|height):\s*([-\d.eE+]+)px/, style),
        into: %{},
        do: {k, String.to_float(if String.contains?(v, "."), do: v, else: v <> ".0")}
  end

  defp render_flow(viewport_attrs) do
    nodes = [
      Node.new("a", %{x: 0, y: 0}, %{}) |> Node.set_dimensions(100, 50),
      Node.new("b", %{x: 900, y: 0}, %{}) |> Node.set_dimensions(100, 50)
    ]

    flow = State.new(nodes: nodes) |> State.update_viewport(viewport_attrs)

    render_component(Components.Flow,
      id: "f",
      flow: flow,
      opts: %{minimap: true}
    )
  end

  test "viewport rectangle is sized from the reported container size" do
    small = render_flow(%{"zoom" => 1, "container_width" => 500, "container_height" => 400})
    large = render_flow(%{"zoom" => 1, "container_width" => 1000, "container_height" => 400})

    assert_in_delta viewport_rect(large)["width"], viewport_rect(small)["width"] * 2, 0.01
    assert_in_delta viewport_rect(large)["height"], viewport_rect(small)["height"], 0.01
  end

  test "content is centered in the 200x150 minimap" do
    # bounds 1000x50 → scale 0.18 → content 180x9, centered at x=10, y=(150-9)/2
    rect = viewport_rect(render_flow(%{"x" => 0, "y" => 0, "zoom" => 1}))

    assert_in_delta rect["left"], 10.0, 0.01
    assert_in_delta rect["top"], (150 - 50 * 0.18) / 2, 0.01
  end
end
