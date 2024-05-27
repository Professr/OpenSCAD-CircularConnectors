include <circular_connectors.scad>

/****************
 * Example code *
 ****************/
piece = 3; // Change to select component, so they can be rendered & exported separately

pin = false;
sock = false;
bracket = false;
if(pin || piece==1) {
  pin_connector(pin_options=["round", ".062"], num_pins=19);
}
if(bracket || piece==2) {
  pin_connector_bracket(num_pins=19);
}
if(sock || piece==3) {
  sock_connector(pin_options=["round", ".062"], num_pins=19);
}
