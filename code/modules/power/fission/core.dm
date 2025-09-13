/**
 * Contains the core components of the fission reactor.
 * /obj/machinery/power/fission/core - The main reactor structure where the reaction takes place.
 * /obj/machinery/power/fission/graphite_moderator - The graphite blocks that make up the bulk of the core.
 * /obj/machinery/power/fission/fuel_channel - A channel within the core that holds a fuel rod.
 * /obj/machinery/power/fission/control_rod_assembly - The housing and mechanism for a control rod.
 */

/obj/machinery/power/fission
	name = "fission reactor component"
	icon = 'icons/obj/machines/engine/fission.dmi' // Generic placeholder
	density = TRUE
	anchored = TRUE
	resistance_flags = FIRE_PROOF | ACID_PROOF

// Modifiers for the fission reaction simulation
#define FUEL_REACTIVITY_MODIFIER 5
#define MODERATOR_REACTIVITY_MODIFIER 1
#define CONTROL_ROD_DAMPENING_MODIFIER 10
#define HEAT_PER_REACTIVITY_POINT 50
#define FUEL_CONSUMPTION_RATE 0.001
#define CRITICAL_TEMPERATURE 2000
#define VOID_COEFFICIENT_BONUS 15
#define SCRAM_REACTIVITY_SPIKE 50

/obj/machinery/power/fission/core
	name = "fission reactor core"
	desc = "The heart of a nuclear fission reactor. It's dangerously hot."
	icon_state = "core_off"
	circuit = /obj/item/circuitboard/machine/fission_core

	var/is_active = FALSE
	var/reactor_temperature = T20C
	var/structural_integrity = 100
	var/reactivity = 0 // A measure of the reaction's intensity
	var/power_output = 0 // Watts

	// Structure components, populated on activation
	var/list/fuel_assemblies = list()
	var/list/control_rod_assemblies = list()
	var/list/moderator_piles = list()

/obj/machinery/power/fission/core/verb/toggle_activation()
	set name = "Toggle Reactor"
	set category = "Object"
	set src in oview(1)

	if(is_active)
		deactivate()
	else
		activate()

/obj/machinery/power/fission/core/proc/activate()
	if(is_active)
		return

	to_chat(usr, span_notice("You start the reactor activation sequence..."))
	if(!build_reactor_map())
		to_chat(usr, span_warning("Reactor structural integrity check failed. Activation aborted."))
		return

	is_active = TRUE
	to_chat(usr, span_notice("Reactor is now active."))
	SSfission.register_reactor(src)
	update_icon()


/obj/machinery/power/fission/core/proc/deactivate()
	if(!is_active)
		return

	is_active = FALSE
	to_chat(usr, span_warning("Reactor is now inactive."))
	SSfission.unregister_reactor(src)
	update_icon()

// Scans for the complete reactor structure
/obj/machinery/power/fission/core/proc/build_reactor_map()
	var/list/found_components = list(src)
	var/list/scan_queue = list(src)

	while(scan_queue.len > 0)
		var/obj/machinery/power/fission/current = scan_queue[1]
		scan_queue.Remove(current)

		for(var/dir in GLOB.cardinal)
			var/obj/machinery/power/fission/neighbor = locate(get_step(current, dir))
			if(neighbor && !(neighbor in found_components))
				scan_queue += neighbor
				found_components += neighbor

	// Reset and populate component lists
	fuel_assemblies.Cut()
	control_rod_assemblies.Cut()
	moderator_piles.Cut()

	for(var/obj/machinery/M in found_components)
		if(istype(M, /obj/machinery/atmospherics/pipe/simple/fuel_channel))
			var/obj/machinery/atmospherics/pipe/simple/fuel_channel/FC = M
			FC.reactor_core = src
			fuel_assemblies += FC
		else if(istype(M, /obj/machinery/power/fission/control_rod_assembly))
			control_rod_assemblies += M
		else if(istype(M, /obj/machinery/power/fission/graphite_moderator))
			moderator_piles += M

	// Basic validation
	if(fuel_assemblies.len == 0)
		to_chat(usr, span_warning("Reactor has no fuel channels."))
		return FALSE

	if(control_rod_assemblies.len == 0)
		to_chat(usr, span_warning("Reactor has no control rod assemblies."))
		return FALSE

	to_chat(usr, span_info("Found [fuel_assemblies.len] fuel channels, [control_rod_assemblies.len] control rod assemblies, and [moderator_piles.len] moderators."))
	return TRUE

/obj/machinery/power/fission/core/proc/scram()
	to_chat(world, span_boldwarning("The reactor SCRAM has been initiated!"))

	// The Chernobyl Twist: Graphite tips cause a reactivity spike
	reactivity += SCRAM_REACTIVITY_SPIKE

	// Process one last time with the spike
	process_reaction(1)

	// Then rapidly insert all rods
	for(var/obj/machinery/power/fission/control_rod_assembly/CRA in control_rod_assemblies)
		if(CRA.rod)
			CRA.rod.insertion_percent = 100

	// Deactivate the reactor after SCRAM
	deactivate()


/obj/machinery/power/fission/core/proc/process_reaction(delta_time)
	if(!is_active)
		return

	// Step 1 & 2: Calculate reactivity from fuel and moderators
	reactivity = 0
	for(var/obj/machinery/atmospherics/pipe/simple/fuel_channel/FC in fuel_assemblies)
		if(FC.rod && FC.rod.fuel_amount > 0)
			reactivity += FUEL_REACTIVITY_MODIFIER

			// Positive Void Coefficient
			if(!FC.parent || !FC.parent.air || FC.parent.air.total_moles() < 1)
				reactivity += VOID_COEFFICIENT_BONUS

			// Step 2.3: Fuel Consumption
			FC.rod.fuel_amount = max(0, FC.rod.fuel_amount - (reactivity * FUEL_CONSUMPTION_RATE * delta_time))
			if(FC.rod.fuel_amount <= 0)
				// Turn into spent fuel
				new /obj/item/fission/spent_fuel_rod(FC)
				qdel(FC.rod)
				FC.rod = null


	for(var/obj/machinery/power/fission/graphite_moderator/GM in moderator_piles)
		reactivity += MODERATOR_REACTIVITY_MODIFIER

	// Step 3: Dampen reactivity with control rods
	for(var/obj/machinery/power/fission/control_rod_assembly/CRA in control_rod_assemblies)
		if(CRA.rod)
			reactivity -= (CRA.rod.insertion_percent / 100) * CONTROL_ROD_DAMPENING_MODIFIER

	// Step 4: Final reactivity and heat generation
	reactivity = max(0, reactivity)
	var/heat_generated = reactivity * HEAT_PER_REACTIVITY_POINT * delta_time
	reactor_temperature += heat_generated

	// Simple power output calculation for now
	power_output = reactivity * 10000 // Placeholder

	// Meltdown and radiation logic
	if(reactor_temperature > CRITICAL_TEMPERATURE)
		var/damage = (reactor_temperature - CRITICAL_TEMPERATURE) / 1000
		structural_integrity -= damage * delta_time
		if(structural_integrity <= 0)
			explosion(src, 3, 6, 12) // Kaboom
			qdel(src) // qdel the core after explosion
			return

	if(is_active && reactivity > 0)
		var/rad_range = round(reactivity / 2)
		var/rad_chance = reactivity * 5
		radiation_pulse(src, max_range = rad_range, chance = rad_chance)

	update_icon()

/obj/machinery/power/fission/core/attackby(obj/item/I, mob/user, params)
	if(default_deconstruction_screwdriver(user, I))
		return
	if(default_deconstruction_crowbar(I))
		return
	return ..()

/obj/machinery/power/fission/core/proc/update_icon()
	if(is_active && reactivity > 0)
		icon_state = "core_on"
	else
		icon_state = "core_off"

/obj/machinery/atmospherics/pipe/simple/fuel_channel/attackby(obj/item/I, mob/user, params)
	if(default_deconstruction_screwdriver(user, I))
		return
	if(default_deconstruction_crowbar(I))
		return
	if(istype(I, /obj/item/fission/fuel_rod))
		if(rod)
			to_chat(user, span_warning("The channel is already loaded."))
			return
		if(!user.transferItemToLoc(I, src))
			return
		rod = I
		user.visible_message(span_notice("[user] inserts [I] into the fuel channel."), span_notice("You insert [I] into the fuel channel."))
		return
	return ..()

/obj/machinery/power/fission/graphite_moderator
	name = "graphite moderator pile"
	desc = "A block of graphite used to moderate the nuclear reaction."
	icon_state = "graphite"

/obj/machinery/atmospherics/pipe/simple/fuel_channel
	name = "reactor fuel channel"
	desc = "A reinforced channel designed to hold a nuclear fuel assembly."
	resistance_flags = FIRE_PROOF | ACID_PROOF

	var/obj/item/fission/fuel_rod/rod
	var/obj/machinery/power/fission/core/reactor_core

/obj/machinery/atmospherics/pipe/simple/fuel_channel/process()
	if(reactor_core && parent && parent.air)
		// Simplified heat exchange
		var/reactor_temp = reactor_core.reactor_temperature
		var/gas_temp = parent.air.temperature
		var/delta_temp = reactor_temp - gas_temp

		if(abs(delta_temp) > 1)
			var/heat_transfer_coeff = 0.1
			var/heat_to_transfer = delta_temp * heat_transfer_coeff

			// A more realistic model would use specific heat of the gas mixture.
			// This is a placeholder.
			var/gas_heat_capacity = parent.air.heat_capacity()
			if(gas_heat_capacity > 0)
				reactor_core.reactor_temperature -= heat_to_transfer
				parent.air.temperature += heat_to_transfer / gas_heat_capacity

			// Check for steam conversion
			if(parent.air.temperature > T0C + 100) // 100 C
				var/datum/gas_mixture/pipe_air = parent.air
				var/moles_water = pipe_air.get_moles(/datum/gas/water_vapor)
				if(moles_water > 0.1)
					var/moles_to_convert = min(moles_water, (parent.air.temperature - (T0C + 100)) * 0.01) // Convert more the hotter it is
					pipe_air.remove_specific(/datum/gas/water_vapor, moles_to_convert)
					pipe_air.add_specific(/datum/gas/steam, moles_to_convert)

			parent.update_visuals()

/obj/machinery/atmospherics/pipe/simple/fuel_channel/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/fission/fuel_rod))
		if(rod)
			to_chat(user, span_warning("The channel is already loaded."))
			return
		if(!user.transferItemToLoc(I, src))
			return
		rod = I
		user.visible_message(span_notice("[user] inserts [I] into the fuel channel."), span_notice("You insert [I] into the fuel channel."))
		return
	return ..()

/obj/machinery/atmospherics/pipe/simple/fuel_channel/verb/eject_rod()
	set name = "Eject Fuel Rod"
	set category = "Object"
	set src in oview(1)

	if(!rod)
		to_chat(usr, span_warning("There is no rod to eject."))
		return

	usr.put_in_hands(rod)
	rod = null
	to_chat(usr, span_notice("You eject the fuel rod."))


/obj/machinery/power/fission/control_rod_assembly
	name = "control rod assembly"
	desc = "A mechanism for raising and lowering a control rod to regulate the reactor's output."
	icon_state = "rod_assembly"

	var/obj/item/fission/control_rod/rod

/obj/machinery/power/fission/control_rod_assembly/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/fission/control_rod))
		if(rod)
			to_chat(user, span_warning("The assembly already holds a control rod."))
			return
		if(!user.transferItemToLoc(I, src))
			return
		rod = I
		user.visible_message(span_notice("[user] inserts [I] into the control rod assembly."), span_notice("You insert [I] into the control rod assembly."))
		return
	return ..()

/obj/machinery/power/fission/control_rod_assembly/verb/eject_rod()
	set name = "Eject Control Rod"
	set category = "Object"
	set src in oview(1)

	if(!rod)
		to_chat(usr, span_warning("There is no rod to eject."))
		return

	usr.put_in_hands(rod)
	rod = null
	to_chat(usr, span_notice("You eject the control rod."))

/obj/machinery/power/fission/control_rod_assembly/verb/set_insertion_level()
	set name = "Set Rod Insertion"
	set category = "Object"
	set src in oview(1)

	if(!rod)
		to_chat(usr, span_warning("There is no control rod inserted."))
		return

	var/new_level = input(usr, "Set insertion percentage (0-100):", "Rod Insertion", rod.insertion_percent) as num
	if(!usr.canUseTopic(src))
		return
	rod.insertion_percent = clamp(new_level, 0, 100)
	to_chat(usr, span_notice("You set the control rod insertion to [rod.insertion_percent]%."))
