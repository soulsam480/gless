import preact/vnode

@external(javascript, "preact", "ComponentChildren")
pub type PreactComponent

@external(javascript, "./component_ffi.mjs", "h")
pub fn to_preact(from node: vnode.VNode) -> PreactComponent

pub fn unwrap(
  render component: fn(p) -> Result(vnode.VNode, b),
  with props: p,
) -> vnode.VNode {
  case component(props) {
    Ok(node) -> node
    Error(_) -> vnode.empty()
  }
}
