import dom
import gleam/javascript/array
import preact/signal
import preact/vnode
import state

pub fn new(state: signal.Signal(state.App)) -> vnode.VNode {
  signal.effect(fn() {
    let theme = signal.value(state).theme

    dom.document_element()
    |> dom.set_attributes([#("data-theme", theme)] |> array.from_list)
  })

  let set_theme = fn(theme: String) {
    state |> signal.setter(state.set_theme(_, theme))
    Nil
  }

  vnode.new("div")
  |> vnode.prop("class", "theme-switcher")
  |> vnode.children([
    theme_option(
      "wood",
      state |> signal.map(fn(s) { s.theme == "wood" }),
      set_theme,
    ),
    theme_option(
      "sky",
      state |> signal.map(fn(s) { s.theme == "sky" }),
      set_theme,
    ),
    theme_option(
      "cyberpunk",
      state |> signal.map(fn(s) { s.theme == "cyberpunk" }),
      set_theme,
    ),
  ])
}

fn theme_option(
  theme: String,
  checked: signal.Signal(Bool),
  on_change: fn(String) -> Nil,
) {
  vnode.new("div")
  |> vnode.children([
    vnode.new("input")
      |> vnode.prop("type", "radio")
      |> vnode.prop("name", "theme")
      |> vnode.prop("value", theme)
      |> vnode.prop("id", theme)
      |> vnode.prop("checked", checked)
      |> vnode.on("change", fn(_) {
        on_change(theme)

        Nil
      }),
    vnode.new("label")
      |> vnode.prop("for", theme)
      |> vnode.text(theme),
  ])
}
