import _ from "lodash";
import { MEDIA_CONSTRAINTS /* , LOCAL_PEER_ID */ } from "./consts";
import {
  // addVideoElement,
  // getRoomId,
  // removeVideoElement,
  setErrorMessage,
  // setParticipantsList,
  attachStream,
  resetStreamElements,
  elementId,
} from "./room_ui";
import {
  MembraneWebRTC,
  // Peer,
  SerializedMediaEvent,
} from "@membraneframework/membrane-webrtc-js";
import { Socket, Channel } from "phoenix";
import { Subject, Subscription } from "rxjs";

export class Room {
  private _isJoined: boolean;
  private displayName: string;
  private my_peer_id = "";
  private my_video_track_id = "";
  private my_audio_track_id = "";
  private localStream: MediaStream = new MediaStream();
  private localAudioStream: MediaStream | undefined;
  private localVideoStream: MediaStream | undefined;
  private webrtc: MembraneWebRTC;
  private socket: Socket;
  private webrtcSocketRefs: string[] = [];
  private webrtcChannel: Channel;
  private tracksSubject = new Subject<{
    peerId: string;
    track: MediaStreamTrack;
    stream: MediaStream;
  }>();
  private tracksSubjectPeersSubscription: Subscription | undefined = undefined;

  constructor(roomId: string, name: string) {
    this.socket = new Socket("/socket");
    this.socket.connect();
    this.displayName = name;
    this.webrtcChannel = this.socket.channel(`room:${roomId}`, { name });
    this.webrtcChannel.join();

    this.webrtcChannel.on("connect", async () => {
      await this.join();
    });
    this.webrtcChannel.on("toggle-video", async () => {
      if (this.localVideoStream && this.my_video_track_id) {
        this.webrtc.removeTrack(this.my_video_track_id);
        this.my_video_track_id = "";
        this.localVideoStream.getTracks().forEach((track) => {
          track.stop();
          this.localStream.removeTrack(track);
        });
        this.localVideoStream = undefined;
        resetStreamElements(this.my_peer_id, true, "VIDEO");
      } else {
        try {
          if (this.localStream.getVideoTracks().length === 0) {
            await this.requestVideoStream();
          } else {
            this.localVideoStream = this.localStream;
          }
          this.localVideoStream!.getVideoTracks().forEach((track) => {
            this.my_video_track_id = this.webrtc.addTrack(
              track,
              this.localVideoStream!,
              {}
            );
          });
        } catch (__) {}
      }
    });
    this.webrtcChannel.on("toggle-audio", async () => {
      if (this.localAudioStream && this.my_video_track_id) {
        this.webrtc.removeTrack(this.my_audio_track_id);
        this.my_audio_track_id = "";
        this.localAudioStream.getTracks().forEach((track) => {
          track.stop();
          this.localStream.removeTrack(track);
        });
        this.localAudioStream = undefined;
        resetStreamElements(this.my_peer_id, true, "AUDIO");
      } else {
        try {
          if (this.localStream.getAudioTracks().length === 0) {
            await this.requestAudioStream();
          } else {
            this.localAudioStream = this.localStream;
          }
          this.localAudioStream!.getAudioTracks().forEach((track) => {
            this.my_audio_track_id = this.webrtc.addTrack(
              track,
              this.localAudioStream!,
              {}
            );
          });
        } catch (__) {}
      }
    });
    this.webrtcChannel.on("disconnect", () => {
      this.leave();
      if (this.tracksSubjectPeersSubscription)
        this.tracksSubjectPeersSubscription.unsubscribe();
      this.tracksSubject.complete();
      this.tracksSubject = new Subject();
    });
    this.webrtcChannel.onError(() => {
      this.socketOff();
      this._isJoined = false;
    });
    this.webrtcChannel.onClose(() => {
      // this.socketOff();
      this._isJoined = false;
      // window.location.reload();
    });

    this.webrtcSocketRefs.push(this.socket.onError(this.leave));
    this.webrtcSocketRefs.push(this.socket.onClose(this.leave));

    this.webrtc = new MembraneWebRTC({
      callbacks: {
        onSendMediaEvent: (mediaEvent: SerializedMediaEvent) => {
          this.webrtcChannel.push("mediaEvent", { data: mediaEvent });
        },
        onConnectionError: setErrorMessage,
        onJoinSuccess: (peerId, _peersInRoom) => {
          this.tracksSubjectPeersSubscription = this.tracksSubject.subscribe({
            next: async (trackObj) => {
              const trackElementId = elementId(
                trackObj.peerId,
                trackObj.track.kind === "video" ? "video" : "audio"
              );
              if (document.getElementById(trackElementId)) {
                try {
                  await attachStream(
                    trackObj.stream,
                    trackObj.peerId,
                    trackObj.track.kind === "video" ? "VIDEO" : "AUDIO"
                  );
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
          this.my_peer_id = peerId;
          this._isJoined = true;
          if (this.localAudioStream) {
            this.localAudioStream.getAudioTracks().forEach((track) => {
              const trackId = this.webrtc.addTrack(
                track,
                this.localAudioStream!,
                {}
              );
              this.my_audio_track_id = trackId;
            });
          }
          if (this.localVideoStream) {
            this.localVideoStream!.getVideoTracks().forEach((track) => {
              const trackId = this.webrtc.addTrack(
                track,
                this.localVideoStream!,
                {}
              );
              this.my_video_track_id = trackId;
            });
          }
        },
        onJoinError: (_metadata) => {
          this._isJoined = false;
          throw `Peer denied.`;
        },
        onTrackReady: ({ stream, peer, track /* metadata */ }) => {
          this.tracksSubject.next({
            stream: stream!,
            track: track!,
            peerId: peer.id,
          });
        },
        onTrackAdded: async (_ctx) => {},
        onTrackRemoved: (ctx) => {
          if (ctx.peer.id === this.my_peer_id) return;
          resetStreamElements(
            ctx.peer.id,
            false,
            ctx.track!.kind === "video" ? "VIDEO" : "AUDIO"
          );
        },
        onPeerJoined: (_peer) => {},
        onPeerLeft: (peer) => {
          resetStreamElements(peer.id, this.my_peer_id === peer.id);
        },
        onPeerUpdated: (_ctx) => {},
      },
    });

    this.webrtcChannel.on("mediaEvent", (event: any) =>
      this.webrtc.receiveMediaEvent(event.data)
    );
  }

  public join = async () => {
    try {
      if (this.isJoined()) {
        this.webrtcChannel.push("rejoin", {});
      }
      this.webrtc.join({ displayName: this.displayName });
    } catch (error) {
      console.error("Error while joining to the room:", error);
    }
  };

  public isJoined = () => this._isJoined;

  private requestAudioStream = async () => {
    try {
      this.localAudioStream = await navigator.mediaDevices.getUserMedia({
        audio: true,
      });
      this.localAudioStream
        .getTracks()
        .forEach((track) => this.localStream.addTrack(track));
      await attachStream(this.localAudioStream!, this.my_peer_id, "AUDIO");
    } catch (error) {
      console.error(error);
      setErrorMessage(
        "Failed to setup audio, make sure to grant microphone permissions"
      );
      throw "error";
    }
  };

  private requestVideoStream = async () => {
    try {
      this.localVideoStream = await navigator.mediaDevices.getUserMedia({
        video: MEDIA_CONSTRAINTS.video,
      });
      this.localVideoStream
        .getTracks()
        .forEach((track) => this.localStream.addTrack(track));
      await attachStream(this.localVideoStream!, this.my_peer_id, "VIDEO");
    } catch (error) {
      console.error(error);
      setErrorMessage(
        "Failed to setup video, make sure to grant camera permissions"
      );
      throw "error";
    }
  };

  private requestAudioAndVideoStream = async () => {
    try {
      this.localStream = await navigator.mediaDevices.getUserMedia(
        MEDIA_CONSTRAINTS
      );
      this.localAudioStream = this.localStream;
      this.localVideoStream = this.localStream;
      await attachStream(this.localStream!, this.my_peer_id);
    } catch (error) {
      console.error(error);
      setErrorMessage(
        "Failed to setup video room, make sure to grant camera and microphone permissions"
      );
      throw "error";
    }

    // addVideoElement(LOCAL_PEER_ID, "You", true);
  };

  public leave = () => {
    this.webrtc.leave();
    // this.webrtcChannel.leave();
    // this.socketOff();
  };

  private socketOff = () => {
    this.socket.off(this.webrtcSocketRefs);
    while (this.webrtcSocketRefs.length > 0) {
      this.webrtcSocketRefs.pop();
    }
  };

  // private updateParticipantsList = (): void => {
  //   const participantsNames = this.peers.map((p) => p.metadata.displayName);
  //
  //   if (this.displayName) {
  //     participantsNames.push(this.displayName);
  //   }
  //
  //   setParticipantsList(participantsNames);
  // };
}
