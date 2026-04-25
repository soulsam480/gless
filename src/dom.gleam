import gleam/javascript/array
import gleam/option.{type Option}

@external(javascript, "./dom_ffi.ts", "THTMLElement")
pub type HtmlElement

pub type Event

@external(javascript, "./dom_ffi.ts", "find_gl")
pub fn query(selector: String) -> Option(HtmlElement)

@external(javascript, "./dom_ffi.ts", "find_gl")
pub fn query_in(selector: String, scope: HtmlElement) -> Option(HtmlElement)

@external(javascript, "./dom_ffi.ts", "append_child")
pub fn append_child(el: HtmlElement, children: HtmlElement) -> HtmlElement

@external(javascript, "./dom_ffi.ts", "append_child")
pub fn append(
  el: HtmlElement,
  children: array.Array(HtmlElement),
) -> HtmlElement

pub type Rect {
  Rect(x: Int, y: Int, width: Int, height: Int)
}

@external(javascript, "./dom_ffi.ts", "rect")
pub fn rect(el: HtmlElement) -> Rect

@external(javascript, "./dom_ffi.ts", "remove")
pub fn remove(el: HtmlElement) -> Nil

@external(javascript, "./dom_ffi.ts", "add_global_listener")
pub fn add_global_listener(event: String, handle: fn(Event) -> Nil) -> Nil

@external(javascript, "./dom_ffi.ts", "add_listener")
pub fn listen(on: string, event: String, handle: fn(Event) -> Nil) -> Nil

@external(javascript, "./dom_ffi.ts", "event_matches")
pub fn event_matches(event: Event, matches: String) -> Bool

@external(javascript, "./dom_ffi.ts", "event_stop_propagation")
pub fn event_stop_propagation(event: Event) -> Nil

@external(javascript, "./dom_ffi.ts", "set_attr")
pub fn set_attributes(
  el: HtmlElement,
  attrs: array.Array(#(String, String)),
) -> Nil
