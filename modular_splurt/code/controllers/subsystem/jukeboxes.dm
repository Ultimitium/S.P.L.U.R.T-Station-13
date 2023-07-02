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

/datum/controller/subsystem/jukeboxes
	var/bpm_average = 50 //call me when you find a way to command-line calculate the bpm of each song

/datum/controller/subsystem/jukeboxes/Initialize()
	. = ..()
	var/total = 0
	for(var/datum/track/song in songs)
		total += song.song_beat
	bpm_average = total / songs.len

/datum/controller/subsystem/jukeboxes/removejukebox(IDtoremove)
	var/obj/machinery/jukebox/rem_from = islist(activejukeboxes[IDtoremove]) ? activejukeboxes[IDtoremove][JUKE_BOX] : null
	. = ..()
	if(!. || !rem_from)
		return

	// Remove already played songs
	for(var/datum/track/song in rem_from.del_queue)
		if(song.delete_after)
			fdel(song.song_path)

#undef JUKE_TRACK
#undef JUKE_CHANNEL
#undef JUKE_BOX
#undef JUKE_FALLOFF
#undef JUKE_SOUND
