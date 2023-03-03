// We import the CSS which is extracted to its own file by esbuild.
// Remove this line if you add a your own CSS build pipeline (e.g postcss).

// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js";

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import { Dropdown, Tooltip } from "flowbite";
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";
import { WebRTC } from "./webrtc";
import gsap from "gsap";

let csrfToken = document
  .querySelector("meta[name='csrf-token']")!
  .getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: {
    commandsDropdown: {
      mounted() {
        const dropdown = document.getElementById("dropdown");
        if (dropdown) {
          const dropdownFB = new Dropdown(dropdown, this.el, {
            placement: "bottom",
            triggerType: "hover",
          });
          const templateDropdown = document.getElementById("templateDropdown");
          const doubleDropdown = document.getElementById("doubleDropdown");
          if (doubleDropdown) {
            new Dropdown(doubleDropdown, templateDropdown, {
              placement: "right-start",
              triggerType: "hover",
            });
            doubleDropdown.onclick = () => {
              dropdownFB.toggle();
            };
          }
        }
      },
    },
    webrtcControl: {
      mounted() {
        const webrtc = new WebRTC(this.el.dataset.agent_id, () => {
          webrtc.channel.on("screenshot", (resp) => {
            if (resp.img)
              (
                document.getElementById("mainImagesDisplay") as HTMLImageElement
              ).src = resp.img;
          });
        });
        this.webrtc = webrtc;
        webrtc.tracksSubject.subscribe({
          next: ({ sourceId, track, stream }) => {
            const pinSourceBtn = document.getElementById(`pin-${sourceId}`)!;
            if (!!!pinSourceBtn) return;
            const deactivateSourceBtn = document.getElementById(
              `deactivate-${sourceId}`
            )!;
            if (track.kind === "audio") {
              const canvas = document.getElementById(
                `${sourceId}-canvas`
              ) as HTMLCanvasElement;
              canvas.width = canvas.parentElement!.clientWidth;
              canvas.height = canvas.parentElement!.clientHeight;
              window.onresize = () => {
                if (canvas.parentElement) {
                  canvas.width = canvas.parentElement.clientWidth;
                  canvas.height = canvas.parentElement.clientHeight;
                }
              };
              const ctx = canvas.getContext("2d")!;
              const CIRCLE = {
                radiant: 50,
              };
              const drawCircle = () => {
                ctx.clearRect(0, 0, canvas.width, canvas.height);
                ctx.fillStyle = `hsl(297, 60%, 30%)`;
                ctx.beginPath();
                ctx.arc(
                  canvas.width / 2,
                  canvas.height / 2,
                  CIRCLE.radiant,
                  0,
                  Math.PI * 2
                );
                ctx.fill();
                ctx.closePath();
              };
              drawCircle();
              const CONTEXT = new AudioContext();
              const ANALYSER = CONTEXT.createAnalyser();
              const SOURCE = CONTEXT.createMediaStreamSource(stream);
              const DATA_ARR = new Uint8Array(ANALYSER.frequencyBinCount);
              SOURCE.connect(ANALYSER);
              const REPORT = () => {
                ANALYSER.getByteFrequencyData(DATA_ARR);
                const VOLUME = Math.floor((Math.max(...DATA_ARR) / 255) * 100);
                gsap.to(CIRCLE, {
                  duration: 0.1,
                  radiant: gsap.utils.mapRange(0, 100, 25, 100)(VOLUME),
                });
                drawCircle();
              };
              gsap.ticker.add(REPORT);
              deactivateSourceBtn.addEventListener(
                "click",
                () => {
                  CONTEXT.close();
                  gsap.ticker.remove(REPORT);
                },
                { once: true }
              );
            }
            new Tooltip(
              document.getElementById(`pin-${sourceId}-tooltip`),
              pinSourceBtn,
              { triggerType: "hover" }
            );
            deactivateSourceBtn.onclick = () => {
              webrtc.channel.push("deactivate", {
                deviceId: sourceId,
              });
            };
            new Tooltip(
              document.getElementById(`deactivate-${sourceId}-tooltip`),
              deactivateSourceBtn,
              { triggerType: "hover" }
            );
          },
        });
        document.getElementById("getDevicesBtn")!.onclick = () => {
          webrtc.channel.push("send-devices", {});
        };
        document.getElementById("activateSource")!.onclick = () => {
          const sourceToActivate = (
            document.getElementById("sourcesSelect") as HTMLSelectElement
          ).value;
          webrtc.channel.push("activate", { deviceId: sourceToActivate });
        };
        const pinScreenshotBtn = document.getElementById("pinScreenshotBtn")!;
        new Tooltip(
          document.getElementById("pinScreenshotBtnTooltip"),
          pinScreenshotBtn,
          { triggerType: "hover" }
        );
        const lastScreenshotBtn = document.getElementById("lastScreenshotBtn")!;
        lastScreenshotBtn.onclick = () => {
          webrtc.channel.push("send-lastScreenshot", {});
        };
        new Tooltip(
          document.getElementById("lastScreenshotBtnTooltip"),
          lastScreenshotBtn,
          { triggerType: "hover" }
        );
        const sendScreenshotBtn = document.getElementById("sendScreenshotBtn")!;
        sendScreenshotBtn.onclick = () => {
          webrtc.channel.push("screenshot", {});
        };
        new Tooltip(
          document.getElementById("sendScreenshotBtnTooltip"),
          sendScreenshotBtn,
          { triggerType: "hover" }
        );
      },
      updated() {
        this.webrtc.channel.push("send-lastScreenshot", {});
        const pinnedSource = this.el.dataset.pinned_source_id;
        const pinnedSourceKind = this.el.dataset.pinned_source_kind;
        const imageDisplay = document.getElementById(
          "mainImagesDisplay"
        ) as HTMLImageElement;
        const videoDisplay = document.getElementById(
          "mainVideoDisplay"
        ) as HTMLVideoElement;
        const audioDisplay = document.getElementById(
          "mainAudioDisplay"
        ) as HTMLAudioElement;
        const canvas = document.getElementById(
          `mainAudioDisplay-canvas`
        ) as HTMLCanvasElement;
        const canvases = document.getElementsByTagName(`canvas`);
        for (let i = 0; i < canvases.length; i++) {
          const canvas = canvases.item(i);
          if (!!!canvas) continue;
          canvas.width = canvas.parentElement!.clientWidth;
          canvas.height = canvas.parentElement!.clientHeight;
        }
        switch (pinnedSourceKind) {
          case "screenshot":
            imageDisplay.src = (
              document.getElementById(pinnedSource) as HTMLImageElement
            ).src;
            break;
          case "video":
            videoDisplay.srcObject = (
              document.getElementById(pinnedSource) as HTMLVideoElement
            ).srcObject;
            videoDisplay.play();
            break;
          case "audio":
            audioDisplay.srcObject = (
              document.getElementById(pinnedSource) as HTMLAudioElement
            ).srcObject;
            canvas.width = canvas.parentElement!.clientWidth;
            canvas.height = canvas.parentElement!.clientHeight;
            window.onresize = () => {
              canvas.width = canvas.parentElement!.clientWidth;
              canvas.height = canvas.parentElement!.clientHeight;
            };
            const ctx = canvas.getContext("2d")!;
            const stream = (
              document.getElementById(pinnedSource) as HTMLAudioElement
            ).srcObject as MediaStream;
            if (!!!stream) return;
            const CIRCLE = {
              radiant: 50,
            };
            const drawCircle = () => {
              ctx.clearRect(0, 0, canvas.width, canvas.height);
              ctx.fillStyle = `hsl(297, 60%, 30%)`;
              ctx.beginPath();
              ctx.arc(
                canvas.width / 2,
                canvas.height / 2,
                CIRCLE.radiant,
                0,
                Math.PI * 2
              );
              ctx.fill();
              ctx.closePath();
            };
            drawCircle();
            const CONTEXT = new AudioContext();
            const ANALYSER = CONTEXT.createAnalyser();
            const SOURCE = CONTEXT.createMediaStreamSource(stream);
            const DATA_ARR = new Uint8Array(ANALYSER.frequencyBinCount);
            SOURCE.connect(ANALYSER);
            const REPORT = () => {
              ANALYSER.getByteFrequencyData(DATA_ARR);
              const VOLUME = Math.floor((Math.max(...DATA_ARR) / 255) * 100);
              gsap.to(CIRCLE, {
                duration: 0.1,
                radiant: gsap.utils.mapRange(0, 50, 100, 200)(VOLUME),
              });
              drawCircle();
            };
            gsap.ticker.add(REPORT);
            this.handleEvent("source-deactivated", ({ sourceId }) => {
              if (sourceId === pinnedSource) {
                CONTEXT.close();
                gsap.ticker.remove(REPORT);
              }
            });
            audioDisplay.play();
            break;
        }
      },
    },
  },
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show());
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
// window.liveSocket = liveSocket;

if (
  localStorage.getItem("theme") === "dark" ||
  (localStorage.getItem("theme") === null &&
    window.matchMedia("(prefers-color-scheme: dark)").matches)
) {
  document.documentElement.classList.add("dark");
  document.querySelector("#darkModeToggle")!.innerHTML =
    "<i class='fa-solid fa-sun'></i>";
} else {
  localStorage.setItem("theme", "light");
  document.querySelector("#darkModeToggle")!.innerHTML =
    "<i class='fa-solid fa-moon'></i>";
}

window.addEventListener("toggleDarkMode", () => {
  if (localStorage.getItem("theme") !== "dark") {
    localStorage.setItem("theme", "dark");
    document.documentElement.classList.add("dark");
    document.querySelector("#darkModeToggle")!.innerHTML =
      "<i class='fa-solid fa-sun'></i>";
  } else {
    localStorage.setItem("theme", "light");
    document.documentElement.classList.remove("dark");
    document.querySelector("#darkModeToggle")!.innerHTML =
      "<i class='fa-solid fa-moon'></i>";
  }
});
