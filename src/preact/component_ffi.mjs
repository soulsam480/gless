// @ts-check

import { Show } from "@preact/signals/utils";
import { h as preact_h } from "preact";
import {
	Children$isNode,
	Children$isNodeSignal,
	Children$isText,
	Children$isTextArgs,
	Children$isTextSignal,
	Children$Node$child,
	Children$NodeSignal$else_render,
	Children$NodeSignal$state,
	Children$NodeSignal$then_render,
	Children$Text$child,
	Children$TextArgs$args,
	Children$TextArgs$child,
	Prop$Attr$key,
	Prop$Attr$value,
	Prop$AttrSignal$value,
	Prop$Handler$event,
	Prop$Handler$handle,
	Prop$isAttr,
	Prop$isAttrSignal,
	Prop$isHandler,
	VNode$VNode$children,
	VNode$VNode$props,
	VNode$VNode$tag,
} from "@/chess/preact/vnode.mjs";

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
	const tag = VNode$VNode$tag(node);

	if (tag === "$NULL") {
		return null;
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
			if (Prop$isAttr(prop) || Prop$isAttrSignal(prop)) {
				acc[Prop$Attr$key(prop)] =
					Prop$Attr$value(prop) ?? Prop$AttrSignal$value(prop);

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
				return h(Children$Node$child(child));
			}

			if (Children$isNodeSignal(child)) {
				const state = Children$NodeSignal$state(child);
				const then_render = Children$NodeSignal$then_render(child);
				const else_render = Children$NodeSignal$else_render(child);

				return preact_h(Show, {
					when: state,
					children: () => h(then_render()),
					fallback: h(else_render),
				});
			}

			if (Children$isTextArgs(child) || Children$isTextSignal(child)) {
				const args = Children$TextArgs$args(child).toArray();
				const chunks = Children$TextArgs$child(child).split("{}");

				return chunks.flatMap((chunk, index) => {
					if (args[index]) {
						return [chunk, args[index]];
					}

					return [chunk];
				});
			}

			if (Children$isText(child)) {
				return Children$Text$child(child);
			}

			return null;
		})
		.filter(Boolean);
}
