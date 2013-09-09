# /packages/form-manager/process-procs.tcl
ad_library {

  Form submission processing procedures for the form manager
  component of the ArsDigita Publishing System.

  @author Karl Goldstein (karlg@arsdigita.com)
  @cvs-id process-procs.tcl,v 1.3.2.2 2000/07/18 22:06:41 seb Exp

}

# Copyright (C) 1999-2000 ArsDigita Corporation

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

# Master procedure for form submission.

proc ad_form_submit { spec elements } {

  ns_log Notice "Processing form submission"

  global errorMessages
  set errorMessages [ns_set create]

  ad_form_process_pre $spec

  # Build a value map for each form submission in a multikey update

  set count [ns_queryget "form.count"]

  if { [string match $count {}] } {

    set submission [ad_form_process_elements $spec $elements]

  } else {

    if { $count > 128 } { error "Key count exceeds maximum allowed" }

    for { set i 1 } { $i <= $count } { incr i } {
      lappend submissions [ad_form_process_elements $spec $elements ".$i"]
    }
  }

  ad_util_set_variables $spec dbaction validate

  if { [ns_set size $errorMessages] > 0 } { 

    ns_log Notice [ad_util_get_values $errorMessages]

    # Option 1: a separate error page

    if { ! [string match $validate "same"] } {

      set errorMessages [ad_util_get_values $errorMessages]
      error PUBLISH_FORM_VALIDATION_FAILED
    }

    # Option 2: return to the same page

    ad_util_set_global_variables "form.error." $errorMessages
    set errorMessages [ad_util_get_values $errorMessages]

    return

  } else {

    ns_set put [ns_getform] "form.valid" "t"
  }

  if { ! [string match $dbaction {}] } { 

    global errorMessages
    set errorMessages [list]

#    set db [ns_db gethandle]

    db_with_handle db {

      ns_db dml $db "begin transaction"

      set table_map [ad_form_map_tables $spec $elements]

      if { [string match $count {}] } {

	set data_map [ad_form_process_values $table_map $submission]
	ad_form_process_transaction $dbaction $table_map $data_map $db

      } else {

	upvar #0 _FORM_SUBMISSION_SUFFIX suffix

	for { set i 1 } { $i <= $count } { incr i } {

	  set submission [lindex $submissions [expr $i - 1]]
	  set data_map [ad_form_process_values $table_map $submission]

	  set suffix ".$i"
	  ad_form_process_transaction $dbaction $table_map $data_map $db
	}
      }

      ns_db dml $db "end transaction"
    }

#    ns_db releasehandle $db
  }

  ad_form_process_post $spec

  # If there was a dbaction then assume that is time to move on
  # (note this will cause an infinite loop for non-dbaction forms
  # with same-form validation)

  if { ! [string match $dbaction {}] } { 

    ad_form_process_redirect $spec
  }
}

proc ad_form_process_elements { spec elements { suffix "" } } {

  set values [ns_set create]
  global errorMessages

  foreach element $elements {

    ad_util_set_variables $element name widget defaults status label

    if { $widget == "none" } {

      set element_values [ad_form_prepare_element_defaults $name $defaults]

    } else {

      set transproc "ad_form_transform_$widget"

      if { [info procs $transproc] != "" } {
	set element_values [$transproc $name$suffix]
      } else {
	set element_values [ad_util_queryget "$name$suffix"]
      }
    }

    if { $status == "required" && [string match $element_values {{}}] } {

      ns_set put $errorMessages $name$suffix "Required field $label is empty"
      continue
    }

    set element_values [ad_form_process_validate \
                          $element $element_values $suffix]
     
    ns_set put $values $name $element_values
  }

  return $values
}

proc ad_form_process_validate { element values { suffix "" } } {

  global errorMessages

  ad_util_set_variables $element name datatype validate

  if { ! [string match $validate {}] } {
    ad_util_set_variables $validate condition message
  }

  set valid_values [list]

  foreach value $values {

    if { ! [string match $validate {}] } {

      if { [catch { set valid_p [eval $condition] } errMsg] } {
        global errorMessage
        ns_log Notice $errMsg
        set errorMessage $errMsg
        set errorMessages $errMsg
	error PUBLISH_FORM_CUSTOM_VALIDATION_ERROR
      }

      if { ! $valid_p } {
	ns_set put $errorMessages $name$suffix [subst $message]
	continue
      }
    }

    if { ! [ad_form_validate $datatype value message] } {
      ns_set put $errorMessages$suffix $name $message
    }

    lappend valid_values $value
  }

  return $valid_values
}

# Collects the values for each column of each table.  If a column
# is marked as not unique than a variable number of values may be
# submitted (including zero), so a null value should not be assumed.

proc ad_form_process_values { table_map values } {

  set data_map [ns_set create]

  ad_util_set_variables $table_map column_map variable_columns

  foreach table [ad_util_get_keys $column_map] {

    set columns [ns_set get $column_map $table]

    set table_values [ns_set create]
    ns_set put $data_map $table $table_values

    foreach column [ad_util_get_keys $columns] {

      set value_list [list]

      foreach element [ns_set get $columns $column] {

        ad_util_set_variables $element name
        
        set element_values [ns_set get $values $name]

	# Do not append a null list from an element
	if { [string match $element_values {{}}] } { continue }

        set value_list [concat $value_list $element_values]
      }

      # Check for null submissions for variable count columns

      if { [lsearch -exact $variable_columns "$table.$column"] != -1 } {

        if { [ad_util_empty_list $value_list] } {
          set value_list [list]
        }
      } elseif { [llength $value_list] == 0 } {

	set value_list [list ""]
      }

      ns_set update $table_values $column $value_list
    }
  }

  return $data_map
}

# Performs the database operations once the form data has been
# compiled and validated.

proc ad_form_process_transaction { dbaction table_map data_map db } {

  ad_util_set_variables $table_map table_order column_map

  if { $dbaction == "delete" } { 
    set table_order [ad_util_reverse_list $table_order]
  }

  foreach table $table_order {

    set table_values [ns_set get $data_map $table]

    set rows [ad_form_process_rows $table_values]

    ad_form_process_${dbaction} $table_map $db $table $rows
  }
}

# Determines the values of each row that will be inserted or
# updated in a table.

proc ad_form_process_rows { table_values } {

  set max 0
  set columns [ad_util_get_keys $table_values]
    
  # First pass: figure out the maximum number of values

  foreach column $columns {

    set val($column) [ns_set get $table_values $column]
    set len($column) [llength $val($column)]

    # If there are no values for a column than cannot build any rows

    if { $len($column) == 0 } { return [list] }

    if { $len($column) > $max } { 
      set max $len($column) 
    }
  }

  # Second pass: create max number of rows, filling in values with
  # the last entry where the number values is less than the max

  set rows [list]

  for { set i 0 } { $i < $max } { incr i } { 

    set row [list]

    foreach column $columns {

      set last [expr $len($column) - 1]

      if { $i <= $last } {
        set value [lindex $val($column) $i]
      } else { 
        set value [lindex $val($column) $last]
      }

      lappend row $value
    }

    lappend rows $row
  }

  return $rows
}

proc ad_form_process_insert { table_map db table rows } {

  global errorMessages

  ad_util_set_variables $table_map column_map blob_columns clob_columns
  set columns [ns_set get $column_map $table]
  set colnames [ad_util_get_keys $columns]

  foreach row $rows {

    if { [catch { 
      ad_dbinsert $db $table $colnames $row $blob_columns $clob_columns 
    } errmsg] } {

      set constraint_columns [ad_dbinsert_error $errmsg $db]

      foreach col $constraint_columns {

	lappend errorMessages \
	    "Database column $col in table $table was duplicated."
      }

      error PUBLISH_FORM_DUPLICATE_SUBMISSION
    }
  }
}

proc_doc ad_form_process_update { table_map db table rows } "

  Assess the need for a multirow update:
  (1) Count the number of rows under the specified key(s)
  (2) If there is one row in the table and one row to insert,
      perform a single-row update.
  (3) If there are zero or multiple rows, perform a
      multiple-row update (delete/insert sequence).

" {

  
  set where [ad_form_process_whereclause $table_map $table]

  set rowcount [ad_form_process_rowcount $db $table $where]

  if { $rowcount == 1 && [llength $rows] == 1 } {
   
    set row [lindex $rows 0]
    ad_form_process_update_onerow $table_map $db $table $row $where

  } else {

#    if { $rowcount > 0 } {
      ad_form_process_delete_exec $db $table $where
#    }
    ad_form_process_insert $table_map $db $table $rows

  }
}

proc_doc ad_form_process_delete { table_map db table rows } "

  Deletes rows from the table under the specified key(s).

" {

  set where [ad_form_process_whereclause $table_map $table]

  ad_form_process_delete_exec $db $table $where
}

proc_doc ad_form_process_update_onerow { table_map db table row where } "

" {

  ad_util_set_variables $table_map column_map blob_columns clob_columns
  set columns [ns_set get $column_map $table]
  set colnames [ad_util_get_keys $columns]

  ad_dbupdate $db $table $colnames $row $where $blob_columns $clob_columns 
}  

proc_doc ad_form_process_rowcount { db table where } "

  Gets the number of rows in a particular table for the specified keys.

" {
  
  set query "
    select 
      count(*)
    from 
      $table 
    where $where"

  set row_count [ad_dbquery onevalue $query]

  ns_log Notice "COUNT: $row_count\n$query"

  return $row_count
}

proc_doc ad_form_process_delete_exec { db table where } "

  Deletes rows from the table having the specified keys.

" {
  
  set statement "
    delete from 
      $table 
    where $where"

  ns_db dml $db $statement
}

proc_doc ad_form_process_whereclause { table_map table } "

  Builds a where clause for a select or delete of the rows
  in the table with the specified keys.

" {

  # Check for a suffix offset for multiple-submission forms
  upvar #0 _FORM_SUBMISSION_SUFFIX suffix
  if { ! [info exists suffix] } { set suffix "" }

  ad_util_set_variables $table_map key_map column_map

  set key_list [ns_set get $key_map $table]
  set columns [ns_set get $column_map $table]

  set keyvalues [list]

  foreach column $key_list {

    set element [ns_set get $columns $column]
    ad_util_set_variables $element name defaults widget

    set value [ns_queryget $name$suffix] 

    if { [empty_string_p $value] || $widget == "none" } {

      set defaults [ad_form_prepare_element_defaults $name $defaults]
      set value [lindex $defaults 0]
    }

    if { [string match $value {} ] } {    

      ns_log Notice "NULL KEY for $column"
      error PUBLISH_FORM_NULL_KEY
    }

    lappend keyvalues "$column = [ns_dbquotevalue $value]"
  }

  return [join $keyvalues " and "]
}

# Executes any specified pre-processing

proc ad_form_process_pre { spec } {

  foreach step [ad_util_get_values $spec preprocess] {

    set code [ns_set get $step code]
    eval $code
  }
}

# Executes any specified post-processing

proc ad_form_process_post { spec } {

  foreach step [ad_util_get_values $spec postprocess] {

    set code [ns_set get $step code]
    eval $code    
  }
}

# Redirects to the specified URL if a query parameter is not null

proc ad_form_process_conditional_redirect { url args } {

  set url [ad_util_absolute_url $url [ns_conn url]]

  set params [list]

  foreach param $args {
    set value [ns_queryget $param]
    if { [empty_string_p $value] } { return }
    lappend params "$param=[ns_urlencode $value]"
  }

  global errorURL
  set errorURL "$url?[join $params "&"]"
  error REDIRECT
}

# Redirects to the action url specified in the spec file.  Looks for
# parameters in the target data file that should be passed in.

proc ad_form_process_redirect { spec } {

  ad_util_set_variables $spec action url

  if { [string index $action 0] != "/" } {

    set dir [file dirname [ns_url2file $url]]
    set path "$dir/$action"
    regsub [ns_info pageroot] $path {} action
  }

  regsub {\.adp$} $action {.data} spec_url
  set spec [ad_publish_get_spec $spec_url status]

  if { $spec != "" } {

    set params [list]

    foreach datasource [ad_template_get_datasources $spec] {

      ad_util_set_variables $datasource type name
      
      if { $type == "param" } {
	lappend params "$name=[ns_urlencode [ns_queryget $name]]"
      }
    }

    if { [llength $params] > 0 } { append action "?[join $params "&"]" }
  }
    

  global errorURL
  set errorURL $action
  ns_log Notice "Redirecting to $action"

  error REDIRECT
}
