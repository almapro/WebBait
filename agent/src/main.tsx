// import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";
import "./index.css";

const element =
  document.getElementById("root") || document.createElement("div");
element.id = "root";
if (!document.contains(element)) {
  document.body.appendChild(element);
}

const root = ReactDOM.createRoot(element);
root.render(
  // <React.StrictMode>
  <App />
  // </React.StrictMode>,
);
