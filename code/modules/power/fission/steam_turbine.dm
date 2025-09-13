/**
 * A turbine that generates power from high-pressure, high-temperature steam.
 */

/obj/machinery/power/steam_turbine
	name = "steam turbine"
	desc = "A large turbine designed to generate electrical power from pressurized steam."
	icon = 'icons/obj/machines/engine/turbine.dmi' // Placeholder icon
	icon_state = "turbine_outlet"
	anchored = TRUE
	density = TRUE
	resistance_flags = FIRE_PROOF | ACID_PROOF

	var/obj/machinery/atmospherics/pipe/inlet
	var/obj/machinery/atmospherics/pipe/outlet

/obj/machinery/power/steam_turbine/Initialize()
	. = ..()
	build_connections()
	if(inlet && outlet)
		start_processing()

/obj/machinery/power/steam_turbine/proc/build_connections()
	inlet = locate(/obj/machinery/atmospherics/pipe) in get_step(src, REVERSE_DIR(dir))
	outlet = locate(/obj/machinery/atmospherics/pipe) in get_step(src, dir)

/obj/machinery/power/steam_turbine/process()
	if(!inlet || !outlet || !inlet.parent || !outlet.parent)
		return

	var/datum/gas_mixture/inlet_air = inlet.return_air()
	var/datum/gas_mixture/outlet_air = outlet.return_air()

	if(!inlet_air || inlet_air.total_moles() < 1)
		return

	var/moles_steam = inlet_air.get_moles(/datum/gas/steam)
	if(moles_steam < 0.1)
		return

	// Simplified power generation logic
	var/power_generated = moles_steam * inlet_air.temperature * 0.5 // Placeholder formula
	add_avail(power_generated)

	// Consume steam and convert it back to water vapor at a lower temp
	inlet_air.remove_specific(/datum/gas/steam, moles_steam)
	outlet_air.add_specific(/datum/gas/water_vapor, moles_steam)
	outlet_air.temperature = max(T20C, outlet_air.temperature * 0.8) // Cool the output

	inlet.parent.update_visuals()
	outlet.parent.update_visuals()

/obj/machinery/power/steam_turbine/wrench_act(mob/living/user, obj/item/tool)
	. = ..()
	if(.)
		build_connections()
		if(inlet && outlet)
			start_processing()
		else
			stop_processing()
