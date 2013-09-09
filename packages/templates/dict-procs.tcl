# /packages/templates/dict-procs.tcl
ad_library {

  Documentation procedures for the ArsDigita Publishing System.

  @author Karl Goldstein (karlg@arsdigita.com)
  @cvs-id dict-procs.tcl,v 1.2.2.1 2000/07/18 21:53:27 seb Exp

}

# Copyright (C) 1999-2000 ArsDigita Corporation

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

proc ad_template_dictionary_filter { why } {

  set url [ns_conn url]

  if [catch {

    ad_template_prepare_dictionary $url
    ad_publish_system_message PUBLISH_DICTIONARY
  
  } errCode] {

    ns_log Notice "Error preparing template dictionary: $errCode"
    ad_publish_error_message $errCode
  }

  return "filter_return"
}

# Prepares a data structure according to the definitions stored in
# /templates/define on the the server. Suitable for use by the
# template system for generating a data dictionary.  Collapses lists
# where only a single value is expected.

proc ad_template_prepare_dictionary { url } {

  set spec [ad_publish_get_spec $url status]

  if { $spec == "" } {

    error PUBLISH_SPECIFICATION_NOT_FOUND
  }

  upvar #0 spec.name name spec.title title spec.comment comment
  ad_util_set_variables $spec name title comment

  upvar #0 spec.dict dict
  set dict [list]

  foreach datasource [ad_template_get_datasources $spec] {

    lappend dict [ad_template_dictionary_prepare_datasource $name $datasource]
  }
}

proc ad_template_dictionary_prepare_datasource { template_name datasource } {

  set entry [ns_set create]

  ad_util_set_variables $datasource name structure comment type
  if { $type == "param" } { set structure "onevalue" }

  foreach property [list name structure comment type] {
    ns_set put $entry $property [set $property]
  }

  set datasource_name $name

  set variables [list] 

  set variable [ad_util_get_values $datasource variable]

  if { [llength $variable] == 0  && $structure == "onevalue" } {

    set variable [ns_set create]
    lappend variables $variable
    ns_set put $variable name "$template_name.$name"
    ns_set put $variable comment $comment

  } else {

    foreach var $variable {

      ad_util_set_variables $var name comment

      set variable [ns_set create]
      lappend variables $variable

      ns_set put $variable name "$template_name.$datasource_name.$name"
      ns_set put $variable comment $comment
    }    
  }

  ns_set put $entry variables $variables

  return $entry
}

