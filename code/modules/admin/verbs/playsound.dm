/client/proc/play_sound(S as sound)
	set category = "Fun"
	set name = "Play Global Sound"
	if(!check_rights(R_SOUND))
		return

	var/freq = 1
	var/vol = input(usr, "What volume would you like the sound to play at?",, 100) as null|num
	if(!vol)
		return
	vol = CLAMP(vol, 1, 100)

	var/sound/admin_sound = new()
	admin_sound.file = S
	admin_sound.priority = 250
	admin_sound.channel = CHANNEL_ADMIN
	admin_sound.frequency = freq
	admin_sound.wait = 1
	admin_sound.repeat = 0
	admin_sound.status = SOUND_STREAM
	admin_sound.volume = vol

	var/res = alert(usr, "Show the title of this song to the players?",, "Yes","No", "Cancel")
	switch(res)
		if("Yes")
			to_chat(world, span_boldannounce("An admin played: [S]"))
		if("Cancel")
			return

	log_admin("[key_name(src)] played sound [S]")
	message_admins("[key_name_admin(src)] played sound [S]")

	for(var/mob/M in GLOB.player_list)
		if(M.client.prefs.toggles & SOUND_MIDI)
			var/user_vol = M.client.prefs.musicvol
			if(user_vol)
				admin_sound.volume = vol * (user_vol / 100)
			SEND_SOUND(M, admin_sound)

	SSblackbox.record_feedback("tally", "admin_verb", 1, "Play Global Sound") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/client/verb/change_music_vol()
	set category = "Options"
	set name = "ChangeMusicPower"

	if(prefs)
/*		if(blacklisted() == 1)
			var/vol = input(usr, "Current music power: [prefs.musicvol]",, 100) as null|num
			vol = 100
			prefs.musicvol = vol
			prefs.save_preferences()
			mob.update_music_volume(CHANNEL_MUSIC, prefs.musicvol)
			mob.update_music_volume(CHANNEL_LOBBYMUSIC, prefs.musicvol)
			mob.update_music_volume(CHANNEL_ADMIN, prefs.musicvol)
		else*/
		var/vol = input(usr, "Current music power: [prefs.musicvol]",, 100) as null|num
		if(!vol)
			if(vol != 0)
				return
		vol = min(vol, 100)
		prefs.musicvol = vol
		prefs.save_preferences()

		mob.update_music_volume(CHANNEL_MUSIC, prefs.musicvol)
		mob.update_music_volume(CHANNEL_LOBBYMUSIC, prefs.musicvol)
		mob.update_music_volume(CHANNEL_ADMIN, prefs.musicvol)


/client/verb/show_rolls()
	set category = "Options"
	set name = "ShowRolls"

	if(prefs)
		prefs.showrolls = !prefs.showrolls
		prefs.save_preferences()
		if(prefs.showrolls)
			to_chat(src, "ShowRolls Enabled")
		else
			to_chat(src, "ShowRolls Disabled")

/client/verb/change_master_vol()
	set category = "Options"
	set name = "ChangeVolPower"

	if(prefs)
		var/vol = input(usr, "Current volume power: [prefs.mastervol]",, 100) as null|num
		if(!vol)
			if(vol != 0)
				return
		vol = min(vol, 100)
		prefs.mastervol = vol
		prefs.save_preferences()

		mob.update_channel_volume(CHANNEL_AMBIENCE, prefs.mastervol)
/*
/client/verb/help_rpguide()
	set category = "Options"
	set name = "zHelp-RPGuide"

	src << link("https://cdn.discordapp.com/attachments/844865105040506891/938971395445112922/rpguide.jpg")

/client/verb/help_uihelp()
	set category = "Options"
	set name = "zHelp-UIGuide"

	src << link("https://cdn.discordapp.com/attachments/844865105040506891/938275090414579762/unknown.png")
*/

/client/proc/play_local_sound(S as sound)
	set category = "Fun"
	set name = "Play Local Sound"
	if(!check_rights(R_SOUND))
		return

	log_admin("[key_name(src)] played a local sound [S]")
	message_admins("[key_name_admin(src)] played a local sound [S]")
	playsound(get_turf(src.mob), S, 50, FALSE, FALSE)
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Play Local Sound") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/client/proc/play_web_sound()
	set category = "Fun"
	set name = "Play Internet Sound"
	if(!check_rights(R_SOUND))
		return

	var/ytdl = CONFIG_GET(string/invoke_youtubedl)
	if(!ytdl)
		to_chat(src, span_boldwarning("Youtube-dl was not configured, action unavailable")) //Check config.txt for the INVOKE_YOUTUBEDL value
		return

	var/web_sound_input = input("Enter content URL (supported sites only, leave blank to stop playing)", "Play Internet Sound via youtube-dl") as text|null
	if(istext(web_sound_input))
		var/web_sound_url = ""
		var/stop_web_sounds = FALSE
		var/list/music_extra_data = list()
		if(length(web_sound_input))

			web_sound_input = trim(web_sound_input)
			if(findtext(web_sound_input, ":") && !findtext(web_sound_input, GLOB.is_http_protocol))
				to_chat(src, span_boldwarning("Non-http(s) URIs are not allowed."))
				to_chat(src, span_warning("For youtube-dl shortcuts like ytsearch: please use the appropriate full url from the website."))
				return
			var/shell_scrubbed_input = shell_url_scrub(web_sound_input)
			var/list/output = world.shelleo("[ytdl] --geo-bypass --format \"bestaudio\[ext=mp3]/best\[ext=mp4]\[height<=360]/bestaudio\[ext=m4a]/bestaudio\[ext=aac]\" --dump-single-json --no-playlist -- \"[shell_scrubbed_input]\"")
			var/errorlevel = output[SHELLEO_ERRORLEVEL]
			var/stdout = output[SHELLEO_STDOUT]
			var/stderr = output[SHELLEO_STDERR]
			if(!errorlevel)
				var/list/data
				try
					data = json_decode(stdout)
				catch(var/exception/e)
					to_chat(src, span_boldwarning("Youtube-dl JSON parsing FAILED:"))
					to_chat(src, span_warning("[e]: [stdout]"))
					return

				if (data["url"])
					web_sound_url = data["url"]
					var/title = "[data["title"]]"
					var/webpage_url = title
					if (data["webpage_url"])
						webpage_url = "<a href=\"[data["webpage_url"]]\">[title]</a>"
					music_extra_data["start"] = data["start_time"]
					music_extra_data["end"] = data["end_time"]

					var/res = alert(usr, "Show the title of and link to this song to the players?\n[title]",, "No", "Yes", "Cancel")
					switch(res)
						if("Yes")
							to_chat(world, span_boldannounce("An admin played: [webpage_url]"))
						if("Cancel")
							return

					SSblackbox.record_feedback("nested tally", "played_url", 1, list("[ckey]", "[web_sound_input]"))
					log_admin("[key_name(src)] played web sound: [web_sound_input]")
					message_admins("[key_name(src)] played web sound: [web_sound_input]")
			else
				to_chat(src, span_boldwarning("Youtube-dl URL retrieval FAILED:"))
				to_chat(src, span_warning("[stderr]"))

		else //pressed ok with blank
			log_admin("[key_name(src)] stopped web sound")
			message_admins("[key_name(src)] stopped web sound")
			web_sound_url = null
			stop_web_sounds = TRUE

		if(web_sound_url && !findtext(web_sound_url, GLOB.is_http_protocol))
			to_chat(src, span_boldwarning("BLOCKED: Content URL not using http(s) protocol"))
			to_chat(src, span_warning("The media provider returned a content URL that isn't using the HTTP or HTTPS protocol"))
			return
		if(web_sound_url || stop_web_sounds)
			for(var/m in GLOB.player_list)
				var/mob/M = m
				var/client/C = M.client
				if((C.prefs.toggles & SOUND_MIDI) && C.chatOutput && !C.chatOutput.broken && C.chatOutput.loaded)
					if(!stop_web_sounds)
						C.chatOutput.sendMusic(web_sound_url, music_extra_data)
					else
						C.chatOutput.stopMusic()

	SSblackbox.record_feedback("tally", "admin_verb", 1, "Play Internet Sound")

/client/proc/set_round_end_sound(S as sound)
	set category = "Fun"
	set name = "Set Round End Sound"
	if(!check_rights(R_SOUND))
		return

	SSticker.SetRoundEndSound(S)

	log_admin("[key_name(src)] set the round end sound to [S]")
	message_admins("[key_name_admin(src)] set the round end sound to [S]")
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Set Round End Sound") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/client/proc/stop_sounds()
	set category = "Debug"
	set name = "Stop All Playing Sounds"
	if(!src.holder)
		return

	log_admin("[key_name(src)] stopped all currently playing sounds.")
	message_admins("[key_name_admin(src)] stopped all currently playing sounds.")
	for(var/mob/M in GLOB.player_list)
		SEND_SOUND(M, sound(null))
		var/client/C = M.client
		if(C && C.chatOutput && !C.chatOutput.broken && C.chatOutput.loaded)
			C.chatOutput.stopMusic()
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Stop All Playing Sounds") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

GLOBAL_LIST_INIT(ambience_files, list(
	'sound/music/area/academy.ogg',
	'sound/music/area/bath.ogg',
	'sound/music/area/bog.ogg',
	'sound/music/area/catacombs.ogg',
	'sound/music/area/caves.ogg',
	'sound/music/area/church.ogg',
	'sound/music/area/decap.ogg',
	'sound/music/area/druid.ogg',
	'sound/music/area/dungeon.ogg',
	'sound/music/area/dwarf.ogg',
	'sound/music/area/field.ogg',
	'sound/music/area/forest.ogg',
	'sound/music/area/forestnight.ogg',
	'sound/music/area/harbor.ogg',
	'sound/music/area/magiciantower.ogg',
	'sound/music/area/manorgarri.ogg',
	'sound/music/area/manorgarri_old.ogg',
	'sound/music/area/sargoth.ogg',
	'sound/music/area/septimus.ogg',
	'sound/music/area/sewers.ogg',
	'sound/music/area/shop.ogg',
	'sound/music/area/siege.ogg',
	'sound/music/area/sleeping.ogg',
	'sound/music/area/spidercave.ogg',
	'sound/music/area/towngen.ogg',
	'sound/music/area/townstreets.ogg',
	'sound/music/jukeboxes/tav3.ogg',
	'sound/music/area/underworlddrone.ogg',
	'sound/misc/comboff.ogg',
	'sound/misc/combon.ogg'
))

/client/New() // This tiny little bit of code is what we use to make preloading happen automatically upon a new client connecting.
	..()
	spawn(10)
		PreloadAmbience()

/client/proc/PreloadAmbience()
    if(!mob)
        return

    var/chunk_size = 3 // We use this for batches essentially
    var/inbetween_delay = 5 // Added this to try to smooth the loading out a bit more. It's used to make it so each sound loaded within a chunk is separated by five ticks. Just so you're not bombarded with the full download at once.
    var/chunk_delay = 10 // When a chunk ends, this var is what we use to give the client a little more breathing room. (Which should smooth out the load)
    var/max_lag = 3 // This is the stop button. If the server is lagging too much, we halt preloading.

    var/list/to_load = GLOB.ambience_files.Copy()
    if(!to_load.len)
        return

    var/ambiencecounter = to_load.len

    PreloadAmbienceChunk(1, ambiencecounter, chunk_size, inbetween_delay, chunk_delay, max_lag, to_load)


/client/proc/PreloadAmbienceChunk(start, ambiencecounter, chunk_size, inbetween_delay, chunk_delay, max_lag, to_load)
    if(world.tick_usage > max_lag)
        return

    if(!mob)
        return

    if(start > ambiencecounter)
        return

    var/chunkcap = start + chunk_size - 1
    if(chunkcap > ambiencecounter)
        chunkcap = ambiencecounter

    for(var/i = start, i <= chunkcap, i++)
        if(!mob)
            return

        var/sound_path = to_load[i]
        mob.playsound_local(mob, sound_path, 0)
        sleep(inbetween_delay)

    sleep(chunk_delay)

    PreloadAmbienceChunk(chunkcap + 1, ambiencecounter, chunk_size, inbetween_delay, chunk_delay, max_lag, to_load)
