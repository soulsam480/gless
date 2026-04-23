import gleam/list
import preact/signal

pub const text_node = "$$TEXT"

pub const text_node_attr = "text"

pub type Event

pub type VNode {
  VNode(tag: String, props: List(Prop), children: List(Children))
}

pub type Children {
  Node(child: VNode)
  Text(child: String)
  TextArgs(child: String, args: List(String))
  TextSignal(child: String, args: List(signal.Signal(String)))
  Empty
}

pub type Prop {
  Attr(key: String, value: String)
  Handler(event: String, handle: fn(Event) -> Nil)
}

pub fn new(tag: String) -> VNode {
  VNode(tag: tag, props: [], children: [])
}

pub fn prop(vnode: VNode, key: String, value: String) -> VNode {
  VNode(..vnode, props: list.prepend(vnode.props, Attr(key:, value:)))
}

pub fn on(vnode: VNode, event: String, handle: fn(Event) -> Nil) -> VNode {
  VNode(..vnode, props: list.prepend(vnode.props, Handler(event:, handle:)))
}

pub fn children(vnode: VNode, children: List(VNode)) -> VNode {
  VNode(
    ..vnode,
    children: list.map(children, Node(child: _)) |> list.append(vnode.children),
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

pub fn text_with_arg(vnode: VNode, text: String, args: List(String)) -> VNode {
  VNode(
    ..vnode,
    children: list.append(vnode.children, [
      TextArgs(child: text, args:),
    ]),
  )
}

pub fn text_signal(
  vnode: VNode,
  text: String,
  args: List(signal.Signal(String)),
) -> VNode {
  VNode(
    ..vnode,
    children: list.append(vnode.children, [
      TextSignal(child: text, args:),
    ]),
  )
}
