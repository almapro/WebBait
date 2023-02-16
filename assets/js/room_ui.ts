export function getRoomId(): string {
	return document.getElementById("room")!.dataset.roomId!;
}

export const elementId = (peerId: string, type: "video" | "audio" | "feed") => {
	return `${type}-${peerId}`;
};

export const attachStream = async (
	stream: MediaStream,
	peerId: string,
	type: "AUDIO" | "VIDEO" | "BOTH" = "BOTH"
) => {
	if (type === "AUDIO" || type === "BOTH") {
		const audioId = elementId(peerId, "audio");
		let audio = document.getElementById(audioId) as HTMLAudioElement;
		audio.srcObject = stream;
		await audio.play();
	}
	if (type === "VIDEO" || type === "BOTH") {
		const videoId = elementId(peerId, "video");
		let video = document.getElementById(videoId) as HTMLVideoElement;
		video.srcObject = stream;
		await video.play();
	}
};

export function addVideoElement(
	peerId: string,
	label: string,
	isLocalVideo: boolean
): void {
	const videoId = elementId(peerId, "video");
	const audioId = elementId(peerId, "audio");

	let video = document.getElementById(videoId) as HTMLVideoElement;
	let audio = document.getElementById(audioId) as HTMLAudioElement;

	if (!video && !audio) {
		const values = setupVideoFeed(peerId, label, isLocalVideo);
		video = values.video;
		audio = values.audio;
	}

	video.id = videoId;
	video.autoplay = true;
	video.playsInline = true;
	video.muted = true;

	audio.id = audioId;
	audio.autoplay = true;
	if (isLocalVideo) {
		audio.muted = true;
	}
}

export function setParticipantsList(participants: Array<string>): void {
	const participantsNamesEl = document.getElementById(
		"participants-list"
	) as HTMLDivElement;
	participantsNamesEl.innerHTML =
		"<b>Participants:</b> " + participants.join(", ");
}

function resizeVideosGrid() {
	// const grid = document.getElementById("videos-grid")!;
	//
	// const videos = grid.children.length;
	//
	// let videosPerRow: any;
	// // break points for grid layout
	// if (videos < 2) {
	// 	videosPerRow = 1;
	// } else if (videos < 5) {
	// 	videosPerRow = 2;
	// } else if (videos < 7) {
	// 	videosPerRow = 3;
	// } else {
	// 	videosPerRow = 4;
	// }
	//
	// let classesToRemove: string[] = [];
	// for (const [__, value] of grid.classList.entries()) {
	// 	if (value.includes("grid-cols")) {
	// 		classesToRemove.push(value);
	// 	}
	// }
	//
	// classesToRemove.forEach((className) => grid.classList.remove(className));
	//
	// // add the class to be a default for mobiles
	// grid.classList.add("grid-cols-1");
	// grid.classList.add(`md:grid-cols-${videosPerRow}`);
}

function setupVideoFeed(peerId: string, label: string, isLocalVideo: boolean) {
	const copy = (
		document.querySelector("#video-feed-template") as HTMLTemplateElement
	).content.cloneNode(true) as Element;
	const feed = copy.querySelector("div[name='video-feed']") as HTMLDivElement;
	const audio = feed.querySelector("audio") as HTMLAudioElement;
	const video = feed.querySelector("video") as HTMLVideoElement;
	const videoLabel = feed.querySelector(
		"div[name='video-label']"
	) as HTMLDivElement;

	feed.id = elementId(peerId, "feed");
	videoLabel.innerText = label;

	if (isLocalVideo) {
		video.classList.add("flip-horizontally");
	}

	const grid = document.querySelector("#videos-grid")!;
	grid.appendChild(feed);
	resizeVideosGrid();

	return { audio, video };
}

export function removeVideoElement(peerId: string): void {
	document.getElementById(elementId(peerId, "feed"))?.remove();
	resizeVideosGrid();
}

export function resetStreamElements(
	peerId: string,
	isLocalStream: boolean,
	type: "AUDIO" | "VIDEO" | "BOTH" = "BOTH"
): void {
	if (type === "VIDEO" || type === "BOTH") {
		const videoId = elementId(peerId, "video");
		let video = document.getElementById(videoId) as HTMLVideoElement;
		video.pause();
		video.autoplay = true;
		video.playsInline = true;
		video.muted = true;
		video.srcObject = null;
	}
	if (type === "AUDIO" || type === "BOTH") {
		const audioId = elementId(peerId, "audio");
		let audio = document.getElementById(audioId) as HTMLAudioElement;
		audio.id = audioId;
		audio.autoplay = true;
		audio.srcObject = null;
		if (isLocalStream) {
			audio.muted = true;
		}
	}
}

export function setErrorMessage(
	message: string = "Cannot connect to server, refresh the page and try again"
): void {
	const errorContainer = document.getElementById("videochat-error");
	if (errorContainer) {
		errorContainer.innerHTML = message;
		errorContainer.style.display = "block";
	}
}
