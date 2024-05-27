/************************************************************
 *                                                          *
 *  A library for generating circular electrical connectors *
 *                                                          *
 ************************************************************/  

// Requires the BOSL2 library (https://github.com/BelfrySCAD/BOSL2/)
include <BOSL2/std.scad>
include <BOSL2/threading.scad>

/****************************************************************************************
 * Configurable parameters for printing                                                 *
 *                                                                                      *
 * To get a good fit, you might have to adjust these based on your printer and filament *
 ****************************************************************************************/
// Scale factor for pin and socket dimensions
circular_connectors_pin_scale_factor=1.1;
// Offset to allow the outer screw threads to mesh with inner screw threads without sticking
circular_connectors_screw_offset = 0.9;
// Scale factor so the socket connector fits into the pin connector without sticking
circular_connectors_inner_offset_sf = 0.99;
// Offset for printing captive moving parts, usually set to layer height+
circular_connectors_captive_offset = 0.2;

/*************************
 * Configurable defaults *
 *************************/

// Space between pin footprints
circular_connectors_default_pin_spacing = 1.0;
// Maximum pin/socket footprint, used to determine spacing
circular_connectors_default_pin_footprint_diameter = 4.0;
// Connector depth / overlap
circular_connectors_default_depth = 7.0;
// Wall thickness for the threaded parts
circular_connectors_default_wall_thickness = 3.0;
// Offset scale factor for the empty space around the edge of the connector
circular_connectors_default_outer_offset_sf = 2;

$fa = 4;
$fs = 0.024;
m = 0.001;

/*********************************************************************************
 * Definitions for round pins and sockets, often seen in common power connectors *
 *********************************************************************************/
module round_pin(options) {
  round_sf_tip_d=circular_connectors_pin_scale_factor;
  if(options.y == ".062") { // TODO: make this more modular
    round_tip  = [1.6, 5.0] *round_sf_tip_d;
    round_tabs = [3.0, 2.5] *round_sf_tip_d;
    round_lock = [2.0, 2.0] *round_sf_tip_d;
    round_base = [4.5, 2.0] *round_sf_tip_d;
    union() {
      // Exposed pin
      up((round_tip.y+m)*0.75)
        cyl(h=round_tip.y+m, d=round_tip.x, chamfer=round_tip.x/2);
      // Cone to hold expanded locking tabs and retain tip of pin
      down((round_tabs.y+m)/2)
        cyl(h=round_tabs.y+(m*2), d1=round_tabs.x+m, d2=round_tip.x+m);
      // Locking lip
      down((round_tabs.y+m)+(round_lock.y+m)/2)
        cyl(h=round_lock.y+(m*2), d=round_lock.x+m);
      // Pin body entry cylinder
      down((round_tabs.y+m)+(round_lock.y+m)+(round_base.y+m)/2)
        cyl(h=round_base.y+(m*2), d1=round_base.x+m, d2=round_lock.x+m);
    }
  }
}
module round_socket(options) {
  round_sf_tip_d=circular_connectors_pin_scale_factor;
  if(options.y == ".062") { // TODO: make this more modular
    round_tip  = [2.1, 6.0] *round_sf_tip_d;
    round_tabs = [3.2, 1.5] *round_sf_tip_d;
    round_lock = [2.3, 2.5] *round_sf_tip_d;
    round_base = [4.0, 2.0] *round_sf_tip_d;
    union() {
      // Pin entry
      down((round_tip.y+m)/2)
        cyl(h=round_tip.y+m, d=round_tip.x+m);
      // Cone to hold expanded locking tabs
      down((round_tip.y+m)+(round_tabs.y+m)/2)
        cyl(h=round_tabs.y+(m*2), d1=round_tabs.x+m, d2=round_tip.x+m);
      // Locking lip for tabs and for forward-stop
      down((round_tip.y+m)+(round_tabs.y+m)+(round_lock.y+m)/2)
        cyl(h=round_lock.y+(m*2), d1=round_base.x, d2=round_lock.x+m);
      // Socket body entry cylinder
      down((round_tip.y+m)+(round_tabs.y+m)+(round_lock.y+m)+(round_base.y+m)/2)
        cyl(h=round_base.y+(m*2), d=round_base.x+m);
    }
  }
}

/*************
 * Utilities *
 *************/
 
/**
 * Generate pin models based on options
 *
 *  Valid options:
 *    round:
 *      ["round", ".062", "pin"]    - .062" pin
 *      ["round", ".062", "socket"] - .062" socket
 */
module pin_generator(options=["jst","pin"]) {
  type = options[len(options)-1];
  color("silver") {
    if(options.x == "round") {
      if(type == "pin") {
        round_pin(options);
      } else {
        round_socket(options);
      }
    }
  }
}

// Calculate the diameter of a radial pin array
function radial_array_diameter(
  num_pins,
  pin_spacing,
  pin_footprint_diameter,
  outer_offset_sf,
  start_radius=0
) =
  let (max_pins = max(floor((2*PI*start_radius)/(pin_spacing+pin_footprint_diameter)), 1))
    (num_pins > max_pins) ?
      radial_array_diameter(
        num_pins=num_pins-max_pins,
        pin_spacing=pin_spacing,
        pin_footprint_diameter=pin_footprint_diameter,
        outer_offset_sf=outer_offset_sf,
        start_radius=(start_radius+pin_spacing+pin_footprint_diameter)
      ) : (2*start_radius+pin_spacing)+pin_footprint_diameter+(pin_spacing*outer_offset_sf);

// Generate a radial pin array
module radial_array_generator(
  pin_options,
  num_pins,
  pin_spacing,
  pin_footprint_diameter,
  outer_offset_sf,
  start_radius=0,
  parity=1
) {
  pin_footprint_d = pin_spacing+pin_footprint_diameter;
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
    radial_array_generator(
      pin_options=pin_options,
      num_pins=num_pins-max_pins,
      pin_spacing=pin_spacing,
      pin_footprint_diameter=pin_footprint_diameter,
      outer_offset_sf=outer_offset_sf,
      start_radius=start_radius+pin_footprint_d,
      parity=(parity==1 ? 0 : 1)
    );
  }
}

/******************************************
 * Modules for generating a pin connector *
 ******************************************/
module pin_connector_body(
  diameter,
  pin_options,
  num_pins,
  pin_spacing,
  pin_footprint_diameter,
  depth,
  wall_thickness,
  outer_offset_sf
) {
  difference() {
    cyl(h=depth+m, d=diameter+m);
    up(depth/2+m)
      radial_array_generator(
        pin_options=concat(pin_options, "pin"),
        num_pins=num_pins,
        pin_spacing=pin_spacing,
        pin_footprint_diameter=pin_footprint_diameter,
        outer_offset_sf=outer_offset_sf
      );
  }
}
module pin_connector_screw(
  diameter,
  depth,
  wall_thickness
) {
  p = (wall_thickness/2);
  union() {
    up(depth)
      difference() {
        threaded_rod(h=depth, d=diameter+wall_thickness, pitch=(wall_thickness/2));
        cyl(h=depth+(m*2), d=diameter);
      }
    difference() {
      threaded_rod(h=depth, d=diameter+p*2, pitch=p);
      cyl(h=depth+(m*2), d=diameter);
    }
  }
}
module pin_connector_key(
  diameter,
  depth,
  wall_thickness,
  rounded_ends=true,
  key_sf=1
) {
  move([
    0,
    (diameter/2)-(wall_thickness/6),
    depth-(wall_thickness/4)
  ])
    cuboid(
      [
        wall_thickness*0.5*key_sf,
        wall_thickness*0.75*key_sf,
        depth+(wall_thickness/2)
      ],
      rounding=wall_thickness/4,
      edges=(rounded_ends ? "ALL" : "Z")
    );
}
module pin_connector(
  pin_options,
  num_pins,
  pin_spacing=circular_connectors_default_pin_spacing,
  pin_footprint_diameter=circular_connectors_default_pin_footprint_diameter,
  depth=circular_connectors_default_depth,
  wall_thickness=circular_connectors_default_wall_thickness,
  outer_offset_sf=circular_connectors_default_outer_offset_sf,
  key=true
) {
  body_d = radial_array_diameter(
    num_pins=num_pins,
    pin_spacing=pin_spacing,
    pin_footprint_diameter=pin_footprint_diameter,
    outer_offset_sf=outer_offset_sf
  );
  union() {
    down(depth) {
      color("#665533")
        pin_connector_body(
          diameter=body_d,
          pin_options=pin_options,
          num_pins=num_pins,
          pin_spacing=pin_spacing,
          pin_footprint_diameter=pin_footprint_diameter,
          depth=depth,
          wall_thickness=wall_thickness,
          outer_offset_sf=outer_offset_sf
        );
      color("#444444") {
        pin_connector_screw(
          diameter=body_d,
          depth=depth,
          wall_thickness=wall_thickness
        );
        if(key) {
          pin_connector_key(
            diameter=body_d,
            depth=depth,
            wall_thickness=wall_thickness,
            rounded_ends=true
          );
        }
        up(depth/2-1-0.25)
          tube(h=2.5, od=body_d+(wall_thickness*2), id=body_d);
      }
    }
  }
}
module pin_connector_bracket(
  num_pins,
  pin_spacing=circular_connectors_default_pin_spacing,
  pin_footprint_diameter=circular_connectors_default_pin_footprint_diameter,
  depth=circular_connectors_default_depth,
  wall_thickness=circular_connectors_default_wall_thickness,
  outer_offset_sf=circular_connectors_default_outer_offset_sf,
  bracket_offset=10
) {
  body_d = radial_array_diameter(
    num_pins=num_pins,
    pin_spacing=pin_spacing,
    pin_footprint_diameter=pin_footprint_diameter,
    outer_offset_sf=outer_offset_sf
  );
  bracket_l = body_d+(wall_thickness*2);
  bracket_w = bracket_l-(body_d/2)+bracket_offset;
  bracket_t = 2.5;
  
  down(bracket_t/2) {
    difference() {
      union() {
        move([-bracket_w+(bracket_w/4), 0, depth/2-(bracket_t)])
          prismoid(
            size1=[bracket_w/2, bracket_l], 
            size2=[bracket_t, bracket_l],
            shift=[-bracket_w/4+(bracket_t/2), 0],
            h=depth*2
          );
        left((bracket_w/2))
          cuboid([bracket_w, bracket_l, bracket_t]);
        tube(h=bracket_t, od=body_d+(wall_thickness*2), id=body_d);
      }
      cyl(h=bracket_t+(m*2), d=body_d+(circular_connectors_screw_offset/2)+m);
      pin_connector_screw(
        diameter=body_d+(circular_connectors_screw_offset/2),
        depth=depth,
        wall_thickness=wall_thickness
      );
    }
  }
}

/*********************************************
 * Modules for generating a socket connector *
 *********************************************/
module sock_connector_body(
  diameter,
  pin_options,
  num_pins,
  pin_spacing,
  pin_footprint_diameter,
  depth,
  wall_thickness,
  outer_offset_sf
) {
  inner_offset_sf = circular_connectors_inner_offset_sf;
  body_h = depth;
  body_ring_h = 2;
  body_base_h = 3;
  captive_spacing_h = 0.2;
  difference() {
    union() {
      // Connection body
      up(captive_spacing_h/2)
        cyl(h=body_h-captive_spacing_h, d=(diameter*inner_offset_sf)+m, rounding2=1);
      // Cutout for captive ring
      down((body_h/2)+(body_ring_h/2))
        cyl(h=body_ring_h+(captive_spacing_h*2), d=diameter-wall_thickness);
      // Retainer for captive ring
      down((body_h/2)+(body_ring_h)+captive_spacing_h+(body_base_h/2))
        cyl(h=body_base_h, d=diameter);
    }
    // Subtract pins
    up(depth/2+m)
      radial_array_generator(
        pin_options=concat(pin_options, "socket"),
        num_pins=num_pins,
        pin_spacing=pin_spacing,
        pin_footprint_diameter=pin_footprint_diameter,
        outer_offset_sf=outer_offset_sf
      );
  }
}
module sock_connector_screw(
  diameter,
  depth,
  wall_thickness,
  knurling_depth=0.75
) {
  body_ring_h = 2;
  // Captive ring
  down((depth/2)+(body_ring_h/2)+m) {
    difference() {
      cyl(h=body_ring_h, d=diameter+(wall_thickness*2), rounding1=wall_thickness/2);
      cyl(h=body_ring_h+m, d=diameter-(wall_thickness*0.75));
    }
  }
  difference() {
    // Textured nut
    down(m)
      cyl(h=depth-m, d=diameter+(wall_thickness*2), texture="diamonds", tex_size=[2,2], tex_depth=knurling_depth);
    // Top bevel + center cutout
    cyl(h=depth+wall_thickness, d=diameter+(wall_thickness/2)+m, chamfer2=-wall_thickness);
    // Negative screw threads
    down(depth)
      pin_connector_screw(
        diameter=diameter+circular_connectors_screw_offset,
        depth=depth,
        wall_thickness=wall_thickness
      );
  }
}
module sock_connector(
  pin_options,
  num_pins,
  pin_spacing=circular_connectors_default_pin_spacing,
  pin_footprint_diameter=circular_connectors_default_pin_footprint_diameter,
  depth=circular_connectors_default_depth,
  wall_thickness=circular_connectors_default_wall_thickness,
  outer_offset_sf=circular_connectors_default_outer_offset_sf,
  key=true,
  key_sf=1.2
) {
  body_d = radial_array_diameter(
    num_pins=num_pins,
    pin_spacing=pin_spacing,
    pin_footprint_diameter=pin_footprint_diameter,
    outer_offset_sf=outer_offset_sf
  );
  union() {
    difference() {
      color("#665533")
        sock_connector_body(
          diameter=body_d,
          depth=depth,
          pin_options=pin_options,
          num_pins=num_pins,
          pin_spacing=pin_spacing,
          pin_footprint_diameter=pin_footprint_diameter,
          wall_thickness=wall_thickness,
          outer_offset_sf=outer_offset_sf
        );
      if(key) {
        down(depth-(wall_thickness/4))
          pin_connector_key(
            diameter=body_d,
            key_sf=key_sf,
            depth=depth,
            wall_thickness=wall_thickness,
            rounded_ends=false
          );
      }
    }
    color("#444444")
      sock_connector_screw(
        diameter=body_d,
        depth=depth,
        wall_thickness=wall_thickness
      );
  }
}