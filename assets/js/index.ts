import { Room } from "./room";

if (location.pathname.startsWith("/room")) {
	const room = new Room(
		window.location.pathname.split("/")[
			window.location.pathname.split("/").length - 2
		],
		window.location.pathname.split("/")[
			window.location.pathname.split("/").length - 1
		]
	);
	window.addEventListener("DOMContentLoaded", async () => {
		await room.join();
	});

	window.addEventListener("webrtc:connectDisconnect", async () => {
		if (room.isJoined()) room.leave();
		else await room.join();
	});
}
