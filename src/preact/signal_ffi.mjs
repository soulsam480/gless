import { signal } from "@preact/signals";

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

/**
 * @template T
 * @param {string} name
 * @param {T} initial
 * @returns {import('@preact/signals').Signal<T>}
 */
export function persisted(name, initial) {
	const key = `signal_${name}`;

	let from_local = initial;

	try {
		const stored = localStorage.getItem(key);
		from_local = JSON.parse(stored);
	} catch {
		//
	}

	const sig = signal(from_local);

	sig.subscribe((state) => {
		localStorage.setItem(key, JSON.stringify(state));
	});

	return sig;
}
