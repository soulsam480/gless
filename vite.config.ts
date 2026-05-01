import path from "node:path";
import { defineConfig } from "vite";
import gleam from "vite-gleam";

export default defineConfig({
	plugins: [gleam()],
	build: {
		target: "esnext",
		minify: true,
		sourcemap: true,
	},
	resolve: {
		alias: {
			"@/gleam_std": path.resolve(
				__dirname,
				"./build/dev/javascript/gleam_stdlib",
			),
			"@/chess/preact": path.resolve(
				__dirname,
				"./build/dev/javascript/chess/preact",
			),
			react: "preact/compat",
			"react-dom/test-utils": "preact/test-utils",
			"react-dom": "preact/compat", // Must be below test-utils
			"react/jsx-runtime": "preact/jsx-runtime",
		},
	},
});
