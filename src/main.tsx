import "./style.css";
import { render } from "preact";
import { main as Main } from "./chess.gleam";

if (import.meta.env.DEV) {
	await import("preact/devtools");
}

const app = document.getElementById("app");

if (app) {
	render(<Main />, app);
}
