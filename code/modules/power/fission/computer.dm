/**
 * Contains the control computer for the fission reactor.
 */

/obj/machinery/computer/fission_control
	name = "fission reactor control console"
	desc = "A computer console for monitoring and controlling a nuclear fission reactor."
	icon_screen = "reactor_control"
	icon_keyboard = "rd_key"
	req_access = list(ACCESS_ENGINE)
	circuit = /obj/item/circuitboard/machine/fission_control // Needs to be defined

	var/obj/machinery/power/fission/core/reactor_core

/obj/machinery/computer/fission_control/multitool_act(mob/user, obj/item/I)
	if(!I.is_advanced_multitool())
		return ..()

	var/obj/item/multitool/multitool = I
	var/obj/machinery/power/fission/core/linked_core = multitool.buffer
	if(istype(linked_core))
		reactor_core = linked_core
		to_chat(user, span_notice("You link the console to the reactor core."))
		update_icon()
	else
		to_chat(user, span_warning("The multitool buffer does not contain a valid reactor core link."))

	return TRUE

/obj/machinery/computer/fission_control/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "FissionControl", name)
		ui.open()

/obj/machinery/computer/fission_control/ui_data(mob/user)
	var/list/data = list()

	if(!reactor_core)
		data["status"] = "No Core Linked"
		return data

	if(!reactor_core.is_active)
		data["status"] = "Reactor Offline"
	else
		data["status"] = "Reactor Online"

	data["temperature"] = reactor_core.reactor_temperature
	data["reactivity"] = reactor_core.reactivity
	data["power_output"] = reactor_core.power_output

	var/list/rods = list()
	for(var/obj/machinery/power/fission/control_rod_assembly/CRA in reactor_core.control_rod_assemblies)
		if(CRA.rod)
			rods.Add(list(list("ref" = REF(CRA.rod), "insertion" = CRA.rod.insertion_percent)))

	data["control_rods"] = rods

	return data

/obj/machinery/computer/fission_control/ui_act(action, params)
	if(..())
		return

	if(!reactor_core)
		return

	switch(action)
		if("toggle_power")
			if(reactor_core.is_active)
				reactor_core.deactivate()
			else
				reactor_core.activate()
			. = TRUE
		if("set_rod_insertion")
			var/rod_ref = params["ref"]
			var/value = text2num(params["value"])
			var/obj/item/fission/control_rod/rod = locate(rod_ref)
			if(istype(rod) && reactor_core && rod.loc && rod.loc.loc == reactor_core.loc) // Basic check to ensure rod is part of this reactor
				rod.insertion_percent = clamp(value, 0, 100)
				. = TRUE
		if("scram")
			reactor_core.scram()
			. = TRUE

	return .
