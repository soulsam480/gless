import dom
import gleam/list
import gleam/option
import preact/signal

pub type VNode {
  VNode(tag: String, props: List(Prop), children: List(Children))
}

pub type Children {
  Node(child: VNode)
  Text(child: String)
  TextArgs(child: String, args: List(String))
  TextSignal(child: String, args: List(signal.Signal(String)))
  NodeSignal(state: signal.Signal(Bool), then_render: VNode, else_render: VNode)
}

pub type Prop {
  Attr(key: String, value: String)
  AttrSignal(key: String, value: signal.Signal(String))
  Handler(event: String, handle: fn(dom.Event) -> Nil)
}

pub fn new(tag: String) -> VNode {
  VNode(tag: tag, props: [], children: [])
}

pub fn prop(vnode: VNode, key: String, value: String) -> VNode {
  VNode(..vnode, props: list.prepend(vnode.props, Attr(key:, value:)))
}

pub fn signal_prop(
  vnode: VNode,
  key: String,
  value: signal.Signal(String),
) -> VNode {
  VNode(..vnode, props: list.prepend(vnode.props, AttrSignal(key:, value:)))
}

pub fn on(vnode: VNode, event: String, handle: fn(dom.Event) -> Nil) -> VNode {
  VNode(..vnode, props: list.prepend(vnode.props, Handler(event:, handle:)))
}

pub fn children(vnode: VNode, children: List(VNode)) -> VNode {
  VNode(
    ..vnode,
    children: list.map(children, Node(child: _)) |> list.append(vnode.children),
  )
}

pub fn empty() -> VNode {
  VNode("$NULL", [], [])
}

pub fn wrap_if_signal(
  vnode: VNode,
  when: signal.Signal(option.Option(a)),
  render render: fn(a) -> VNode,
) -> VNode {
  VNode(
    ..vnode,
    children: list.append(vnode.children, [
      NodeSignal(
        signal.map(when, option.is_some),
        case signal.value(when) {
          option.Some(v) -> render(v)
          _ -> empty()
        },
        empty(),
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
