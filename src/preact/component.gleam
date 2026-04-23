import gleam/option
import preact/vnode

pub type PreactComponent

@external(javascript, "./component_ffi.mjs", "h")
pub fn to_preact(node: vnode.VNode) -> PreactComponent

pub type Component(s, p) {
  Component(
    render: fn(option.Option(s), p) -> vnode.VNode,
    state: option.Option(fn(p) -> s),
  )
}

pub fn new(render: fn(option.Option(s), p) -> vnode.VNode) -> Component(s, p) {
  Component(render:, state: option.None)
}

pub fn setup(component: Component(s, p), state: fn(p) -> s) -> Component(s, p) {
  Component(..component, state: option.Some(state))
}

pub fn render(component: Component(s, p), props: p) -> vnode.VNode {
  case component.state {
    option.Some(setup) -> {
      setup(props)
      |> option.Some
      |> component.render(props)
    }
    _ -> {
      component.render(option.None, props)
    }
  }
}
