// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"
import { bgStarShow } from "./bgStarShow"

document.addEventListener("turbo:load", function() {
  bgStarShow();
});

document.addEventListener("DOMContentLoaded", function() {
  bgStarShow();
});
