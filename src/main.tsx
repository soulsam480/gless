import "preact/debug";
import "./style.css";

import { render } from "preact";
import { render_board } from "./board.gleam";

const component = render_board();

const app = document.getElementById("app");

if (app) {
	render(component, app);
}
