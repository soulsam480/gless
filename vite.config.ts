import path from "node:path";
import { defineConfig } from "vite";
import gleam from "vite-gleam";

export default defineConfig({
	plugins: [gleam()],
	build: {
		target: "esnext",
		minify: false,
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
		},
	},
});
