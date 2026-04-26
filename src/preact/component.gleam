import preact/vnode

pub type PreactComponent

@external(javascript, "./component_ffi.mjs", "h")
pub fn to_preact(from node: vnode.VNode) -> PreactComponent

pub type Component(p) {
  Component(render: fn(p) -> vnode.VNode)
}

pub fn new() -> Component(p) {
  Component(render: fn(__) { vnode.empty() })
}

pub fn render(
  for _component: Component(p),
  with factory: fn(p) -> vnode.VNode,
) -> Component(p) {
  Component(render: factory)
}

/// a component that can render empty node
pub fn try_render(
  for _component: Component(p),
  with factory: fn(p) -> Result(vnode.VNode, e),
) -> Component(p) {
  Component(render: fn(props) {
    case factory(props) {
      Ok(node) -> node
      Error(_) -> vnode.empty()
    }
  })
}

pub fn to_vnode(render component: Component(p), with props: p) -> vnode.VNode {
  component.render(props)
}
