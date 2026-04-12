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

const h = (
	tag: string,
	attrs: Record<string, string> | Array<[string, string]> = {},
	children: Array<string | HTMLElement> = [],
) => {
	if (Array.isArray(attrs)) {
		attrs = Object.fromEntries(attrs);
	}

	const el = document.createElement(tag);

	for (const attr in attrs) {
		el.setAttribute(attr, attrs[attr]);
	}

	for (const child of children) {
		if (typeof child === "string") {
			el.appendChild(document.createTextNode(child));
		} else {
			el.appendChild(child);
		}
	}

	return el;
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
	on: string | HTMLElement,
	event: string,
	handle: (event: Event) => void,
) => {
	const handler = (event: Event) => {
		if (typeof on === "string" && !event_has_target(event, on)) {
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

const event_has_target = (event: Event, target: string) => {
	const el = event.target as HTMLElement;

	return el.matches(target);
};

export {
	add_listener,
	append_child,
	event_has_target,
	find as $,
	find_gl,
	h,
	rect,
	remove,
	set_attr,
	type THTMLElement,
};
