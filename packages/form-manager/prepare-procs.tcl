# /packages/form-manager/prepare-procs.tcl
ad_library {

  Form template preparation procedures for form manager component of the 
  ArsDigita Publishing System.

  @author Karl Goldstein (karlg@arsdigita.com)
  @cvs-id prepare-procs.tcl,v 1.6.2.2 2000/08/08 05:05:53 karl Exp

}

# Copyright (C) 1999 Karl Goldstein (karlg@arsdigita.com)

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

# Automatically generate a form template

proc ad_form_template { spec { style "standard" } } {
  
  if { [string match $style {}] } {
    set style "standard"
  }

  # Get template cache or create if necessary 
  set templates [ns_set get $spec templates]
  if { $templates == "" } {
    set templates [ns_set create -persist templates]
    ns_set put $spec templates $templates
  }
  
  # First look for a cached copy of the template
  set template [ns_set get $templates $style]
  set last_mtime [ns_set get $templates "$style.mtime"]
  
  # Look for the form style template
  set path [ad_util_url2file /templates/forms/$style.adp]

  if { [catch { set mtime [file mtime $path] } errMsg] } {
    return "<em>Could not access template file for form style $style</em>"
  } 

  if { $mtime != $last_mtime } { 
    ns_log Notice "Updating template cache for form style $style"
    set template [ad_form_template_prepare $spec $path $style $mtime]
  }

  return $template
}

# Promote layout variables from inner set so they are accessible when
# generating the template (a more general solution would be better).

proc ad_form_template_prepare_layout { spec } {

  set proto_layout [ns_set create]
  foreach k [list label_width element_width line_break_after \
                     section_break_before section_message] {
    ns_set put $proto_layout $k ""
  }

  foreach element [ad_form_get_elements $spec] {
    set layout [ns_set get $element layout]
    if { $layout != "" } {
      ns_set merge $element $layout
    }
    ns_set merge $element $proto_layout
  }
}

proc ad_form_template_prepare { spec path style mtime } {

  upvar #0 "form.elements" elements 
  set elements [ad_form_get_elements $spec]

  # make sure that all elements have a label and help string.
  # otherwise they will get the one from the previous element.
  foreach element $elements {
    if { [ns_set find $element label] == -1 } {
      ns_set put $element label ""
    }
    if { [ns_set find $element help] == -1 } {
      ns_set put $element help ""
    }
  }

  upvar #0 "form.help" help "form.submit" submit
  ad_util_set_variables $spec help submit

  set template [ns_adp_parse -file $path]
  regsub -all {<\?} $template {<} template

  ad_util_set_variables $spec templates

  ns_set put $templates $style $template

  ns_set put $templates "$style.mtime" $mtime

  return $template
}

# Prepare a substitute form spec when appropriate

proc ad_form_prepare_substitute { spec } {

  if { [empty_string_p $spec] } { return "" }

  # if preparing then check if we are subsituting for another spec
  # (only one level of substitution allowed).

  ad_util_set_variables $spec url substitute

  if { ! [empty_string_p $substitute] } {
    set src [eval $substitute]
    if { ! [empty_string_p $src] } {
      set url [ad_util_absolute_url $src $url]
      set spec [ad_form_get_spec $url]
    }
  }

  return $spec
}


# Prepare form widgets and labels for insertion into a template

proc ad_form_prepare { spec elements } {

  ad_util_set_variables $spec dbaction multikey name
  set form_name $name

  # A non-null value for this would indicate a form that failed validation
  # and was returned to the user

  set src [ns_queryget form.src]

  # Process data sources specified in the form file
  ad_template_get_all_data $spec

  # If preparing an update form then look up existing values.  Do not
  # substitute in default values (again) if the form has already been
  # submitted once (i.e. form.src is present).

  if { $multikey != "t" && $dbaction == "update" && $src == "" } {

    set table_map [ad_form_map_tables $spec $elements]
    set formdata [ad_form_prepare_update $table_map]

  } else {

    set formdata [ns_getform]
    if { $formdata == "" } { set formdata [ns_set create] }
  }

  foreach element $elements {

    set name [ns_set get $element name]

    upvar #0 "formelement.$name" elem "formvalues.$name" values 

    set elem $element

    set values [ad_util_get_values $formdata $name]
  }
}

# Query the database for default values to populate an update form.
# Columns such as datetime may need to be wrapped in a function to
# return an interpretable value.

proc ad_form_prepare_update { table_map } {

  set updata [ns_set create]

  ad_util_set_variables $table_map column_map

  foreach table [ad_util_get_keys $column_map] {

    set columns [ns_set get $column_map $table]
    
    set whereclause [ad_form_process_whereclause $table_map $table]

    if { [empty_string_p $whereclause] } { continue }

    set column_list [list]
    set query_list [list]

    for { set i 0 } { $i < [ns_set size $columns] } { incr i } {

      set column [ns_set key $columns $i]
      # Use the first element in the list of elements for this column
      set element [lindex [ns_set value $columns $i] 0]
      set datatype [ns_set get $element datatype]
    
      switch $datatype {
        datetime { 
         lappend query_list \
           "to_char($column, 'YYYY-MM-DD HH24:MI:SS') as $column" 
        }
        default { 
         lappend query_list $column
        }
      }
      lappend column_list $column
    }

    set query "
      select 
        [join $query_list ","] 
      from
        $table
      where
        $whereclause
    "
  
    foreach row [ad_dbquery multirow $query] {
      
      foreach column $column_list {

        set value [ns_set get $row $column]
      
        foreach element [ns_set get $columns $column] {

          set name [ns_set get $element name]
          ns_set put $updata $name $value          
	} 
      }
    }
  }

  return $updata
}

# Prepare the widget code for a single form element

proc ad_form_prepare_element { element values { order "" } } {

  ad_util_set_variables $element name widget options defaults

  if {[catch { 

    # Check for default values either from a previous failed submission
    # or from the database in the case of updates

    if { ! [string match $order {}] } {
      set values [ad_util_queryget -none $name.$order]
    }

    if { ! [string match [lindex $values 0] {}] } { 
      set def_list $values
    } else {
      set def_list [ad_form_prepare_element_defaults $name $defaults]
    }

    set opt_list [ad_form_prepare_element_options $name $options]

    if { [info procs ad_form_widget_$widget] != "" } {
      set markup [ad_form_widget_$widget $element $def_list $opt_list $order]
    } else {
      set markup "<em>Invalid widget type $widget for form element $name</em>"
    }

  } errMsg]} {

    global errorInfo
    ns_log Notice "Error preparing form element $name: $errMsg"
    ns_log Notice $errorInfo
    set markup "Error preparing form element $name: $errMsg"
  }

  return $markup
}

proc ad_form_prepare_element_defaults { name defaults } {

  if { $defaults == "" } { return [list] }

  ad_util_set_variables $defaults method text cache

  # upvar #0 $name default_list 
  set default_list [list]

  # First look to see if default values have been cached

  if { $cache == "t" && [ns_set find $defaults values] != -1 } {
    return [ns_set get $defaults values]
  }

  if { [catch {

    switch $method {

      query {
	set default_list [eval "uplevel #0 { 
	  subst \"\[ad_dbquery onelist \"$text\"\]\"
	}"]
      }
      static {
	set default_list [split $text ","]
      }
      param {
	set default_list [ad_util_queryget $text]
      }
      eval {
	set default_list [eval "uplevel #0 { eval \{$text\} }"]
      }	
    }

  } errMsg] } {

    ns_log Notice "Error preparing defaults for form element $name:\n$errMsg"
  }

  if { $cache == "t" } {
    ns_set put $defaults values $default_list
  }
  
  return $default_list
}

proc ad_form_prepare_element_options { name options } {

  if { $options == "" } { return [list] }

  ad_util_set_variables $options method text null cache

  if { $cache == "t" && [ns_set find $options values] != -1 } {
    return [ns_set get $options values]
  }

  switch $method {

    query {
      set option_list [eval "uplevel #0 { 
        subst \"\[ad_dbquery multilist \"$text\"\]\"
      }"]
    }
    static {
      set option_list [ad_form_prepare_parse_static_options $options]
    }
    eval {
     set option_list [eval "uplevel #0 { eval \{$text\} }"]
    }	
    default {
      error PUBLISH_FORM_INVALID_OPTION_METHOD
    }
  }

  if { $null == "t" } {
    set option_list [linsert $option_list 0 [list "(None)" ""]]
  }

  if { $cache == "t" } {
    ns_set put $options values $option_list
  }

  return $option_list
}

proc ad_form_prepare_parse_static_options { options } {

   set option_elements [ad_util_get_values $options option]

   if { [llength $option_elements] > 0 } {
     set option_list [list]
     foreach option $option_elements {
	ad_util_set_variables $option text value
	lappend option_list [list $text $value]
     }
   } else {
     set option_list [ad_util_parse_keys [ns_set get $options text]]
   }

   return $option_list
}
