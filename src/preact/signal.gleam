pub type Signal(a)

@external(javascript, "@preact/signals", "signal")
pub fn signal(a: a) -> Signal(a)

@external(javascript, "@preact/signals", "computed")
pub fn computed(fun: fn() -> a) -> Signal(a)

@external(javascript, "./signal_ffi.mjs", "signal_value")
pub fn value(signal: Signal(a)) -> a

@external(javascript, "./signal_ffi.mjs", "signal_set")
pub fn set(signal: Signal(a), value: a) -> Signal(a)
