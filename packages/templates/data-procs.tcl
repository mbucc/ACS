# /packages/templates/data-procs.tcl
ad_library {

  Data source preparation procedures for the ArsDigita Publishing System.

  @author Karl Goldstein (karlg@arsdigita.com)
  @cvs-id data-procs.tcl,v 1.2.2.2 2000/07/23 22:36:34 seb Exp

}

# Copyright (C) 1999-2000 ArsDigita Corporation

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

proc ad_template_get_all_data { spec } {

  set name [ns_set get $spec name]

  foreach datasource [ad_template_get_datasources $spec] {

    if { [ns_set name $datasource] == "datasource" } {
      ad_template_get_data $name $datasource
    } else {
      ad_template_status_check $name $datasource
    }
  }

  # release handles before doing the expensive ADP parsing.

  db_release_unused_handles
}

# Execute code which may throw an exception to terminate
# datasource processing

proc ad_template_status_check { template_name statuscheck } {

  upvar #0 _EVALCODE code

  ad_util_set_variables $statuscheck code name

  eval "uplevel #0 { 
    eval \$_EVALCODE
  }" 
}

proc ad_template_get_data { template_name datasource } {

  ad_util_set_variables $datasource name type structure depends

  foreach dependency $depends {

    upvar #0 $dependency x

    if { ! [info exists x] } {
      return
    }
  }

  # ns_log Notice "Processing data source $name in $template_name"

  switch $type {

    eval       { ad_template_get_data_eval $template_name $datasource }
    param      { ad_template_get_data_param $template_name $datasource }
    static     { ad_template_get_data_static $template_name $datasource }
    query      { ad_template_get_data_query $template_name $datasource }

  }

  eval "uplevel #0 { set $name.structure $structure }"
}

# Presents text contained within the data source itself.  For onevalue
# data sources, condition is a simple string.  For onerow data
# sources, condition is expected to contain a single XML element,
# corresponding to a single ns_set.  For multirow data sources,
# condition is expected to be a list of XML elements.

proc ad_template_get_data_static { template_name datasource } {

  ad_util_set_variables $datasource name condition structure

  set varname "$template_name.$name"

  switch $structure {

    onevalue {
      
      eval "
        uplevel #0 {
          set $varname \"$condition\"
          set $name \"$condition\"
        }
      "
    }

    onerow {

      ad_util_set_global_variables "$varname." $condition
      ad_util_set_global_variables "$name." $condition
    }

    multirow {

      upvar #0 $varname vardata
      upvar #0 $name data

      set data [ad_util_get_values $condition]
      set vardata $data

      ad_template_set_row_count $template_name $datasource
    }
  }
}

proc ad_template_get_data_eval { template_name datasource } {

  upvar #0 _EVALCONDITION condition

  ad_util_set_variables $datasource name condition structure

  set varname "$template_name.$name"

  global errMsg

  if [catch { 

    eval "uplevel #0 { 
      set $varname \[eval \$_EVALCONDITION \] 
      set $name \[set $varname\]
    }" 

  } errMsg] {

    global errorInfo
    error PUBLISH_DATASOURCE_EVAL_ERROR $errorInfo
  }

  if {$structure == "onerow"} {

    upvar #0 $name data

    ad_util_set_global_variables "$varname." $data
    ad_util_set_global_variables "$name." $data
  }

  if {$structure == "multirow"} {

    ad_template_set_row_count $template_name $datasource
  }
}
 
proc ad_template_get_data_param { template_name datasource } {

  ad_util_set_variables $datasource name status condition datatype structure

  set varname "$template_name.$name"

  upvar #0 $name var
  if { [info exists var] } { return }

  set values [ad_util_queryget -none $name]

  foreach value $values {
    ad_template_get_data_param_validate $name $value $datatype
  }	

  if { $structure != "onelist" } {
    set values [lindex $values 0]
  }

  eval "
    uplevel #0 {      
      set $name \{$values\}
      set $varname \{$values\}
    }
  "

  # handle missing parameters

  if { [empty_string_p $values] } {

    # if the parameter is required than complain

    if { $status != "optional" } {

      global errorSet
      ns_set put $errorSet param $name

      error PUBLISH_DATASOURCE_PARAM_MISSING

    } elseif { ! [string match $condition {}] } {

      # if the parameter is optional than eval the condition to get a
      # default value

      ad_template_get_data_eval $template_name $datasource
    }
  }
}

proc ad_template_get_data_param_validate { name value datatype } {

  if { ! [ad_form_validate $datatype value msg] } {

    global errorSet
    ns_set put $errorSet param $name

    error PUBLISH_DATASOURCE_PARAM_INVALID
  }
}

proc ad_template_get_data_query { template_name datasource } {

  ad_util_set_variables $datasource name structure

  switch $structure {
    onevalue   { ad_template_get_data_onevalue $template_name $datasource } 
    onelist    { ad_template_get_data_onelist $template_name $datasource } 
    onerow     { ad_template_get_data_onerow $template_name $datasource }
    multirow   { ad_template_get_data_multirow $template_name $datasource }
  }
}

proc ad_template_get_data_onevalue { template_name datasource } {

  ad_template_get_data_query_exec $template_name $datasource
}

proc ad_template_get_data_onelist { template_name datasource } {

  ad_template_get_data_query_exec $template_name $datasource
  ad_template_set_row_count $template_name $datasource
}

proc ad_template_get_data_onerow { template_name datasource } {

  ad_template_get_data_query_exec $template_name $datasource

  ad_util_set_variables $datasource name noprefix

  upvar #0 $name data

  if { $noprefix == "t" } { 
    ad_util_set_global_variables "" $data
  } else {
    ad_util_set_global_variables "$name." $data
    ad_util_set_global_variables "$template_name.$name." $data
  }
}

proc ad_template_get_data_multirow { template_name datasource } {

  ad_template_get_data_query_exec $template_name $datasource
  ad_template_set_row_count $template_name $datasource
}

proc ad_template_get_data_query_exec { template_name datasource } {

  ad_util_set_variables $datasource name structure condition maxrows startrow

  set varname "$template_name.$name"

  global errMsg

  if [string match {} $condition] { error TEMPLATE_DATASOURCE_QUERY_MISSING }

  if [catch { 

    eval "

      uplevel #0 {

        set $varname \[ad_dbquery $structure \[subst \"$condition\"\] {} \\
                         \[subst $maxrows\] \[subst $startrow\]\] 
        set $name \[set $varname\]
      }
    "

  } errMsg] {

    ns_log Notice "$errMsg: $condition"
    error PUBLISH_DATASOURCE_QUERY_ERROR $name
  }
}

proc ad_template_set_row_count { template_name datasource } {

  ad_util_set_variables $datasource name
  set varname "$template_name.$name"

  eval "

    uplevel #0 {

      set \"$varname.rowcount\" \[llength \[set $varname\]\]
      set \"$name.rowcount\" \[set \"$varname.rowcount\"]
    }
  "
}
