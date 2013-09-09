# /packages/templates/database-util-procs.tcl
ad_library {

  Utilities for processing database queries.

  @author Karl Goldstein (karlg@arsdigita.com)
  @cvs-id database-util-procs.tcl,v 1.2.2.2 2000/07/18 21:53:27 seb Exp

}

# Copyright (C) 1999-2000 ArsDigita Corporation

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

proc_doc ad_db_exec { command {db ""}  } "

  Performs a database command

  If a database handle is not specified, attempts to grab
  the subquery handle to perform the query, after which
  it is released.

" {

#  if { $db == "" } {
#    set mydb [ns_db gethandle subquery]
#  } else {
#    set mydb $db
#  }

  db_with_handle mydb {
    ns_db dml $mydb $command
  }

#  if { $db == "" } {
#    ns_db releasehandle $mydb
#  }
}

proc_doc ad_dbquery { type query {db ""} {maxrows {10000}} {startrow {1}} } "

  Performs a database query.  Type may be one of:

  onevalue - returns a single value
  onerow - returns a single ns_set
  multirow - returns a list of ns_sets
  onelist - returns a single list
  multilist - returns a list of lists

  If a database handle is not specified, attempts to grab
  the subquery handle to perform the query, after which
  it is released.

" {

#  if { $db == "" } {
#    set mydb [ns_db gethandle subquery]
#  } else {
#    set mydb $db
#  }

  switch $type {

    onevalue   -
    onerow     -
    multirow   -
    onelist    -
    multilist  { 

       set error_p [catch {
         db_with_handle mydb {
           set result [ad_dbquery_$type $query $mydb $maxrows $startrow] 
         }
       } errMsg]

    }
    default    { error "Invalid query type $type" }
  }

#  if { $db == "" } {
#    ns_db releasehandle $mydb
#  }

  if { $error_p } {
    global errorInfo
    error $errMsg $errorInfo
  }

  return $result
}  
   
proc_doc ad_dbquery_onevalue { query db args } "

  Returns the value of a one-row by one-column query result.

" {

  set selection [ns_db 0or1row $db $query]

  if { $selection == "" } { return "" }

  return [ns_set value $selection 0]
}

proc_doc ad_dbquery_onerow { query db args } "

  Returns a one-row query result as a single ns_set.

" {

  set selection [ns_db 0or1row $db $query]

  return $selection
}

proc_doc ad_dbquery_multirow { query db {maxrows {10000}} {startrow {1}} } "

  Returns a query result as a list of ns_sets.  A maximum
  number of rows can be specified to limit
  the size of the result list.

" {

  set selection [ns_db select $db $query]
  set selections [list]

  set rowcount 0
  set skiprow 1

  while { [ns_db getrow $db $selection] } {

    if { $skiprow < $startrow } {
      incr skiprow
      continue
    } 

    if { $rowcount >= $maxrows } {

      ns_db flush $db
      break
    }

    lappend selections [ns_set copy $selection]
    incr rowcount
  }

  return $selections
}

proc_doc ad_dbquery_onelist { query db args } "

  Returns a single-column query result as a list.

" {

  set selection [ns_db select $db $query]

  set values [list]

  while {[ns_db getrow $db $selection]} {

    lappend values [ns_set value $selection 0]
  }

  return $values
}

proc_doc ad_dbquery_multilist { query db args } "

  Returns a n-column by m-row query result as a list of m lists, each
  with n values.

" {

  set selection [ns_db select $db $query]
  set values [list]

  while {[ns_db getrow $db $selection]} {

    lappend values [ad_util_get_values $selection]
  }

  return $values
}

proc_doc ad_dbinsert { db table columns values blobs clobs } "

  Formats and executes an insert DML statement.  If blobs or clobs are
  specified,
  generates an insert statement using one of the ns_ora procedures.
  The number of columns must match the number of values.

" {

  set stmt "insert into $table ([join $columns ","]) values ("

  set len [llength $columns]
  set dml_values [list]

  for { set i 0 } { $i < $len } { incr i } {

    set column [lindex $columns $i]
    set value [lindex $values $i]

    if { [lsearch -exact $blobs "$table.$column"] != -1 } {

      set cmd blob
      lappend dml_values "empty_blob()"
      set lob_value $value
      set lob_column $column

    } elseif { [lsearch -exact $clobs "$table.$column"] != -1 } {

      set cmd clob
      lappend dml_values "empty_clob()"
      set lob_value $value
      set lob_column $column

    } else {
      lappend dml_values [ad_dbquotevalue $value]
    }
  }

  append stmt [join $dml_values ", "] ") "

  if { ! [info exists cmd] } { 
    ns_db dml $db $stmt
  } else {
    ns_ora ${cmd}_dml $db "$stmt returning $lob_column into :1" $lob_value
  }
}

proc_doc ad_dbinsert_error { errmsg db } "

  Analyzes the error message from a failed insert for unique
  constraint or not null violations.

" {

  set pattern {ORA-00001: unique constraint \(.+\.(.+)\) violated}

  if { [regexp $pattern $errmsg x constraint] == 1 } {
    return [ad_db_get_constraint_columns $constraint $db]
  }

  set pattern \
    {ORA-01400: cannot insert NULL into \("(.+)"."(.+)"."(.+)"\).+SQL}

  if { [regexp $pattern $errmsg x space table column] == 1 } {

    global errorSet

    ns_set put $errorSet column $column
    ns_set put $errorSet table $table

    error PUBLISH_FORM_NULL_INSERTION
  }

  global errorInfo
  error $errmsg $errorInfo
}

proc_doc ad_db_get_constraint_columns { constraint { db "" } } "

  Returns a list of column names associated with a constraint.

" {

  set query "
    select
      column_name
    from
      user_cons_columns
    where
      constraint_name = '$constraint'
  "
  set columns [ad_dbquery onelist $query $db]

  return $columns
}

proc_doc ad_dbupdate { db table columns values where blobs clobs } "

  Formats and executes an update DML statement.  If blobs or clobs are
  specified,
  generates an insert statement using one of the ns_ora procedures.
  The number of columns must match the number of values.

" {

  set len [llength $columns]
  set dml_values [list]

  for { set i 0 } { $i < $len } { incr i } {

    set column [lindex $columns $i]
    set value [lindex $values $i]

    if { [lsearch -exact $blobs "$table.$column"] != -1 } {

      set cmd blob
      lappend dml_values "$column = empty_blob()"
      set lob_value $value
      set lob_column $column

    } elseif { [lsearch -exact $clobs "$table.$column"] != -1 } {

      set cmd clob
      lappend dml_values "$column = empty_clob()"
      set lob_value $value
      set lob_column $column

    } else {
      lappend dml_values "$column = [ad_dbquotevalue $value]"
    }
  }

  set stmt "update $table set [join $dml_values ", "]
                 where $where"

  if { ! [info exists cmd] } { 
    ns_db dml $db $stmt
  } else {
    ns_ora ${cmd}_dml $db "$stmt returning $lob_column into :1" $lob_value
  }
}

proc_doc ad_dbstore { table keys values db } "

  Counts the number of rows with the specified keys in the table.
  If no rows are found, performs an insert based on the values (an ns_set).
  If a row already exists, updates the row based on the values.

" {

  foreach key $keys {
    lappend eq "$key = [ns_dbquotevalue [ns_set get $values $key]]"
  }

  set query "select count(*) from $table
             where [join $eq " and "]"
  set count [ad_dbquery onevalue $query $db]

  set cols [ad_util_get_keys $values]

  if { $count == 0 } {

    foreach col $cols {
      lappend vals [ns_dbquotevalue [ns_set get $values $col]]
    }
    ns_db dml $db "insert into $table ([join $cols ","])
                   values ([join $vals ","])"

  } else {

    foreach col $cols {
      lappend vals "$col = [ns_dbquotevalue [ns_set get $values $col]]"
    }
    ns_db dml $db "update $table
                   set [join $vals ","]
                   where [join $eq " and "]"
  }
}

proc_doc ad_dbquotevalue { value } "

  Returns a quoted value if it does not look like a function

" {

  switch -regexp $value {

    {^sysdate$} {

      set value sysdate
    }

    {^[a-zA-Z0-9_]+\(} {

      set value $value
    }

    default {

      set value [ns_dbquotevalue $value]
    }
  }

  return $value
}

proc_doc ad_db_search_clause { columns terms } "

  Builds a where clause for a search based on partial-word or
  soundex matches.

" {

  if { [llength $terms] == 0 } { return "$column is not null" }

  foreach column $columns {

    foreach term $terms {

      regsub -all {'} $term {''} term

      foreach token [split $term] {

	lappend where "
        lower($column) like '%[string tolower $token]%'"
      }

      lappend where "soundex($column) = soundex('$term')"
    }
  }

  return [join $where " or "]
}

proc_doc ad_db_build_token_index { table token id index_table } "

  Builds a search table by tokenizing a column from table and
  adding each token to index_table keyed on an id column.
  Used to do combined partial-word and soundex searching.

" {

  
}

proc_doc ad_db_treepath { query { db "" } { multiple 1 } } "

  Performs a query that includes a column calling the
  treepath stored procedure.  Parses out the depth value
  from the returned path and includes in the query result.

" {

  set rows [ad_dbquery multirow $query $db]

  foreach row $rows {
    set path [string trim [ns_set get $row path]]
    set index [expr [string length $path] - 2]
    set depth [expr [string range $path $index end] * $multiple]
    ns_set put $row depth $depth
  }

  return $rows
}

proc_doc ad_db_load_csv { file table constants columns } "

  Loads a csv file into a database table.  Constants is an ns_set
  with constant expressions such as literal strings, sequences, or
  sysdates.  Pass an empty ns_set if there are no constants.
  Columns is a list of column names corresponding to
  each entry in a row from the csv file.

" {

  # Build the statement stub

  set stub "insert into $table ("

  if { [ns_set size $constants] > 0 } {
    append stub "[join [ad_util_get_keys $constants] ","],"
  }

  append stub "[join $columns ","]
    ) values (
  "

  if { [ns_set size $constants] > 0 } {
    append stub "[join [ad_util_get_values $constants] ","],"
  }

  # Open the file

  set fd [open $file]

#  set db [ns_db gethandle subquery]
  
  db_with_handle db {

    while { 1 } {

      set count [ns_getcsv $fd values]

      if { $count == -1 } { break }
      if { $count != [llength $columns] } { continue }

      set stmt $stub
      set dbvalues [list]
      foreach value $values { 
	lappend dbvalues [ns_dbquotevalue $value]
      }

      append stmt "[join $dbvalues ","])"

      ns_db dml $db $stmt
    }
  }

  close $fd

#  ns_db releasehandle $db
}

