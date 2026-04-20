/**
 * @template T
 * @param {import('@/chess/preact/signal.mjs').Signal<T>} signal
 * @returns T
 */
export function signal_value(signal) {
	return signal.value;
}

/**
 * @template T
 * @param {import('@/chess/preact/signal.mjs').Signal<T>} signal
 * @param {import('@/chess/preact/signal.mjs').Signal<T>} value
 */
export function signal_set(signal, value) {
	signal.value = value;
	return signal;
}
