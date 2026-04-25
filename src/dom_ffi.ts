import { Option$None, Option$Some } from "@/gleam_std/gleam/option.mjs";

/**
 * @private only for gleam compat
 */
type THTMLElement = HTMLElement;

const find = (el: string, scope: HTMLElement = document.documentElement) =>
	scope.querySelector(el);

const find_gl = (el: string, scope?: HTMLElement) => {
	const found = find(el, scope);

	if (found) {
		return Option$Some(found);
	}

	return Option$None();
};

const set_attr = (
	element: HTMLElement,
	attrs: Record<string, string> | Array<[string, string]>,
) => {
	if (Array.isArray(attrs)) {
		attrs = Object.fromEntries(attrs);
	}

	for (const attr in attrs) {
		element.setAttribute(attr, attrs[attr]);
	}
};

const append_child = (el: HTMLElement, ...children: HTMLElement[]) => {
	el.append(...children);

	return el;
};

const rect = (el: HTMLElement) => {
	return el.getBoundingClientRect();
};

const remove = (el: HTMLElement) => {
	el.remove();
};

const add_listener = (
	on: string | HTMLElement | Window,
	event: string,
	handle: (event: Event) => void,
) => {
	const handler = (event: Event) => {
		if (typeof on === "string" && !event_matches(event, on)) {
			return;
		}

		handle(event);
	};

	const on_target = typeof on === "string" ? document : on;

	on_target.addEventListener(event, handler);

	return () => {
		on_target.removeEventListener(event, handler);
	};
};

const add_global_listener = (
	event: string,
	handler: (event: Event) => void,
) => {
	add_listener(window, event, handler);
};

const event_matches = (event: Event, target: string) => {
	const el = event.target as HTMLElement;

	return el.matches(target);
};

const event_stop_propagation = (event: Event) => {
	event.stopPropagation();
};

export {
	add_global_listener,
	add_listener,
	append_child,
	event_matches,
	event_stop_propagation,
	find as $,
	find_gl,
	rect,
	remove,
	set_attr,
	type THTMLElement,
};
