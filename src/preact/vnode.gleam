import dom
import gleam/list
import gleam/option
import preact/signal
import utils

pub type Native

@internal
pub type VNode {
  VNode(tag: String, props: List(Prop), children: List(Children))
}

@internal
pub type Children {
  Node(child: VNode)
  Text(child: String)
  NodeSignal(child: signal.Signal(VNode))
}

@internal
pub type Prop {
  /// NOTE: a prop can be any gleam value
  /// we're swallowing the type here and handle
  /// it downstram in ffi. this is done to make
  /// the render API simple
  Attr(key: String, value: Native)
  Handler(event: String, handle: fn(dom.Event) -> Nil)
}

pub fn new(tag: String) -> VNode {
  VNode(tag: tag, props: [], children: [])
}

pub fn empty() -> VNode {
  VNode("$NULL", [], [])
}

pub fn fragment() -> VNode {
  VNode("$FRAGMENT", [], [])
}

pub fn prop(vnode: VNode, key: String, value: a) -> VNode {
  VNode(
    ..vnode,
    props: list.prepend(vnode.props, Attr(key:, value: to_native(value))),
  )
}

pub fn on(vnode: VNode, event: String, handle: fn(dom.Event) -> Nil) -> VNode {
  VNode(..vnode, props: list.prepend(vnode.props, Handler(event:, handle:)))
}

pub fn child(vnode: VNode, child: VNode) -> VNode {
  VNode(..vnode, children: list.append(vnode.children, [Node(child: child)]))
}

pub fn children(vnode: VNode, children: List(VNode)) -> VNode {
  VNode(
    ..vnode,
    children: list.map(children, Node(child: _)) |> list.append(vnode.children),
  )
}

pub fn signal_child(vnode: VNode, child: signal.Signal(VNode)) -> VNode {
  VNode(..vnode, children: list.append(vnode.children, [NodeSignal(child:)]))
}

pub fn signal_children(
  vnode: VNode,
  child: signal.Signal(List(VNode)),
) -> VNode {
  VNode(
    ..vnode,
    children: list.append(vnode.children, [
      NodeSignal(
        // wrap inside a fragment to match type
        child: signal.map(child, fn(inner) {
          fragment()
          |> children(inner)
        }),
      ),
    ]),
  )
}

pub fn child_if_signal(
  vnode: VNode,
  when condition: signal.Signal(option.Option(a)),
  render render: fn(a) -> VNode,
) -> VNode {
  child_ternary_signal(vnode, condition, render, empty)
}

pub fn child_ternary_signal(
  vnode: VNode,
  when condition: signal.Signal(option.Option(a)),
  render render: fn(a) -> VNode,
  else_render else_render: fn() -> VNode,
) -> VNode {
  VNode(
    ..vnode,
    children: list.append(vnode.children, [
      NodeSignal(
        signal.map(condition, fn(v) {
          case v {
            option.Some(v) -> render(v)
            _ -> else_render()
          }
        }),
      ),
    ]),
  )
}

pub fn text(vnode: VNode, text: String) -> VNode {
  VNode(
    ..vnode,
    children: list.append(vnode.children, [
      Text(child: text),
    ]),
  )
}

pub fn text_with(vnode: VNode, text: String, args: List(String)) -> VNode {
  VNode(
    ..vnode,
    children: list.append(vnode.children, [
      Text(child: utils.format(text, args)),
    ]),
  )
}

pub fn text_signal_with(
  vnode: VNode,
  text_arg: String,
  args: List(signal.Signal(String)),
) -> VNode {
  VNode(
    ..vnode,
    children: list.append(vnode.children, [
      NodeSignal(
        child: signal.computed(fn() {
          fragment()
          |> text(utils.format(text_arg, list.map(args, signal.value)))
        }),
      ),
    ]),
  )
}

@external(javascript, "../dom_ffi.ts", "to_native")
pub fn to_native(value: a) -> Native
