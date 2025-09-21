/datum/computer_file/program/digitalwarrant
	filename = "digitalwarrant"
	filedesc = "Warrant Assistant"
	downloader_category = PROGRAM_CATEGORY_SECURITY
	program_icon = "warrant"
	program_open_overlay = "warrant"
	tgui_id = "NtosDigitalWarrant"
	size = 8
	program_flags = PROGRAM_ON_NTNET_STORE | PROGRAM_REQUIRES_NTNET
	download_access = list(ACCESS_SECURITY, ACCESS_FLAG_COMMAND)

/datum/computer_file/program/digitalwarrant/proc/serialize_warrant(datum/digital_warrant/W)
	return list(
		"id" = REF(W),
		"namewarrant" = W.namewarrant,
		"jobwarrant" = W.jobwarrant,
		"charges" = W.charges,
		"auth" = W.auth,
		"idauth" = W.idauth,
		"arrestsearch" = W.arrestsearch,
	)

/datum/computer_file/program/digitalwarrant/ui_data(mob/user, datum/tgui/ui)
	var/list/data = list()
	var/datum/digital_warrant/active_warrant = ui.vars["active_warrant"]
	var/list/new_warrant_data = ui.vars["new_warrant_data"]

	if(active_warrant)
		data["active"] = serialize_warrant(active_warrant)
	else if(new_warrant_data)
		data["active"] = new_warrant_data
	else
		var/list/listed = list()
		for(var/datum/digital_warrant/W in GLOB.all_warrants)
			listed += list(serialize_warrant(W))
		data["warrants"] = listed

	var/list/crew_manifest = list()
	for(var/datum/record/crew/CR in GLOB.manifest.general)
		if(CR.name && CR.rank)
			crew_manifest += list(list("name" = CR.name, "rank" = CR.rank))
	data["crew_manifest"] = crew_manifest
	return data

/datum/computer_file/program/digitalwarrant/ui_act(action, params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/mob/living/user_living = ui.user
	var/obj/item/card/id/I = user_living?.get_idcard(TRUE)
	var/datum/digital_warrant/active_warrant = ui.vars["active_warrant"]
	var/list/new_warrant_data = ui.vars["new_warrant_data"]

	if(!active_warrant && !new_warrant_data)
		switch(action)
			if("open", "add_arrest", "add_search", "delete")
				// These actions are valid without a target
			else
				return TRUE // most actions require a target

	switch(action)
		if("open")
			var/datum/digital_warrant/W = locate(params["id"]) in GLOB.all_warrants
			if(W)
				ui.vars["active_warrant"] = W
				ui.vars["new_warrant_data"] = null
			return TRUE
		if("add_arrest")
			ui.vars["new_warrant_data"] = list(
				"namewarrant" = "Unknown",
				"jobwarrant" = "N/A",
				"charges" = "No charges present",
				"auth" = "Unauthorized",
				"idauth" = "Unauthorized",
				"arrestsearch" = "arrest"
			)
			ui.vars["active_warrant"] = null
			return TRUE
		if("add_search")
			ui.vars["new_warrant_data"] = list(
				"namewarrant" = "Unknown",
				"jobwarrant" = "N/A",
				"charges" = "No reason given",
				"auth" = "Unauthorized",
				"idauth" = "Unauthorized",
				"arrestsearch" = "search"
			)
			ui.vars["active_warrant"] = null
			return TRUE
		if("select_from_manifest")
			var/name = params["name"]
			var/job = params["job"]
			if(!name || !job)
				return TRUE

			if(active_warrant)
				active_warrant.namewarrant = name
				active_warrant.jobwarrant = job
				active_warrant.auth = "Unauthorized"
				active_warrant.idauth = "Unauthorized"
				active_warrant.access = list()
			else if(new_warrant_data)
				new_warrant_data["namewarrant"] = name
				new_warrant_data["jobwarrant"] = job
				new_warrant_data["auth"] = "Unauthorized"
				new_warrant_data["idauth"] = "Unauthorized"
			return TRUE
		if("edit_name")
			if(active_warrant)
				active_warrant.namewarrant = isnull(params["name"]) ? active_warrant.namewarrant : sanitize(params["name"])
				active_warrant.jobwarrant = isnull(params["job"]) ? active_warrant.jobwarrant : sanitize(params["job"])
				active_warrant.auth = "Unauthorized"
				active_warrant.idauth = "Unauthorized"
				active_warrant.access = list()
			else if(new_warrant_data)
				new_warrant_data["namewarrant"] = isnull(params["name"]) ? new_warrant_data["namewarrant"] : sanitize(params["name"])
				new_warrant_data["jobwarrant"] = isnull(params["job"]) ? new_warrant_data["jobwarrant"] : sanitize(params["job"])
				new_warrant_data["auth"] = "Unauthorized"
				new_warrant_data["idauth"] = "Unauthorized"
			return TRUE
		if("edit_charges")
			if(active_warrant)
				active_warrant.charges = isnull(params["charges"]) ? active_warrant.charges : sanitize(params["charges"])
				active_warrant.auth = "Unauthorized"
				active_warrant.idauth = "Unauthorized"
				active_warrant.access = list()
			else if(new_warrant_data)
				new_warrant_data["charges"] = isnull(params["charges"]) ? new_warrant_data["charges"] : sanitize(params["charges"])
				new_warrant_data["auth"] = "Unauthorized"
				new_warrant_data["idauth"] = "Unauthorized"
			return TRUE
		if("authorize")
			if(!active_warrant || !I)
				return TRUE
			active_warrant.auth = "[I.registered_name] - [I.assignment ? I.assignment : "(Unknown)"]"
			return TRUE
		if("authorize_access")
			if(!active_warrant || active_warrant.arrestsearch == "search" || !I)
				return TRUE
			if(!(ACCESS_CHANGE_IDS in I.access))
				return TRUE
			var/datum/record/crew/warrant_subject
			var/datum/job/J = SSjob.get_job(active_warrant.jobwarrant)
			if(!J)
				return TRUE
			for(var/datum/record/crew/CR in GLOB.manifest.general)
				if(CR.name == active_warrant.namewarrant && CR.rank == active_warrant.jobwarrant)
					warrant_subject = CR
					break
			if(!warrant_subject)
				return TRUE
			var/list/warrant_access = get_job_accesses(J)
			if(islist(warrant_access))
				active_warrant.idauth = "[I.registered_name] - [I.assignment ? I.assignment : "(Unknown)"]"
				active_warrant.access = warrant_access
			return TRUE
		if("save")
			if(new_warrant_data)
				var/datum/digital_warrant/W = new()
				W.namewarrant = new_warrant_data["namewarrant"]
				W.jobwarrant = new_warrant_data["jobwarrant"]
				W.charges = new_warrant_data["charges"]
				W.auth = new_warrant_data["auth"]
				W.idauth = new_warrant_data["idauth"]
				W.arrestsearch = new_warrant_data["arrestsearch"]
				GLOB.all_warrants |= W

			ui.vars["active_warrant"] = null
			ui.vars["new_warrant_data"] = null
			return TRUE
		if("delete")
			var/datum/digital_warrant/W = locate(params["id"]) in GLOB.all_warrants
			if(W)
				GLOB.all_warrants -= W
				qdel(W)
			if(active_warrant == W)
				ui.vars["active_warrant"] = null
			return TRUE
		if("back")
			ui.vars["active_warrant"] = null
			ui.vars["new_warrant_data"] = null
			return TRUE
	return FALSE

/**
 * Returns the configured access list for a given job, based on the job's ID trim singleton.
 */
/datum/computer_file/program/digitalwarrant/proc/get_job_accesses(datum/job/J)
	if(!istype(J))
		return list()
	// Search existing trim singletons for the one tied to this job and copy its access list
	for(var/trim_path in SSid_access.trim_singletons_by_path)
		var/datum/id_trim/trim = SSid_access.trim_singletons_by_path[trim_path]
		if(!istype(trim, /datum/id_trim/job))
			continue
		var/datum/id_trim/job/job_trim = trim
		if(job_trim.find_job() == J)
			return job_trim.access.Copy()
	return list()
