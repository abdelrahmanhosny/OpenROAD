#############################################################################
##
## Copyright (c) 2019, James Cherry, Parallax Software, Inc.
## All rights reserved.
##
## BSD 3-Clause License
##
## Redistribution and use in source and binary forms, with or without
## modification, are permitted provided that the following conditions are met:
##
## * Redistributions of source code must retain the above copyright notice, this
##   list of conditions and the following disclaimer.
##
## * Redistributions in binary form must reproduce the above copyright notice,
##   this list of conditions and the following disclaimer in the documentation
##   and/or other materials provided with the distribution.
##
## * Neither the name of the copyright holder nor the names of its
##   contributors may be used to endorse or promote products derived from
##   this software without specific prior written permission.
##
## THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
## AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
## IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
## ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
## LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
## CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
## SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
## INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
## CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
## ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
## POSSIBILITY OF SUCH DAMAGE.
#############################################################################

# -constraints is an undocumented option for worthless academic contests
sta::define_cmd_args "detailed_placement" {[-constraints constraints_file]}

proc legalize_placement { args } {
  sta::parse_key_args "legalize_placement" args \
    keys {} flags {-verbose}

  puts "Warning: the legalize_placement command has been renamed to 'detailed_placement'."
  set verbose [info exists flags(-verbose)]
  sta::check_argc_eq0 "legalize_placement" $args
  if { [ord::db_has_rows] } {
    opendp::detailedPlacement
  } else {
    sta::sta_error "no rows defined in design. Use initialize_floorplan to add rows."
  }
  opendp::check_placement_cmd $verbose
}

proc detailed_placement { args } {
  sta::parse_key_args "detailed_placement" args \
    keys {-constraints} flags {}

  if { [info exists keys(-constraints)] } {
    set constraints_file $keys(-constraints)
    if { [file readable $constraints_file] } {
      opendp::read_constraints $constraint_file
    } else {
      puts "Warning: cannot read $constraints_file"
    }
  }

  sta::check_argc_eq0 "detailed_placement" $args
  if { [ord::db_has_rows] } {
    opendp::detailed_placement_cmd
  } else {
    sta::sta_error "no rows defined in design. Use initialize_floorplan to add rows."
  }
}

sta::define_cmd_args "set_placement_padding" { [-global]\
						 [-right site_count]\
						 [-left site_count] \
					       }

proc set_padding { args } {
  puts "Warning: the set_padding command has been renamed to 'set_placement_padding'."
  eval [concat set_placement_padding $args]

}

proc set_placement_padding { args } {
  sta::parse_key_args "set_placement_padding" args \
    keys {-right -left} flags {-global}

  set left 0
  if { [info exists keys(-left)] } {
    set left $keys(-left)
    sta::check_positive_integer "-left" $left
  }
  set right 0
  if { [info exists keys(-right)] } {
    set right $keys(-right)
    sta::check_positive_integer "-right" $right
  }
  set global [info exists flags(-global)]
  sta::check_argc_eq0 "set_placement_padding" $args
  if { $global } {
    opendp::set_padding_global $left $right
  } else {
    sta::sta_error "Only set_placement_padding -global supported."
  }
}

sta::define_cmd_args "filler_placement" { filler_masters }

proc filler_placement { args } {
  sta::check_argc_eq1 "filler_placement" $args
  set fillers [opendp::get_masters_arg $args]
  opendp::filler_placement_cmd $fillers
}

sta::define_cmd_args "check_placement" {[-verbose]}

proc check_placement { args } {
  sta::parse_key_args "check_placement" args \
    keys {} flags {-verbose}

  set verbose [info exists flags(-verbose)]
  sta::check_argc_eq0 "check_placement" $args
  if { [opendp::check_placement_cmd $verbose] } {
    error "Error: placement check failed."
  }
}

namespace eval opendp {

# expand master name regexps
proc get_masters_arg { master_names } {
  set db [ord::get_db]
  set names {}
  foreach name $master_names {
    foreach lib [$db getLibs] {
      foreach master [$lib getMasters] {
	set master_name [$master getConstName]
	if { [regexp $name $master_name] } {
	  lappend names $master_name
	}
      }
    }
  }
  return $names;
}

}
