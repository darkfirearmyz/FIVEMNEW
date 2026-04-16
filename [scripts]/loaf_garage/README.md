<!-- Please open this file in Visual Studio Code and press Ctrl + Shift + V, or right click it and press "Open Preview" -->

# Loaf Garage
Garage script for ESX & QBCore
If you for some reason want the old version, you can download it [here](https://drive.google.com/drive/u/4/folders/18dWwuFl9HCLA4-vXI8rRHwcxAkBjQhSo)

## Features
* Browse vehicles either in a menu system or by sitting in the vehicle and using arrows to switch
* Impound included
* You can only take out your vehicle once
* Vehicle is spawned using OneSync methods, meaning it *should* not despawn randomly
* Save damages:
    * Engine health
    * Body health
    * Dirt level
    * Deformation (only if using [VehicleDeformation](https://github.com/Kiminaze/VehicleDeformation))
    * Burst tires
    * Windows
    * Doors

## Requirements
* ESX or QBCore server
* [loaf_lib](https://github.com/loaf-scripts/loaf_lib)
* (should already be on your server) [mysql-async](https://github.com/brouznouf/fivem-mysql-async) or [oxmysql](https://github.com/overextended/oxmysql/)
* (only if you want to save damages) [VehicleDeformation](https://github.com/Kiminaze/VehicleDeformation)
* (optional, needed for qb-core) [qb-menu](https://github.com/qbcore-framework/qb-menu)

## Installation
* Run esx.sql if you use es_extended, qb.sql if you use qb-core
* Install all requirements & follow their installation guides
* Add `ensure loaf_garage` to your server.cfg (you do not need to ensure loaf_lib)