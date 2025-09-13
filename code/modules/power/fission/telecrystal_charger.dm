/**
 * A machine that uses the intense radiation from a fission reactor
 * to convert a standard telecrystal sheet into a usable fuel rod.
 */

/obj/machinery/telecrystal_charger
	name = "telecrystal fuel charger"
	desc = "A heavily shielded chamber designed to safely irradiate telecrystals, converting them into a viable, if unstable, fuel source. Must be placed directly adjacent to an active reactor core."
	icon = 'icons/obj/machines/limbgrower.dmi' // Placeholder icon
	icon_state = "idle"
	anchored = TRUE
	density = TRUE
	resistance_flags = FIRE_PROOF | ACID_PROOF

	var/obj/item/stack/sheet/telecrystal/loaded_crystal
	var/charge_progress = 0

/obj/machinery/telecrystal_charger/Initialize()
	. = ..()
	start_processing()

/obj/machinery/telecrystal_charger/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/stack/sheet/telecrystal))
		if(loaded_crystal)
			to_chat(user, span_warning("The charger is already loaded."))
			return
		if(I.get_amount() < 1)
			to_chat(user, span_warning("You need a full sheet of telecrystal."))
			return

		var/obj/item/stack/sheet/telecrystal/crystal_sheet = I.use(1)
		if(!crystal_sheet)
			return

		loaded_crystal = crystal_sheet
		crystal_sheet.forceMove(src)
		user.visible_message(span_notice("[user] inserts a telecrystal sheet into the charger."), span_notice("You insert a telecrystal sheet into the charger."))
		update_icon()
		return

	if(istype(I, /obj/item/wrench))
		if(loaded_crystal)
			to_chat(user, span_warning("Eject the crystal before unwrenching the machine."))
			return

	return ..()

/obj/machinery/telecrystal_charger/verb/eject_crystal()
	set name = "Eject Crystal"
	set category = "Object"
	set src in oview(1)

	if(!loaded_crystal)
		to_chat(usr, span_warning("There is nothing to eject."))
		return

	loaded_crystal.forceMove(get_turf(src))
	loaded_crystal = null
	charge_progress = 0
	to_chat(usr, span_notice("You eject the telecrystal sheet."))
	update_icon()

/obj/machinery/telecrystal_charger/process()
	if(!loaded_crystal || charge_progress >= 100)
		return

	var/obj/machinery/power/fission/core/adjacent_core
	for(var/dir in GLOB.cardinal)
		adjacent_core = locate(/obj/machinery/power/fission/core) in get_step(src, dir)
		if(adjacent_core)
			break

	if(adjacent_core && adjacent_core.is_active && adjacent_core.reactivity > 20)
		charge_progress += adjacent_core.reactivity / 10
		update_icon()

	if(charge_progress >= 100)
		to_chat(src, span_notice("The charger hums loudly as the conversion process completes."))
		qdel(loaded_crystal)
		loaded_crystal = null
		new /obj/item/fission/fuel_rod/telecrystal(get_turf(src))
		update_icon()

/obj/machinery/telecrystal_charger/update_icon()
	if(charge_progress >= 100)
		icon_state = "finished"
	else if(loaded_crystal)
		icon_state = "charging"
	else
		icon_state = "idle"
