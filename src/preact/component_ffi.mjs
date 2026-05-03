// @ts-check
// d

import { computed } from "@preact/signals";
import { Fragment, h as preact_h } from "preact";
import {
	Children$isNode,
	Children$isNodeSignal,
	Children$isText,
	Children$Node$child,
	Children$NodeSignal$child,
	Children$Text$child,
	Prop$Attr$key,
	Prop$Attr$value,
	Prop$Handler$event,
	Prop$Handler$handle,
	Prop$isAttr,
	Prop$isHandler,
	VNode$VNode$children,
	VNode$VNode$props,
	VNode$VNode$tag,
} from "@/chess/preact/vnode.mjs";
import { CustomType } from "@/gleam_std/gleam.mjs";

/**
 * @param {string} str
 * @returns {string}
 */
function camelCase(str) {
	return str
		.trim()
		.toLowerCase()
		.replace(/[_\-\s]+(.)?/g, (_, char) => (char ? char.toUpperCase() : ""));
}

/**
 * @param {import('@/chess/preact/vnode.mjs').VNode} node
 * @returns {import('preact').ComponentChildren}
 */
export function h(node) {
	/** @type {import('preact').FunctionComponent | string} */
	let tag = VNode$VNode$tag(node);

	if (tag === "$NULL") {
		return null;
	}

	if (tag === "$FRAGMENT") {
		tag = Fragment;
	}

	return preact_h(
		tag,
		serializeProps(VNode$VNode$props(node)),
		serializeChildren(VNode$VNode$children(node)),
	);
}

/**
 * @param {import('@/gleam_std/gleam.mjs').List<import('@/chess/preact/vnode.mjs').Prop$>} props
 * @returns {Record<string, unknown>}
 */
function serializeProps(props) {
	return props.toArray().reduce(
		(
			/** @type {Record<string, unknown>} */
			acc,
			prop,
		) => {
			if (Prop$isAttr(prop)) {
				acc[Prop$Attr$key(prop)] = Prop$Attr$value(prop);

				return acc;
			}

			if (Prop$isHandler(prop)) {
				acc[camelCase(`on_${Prop$Handler$event(prop)}`)] =
					Prop$Handler$handle(prop);

				return acc;
			}

			return acc;
		},
		{},
	);
}

/**
 * @param {import('@/gleam_std/gleam.mjs').List<import('@/chess/preact/vnode.mjs').Children$>} children
 */
function serializeChildren(children) {
	return children
		.toArray()
		.map((child) => {
			if (Children$isNode(child)) {
				const inner = Children$Node$child(child);

				if (inner instanceof CustomType) {
					return h(inner);
				}

				return inner;
			}

			if (Children$isText(child)) {
				return Children$Text$child(child);
			}

			if (Children$isNodeSignal(child)) {
				return computed(() => h(Children$NodeSignal$child(child).value));
			}

			return null;
		})
		.filter(Boolean);
}
