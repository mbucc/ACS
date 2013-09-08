# /packages/form-manager/tags-procs.tcl
ad_library {

  Tag handlers for form manager for the ArsDigita Publishing System.

  @author Karl Goldstein (karlg@arsdigita.com)
  @cvs-id tags-procs.tcl,v 1.4.2.1 2000/07/18 22:06:41 seb Exp

}

# Copyright (C) 1999-2000 ArsDigita Corporation

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

# The form container

proc ad_tag_formtemplate { template params } {

  ad_util_set_variables $params src count

  if { [string match $src {}] } {
    return "<em>No src attribute in formtemplate tag</em>"
  }

  set src [ad_tag_interp_param $src]
  set count [ad_tag_interp_arg $count]

  set url [ad_util_absolute_url $src [ns_conn url]]

  ns_log Notice "URL is $url"

  set spec [ad_form prepare $url]

  if { $spec == "" } { 
    return "<em>No form specification found at $spec</em>" 
  }

  ad_util_set_variables $spec dbaction action name validate

  # if the tag is empty than autogenerate a template

  if { [string match [string trim $template] {}] } {

    set style [ns_set get $params style]
    set template [ad_form_template $spec $style]
  }

  if { ! [string match $validate "same"] } { 
    set action_url $action
  } else {
    set action_url [ns_conn url]
  }

  append output "
    <[ad_form_widget_tag form $spec] action=\"$action_url\" method=\"post\">

      <input type=hidden name=form.src value=\"$url\">
      <input type=hidden name=form.count value=\"$count\">

      [ns_adp_parse -string $template]

    </form>
  "

  return $output
}

# Insert a form label

proc ad_tag_formlabel { params } {

  set name [ns_set iget $params name]
  if { [string match $name {}] } {
    return "<em>No name parameter in FORMLABEL tag</em>"
  }

  upvar #0 "formlabel.$name" label

  if { [info exists label] } { return $label }

  upvar #0 "formelement.$name" element

  if { ! [info exists element] } {
    return "<em>No form element named $name found.</em>"
  }

  return [ns_set get $element label]
}

proc ad_tag_formerror { template params } {

  ad_util_set_variables $params name order

  if { [string match $name {}] } {
    return "<em>No name parameter in FORMERROR tag</em>"
  }

  set order [ad_tag_interp_arg $order]
  if { $order != "" } { set order ".$order" }

  upvar #0 form.error.$name$order error_message

  if { [info exists error_message] } {

    upvar #0 form.error.$name error_var
    set error_var $error_message
    return [ns_adp_parse -string $template]

  } else {
    return ""
  }
}

# Insert a form widget

proc ad_tag_formwidget { params } {

  ad_util_set_variables $params name order value

  if { [string match $name {}] } {
    return "<em>No name parameter in FORMWIDGET tag</em>"
  }

  # This will be set already if within a formgroup tag
  upvar #0 "formwidget.$name" markup
  if { [info exists markup] } { return $markup }

  upvar #0 "formelement.$name" element 

  set order [ad_tag_interp_arg $order]
  set value [ad_tag_interp_arg $value]

  if { [string match $value {}] } {
    upvar #0 "formvalues.$name" values
  } else {
    set values [list $value]
  }

  if { ! [info exists element] || ! [info exists values] } {
    return "<em>Info for form element $name not found.</em>"
  }

  return [ad_form_prepare_element $element $values $order]
}

# Embed passed-in form variables as hidden inputs.

proc ad_tag_formvalues { params } {

  ad_util_set_variables $params name order

  if { [string match $name {}] } {
    return "<em>No name parameter in FORMVALUES tag</em>"
  }

  upvar #0 "formelement.$name" element 

  set order [ad_tag_interp_arg $order]

  upvar #0 "formvalues.$name" values

  if { ! [info exists element] || ! [info exists values] } {
    return "<em>Info for form element $name not found.</em>"
  }

  set markup ""

  foreach value $values {
    set value [list $value]
    append markup [ad_form_widget_hidden $element $value "" $order] "\n"
  }

  return $markup
}

# Insert a logical group of form widgets

proc ad_tag_formgroup { template params } {

  ad_util_set_variables $params name order value

  if { [string match $name {}] } {
    return "<em>No name parameter in FORMGROUP tag</em>"
  }

  upvar #0 "formelement.$name" element

  set order [ad_tag_interp_arg $order]
  set value [ad_tag_interp_arg $value]

  if { [string match $value {}] } {
    upvar #0 "formvalues.$name" values
  } else {
    set values [list $value]
  }

  if { ! [info exists element] || ! [info exists values] } {
    return "<em>Info for form group $name not found.</em>"
  }

  set group [ad_form_prepare_element $element $values $order]

  upvar #0 "$name.rownum" rownum "$name.rowcount" n "$name.row" r "$name.col" c

  upvar #0 "formwidget.$name" markup 
  upvar #0 "formlabel.$name" label

  set output ""
  set rownum 1

  set cols [ns_set iget $params cols]
  if { [string match $cols {}] } { set cols 1 }

  set n "[llength $group].0"
  set rows [expr ceil($n / $cols)]
  set items $group

  for { set r 1 } { $r <= $rows } { incr r } {
    for { set c 1 } { $c <= $cols } { incr c } {
 
      set i [expr int(($r - 1) + (($c - 1) * $rows))]
      set rownum [expr $i + 1]

      if { $i < $n } {

        set item [lindex $items $i]
        set markup [ns_set get $item markup]
        set label [ns_set get $item label]
        append output [ns_adp_parse -string $template]
      }
    }
  }

  return $output
}

