# /packages/form-manager/widget-procs.tcl
ad_library {

  Form widgets for the form manager component of the ArsDigita
  Publishing System.

  @author Karl Goldstein (karlg@arsdigita.com)
  @cvs-id widget-procs.tcl,v 1.4.2.2 2000/07/23 22:34:46 seb Exp

}

# Copyright (C) 1999-2000 ArsDigita Corporation

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

# Returns the widget tag with any additional specified attributes

proc ad_form_widget_tag { widget_name element { order "" } } {

  ad_util_set_variables $element name

  if { ! [string match $order {}] } { append name ".$order" }

  set tag "$widget_name name=\"$name\""

  foreach attribute [ad_util_get_values $element attribute] {

    ad_util_set_variables $attribute name text
    append tag " $name=\"$text\""
  }

  return $tag    
}

proc ad_form_widget_none { element default_list option_list order } {

  return ""
}

proc ad_form_widget_submit { element default_list option_list order } {

  ad_util_set_variables $element name

  set value [lindex $default_list 0]

  set html "<[ad_form_widget_tag input $element $order] type=\"submit\" 
              value=\"[util_quotehtml $value]\">"

  return $html
}

proc ad_form_widget_readonly { element default_list option_list order } {

  ad_util_set_variables $element name

  set value [lindex $default_list 0]

  set html "$value<[ad_form_widget_tag input $element $order] type=\"hidden\" 
              value=\"[util_quotehtml $value]\">"

  return $html
}

proc ad_form_widget_hidden { element default_list option_list order } {

  ad_util_set_variables $element name

  set value [lindex $default_list 0]

  set html "<[ad_form_widget_tag input $element $order] type=\"hidden\" 
              value=\"[util_quotehtml $value]\">"

  return $html
}

proc ad_form_widget_file { element default_list option_list order } {

  ad_util_set_variables $element name width

  set value [lindex $default_list 0]

  if { [string match $width {}] } {
    set size ""
  } else {
    set size " size=\"$width\""
  }

  set html "<[ad_form_widget_tag input $element $order]$size type=\"file\">"

  return $html
}

proc ad_form_widget_text { element default_list option_list order } {

  ad_util_set_variables $element name width

  set value [lindex $default_list 0]

  if { [string match $width {}] } {
    set size ""
  } else {
    set size " size=\"$width\""
  }

  set html "<[ad_form_widget_tag input $element $order]$size 
              type=\"text\" value=\"[util_quotehtml $value]\">"

  return $html
}

proc ad_form_widget_password { element default_list option_list order } {

  ad_util_set_variables $element name width

  set value [lindex $default_list 0]

  set html "<[ad_form_widget_tag input $element $order] type=\"password\" 
              size=\"$width\" 
              value=\"[util_quotehtml $value]\">"

  return $html
}

proc ad_form_widget_textarea { element default_list option_list order } {

  ad_util_set_variables $element name height width

  set value [lindex $default_list 0]

  set html "<tt><[ad_form_widget_tag textarea $element $order]
              rows=\"$height\" cols=\"$width\">$value</textarea></tt>"

  return $html
}

proc ad_form_widget_select { element default_list option_list order } {

  ad_util_set_variables $element name widget height nulloption

  if { ! [string match $height {}] } {
    set size " size=\"$height\""
  } else {
    set size ""
  }

  if { $widget == "multiselect" && $height > 1 } {
    set multiple " multiple"
  } else {
    set multiple ""
  }

  set html "<[ad_form_widget_tag select $element $order]$size$multiple>\n"

  foreach option $option_list {

    set value [lindex $option 1]
    set label [lindex $option 0]

    if { [lsearch -exact $default_list $value] != -1 } {
      set selected " selected"
    } else {
      set selected ""
    }

    append html "<option$selected value=\"[util_quotehtml $value]\">$label\n"
  }

  append html "</select>\n"

  return $html
}

proc ad_form_widget_multiselect { element default_list option_list order } {

  return [ad_form_widget_select $element $default_list $option_list $order]
}

proc ad_form_widget_checkbox { element default_list option_list order } {

  return [ad_form_widget_button_group $element $default_list $option_list $order]
}

proc ad_form_widget_radio { element default_list option_list order } {

  return [ad_form_widget_button_group $element $default_list $option_list $order]
}

# Builds a group of checkbox elements based on metadata.  Each element 
# and element label is placed in an ns_set under the keys input and
# label for use with the <multiple> template tag.

proc ad_form_widget_button_group { element default_list option_list order } {

  ad_util_set_variables $element name widget 

  set group [list]

  foreach option $option_list {

    set value [lindex $option 1]
    set label [lindex $option 0]

    if { [lsearch -exact $default_list $value] != -1 } {
      set checked " checked"
    } else {
      set checked ""
    }

    set submeta [ns_set create]
    ns_set put $submeta label $label
    ns_set put $submeta markup "
      <[ad_form_widget_tag input $element $order]$checked type=\"$widget\" 
             value=\"[util_quotehtml $value]\">"
    lappend group $submeta
  }

  return $group
}

# Builds a date input element based on metadata.  The default is
# expected to be a date string in the form 'YYYY-MM-DD'.

proc ad_form_widget_date { element default_list option_list order } {

  ad_util_set_variables $element name

  set value [lindex $default_list 0]

  if { [string match $value {}] } { 

    set value [ad_util_today]
  }

  regexp {(....)-(..)-(..)} $value x year month day

  append input [ad_form_widget_month "$name.month" $month]

  append input [ad_form_widget_numericrange "$name.day" 1 31 $day]

  append input "<input name=\"$name.year\" 
                         size=5 maxlength=4 
                         value=\"$year\">"

  return $input
}

# Builds a date and time input element based on metadata.  The default is
# expected to be a date string in the form 'YYYY-MM-DD'.

proc ad_form_widget_datetime { element default_list option_list order } {

  ad_util_set_variables $element name
  set name "$name"

  set value [lindex $default_list 0]

  if { [string match $value {}] } { 
    set value [ad_util_today]
  }

  regexp {(....)-(..)-(..) (..):(..):(..)} $value x year month day hours minutes seconds

  append input [ad_form_widget_month "$name.month" $month]

  append input [ad_form_widget_numericrange "$name.day" 1 31 $day]

  append input "<input name=\"$name.year\" size=5 maxlength=4 
                         value=\"$year\"> &nbsp; "

  append input [ad_form_widget_numericrange "$name.hours" 0 23 $hours] ": "

  append input [ad_form_widget_numericrange "$name.minutes" 0 59 $minutes] ": "

  append input [ad_form_widget_numericrange "$name.seconds" 0 59 $seconds]

  return $input
}

# Builds a picklist of months of the year

proc ad_form_widget_month { name default } {

  set month_names {January February March April May June July August September October November December}

  regsub {^0} $default {} default

  set input "<select name=\"$name\">\n"

  for { set i 1 } { $i <= 12 } { incr i } {

    set month_name [lindex $month_names [expr $i - 1]]

    if { $i == $default } {
      set selected " selected"
    } else {
      set selected ""
    }

    append input "<option$selected value=$i>$month_name\n"
  }

  append input "</select>\n"

  return $input
}

# Combines date widgets into a date.

proc ad_form_transform_date { name } {
  
  set dates [list]

  set years [ad_util_queryget -none "$name.year"]
  set months [ad_util_queryget -none "$name.month"]
  set days [ad_util_queryget -none "$name.day"]

  for { set i 0 } { $i < [llength $years] } { incr i } { 

    set year [lindex $years $i]
    set month [lindex $months $i]
    set day [lindex $days $i]

    lappend dates "${year}-${month}-${day}"
  }

  return $dates
}

# Combines date widgets into a date.

proc ad_form_transform_datetime { name } {
  
  set dates [list]

  set years [ad_util_queryget -none "$name.year"]
  set months [ad_util_queryget -none "$name.month"]
  set days [ad_util_queryget -none "$name.day"]
  set hours [ad_util_queryget -none "$name.hours"]
  set minutes [ad_util_queryget -none "$name.minutes"]
  set seconds [ad_util_queryget -none "$name.seconds"]

  for { set i 0 } { $i < [llength $years] } { incr i } { 

    set year [lindex $years $i]
    set month [lindex $months $i]
    set day [lindex $days $i]
    set hours [lindex $hours $i]
    set minutes [lindex $minutes $i]
    set seconds [lindex $seconds $i]

    set date "${year}-${month}-${day} $hours:$minutes:$seconds"

    lappend dates "to_date('$date', 'YYYY:MM:DD HH24:MI:SS')"
  }

  return $dates
}

# Builds a time interval input (years, months, weeks) element based on
# metadata.

proc ad_form_widget_timespan { element default_list option_list order } {

  ad_util_set_variables $element name

  set value [lindex $default_list 0]

  if { [string match $value {}] } { 

    set days 0

  } else {

    set query "select sysdate - to_date('$value') from dual"
    set days [ad_dbquery onevalue $query]
  }

  set years [expr round(floor($days / 365))]
  set days [expr $days - ($years * 365)]

  set months [expr round(floor($days / 30.5))]
  set days [expr $days - ($months * 30.5)]

  set weeks [expr round($days / 7)]

  set input "
  [ad_form_widget_numericrange "Timespan.$name.years" 0 30 $years]
  Years &nbsp; 
  [ad_form_widget_numericrange "Timespan.$name.months" 0 11 $months]
  Months &nbsp;
  [ad_form_widget_numericrange "Timespan.$name.weeks" 0 16 $weeks]
  Weeks"

  return $input
}

# Combines date widgets into a date.

proc ad_form_transform_timespan { name } {

  set dates [list]

  set years [ad_util_queryget -none "Timespan.$name.years"]
  set months [ad_util_queryget -none "Timespan.$name.months"]
  set weeks [ad_util_queryget -none "Timespan.$name.weeks"]

  for { set i 0 } { $i < [llength $years] } { incr i } { 

    set y [lindex $years $i]
    set m [lindex $months $i]
    set w [lindex $weeks $i]

    set formula "($y * 365) + ($m * 30.5) + ($w * 7)"
    # work around bug in Tcl interpreter in handling double 00's
    regsub -all {\(0([0-9])} $formula {(\1} formula
    set days [expr $formula]
  
    set query "select sysdate - $days from dual"
    lappend dates [ad_dbquery onevalue $query]
  }

  return $dates
}

proc ad_form_widget_numericrange { name begin end { default "" } } {

  append input "<select name=\"$name\">\n"

  for { set i $begin } { $i <= $end } { incr i } {

    if { $i == $default } {
      set selected " selected"
    } else {
      set selected ""
    }

    append input "<option$selected>[format %02d $i]\n"
  }

  append input "</select>\n"

  return $input
}

