/* eslint-disable no-restricted-globals */
self.addEventListener("message", async (e) => {
  if (e.data.cmd === "screenshot") {
    self.postMessage({
      cmd: "screenshot",
    });
  }
});
