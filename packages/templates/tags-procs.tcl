# /packages/templates/tags-procs.tcl
ad_library {

  Markup tag handlers for the form manager component of the
  ArsDigita Publishing System.

  @author Karl Goldstein (karlg@arsdigita.com)
  @cvs-id tags-procs.tcl,v 1.2.6.2 2000/08/08 05:05:02 karl Exp

}

# Copyright (C) 1999-2000 ArsDigita Corporation

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

# set up a datasource in a template to avoid having to set up a data file

proc ad_tag_datasource { params } {

  set src [ns_set iget $params src]
  set name [ns_set iget $params name]

  if { [empty_string_p $src] } {
    return "<em>No SRC attribute in DATASOURCE tag</em>"
  }

  if { [empty_string_p $name] } {
    return "<em>No NAME attribute in DATASOURCE tag</em>"
  }

  if { [catch {

    set url [ad_util_absolute_url $src [ns_conn url]]

    set datasource [ad_template_get_datasource $url $name]

    ad_template_get_data this $datasource

  } errmsg] } {

    ns_log Notice "ERROR evaluating data source $name in $src:\n$errmsg"
  }
}

# output a variable

proc ad_tag_var { params } {

  set name [ns_set iget $params name]

  # if no name then assume it is a standard HTML var tag

  if { $name == "" } { return "<var>" }

  global doc_properties
  if { [doc_property_exists_p $name] } {
      return [doc_get_property $name]
  }

  upvar #0 $name var
  if { ! [info exists var] } {
    return "<em>Undefined variable $name in VAR tag</em>"
  }

  return $var
}

# output a variable in URL encoded form

proc ad_tag_encvar { params } {

  set name [ns_set iget $params name]

  # if no name then assume it is a standard HTML var tag

  if { $name == "" } { return "NO_NAME_PARAM" }

  global doc_properties
  if { [doc_property_exists_p $name] } {
      return [ns_urlencode [doc_get_property $name]]
  }

  upvar #0 $name var

  if { ! [info exists var] } {
    return "VARIABLE_NOT_FOUND"
  }

  return [ns_urlencode $var]
}

# output a template for each item in a list

proc ad_tag_list { template params } {

  set name [ns_set iget $params name]
  set prefix "$name."

  upvar #0 $name items "$name.rownum" rownum "$name.item" i

  if { ! [info exists items] } {
    return "<em>Undefined data source $name in LIST tag</em>"
  }

  set content ""
  set rownum 1

  foreach item $items {

    set i $item    

    append content [ns_adp_parse -string $template]

    incr rownum
  }

  return $content
}

# output a template in grid form

proc ad_tag_grid { template params } {

  set name [ns_set iget $params name]
  set prefix "$name."

  upvar #0 $name sets "$name.rownum" rownum "$name.rowcount" n
  upvar #0 "$name.row" r "$name.col" c

  if { ! [info exists sets] } {
    return "<em>Undefined data source $name in GRID tag</em>"
  }

  set content ""
  set rownum 1

  set maxrows [ns_set iget $params maxrows]
  if { [string match $maxrows {}] } { set maxrows 10000 }

  set cols [ns_set iget $params cols]
  if { [string match $cols {}] } { 
    return "<em>No COLS attribute specified in GRID tag</em>"
  }

  set n "[llength $sets].0"

  if { $maxrows < $n} { set n "$maxrows.0" }

  set rows [expr ceil($n / $cols)]

  for { set r 1 } { $r <= $rows } { incr r } {
    for { set c 1 } { $c <= $cols } { incr c } {
 
      set i [expr int(($r - 1) + (($c - 1) * $rows))]
      set rownum [expr $i + 1]

      if { $i < $n } {

        set set [lindex $sets $i]

        if { [string match $set {}] } { 
          return "<em>Null set for data source $name in GRID tag</em>"
        }
    
        if { [catch { ad_util_set_global_variables $prefix $set } errMsg] } {
          return "<em>Invalid set $set for data source $name in GRID tag</em>"
        }
      }

      append content [ns_adp_parse -string $template]

    }
  }

  return $content
}

# output a template for each row of data from a data source

proc ad_tag_multiple { template params } {

  set name [ns_set iget $params name]
  set prefix "$name."

  upvar #0 $name sets "$name.rownum" rownum

  if { ! [info exists sets] } {
    return "<em>Undefined data source $name in MULTIPLE tag</em>"
  }

  set content ""
  set rownum 1

  set maxrows [ns_set iget $params maxrows]
  if { [string match $maxrows {}] } { set maxrows 10000 }

  set length [llength $sets]

  for { set i 0 } { $i < $length } { incr i } {

    set set [lindex $sets $i]

    set last_set [lindex $sets [expr $i - 1]]
    set next_set [lindex $sets [expr $i + 1]]

    if { [string match $set {}] } { 
      return "<em>Null set for data source $name in MULTIPLE tag</em>"
    }
    
    if { [catch { 

      if { $last_set == "" } { 
        ad_util_clear_global_variables "Last." $set
      } else {
        ad_util_set_global_variables "Last." $last_set 
      }

      if { $next_set == "" } {
        ad_util_clear_global_variables "Next." $set
      } else {
        ad_util_set_global_variables "Next." $next_set 
      }
      
      ad_util_set_global_variables $prefix $set 

    } errMsg] } {

      return "<em>Invalid set $set for data source $name in MULTIPLE tag</em>"
    }

    append content [ns_adp_parse -string $template]

    if { $rownum == $maxrows } { break }

    incr rownum
  }

  return $content
}

proc ad_tag_separator { template params } {

  set name [ns_set iget $params name]

  upvar #0 "$name.rownum" rownum "$name.rowcount" rowcount

  if { $rownum < $rowcount } {

    set content [ns_adp_parse -string $template]

  } else {

    set content ""
  }

  return $content
}

proc ad_tag_enclose { template params } {

  set url [ad_tag_prepare_external_template $params]

  if { [string match $url {}] } { 
    return "<em>No src attribute in ENCLOSE tag</em>" 
  }

  upvar #0 content content
  set content [ns_adp_parse -string $template]

  return [ns_adp_parse -file [ns_url2file $url]]
}

# initialize and output an external template

proc ad_tag_include { params } {

  set url [ad_tag_prepare_external_template $params]

  if { [string match $url {}] } { 
    return "<em>No src attribute in INCLUDE tag</em>" 
  }

  return [ad_template_parse -file [ns_url2file $url]]
}

# prepare to parse an external template (used by include and enclose)

proc ad_tag_prepare_external_template { params } {

  set src [ns_set iget $params src]

  if { [string match $src {}] } { 
    return ""
  }

  ns_set idelkey $params src
  set src [ad_tag_interp_param $src]
    
  for { set i 0 } { $i < [ns_set size $params] } { incr i } {

    set key [ns_set key $params $i]
    set value [ns_set value $params $i]

    if { ! [string match $value {}] } {

      upvar #0 $key k
      set k [ad_tag_interp_param $value]
    }
  }

  set url [ad_util_absolute_url $src [ns_conn url]]

  ad_template_init url

  return $url
}

# output a template contingent on a condition

proc ad_tag_if { template params } {

  upvar #0 _IFCONDITION condition _IFRESULT result

  set condition "if {"

  # try the eval syntax first

  if { [ns_set key $params 0] == "eval" } {

    append condition [ns_set value $params 0]

  } else {

    # parse simplified conditional expression

    set tokens [ad_tag_concat_params $params]

    # interpret tokens for variable names

    foreach token $tokens {

      set arg [ad_tag_interp_arg $token]
      lappend args $arg
    }

    while { 1 } { 

      set complaint [ad_tag_interp_expr]
      if { ! [string match $complaint {}] } { return $complaint }

      if { [llength $args] == 0 } { break }

      set conjunction [lindex $args 0]      

      switch $conjunction {
 
        and { append condition " && " }
        or { append condition " || " }
        default { 
          return "<em>Invalid conjunction $conjunction in IF tag</em>" 
        }
      }
      
      set args [lrange $args 1 end] 
    }
  }

  append condition "}"

  # ns_log Notice $condition

  uplevel #0 {

    set _IFDEBUG $_IFCONDITION

    # evaluate the condition

    append _IFCONDITION " { set _IFRESULT 1 } else { set _IFRESULT 0 }"
    
    if [catch {eval $_IFCONDITION} _IFERR] {
      ns_log Notice "Error evaluating IF tag:\n$_IFDEBUG\n$_IFERR"
      return "<em>Error evaluating IF tag: ${_IFDEBUG}</em>"
    }
  }

  if { $result } {

    set output [ns_adp_parse -string $template]

    # Restore the result code in case an ELSE follows
    set result 1

    return $output

  } else {
    return ""
  }
}

proc ad_tag_else { template params } {

  upvar #0 _IFRESULT result

  if { ! [info exists result] } { 
    return "<em>No IF tag prior to ELSE tag</em>"
  }

  if { ! $result } { 
    return [ns_adp_parse -string $template]
  } else {
    return ""
  }
}

# Interpret an expression as part of the simplified IF syntax

proc ad_tag_interp_expr {} {

  upvar args args condition condition

  append condition "\[expr "

  set op  [lindex $args 1]

  if { $op == "not" } {
    set not "! "
    set op [lindex $args 2]
    set i 3
  } else {
    set not ""
    set i 2
  }

  set arg1 "{[lindex $args 0]}"

  # build the conditional expression

  switch $op {

    gt { 
      append condition "{ $arg1 > {[lindex $args $i]} }" 
      set next [expr $i + 1]
    }
    ge { 
      append condition "{ $arg1 >= {[lindex $args $i]} }" 
      set next [expr $i + 1]
    }
    lt { 
      append condition "{ $arg1 <  {[lindex $args $i]} }" 
      set next [expr $i + 1]
    }
    le { 
      append condition "{ $arg1 <= {[lindex $args $i]} }" 
      set next [expr $i + 1]
    }
    eq { 
      append condition "{ $arg1 == {[lindex $args $i]} }" 
      set next [expr $i + 1]
    }
    ne { 
      append condition "{ $arg1 != {[lindex $args $i]} }" 
      set next [expr $i + 1]
    }

    in { 
      set expr [join [lrange $args $i end] "|"]
      append condition "{ $not\[regexp {$expr} $arg1\] }" 
      set next [llength $args]
    }

    between { 
      set expr1 "$arg1 >= {[lindex $args $i]}"
      set expr2 "$arg1 <= {[lindex $args [expr $i + 1]]}"
      append condition "{ $not\[expr $expr1 && $expr2\] }" 
      set next [expr $i + 2]
    }

    nil {
      if { [string match $arg1 {{}}] } { 
	  append condition "{ $not{1} }"
      } else {
        append condition "{ $not\[string match {$arg1} {}\] }"  
      }
      set next $i
    }

    odd { 
      append condition "{ \[expr $arg1 % 2\] }" 
      set next $i
    }

    even { 
      append condition "{ ! \[expr $arg1 % 2\] }" 
      set next $i
    }

    default { 
      return "<em>Invalid operator $op in IF tag</em>" 
    }
  }

  append condition "]"

  set args [lrange $args $next end]

  return ""
}

# append all the tags together and then eval as a list to restore
# quotes

proc ad_tag_concat_params { params } {

  set size [ns_set size $params]

  for { set i 0 } { $i < $size } { incr i } {
    lappend tokens [ns_set key $params $i]
  }

  set tokens [eval [concat list [join $tokens " "]]]

  return $tokens
}

# interpret a conditional argument as literal or global variable

proc ad_tag_interp_arg { arg } {

  if [regexp {%([^%]*)} $arg x var] {
      global doc_properties
      if { [doc_property_exists_p $arg] } {
	  set value [doc_get_property $arg]
      } else {
	  upvar #0 $var value
      }
  } else {

    set value $arg
  }

  if { ! [info exists value] } {

    return ""
  }

  return $value
}

proc ad_tag_interp_param { param } { 

  regsub -all {%([^%]*)%} $param {${\1}} param

  set param [eval "uplevel #0 { subst \"$param\" }"]

  return $param
}

proc ad_tag_data { params } {

  ad_util_set_variables $params name style

  if { [string match $style {}] } { 
    return "<em>No style attribute in DATA tag</em>" 
  }

  if { [string match $name {}] } { 
    return "<em>No name attribute in DATA tag</em>" 
  }

  set stylepath [ad_util_url2file /templates/styles/$style.adp]

  if { ! [file exists $stylepath] } { 
    return "<em>Style $style in DATA tag not found</em>"
  }

  # determine the structure of the named datasource

  upvar #0 $name.structure structure

  switch $structure {

    onevalue {

      # set one bind variable named :data by convention

      eval "uplevel #0 {
        set :data \$name
      }"
    } 
    onerow {

      # bind a set of variables based on tag parameters

      for { set i 2 } { $i < [ns_set size $params] } { incr i } {
    
        set bindvar [ns_set key $params $i]
        set var [ns_set value $params $i]

        # map variables to bind variables
        eval "uplevel #0 {
          set \":$bindvar\" \$\{$name.$var\}
        }"
      }
    }
    multirow {

      # build a list of bound variables named :data by convention

      upvar #0 :data data :columns columns $name sets
      set data [list]

      set bindcount [ns_set size $params]

      # build a list of column names if in column mode
      if { $bindcount <= 2 && [llength $sets] > 0 } {
	set columns [ad_util_get_keys [lindex $sets 0]]
      }

      foreach set $sets {

	set tmp [ns_set create]
        # if template specifies bind variables by name...

        if { $bindcount > 2 } {

	  for { set i 2 } { $i < $bindcount } { incr i } {
    
	    set bindvar [ns_set key $params $i]
	    set var [ns_set value $params $i]
          
	    ns_set put $tmp $bindvar [ns_set get $set $var]
	  }

	} else {

	  # otherwise just build a list of values in the items key
	  ns_set put $tmp items [ad_util_get_values $set]
	}

        lappend data $tmp
      }
    }
  }

  return [ns_adp_parse -file $stylepath]
}

