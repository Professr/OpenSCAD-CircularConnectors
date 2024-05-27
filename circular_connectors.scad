// Requires the BOSL2 library (https://github.com/BelfrySCAD/BOSL2/)
include <BOSL2/std.scad>
include <BOSL2/threading.scad>

/***************************
 * Configurable parameters *
 ***************************/
// To get a good fit, you might have to adjust these based on your printer and filament
  pin_scale_factor=1.1; // Scale factor for pin and socket dimensions
  screw_offset = 0.9; // Offset to separate the screw threads, so they don't get stuck
  pin_conn_inner_offset_sf = 0.99; // Scale factor so connectors fit together properly

// Maximum pin/socket footprint, used to determine spacing
pin_base_d=4;
// Wall thickness for the threaded parts
pin_conn_wall_t=3.0;
// Connector depth / overlap
pin_conn_depth=7.0;
// Offset scale factor for the empty space around the edge of the connector
pin_conn_outer_offset_sf = 2;
// How much space to leave between the connector edge and the bracket base
bracket_offset = 10;

$fa = 4;
$fs = 0.024;
m = 0.001;

/****************************
 * Molex pin & socket types *
 ****************************/
molex_sf_tip_d=pin_scale_factor;
module molex_pin(options) {
  molex_tip  = [1.6, 5.0] *molex_sf_tip_d;
  molex_tabs = [3.0, 2.5] *molex_sf_tip_d;
  molex_lock = [2.0, 2.0] *molex_sf_tip_d;
  molex_base = [4.5, 2.0] *molex_sf_tip_d;
  union() {
    // Exposed pin
    up((molex_tip.y+m)*0.75)
      cyl(h=molex_tip.y+m, d=molex_tip.x, chamfer=molex_tip.x/2);
    // Cone to hold expanded locking tabs and retain tip of pin
    down((molex_tabs.y+m)/2)
      cyl(h=molex_tabs.y+(m*2), d1=molex_tabs.x+m, d2=molex_tip.x+m);
    // Locking lip
    down((molex_tabs.y+m)+(molex_lock.y+m)/2)
      cyl(h=molex_lock.y+(m*2), d=molex_lock.x+m);
    // Pin body entry cylinder
    down((molex_tabs.y+m)+(molex_lock.y+m)+(molex_base.y+m)/2)
      cyl(h=molex_base.y+(m*2), d1=molex_base.x+m, d2=molex_lock.x+m);
  }
}
module molex_socket(options) {
  molex_tip  = [2.1, 6.0] *molex_sf_tip_d;
  molex_tabs = [3.2, 1.5] *molex_sf_tip_d;
  molex_lock = [2.3, 2.5] *molex_sf_tip_d;
  molex_base = [4.0, 2.0] *molex_sf_tip_d;
  union() {
    // Pin entry
    down((molex_tip.y+m)/2)
      cyl(h=molex_tip.y+m, d=molex_tip.x+m);
    // Cone to hold expanded locking tabs
    down((molex_tip.y+m)+(molex_tabs.y+m)/2)
      cyl(h=molex_tabs.y+(m*2), d1=molex_tabs.x+m, d2=molex_tip.x+m);
    // Locking lip for tabs and for forward-stop
    down((molex_tip.y+m)+(molex_tabs.y+m)+(molex_lock.y+m)/2)
      cyl(h=molex_lock.y+(m*2), d1=molex_base.x, d2=molex_lock.x+m);
    // Socket body entry cylinder
    down((molex_tip.y+m)+(molex_tabs.y+m)+(molex_lock.y+m)+(molex_base.y+m)/2)
      cyl(h=molex_base.y+(m*2), d=molex_base.x+m);
  }
}

/*************
 * Utilities *
 *************/
 
/**
 * Generate pin models based on options
 *
 *  Valid options:
 *    Molex:
 *      ["molex", "pin"]    - .062" pin
 *      ["molex", "socket"] - .062" socket
 */
module pin_generator(options=["jst","pin"]) {
  color("silver") {
    if(options.x == "molex") {
      if(options.y == "pin") molex_pin(options); else molex_socket(options);
    }
  }
}

// Calculate the diameter of a radial pin array
function radial_array_diameter(num_pins, pin_spacing, start_radius=0) =
  let (max_pins = max(floor((2*PI*start_radius)/(pin_spacing+pin_base_d)), 1))
    (num_pins > max_pins) ? (radial_array_diameter(num_pins-max_pins, pin_spacing, start_radius+pin_spacing+pin_base_d)) : (2*start_radius+pin_spacing)+pin_base_d+(pin_spacing*pin_conn_outer_offset_sf);

// Generate a radial pin array model
module radial_array_generator(pin_options, num_pins, pin_spacing, start_radius=0, parity=1) {
  pin_footprint_d = pin_spacing+pin_base_d;
  max_pins = max(floor((2*PI*start_radius)/pin_footprint_d), 1);
  div_angle = 360/max(min(max_pins, num_pins), 1);
  for(i=[0:div_angle:359]) {
    rotate(i+(div_angle/(parity+1)), [0,0,1]) {
      left(start_radius) {
        pin_generator(pin_options);
      }
    }
  }
  if(num_pins > max_pins) {
    radial_array_generator(pin_options, num_pins-max_pins, pin_spacing, start_radius+pin_footprint_d, (parity==1 ? 0 : 1));
  }
}

/******************************************
 * Modules for generating a pin connector *
 ******************************************/
module pin_connector_body(d, pin_options, num_pins, pin_spacing=1) {
  difference() {
    cyl(h=pin_conn_depth+m, d=d+m);
    up(pin_conn_depth/2+m)
      radial_array_generator(concat(pin_options, "pin"), num_pins, pin_spacing);
  }
}
module pin_connector_screw(d) {
  p = (pin_conn_wall_t/2);
  union() {
    up(pin_conn_depth)
      difference() {
        threaded_rod(h=pin_conn_depth, d=d+pin_conn_wall_t, pitch=(pin_conn_wall_t/2));
        cyl(h=pin_conn_depth+(m*2), d=d);
      }
    difference() {
      threaded_rod(h=pin_conn_depth, d=d+p*2, pitch=p);
      cyl(h=pin_conn_depth+(m*2), d=d);
    }
  }
}
module pin_connector_key(d, key_sf=1.0, rounded_ends=true) {
  move([
    0,
    (d/2)-(pin_conn_wall_t/6),
    pin_conn_depth-(pin_conn_wall_t/4)
  ])
    cuboid(
      [
        pin_conn_wall_t*0.5*key_sf,
        pin_conn_wall_t*0.75*key_sf,
        pin_conn_depth+(pin_conn_wall_t/2)
      ],
      rounding=pin_conn_wall_t/4,
      edges=(rounded_ends ? "ALL" : "Z")
    );
}
module pin_connector(pin_options, num_pins, pin_spacing=1, key=true) {
  body_d = radial_array_diameter(num_pins, pin_spacing);
  union() {
    down(pin_conn_depth) {
      color("#665533")
        pin_connector_body(body_d, pin_options, num_pins, pin_spacing);
      color("#444444") {
        pin_connector_screw(body_d);
        if(key) {
          pin_connector_key(body_d);
        }
        up(pin_conn_depth/2-1-0.25)
          tube(h=2.5, od=body_d+(pin_conn_wall_t*2), id=body_d);
      }
    }
  }
}
module pin_connector_bracket(num_pins, pin_spacing) {
  body_d = radial_array_diameter(num_pins, pin_spacing);
  bracket_l = body_d+(pin_conn_wall_t*2);
  bracket_w = bracket_l-(body_d/2)+bracket_offset;
  bracket_t = 2.5;
  
  down(bracket_t/2) {
    difference() {
      union() {
        move([-bracket_w+(bracket_w/4), 0, pin_conn_depth/2-(bracket_t)])
          prismoid(
            size1=[bracket_w/2, bracket_l], 
            size2=[bracket_t, bracket_l],
            shift=[-bracket_w/4+(bracket_t/2), 0],
            h=pin_conn_depth*2
          );
        left((bracket_w/2))
          cuboid([bracket_w, bracket_l, bracket_t]);
        tube(h=bracket_t, od=body_d+(pin_conn_wall_t*2), id=body_d);
      }
      cyl(h=bracket_t+(m*2), d=body_d+(screw_offset/2)+m);
      pin_connector_screw(body_d+(screw_offset/2));
    }
  }
}

/*********************************************
 * Modules for generating a socket connector *
 *********************************************/
module sock_connector_body(d, pin_options, num_pins, pin_spacing=1) {
  body_h = pin_conn_depth;
  body_ring_h = 2;
  body_base_h = 3;
  captive_spacing_h = 0.2;
  difference() {
    union() {
      // Connection body
      up(captive_spacing_h/2)
        cyl(h=body_h-captive_spacing_h, d=(d*pin_conn_inner_offset_sf)+m, rounding2=1);
      // Cutout for captive ring
      down((body_h/2)+(body_ring_h/2))
        cyl(h=body_ring_h+(captive_spacing_h*2), d=d-(pin_conn_wall_t*1));
        //, id=(d-(pin_spacing*pin_conn_outer_offset_sf)));
      // Retainer for captive ring
      down((body_h/2)+(body_ring_h)+captive_spacing_h+(body_base_h/2))
        difference() {
          cyl(h=body_base_h, d=d);
          //cyl(h=body_base_h+1, d=d-(pin_conn_wall_t*1));
        }
    }
    // Subtract pins
    up(pin_conn_depth/2+m)
      radial_array_generator(concat(pin_options, "socket"), num_pins, pin_spacing);
  }
}
module sock_connector_screw(d) {
  body_ring_h = 2;
  // Captive ring
  down((pin_conn_depth/2)+(body_ring_h/2)+m) {
    difference() {
      cyl(h=body_ring_h, d=d+(pin_conn_wall_t*2), rounding1=1.5);
      cyl(h=body_ring_h+m, d=d-(pin_conn_wall_t*0.75));
    }
  }
  difference() {
    // Textured nut
    down(m)
      cyl(h=pin_conn_depth-m, d=d+(pin_conn_wall_t*2), texture="diamonds", tex_size=[2,2], tex_depth=0.75);
    // Top bevel + center cutout
    cyl(h=pin_conn_depth+pin_conn_wall_t, d=d+(pin_conn_wall_t/2)+m, chamfer2=-pin_conn_wall_t);
    // Negative screw threads
    down(pin_conn_depth)
      pin_connector_screw(d+screw_offset);
  }
}
module sock_connector(pin_options, num_pins, pin_spacing=1, key=true) {
  body_d = radial_array_diameter(num_pins, pin_spacing);
  key_sf = 1.2;
  union() {
    difference() {
      color("#665533")
        sock_connector_body(body_d, pin_options, num_pins, pin_spacing);
       if(key) {
        down(pin_conn_depth-(pin_conn_wall_t/4))
          pin_connector_key(body_d, key_sf, rounded_ends=false);
      }
    }
    color("#444444")
      sock_connector_screw(body_d);
  }
}

/************************
 * Main procedural code *
 ************************/
piece = 1; // Change to select component, so they can be rendered & exported separately

pin = false;
sock = false;
bracket = false;
if(pin || piece==1) {
  pin_connector(pin_options=["molex"], num_pins=19, pin_spacing=1.0);
}
if(bracket || piece==2) {
  pin_connector_bracket(num_pins=19, pin_spacing=1.0);
}
if(sock || piece==3) {
  sock_connector(pin_options=["molex"], num_pins=19, pin_spacing=1.0);
}
