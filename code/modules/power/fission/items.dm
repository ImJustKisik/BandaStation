/**
 * Contains the item definitions for the fission reactor, such as fuel and control rods.
 */

/obj/item/fission
	name = "fission reactor component"
	icon = 'icons/obj/items/fission_parts.dmi' // Placeholder icon path

/obj/item/fission/fuel_rod
	name = "nuclear fuel rod"
	desc = "A rod containing enriched fissile material. Handle with care."
	icon_state = "fuel_rod"
	w_class = WEIGHT_CLASS_NORMAL

	var/fuel_amount = 100

/obj/item/fission/control_rod
	name = "reactor control rod"
	desc = "A rod made of a neutron-absorbing material, used to control the rate of fission in a reactor."
	icon_state = "control_rod"
	w_class = WEIGHT_CLASS_NORMAL

	var/insertion_percent = 100 // How far in the rod is, 0-100

/obj/item/fission/spent_fuel_rod
	name = "spent nuclear fuel rod"
	desc = "A depleted fuel rod. It's no longer useful for power generation, but it's highly radioactive."
	icon_state = "spent_fuel_rod"
	w_class = WEIGHT_CLASS_NORMAL

/obj/item/fission/spent_fuel_rod/Initialize(mapload)
	. = ..()
	AddComponent(
		/datum/component/radioactive_emitter,
		cooldown_time = 2 SECONDS,
		range = 2,
		threshold = RAD_MEDIUM_INSULATION,
		examine_text = span_danger("It is glowing with a faint, ominous green light.")
	)
