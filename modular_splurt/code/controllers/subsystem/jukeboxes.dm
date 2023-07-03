// Jukelist indices
#define JUKE_TRACK 1
#define JUKE_CHANNEL 2
#define JUKE_BOX 3
#define JUKE_FALLOFF 4
#define JUKE_SOUND 5

/datum/track
	var/delete_after = FALSE

/datum/track/New(name, path, length, beat, assocID, delete=FALSE)
	. = ..()
	delete_after = delete

/datum/track/Destroy(force, ...)
	. = ..()
	song_path = null //better safe than sorry

/datum/controller/subsystem/jukeboxes/removejukebox(IDtoremove)
	var/obj/machinery/jukebox/rem_from = islist(activejukeboxes[IDtoremove]) ? activejukeboxes[IDtoremove][JUKE_BOX] : null
	. = ..()
	if(!. || !rem_from)
		return

	// Remove already played songs
	if(rem_from.playing.delete_after)
		qdel(rem_from.playing)

/datum/controller/subsystem/jukeboxes
	var/bpm_average = 50 //call me when you find a way to command-line calculate the bpm of each song

/datum/controller/subsystem/jukeboxes/Initialize()
	. = ..()
	if(!songs.len)
		return
	var/total = 0
	for(var/datum/track/song in songs)
		total += song.song_beat
	bpm_average = total / songs.len

	// Clear the jukebox downloads every round
	var/list/downloads = flist(JUKEBOX_YOUTUBE_DOWNLOAD_PATH)
	for(var/download in downloads)
		fdel("[JUKEBOX_YOUTUBE_DOWNLOAD_PATH][download]")

#undef JUKE_TRACK
#undef JUKE_CHANNEL
#undef JUKE_BOX
#undef JUKE_FALLOFF
#undef JUKE_SOUND
