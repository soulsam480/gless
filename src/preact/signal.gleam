@external(javascript, "@preact/signals", "Signal")
pub type Signal(a)

@external(javascript, "@preact/signals", "signal")
pub fn new(state a: a) -> Signal(a)

@external(javascript, "@preact/signals", "computed")
pub fn computed(with fun: fn() -> a) -> Signal(a)

@external(javascript, "./signal_ffi.mjs", "signal_value")
pub fn value(signal: Signal(a)) -> a

@external(javascript, "./signal_ffi.mjs", "signal_set")
pub fn set(signal: Signal(a), value: a) -> Signal(a)

@external(javascript, "./signal_ffi.mjs", "signal_peek")
pub fn peek(signal: Signal(a)) -> a

pub fn setter(signal: Signal(a), setter compute: fn(a) -> a) -> Signal(a) {
  set(signal, compute(peek(signal)))
}

@external(javascript, "@preact/signals", "effect")
pub fn effect(run: fn() -> a) -> a

pub fn map(signal: Signal(a), map compute: fn(a) -> b) -> Signal(b) {
  computed(fn() { compute(value(signal)) })
}
