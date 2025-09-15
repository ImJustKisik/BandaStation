// Load-bearing vest accessory that adds storage to normal clothing

/obj/item/clothing/accessory/load_bearing_vest
        name = "разгрузочный жилет"
        desc = "Тактический жилет с множеством подсумков для переноски снаряжения."
	icon_state = "lbv"
	minimize_when_attached = FALSE
	attachment_slot = CHEST

/obj/item/clothing/accessory/load_bearing_vest/Initialize(mapload)
	. = ..()
	create_storage(max_slots = 6, max_specific_storage = WEIGHT_CLASS_SMALL, max_total_storage = WEIGHT_CLASS_SMALL * 6)

