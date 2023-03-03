import _ from "lodash";
import { MembraneWebRTC } from "@jellyfish-dev/membrane-webrtc-js";
import { Socket, Channel } from "phoenix";
import { Subject, Subscription } from "rxjs";

export class WebRTC {
  private _isJoined: boolean;
  webrtc: MembraneWebRTC;
  socket: Socket;
  channel: Channel;
  tracksSubject = new Subject<{
    sourceId: string;
    track: MediaStreamTrack;
    stream: MediaStream;
  }>();
  private tracksSubjectSubscription: Subscription | undefined = undefined;

  constructor(agentId: string, onConnected?: () => void) {
    let token =
      document.querySelector("meta[name='token']")?.getAttribute("content") ||
      "";
    this.socket = new Socket("/socket", {
      params: { token },
    });
    this.socket.connect();
    this.socket.onOpen(() => {
      this.channel = this.socket.channel(`agent:${agentId}`);
      this.channel.join().receive("ok", async () => {
        if (onConnected) onConnected();
        this.channel.push("send-devices", {});
        this.webrtc.join({});
        this.channel.on("screenshot", (resp) => {
          if (!resp.img) return;
          const screenshot = document.getElementById(
            "screenshot"
          ) as HTMLImageElement;
          screenshot.src = resp.img;
          screenshot.classList.remove("hidden");
        });
        this.channel.on("mediaEvent", (event: any) => {
          this.webrtc.receiveMediaEvent(event.data);
        });
      });
    });
    this.webrtc = new MembraneWebRTC({
      callbacks: {
        onSendMediaEvent: (mediaEvent) => {
          this.channel.push("mediaEvent", { data: mediaEvent });
        },
        onConnectionError: (_msg) => {},
        onJoinSuccess: (_peerId, _peersInRoom) => {
          this.tracksSubjectSubscription = this.tracksSubject.subscribe({
            next: async (trackObj) => {
              if (document.getElementById(trackObj.sourceId)) {
                try {
                  if (trackObj.track.kind === "video") {
                    const videoElement = document.getElementById(
                      trackObj.sourceId
                    ) as HTMLVideoElement;
                    videoElement.srcObject = trackObj.stream;
                    await videoElement.play();
                  } else {
                    const audioElement = document.getElementById(
                      trackObj.sourceId
                    ) as HTMLAudioElement;
                    audioElement.srcObject = trackObj.stream;
                    await audioElement.play();
                  }
                } catch (e) {
                  setTimeout(() => {
                    this.tracksSubject.next(trackObj);
                  }, 1000);
                }
              } else {
                setTimeout(() => {
                  this.tracksSubject.next(trackObj);
                }, 1000);
              }
            },
          });
        },
        onJoinError: (_metadata) => {
          this._isJoined = false;
          throw `Peer denied.`;
        },
        onTrackReady: ({ stream, track, metadata }) => {
          this.channel.push("source-activated", {
            sourceId: metadata.deviceId,
          });
          this.tracksSubject.next({
            stream: stream!,
            track: track!,
            sourceId: metadata.deviceId,
          });
        },
        onTrackAdded: async (_ctx) => {},
        onTrackRemoved: ({ track, metadata }) => {
          this.channel.push("source-deactivated", {
            sourceId: metadata.deviceId,
          });
          if (track?.kind === "video") {
            (
              document.getElementById(metadata.deviceId) as HTMLVideoElement
            ).srcObject = null;
          } else {
            (
              document.getElementById(metadata.deviceId) as HTMLAudioElement
            ).srcObject = null;
          }
        },
        onPeerJoined: (_peer) => {},
        onPeerLeft: (_peer) => {},
        onPeerUpdated: (_ctx) => {},
      },
    });
  }

  public join = async () => {
    try {
      if (this.isJoined()) {
        this.channel.push("join", {});
      }
      this.webrtc.join({});
    } catch (error) {
      console.error("Error while joining to the room:", error);
    }
  };

  public isJoined = () => this._isJoined;

  public leave = () => {
    if (this.tracksSubjectSubscription) {
      this.tracksSubjectSubscription.unsubscribe();
      this.tracksSubjectSubscription = undefined;
    }
    this.webrtc.leave();
  };
}
