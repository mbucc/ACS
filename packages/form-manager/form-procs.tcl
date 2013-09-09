# /packages/form-manager/form-procs.tcl
ad_library {

  Form manager for the ArsDigita Publishing System.

  @author Karl Goldstein (karlg@arsdigita.com)
  @cvs-id form-procs.tcl,v 1.4.2.1 2000/07/18 22:06:40 seb Exp

}

# Copyright (C) 1999-2000 ArsDigita Corporation

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

# Checks for a recognizable form submission and attempts to process
# it.

proc ad_form_filter {} {

  set form_url [ns_queryget "form.src"]

  if { $form_url != "" } { ad_form submit $form_url }
}

# Master handler for form preparation and submission.

proc ad_form { action url } {

  set spec [ad_form_get_spec $url]

  if { $action == "prepare" } { 
    set spec [ad_form_prepare_substitute $spec]
  }

  set elements [ad_form_get_elements $spec]

  switch $action {

    prepare { ad_form_prepare $spec $elements }
    submit { ad_form_submit $spec $elements }
    default { error PUBLISH_FORM_INVALID_ACTION }
  }

  return $spec
}

# Retrieve a form spec from the cache.  A base form is specified by a
# url or name for form specs stored in the database.  The base form
# may optionally be extended.  Each extended form should also be
# stored in the cache.  Form specs are extended by executing the code
# specified in the "extend" element.  The extension code has two child
# elements, each of which should contain code: 1) code in the
# "identifier" child element should return a unique identifier for a
# particular extension of the base form, for the purpose of cache
# storage and retrieval.  2) code in the "prepare" child element can
# expect that the variable "spec" will be defined in its scope.  It
# should modify this spec file as necessary, after which it will be
# cached.  Typically this code will add form elements, but it may make
# other changes to the form spec as well as needed.

proc ad_form_get_spec { url } {

  set spec [ad_publish_get_spec $url status]

  if { $spec == ""} { 
    global errorSet
    ns_set put $errorSet form_url $url
    error PUBLISH_FORM_SPECIFICATION_NOT_FOUND
  }

  if { $status == "UPDATE" } {
    ad_form_template_prepare_layout $spec
  }

  ad_util_set_variables $spec extend substitute

  if { ! [empty_string_p $extend] } {
    ad_util_set_variables $extend identifier prepare
    set ext_id [eval $identifier]
    set full_id "$url:$ext_id"

    if { [nsv_exists fm_cache $full_id] } {
      set spec [nsv_get fm_cache $full_id]
    } else {
      set spec [ad_util_create_persistent_set -empty $spec]
      eval $prepare
      nsv_set fm_cache $full_id $spec
    }
  }

  return $spec
}
      
# Maps elements to columns of tables.  Assigns key columns to each
# table for select, update and delete statements.  Assigns a
# table order in which database operations should be performed,
# to avoid referential integrity problems when performing insert 
# and delete statements.
 
# NOTE that element names must be unique, although it is allowable to
# embed the same element multiple times in the same form

# the table map structure is:
# table_map
#         |
#         |
#         column_map (keyed by table name)
#                  |
#                  |
#                  columns (keyed by column name)
#                        |
#                        |
#                        elements (element list mapped to a column)

proc ad_form_map_tables { spec elements } {

  set column_map [ns_set create]
  set key_map [ns_set create]
  set variable_columns [list]
  set blob_columns [list]
  set clob_columns [list]
  set parent [list]
  set child [list]
  
  foreach element $elements  {

    set element_name [ns_set get $element name]

    foreach datamap [ad_util_get_values $element datamap] {
  
      ad_util_set_variables $datamap key table column count type
      ad_form_map_tables_one
    }

    # dynamic table assignment is also an option

#    foreach datamap [ad_util_queryget -none $element_name.datamap] {
  
#      ad_util_list_variables [split $datamap "."] table column key count
#      ad_form_map_tables_one
#    }
   }

  set table_map [ns_set create]

  ns_set put $table_map column_map $column_map
  ns_set put $table_map key_map $key_map

  set table_order [ad_util_unique_list [concat $parent $child]]

  # append rows with no labeled key

  ns_set put $table_map table_order $table_order
  ns_set put $table_map variable_columns $variable_columns
  ns_set put $table_map blob_columns $blob_columns
  ns_set put $table_map clob_columns $clob_columns

  return $table_map
}

proc ad_form_map_tables_one {} {

  uplevel {

    if { [string match $column {}] } { set column $element_name }
    
    # retrieve the columns for a table

    set columns [ns_set get $column_map $table]

    if { $columns == ""} { 
      set columns [ns_set create]
      ns_set put $column_map $table $columns
    }

    # add to the list of elements that map to that column

    set element_list [ns_set get $columns $column]
    lappend element_list $element   
    ns_set update $columns $column $element_list

    # if it is a key then add to the list of key columns for that table

    if { ! [string match $key {} ] } {      

      set key_list [ns_set get $key_map $table]
      lappend key_list $column
      ns_set update $key_map $table $key_list

      lappend $key $table
    }

    # keep a master list of tables to catch tables that do not have a key

    set all_tables($table) 1

    # keep a list of columns that allow a variable number of values

    if { $count == "variable" } { 
      lappend variable_columns "$table.$column" 
    }
    if { $type != "" } { 
      lappend ${type}_columns "$table.$column" 
    }
  }
}

# Get a list of elements for a form, including those referenced
# in another form specification

proc ad_form_get_elements { spec } {

  set src [ad_xml_get_node $spec elements src]

  if { [string match $src {}] } {

    set elements [list]
  
    foreach element [ad_xml_get_nodes $spec elements element] {

      ad_util_set_variables $element src name

      if { ! [string match $src {}] && ! [string match $name {}] } {
      
        set src [ad_util_absolute_url $src [ns_set get $spec url]]
        set externals [ad_form_get_element $src [split $name ","]]
        set elements [concat $elements $externals]

      } else {
 
        lappend elements $element
      }
    }
  } else {

    set src [ad_util_absolute_url $src [ns_set get $spec url]]
    set spec [ad_form_get_spec $src]
    set elements [ad_form_get_elements $spec]
  }

  return $elements
}

# Look up a single form element (or a list of form elements) in a form spec

proc ad_form_get_element { src name } {

  set spec [ad_form_get_spec $src]

  if { $spec == "" } {
    error "The named form specification $src was not found"
  }

  set elements [list]
  set element_names [list]

  foreach element [ad_xml_get_nodes $spec elements element] {

    set this_name [ns_set get $element name]
    if { [lsearch -exact $name $this_name] > -1 } {

      if { [ns_set find $element src] > -1 } {
        error "Recursive form element references to element $this_name not allowed"
      }

      lappend elements $element
      lappend element_names $this_name
    }
  }

  if { [llength $elements] != [llength $name] } {
    error "Elements $name not all found in $src ($element_names found)"
  }

  return $elements
}

proc ad_form_set_variables { args } {

  foreach var $args {
    upvar $var $var
    set value [ns_queryget $var]
    check_for_form_variable_naughtiness $var $value
    set $var $value
  }
}

nsv_set fm_cache "" ""
