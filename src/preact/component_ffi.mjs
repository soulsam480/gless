import { h as preact_h } from "preact";
import {
	Children$isNode,
	Children$isText,
	Children$isTextArgs,
	Children$isTextSignal,
	Children$Node$child,
	Children$Text$child,
	Children$TextArgs$args,
	Children$TextArgs$child,
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
 * @returns {import('preact').VNode}
 */
export function h(node) {
	return preact_h(
		VNode$VNode$tag(node),
		serializeProps(VNode$VNode$props(node)),
		serializeChildren(VNode$VNode$children(node)),
	);
}

/**
 * @param {import('@/gleam_std/gleam.mjs').List<import('@/chess/preact/vnode.mjs').Prop$>} props
 * @returns {Record<string, unknown>}
 */
function serializeProps(props) {
	return props.toArray().reduce((acc, prop) => {
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
	}, {});
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
