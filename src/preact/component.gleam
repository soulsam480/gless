import preact/vnode

pub type Component

@external(javascript, "./component_ffi.mjs", "h")
pub fn to_component(node: vnode.VNode) -> Component
