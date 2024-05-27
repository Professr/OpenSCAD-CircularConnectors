# OpenSCAD-CircularConnectors
A library for creating circular electrical connectors in OpenSCAD

![connector_demo](https://github.com/Professr/OpenSCAD-CircularConnectors/assets/769049/c69adc05-d676-43a5-94f7-c4bc5d24775c)

## Contributing
Improvements, additional features, and additional pin/socket types are welcome! 

## Installation
This code depends on the BOSL2 library (https://github.com/BelfrySCAD/BOSL2/), so make sure you have that installed first.

Download `circular_connectors.scad` into the apropriate OpenSCAD library directory. The library directory may be on the list below, but for SNAP or other prepackaged installations, it is probably somewhere else. To find it, run OpenSCAD and select Help→Library Info, and look for the entry that says "User Library Path". This is your default library directory. You may choose to change it to something more convenient by setting the environment variable OPENSCADPATH. Using this variable also means that all versions of OpenSCAD you install will look for libraries in the same location.
* Windows: `My Documents\OpenSCAD\libraries\`
* Linux: `$HOME/.local/share/OpenSCAD/libraries/`
* Mac OS X: `$HOME/Documents/OpenSCAD/libraries/`

## Usage
### pin_connector()
* `pin_options` - Specify the type of pin to use for this connector
* `num_pins` - Number of pins the connector should have
* `pin_spacing` - (optional) Space between pin footprints
* `pin_footprint_diameter` - (optional) Maximum pin/socket footprint, used to determine spacing
* `depth` - (optional) Connector depth / overlap
* `wall_thickness` - (optional) Wall thickness for the threaded parts
* `outer_offset_sf` - (optional) Offset scale factor for the empty space around the edge of the connector
* `key` - (optional, default=true) Add a key for alignment

Example:
```
include <circular_connectors.scad>

pin_connector(pin_options=["round", ".062"], num_pins=19);
```
<img width="320" alt="pin_demo" src="https://github.com/Professr/OpenSCAD-CircularConnectors/assets/769049/04fa4926-6be8-42c6-a3bd-eb0ce6abc2bf">

## Usage
### sock_connector()
* `pin_options` - Specify the type of socket to use for this connector
* `num_pins` - Number of pins the connector should have
* `pin_spacing` - (optional) Space between pin footprints
* `pin_footprint_diameter` - (optional) Maximum pin/socket footprint, used to determine spacing
* `depth` - (optional) Connector depth / overlap
* `wall_thickness` - (optional) Wall thickness for the threaded parts
* `outer_offset_sf` - (optional) Offset scale factor for the empty space around the edge of the connector
* `key` - (optional, default=true) Add a key for alignment

Example:
```
include <circular_connectors.scad>

sock_connector(pin_options=["round", ".062"], num_pins=19);
```
<img width="320" alt="socket_demo" src="https://github.com/Professr/OpenSCAD-CircularConnectors/assets/769049/53706008-6a1d-4a2a-8df6-daf75d03cd3c">

### pin_connector_bracket()
Creates a threaded bracket to hold a pin connector.
* `num_pins` - Number of pins the connector should have
* `bracket_offset` - (optional) Space to leave between the connector and the mounting surface
* `pin_spacing` - (optional) Space between pin footprints
* `pin_footprint_diameter` - (optional) Maximum pin/socket footprint, used to determine spacing
* `depth` - (optional) Connector depth / overlap
* `wall_thickness` - (optional) Wall thickness for the threaded parts
* `outer_offset_sf` - (optional) Offset scale factor for the empty space around the edge of the connector

Example:
```
include <circular_connectors.scad>

pin_connector_bracket(num_pins=19, bracket_offset=10);
```
<img width="320" alt="bracket_demo" src="https://github.com/Professr/OpenSCAD-CircularConnectors/assets/769049/dcd9b0fc-254d-4474-b706-193ed5937370">

## Currently available pin/socket types
Round, often seen in common power connectors:
* `["round", ".062"]` - .062" pin
* `["round", ".062"]` - .062" socket
