/obj/machinery/jukebox/ui_static_data(mob/user)
	. = ..()
	.["can_youtube"] = CONFIG_GET(flag/ic_jukebox_download)

/obj/machinery/jukebox/ui_act(action, list/params)
	. = ..()
	if(.)
		return

	switch(action)
		if("urlsong") // Download a song from YT
			if(QDELETED(src))
				return
			if(world.time < queuecooldown)
				return
			if(!CONFIG_GET(flag/ic_jukebox_download))
				to_chat(usr, span_warning("This option is not currently available."))
				return

			var/ytdl = CONFIG_GET(string/invoke_youtubedl)
			if(!ytdl)
				to_chat(usr, span_boldwarning("Action unavailable")) //Check config.txt for the INVOKE_YOUTUBEDL value
				return

			var/song_youtube_url = tgui_input_text(usr, "Enter content URL (supported sites only)", "Play YouTube Sound", null)
			if(!istext(song_youtube_url) || !length(song_youtube_url))
				return

			song_youtube_url = trim(song_youtube_url)
			if(findtext(song_youtube_url, ":") && !findtext(song_youtube_url, GLOB.is_http_protocol))
				to_chat(usr, span_boldwarning("Non-http(s) URIs are not allowed."))
				to_chat(usr, span_warning("For youtube-dl shortcuts like ytsearch: please use the appropriate full url from the website."))
				return
			var/shell_scrubbed_input = shell_url_scrub(song_youtube_url)
			var/list/output = world.shelleo("[ytdl] --format \"bestaudio\[ext=mp3]/best\[ext=mp4]\[height<=360]/bestaudio\[ext=m4a]/bestaudio\[ext=aac]\" --dump-single-json --no-playlist -- \"[shell_scrubbed_input]\"")
			var/errorlevel = output[SHELLEO_ERRORLEVEL]
			var/stdout = output[SHELLEO_STDOUT]
			if(errorlevel)
				return
			var/list/data
			try
				data = json_decode(stdout)
			catch(var/exception/e)
				to_chat(usr, span_boldwarning("Youtube-dl JSON parsing FAILED"))
				message_admins("Youtube-dl JSON parsing FAILED at [ADMIN_LOOKUPFLW(src)]:")
				message_admins("[e]: [stdout]")
				return
			var/song_length_limit = CONFIG_GET(number/yt_time_limit)
			if(song_length_limit && data["duration"] > song_length_limit)
				to_chat(usr, span_warning("This song exceeds the maximum allowed length ([song_length_limit/60] minutes)"))
				return

			var/path_title = sanitize(data["title"], list("/" = " ", "\\" = " "))
			if(!fexists("[JUKEBOX_YOUTUBE_DOWNLOAD_PATH][path_title].ogg"))
				output = world.shelleo("[ytdl] -x --audio-format vorbis -o \"[JUKEBOX_YOUTUBE_DOWNLOAD_PATH][path_title].%(ext)s\" \"[shell_scrubbed_input]\"")
				errorlevel = output[SHELLEO_ERRORLEVEL]
				stdout = output[SHELLEO_STDOUT]
				if(errorlevel)
					return

			log_admin("[ADMIN_LOOKUPFLW(usr)] played web sound: [song_youtube_url] at [ADMIN_LOOKUPFLW(src)]")
			message_admins("[ADMIN_LOOKUPFLW(usr)] played web sound: [song_youtube_url] at [ADMIN_LOOKUPFLW(src)]")
			INVOKE_ASYNC(src, .proc/add_external_to_queue, new /datum/track(data["title"], file("[JUKEBOX_YOUTUBE_DOWNLOAD_PATH][path_title].ogg"), data["duration"] * 10, SSjukeboxes.bpm_average, 0, TRUE))

// it's the same as the add to queue act
/obj/machinery/jukebox/proc/add_external_to_queue(datum/track/selection)
	if(QDELETED(src))
		return
	if(world.time < queuecooldown)
		return
	if(!istype(selection))
		return
	if(!allowed(usr) && queuecost)
		var/obj/item/card/id/C
		if(isliving(usr))
			var/mob/living/L = usr
			C = L.get_idcard(TRUE)
		if(!can_transact(C))
			queuecooldown = world.time + (1 SECONDS)
			playsound(src, 'sound/misc/compiler-failure.ogg', 25, TRUE)
			return
		if(!attempt_transact(C, queuecost))
			say("Insufficient funds.")
			queuecooldown = world.time + (1 SECONDS)
			playsound(src, 'sound/misc/compiler-failure.ogg', 25, TRUE)
			return
		to_chat(usr, "<span class='notice'>You spend [queuecost] credits to queue [selection.song_name].</span>")
		log_econ("[queuecost] credits were inserted into [src] by [key_name(usr)] (ID: [C.registered_name]) to queue [selection.song_name].")
	queuedplaylist += selection
	if(active)
		say("[selection.song_name] has been added to the queue.")
	else if(!playing)
		INVOKE_ASYNC(src, .proc/activate_music)
	playsound(src, 'sound/machines/ping.ogg', 50, TRUE)
	queuecooldown = world.time + (3 SECONDS)
	return TRUE
