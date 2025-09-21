/obj/item/device/holowarrant
	name = "warrant projector"
	desc = "The practical paperwork replacement for the officer on the go."
	icon = 'icons/obj/devices/remote.dmi'
	icon_state = "remote"
	inhand_icon_state = "electronic"
	lefthand_file = 'icons/mob/inhands/items/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/items/devices_righthand.dmi'
	throwforce = 5
	w_class = WEIGHT_CLASS_SMALL
	throw_speed = 4
	throw_range = 10
	obj_flags = CONDUCTS_ELECTRICITY
	slot_flags = ITEM_SLOT_BELT
	req_one_access = list(ACCESS_COMMAND, ACCESS_SECURITY)
	var/datum/digital_warrant/active

/obj/item/device/holowarrant/proc/is_active_warrant_valid()
	return active && (active in GLOB.all_warrants)

/obj/item/device/holowarrant/examine(mob/user)
	. = ..()
	if(is_active_warrant_valid())
		. += "It's a holographic warrant for '[active.namewarrant]'."
		if(in_range(src, user))
			show_content(user)
		else
			. += span_notice("You have to be closer if you want to read it.")

/obj/item/device/holowarrant/GetAccess()
	. = list()
	if(!is_active_warrant_valid() || active.archived)
		return
	. |= active.access

/obj/item/device/holowarrant/attack_self(mob/living/user)
	active = null
	var/list/warrant_options = list()
	var/list/warrant_map = list()
	for(var/datum/digital_warrant/W in GLOB.all_warrants)
		if(!W.archived)
			var/desc = "[W.namewarrant] ([capitalize(W.arrestsearch)]) - [REF(W)]"
			warrant_options += desc
			warrant_map[desc] = W

	if(!length(warrant_options))
		to_chat(user, span_notice("There are no warrants available."))
		update_appearance()
		return

	var/choice = input(user, "Which warrant would you like to load?") as null|anything in warrant_options
	if(!choice || QDELETED(src) || !user || !user.can_perform_action(src) || !in_range(src, user))
		update_appearance()
		return

	active = warrant_map[choice]
	update_appearance()

/obj/item/device/holowarrant/afterattack(atom/target, mob/user, list/modifiers, list/attack_modifiers)
	if(iscarbon(target))
		var/mob/living/carbon/M = target
		user.visible_message(
			span_notice("[user] holds up a warrant projector and shows the contents to [M]."),
			span_notice("You show the warrant to [M].")
		)
		M.examinate(src)
		return TRUE
	return ..()

/obj/item/device/holowarrant/update_icon_state()
	// Use a consistent icon state present in remote.dmi to avoid missing states
	icon_state = "remote"
	return ..()

/obj/item/device/holowarrant/proc/show_content(mob/user)
	if(!active)
		return
	if(active.arrestsearch == "arrest")
		var/output = {"
		<HTML><HEAD><TITLE>[html_encode(active.namewarrant)]</TITLE></HEAD>
		<BODY bgcolor='#ffffff'><center><large><b>SCG SFP Warrant Tracker System</b></large></br>
		</br>
		Issued in the jurisdiction of the</br>
		[station_name()]</br>
		</br>
		<b>ARREST WARRANT</b></center></br>
		</br>
		This document serves as authorization and notice for the arrest of _<u>[html_encode(active.namewarrant)]</u>____ for the crime(s) of:</br>[html_encode(active.charges)]</br>
		</br>
		Vessel or habitat: _<u>[station_name()]</u>____</br>
		</br>_<u>[html_encode(active.auth)]</u>____</br>
		<small>Person authorizing arrest</small></br>
		</BODY></HTML>
		"}
		user << browse(HTML_SKELETON(output), "window=Warrant for the arrest of [html_encode(active.namewarrant)]")
	if(active.arrestsearch == "search")
		var/output = {"
		<HTML><HEAD><TITLE>Search Warrant: [html_encode(active.namewarrant)]</TITLE></HEAD>
		<BODY bgcolor='#ffffff'><center><large><b>SCG SFP Warrant Tracker System</b></large></br>
		</br>
		Issued in the jurisdiction of the</br>
		[station_name()]</br>
		</br>
		<b>SEARCH WARRANT</b></center></br>
		</br>
		<b>Suspect's/location name: </b>[html_encode(active.namewarrant)]</br>
		</br>
		<b>For the following reasons: </b> [html_encode(active.charges)]</br>
		</br>
		<b>Warrant issued by: </b> [html_encode(active.auth)]</br>
		</br>
		Vessel or habitat: _<u>[station_name()]</u>____</br>
		</br>
		<center><small><i>The Security Officer(s) bearing this Warrant are hereby authorized by the Issuer to conduct a one time lawful search of the Suspect's person/belongings/premises and/or Department for any items and materials that could be connected to the suspected criminal act described below, pending an investigation in progress.</br>
		</br>
		The Security Officer(s) are obligated to remove any and all such items from the Suspects posession and/or Department and file it as evidence.</br>
		</br>
		The Suspect/Department staff is expected to offer full co-operation.</br>
		</br>
		In the event of the Suspect/Department staff attempting to resist/impede this search or flee, they must be taken into custody immediately! </br>
		</br>
		All confiscated items must be filed and taken to Evidence!</small></i></center></br>
		</BODY></HTML>
		"}
		user << browse(HTML_SKELETON(output), "window=Search warrant for [html_encode(active.namewarrant)]")
