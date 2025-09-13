/obj/item/circuitboard/machine/fission_control
	name = "Fission Reactor Control Console (Machine Board)"
	build_path = /obj/machinery/computer/fission_control
	req_components = list(
		/obj/item/stock_parts/matter_bin = 1,
		/obj/item/stock_parts/manipulator = 1,
		/obj/item/stock_parts/micro_laser = 1)

/obj/item/circuitboard/machine/fission_core
	name = "Fission Reactor Core (Machine Board)"
	build_path = /obj/machinery/power/fission/core
	req_components = list(
		/obj/item/stock_parts/matter_bin = 2,
		/obj/item/stock_parts/manipulator = 2,
		/obj/item/stock_parts/capacitor = 1)

/obj/item/circuitboard/machine/fission_fuel_channel
	name = "Fission Reactor Fuel Channel (Machine Board)"
	build_path = /obj/machinery/atmospherics/pipe/simple/fuel_channel
	req_components = list(
		/obj/item/stock_parts/matter_bin = 1,
		/obj/item/stock_parts/capacitor = 1)

/obj/item/circuitboard/machine/fission_rod_assembly
	name = "Fission Reactor Control Rod Assembly (Machine Board)"
	build_path = /obj/machinery/power/fission/control_rod_assembly
	req_components = list(
		/obj/item/stock_parts/matter_bin = 1,
		/obj/item/stock_parts/manipulator = 1)

/obj/item/circuitboard/machine/fission_graphite_moderator
	name = "Fission Reactor Graphite Moderator (Machine Board)"
	build_path = /obj/machinery/power/fission/graphite_moderator
	req_components = list(
		/obj/item/stock_parts/matter_bin = 1)

/obj/item/circuitboard/machine/steam_turbine
	name = "Steam Turbine (Machine Board)"
	build_path = /obj/machinery/power/steam_turbine
	req_components = list(
		/obj/item/stock_parts/matter_bin = 2,
		/obj/item/stock_parts/manipulator = 2,
		/obj/item/stock_parts/capacitor = 2)
