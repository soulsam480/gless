/**
 * @template T
 * @param {import('@preact/signals').Signal<T>} signal
 * @returns T
 */
export function signal_value(signal) {
	return signal.value;
}

/**
 * @template T
 * @param {import('@preact/signals').Signal<T>} signal
 * @returns T
 */
export function signal_peek(signal) {
	return signal.peek();
}

/**
 * @template T
 * @param {import('@preact/signals').Signal<T>} signal
 * @param {import('@preact/signals').Signal<T>} value
 */
export function signal_set(signal, value) {
	signal.value = value;
	return signal;
}
