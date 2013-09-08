# /packages/form-manager/validate-procs.tcl
ad_library {

  Validation procedures for form manager component of the ArsDigita
  Publishing System.

  @author Karl Goldstein (karlg@arsdigita.com)
  @cvs-id validate-procs.tcl,v 1.2.2.1 2000/07/18 22:06:41 seb Exp

}

# Copyright (C) 1999-2000 ArsDigita Corporation

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

# Check if a value already exists for values that must be unique

proc ad_form_validate_unique { table columns values { db "" } } {

  set query "select count(*) from $table where "

  for { set i 0 } { $i < [llength $columns] } { incr i } {
   
    set value [ns_dbquotevalue [lindex $values $i]]
    lappend conditions "[lindex $columns $i] = $value"
  }

  append query [join $conditions " and "]

  set count [ad_dbquery onevalue $query $db]

  if { $count == 0 } {
    return 1
  } else {
    return 0
  }
}

# Per data type validation procedures

proc ad_form_validate { type valuevar msgvar } {

  upvar $msgvar msg $valuevar value
  set msg ""

  return [ad_form_validate_$type value msg]
}

proc ad_form_validate_email { valuevar msgvar } {

  upvar $valuevar value

  set value [string trim $value]

  if { [regexp {[;:/,]} $value] || ! [regexp {.+@.+\..+} $value] } {

    upvar $msgvar msg
    set msg "The email $value is not valid."
    return 0
  }

  return 1
}

proc_doc ad_form_validate_zip { valuevar msgvar } "

" {

  upvar $valuevar value

  if { [ad_zip_exists $value] == 0 } {

    upvar $msgvar msg
  }

  return 1
}

proc_doc ad_form_validate_password { valuevar msgvar } "

  Checks for two form elements named password_var and
  password_var.confirm.
  Returns 1 if passwords exist and match.  Otherwise returns 0 and 
  appends a specific message to messages.

" {

  return 1
} 

proc_doc ad_form_validate_newpassword { valuevar msgvar } "

  Checks for two form elements named password_var and
  password_var.confirm.
  Returns 1 if passwords exist and match.  Otherwise returns 0 and 
  appends a specific message to messages.

" {

  return 1
} 

proc_doc ad_form_validate_text { valuevar msgvar } "

  Returns 1 if input variable exists and is not empty.  Otherwise
  returns 0 and appends a message to messages.

" {

  return 1
} 

proc_doc ad_form_validate_keyword { valuevar msgvar } "

" {

  upvar $valuevar value

  set value [string trim $value]

  if { [regexp {[^a-zA-Z0-9_]} $value] } {

    upvar $msgvar msg
    set msg "The keyword $value is not valid."
    return 0
  }

  return 1
} 

proc_doc ad_form_validate_url { valuevar msgvar } "

" {

  upvar $valuevar value

  set value [string trim $value]

  set expr "^(https?:/)?(\[-a-zA-Z0-9_%+?&.;:@=\$,/!*'()])+\$"

  if { ! [regexp $expr $value] } {

    upvar $msgvar msg
    set msg "The url <b>$value</b> is not valid."
    return 0
  }
 
  return 1
} 

proc_doc ad_form_validate_number { valuevar msgvar } "

" {

  upvar $valuevar value

  if { [regexp {[^0-9.]} $value] } {

    upvar $msgvar msg
    set msg "The number $value is not valid."
    return 0
  }

  return 1
} 

proc_doc ad_form_validate_phone { valuevar msgvar } "

" {

  return 1
} 

proc_doc ad_form_validate_date { valuevar msgvar } "

" {

  return 1
}

proc_doc ad_form_validate_datetime { valuevar msgvar } "

" {

  return 1
}

proc_doc ad_form_validate_timespan { valuevar msgvar } "

" {

  return 1
}

proc_doc ad_form_validate_weight { valuevar msgvar } "

" {

  return 1
}

proc_doc ad_form_validate_timestamp { valuevar msgvar } "

" {

  return 1
}

proc_doc ad_form_validate_creditcard { valuevar msgvar } "

  Code modified from http://www.hav.com/valCC/nph-src.htm?valCC.nws

" {

  upvar $valuevar value

  regsub -all { } $value {} entered_number
  set num [split $entered_number {}]
  set numLen [llength $num]       
  set type [_ad_form_validate_creditcard_type $entered_number]
    
  if {$type == "-unknown-"} { return 0 }

  set sum 0

  if {[catch {  
	for {set i [expr $numLen - 1]} {$i >= 0} {} {
          incr sum [lindex $num $i]
	  if {[incr i -1] >= 0} {
	    foreach adigit  [split [expr 2 * [lindex $num $i]] {}] {
              incr sum $adigit
            }
            incr i -1
	  }
	}
    } ] !=  0} {
    return 0
  }

  set lsum [split $sum {}]
  if {[lindex $lsum [expr [llength $lsum] - 1]]} { return 0 }

  return 1
}
 
proc_doc _ad_form_validate_creditcard_type { valuevar } "

  Returns the credit card type based on the first few digits of
  the number.

" {

  switch -glob [string range $value 0 3] {

  "51??" -  "52??" -  "53??" -  "54??" -  "55??" 
    {if {$numLen == 16} {set type "MasterCard"}}
  "4???" 
    {if {$numLen == 13 || $numLen == 16} {set type "VISA"}}
  "34??" -  "37??"
    {if {$numLen == 15}  {set type "American Express"}}
  "300?" -  "301?" -  "302?" -  "303?" - "304?" - "305?" -  "36??" -   "38??" 
    {if {$numLen == 14} {set type "Diner&#39s Club / Carte Blanche"}}
  "6011" 
    {if {$numLen == 16} {set type "Discover"}}
  "2014" -  "2149" 
    {if {$numLen == 15} {set type "enRoute"}; return 1}
  "3???" 
    {if {$numLen == 16} {set type "JCB"}}
  "2131" -  "1800"
    {if {$numLen == 15} {set type "JCB"}}
  default
    {set type "-unknown-"}
  }

  return $type
}

