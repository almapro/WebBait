import { Room } from "./room";

window.addEventListener("phx:page-loading-stop", async (info: any) => {
	console.log({ info });
	if (info.detail.kind === "redirect" || info.detail.kind === "initial") {
		if (location.pathname.startsWith("/room")) {
			const pathNameParts = window.location.pathname.split("/");
			const room = new Room(
				pathNameParts[pathNameParts.length - 2],
				pathNameParts[pathNameParts.length - 1]
			);
			await room.join();

			window.addEventListener("webrtc:connectDisconnect", async () => {
				if (room.isJoined()) room.leave();
				else await room.join();
			});
		}
	}
});
