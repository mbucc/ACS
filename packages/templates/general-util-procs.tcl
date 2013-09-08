# /packages/templates/general-util-procs.tcl
ad_library {

  General utilities for the ArsDigita Publishing System.

  @author Karl Goldstein (karlg@arsdigita.com)
  @cvs-id general-util-procs.tcl,v 1.4.2.3 2000/08/08 07:21:32 ron Exp

}

# Copyright (C) 1999-2000 ArsDigita Corporation

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

util_report_library_entry

proc_doc ad_util_url2file { url } {

    Glue procedure to obtain a proper URL

} {
  
    if { [string match "/templates/*" $url] } {

	set path [file join [acs_root_dir] "packages/templates" [string range $url 1 end]]

    } else {
    
	set path [ns_url2file $url]
    }

    return $path
}

proc_doc ad_util_list_variables { values args } "
 
  Sets variables from a list of values

" {

  for { set i 0 } { $i < [llength $args] } { incr i } {

    set variable [lindex $args $i]
    upvar $variable v
    set v [lindex $values $i]
  }
}

proc_doc ad_util_set_variables { setID args } "
 
  Sets the named variables in the scope of the calling procedure.

" {

  if { $args == "" } {
    set args [ad_util_get_keys $setID]
  }
     
  foreach variable $args {
    upvar $variable v
    set v [ns_set iget $setID $variable]
  }
}

proc_doc ad_util_set_list_variables { setID args } "
 
  Sets the named variables in the scope of the calling procedure.
  Values are assumed to be lists, and the first item in the list
  is used to set each variable.

" {

  if { $args == "" } {
    set args [ad_util_get_keys $setID]
  }
     
  foreach variable $args {
    upvar $variable v
    set v [lindex [ns_set iget $setID $variable] 0]
  }
}

proc_doc ad_util_find_last { setID key } "

  Returns the last index of a key in an ns_set.

" {

  set last [expr [ns_set size $setID] - 1]

  for { set i $last } { $i >= 0 } { set i [expr $i - 1] } {

    if { [string match [ns_set key $setID $i] $key] } { return $i }
  }

  return -1
}

proc_doc ad_util_get_keys { setID } "

  Returns a list of keys in an ns_set.

" {

  set keys [list]

  for { set i 0 } { $i < [ns_set size $setID] } { incr i } {
    lappend keys [ns_set key $setID $i]
  }

  return $keys
}

proc_doc ad_util_get_values { setID { key {} } } "

  Returns a list of values in an ns_set, either for a specified
  key or for the set as a whole.

" {

  set values [list]

  if { [string match $key {} ] } {

    for { set i 0 } { $i < [ns_set size $setID] } { incr i } {
      lappend values [ns_set value $setID $i]
    }

  } else {

    for { set i 0 } { $i < [ns_set size $setID] } { incr i } {

      if { [string match $key [ns_set key $setID $i]] } {
        lappend values [ns_set value $setID $i]
      }
    }
  }

  return $values
}

proc_doc ad_util_set_global_variables { prefix setID } "

  Sets global variables for all keys in an ns_set.  A prefix
  is added to each key to compose the variable name.

" {

  if { $setID == "" } { return }

  for { set i 0 } { $i < [ns_set size $setID] } { incr i } {

    set var [ns_set key $setID $i]

    upvar #0 "$prefix$var" globalVar
    set globalVar [ns_set value $setID $i]

    # ns_log Notice "Setting $prefix$var to [ns_set value $setID $i]"
  }
}

proc_doc ad_util_clear_global_variables { prefix setID } "

  Sets global variables to an empty string for all keys in an ns_set.  
  A prefix is added to each key to compose the variable name.

" {

  if { $setID == "" } { return }

  for { set i 0 } { $i < [ns_set size $setID] } { incr i } {

    set var [ns_set key $setID $i]

    upvar #0 "$prefix$var" globalVar
    set globalVar " "
  }
}

proc_doc ad_util_create_persistent_set_list { set_list } "

  Creates a persistent copy of a list of ns_sets.

" {

  set list_copy [list]

  foreach setID $set_list {

    lappend list_copy [ad_util_create_persistent_set $setID]
  }

  return $list_copy
}

proc_doc ad_util_create_persistent_set { args } "

  Creates a persistent copy of a data structure
  encapsulated in an ns_set.  

" {

  ad_util_set_args setID

  set set_copy [ns_set create -persist [ns_set name $setID]]

  for { set i 0 } { $i < [ns_set size $setID] } { incr i } {

    set key [ns_set key $setID $i]
    set value [ns_set value $setID $i]

    # test if an ns_set and if so descend the data structure recursively

    if {! [catch { set name [ns_set name $value] } errMsg] } {

      # optionally replace the value with an empty string if the set
      # is empty

      if { [ns_set size $value] == 0 && [info exists empty_p] } {
	set value ""
      } else {
	set value [ad_util_create_persistent_set $value]
      }
    }

    ns_set put $set_copy $key $value
  }

  return $set_copy
}

proc_doc ad_util_free_set { setID } "

  Frees a (usually persistent) copy of a data structure
  encapsulated in an ns_set.  

" {

  for { set i 0 } { $i < [ns_set size $setID] } { incr i } {

    set key [ns_set key $setID $i]
    set values [ns_set value $setID $i]

    set values_copy [list]

    # the value might not be a valid list so catch this loop

    catch {

      foreach value $values {

        # test if an ns_set and if so descend the data structure recursively

        if { ! [catch { set name [ns_set name $value] } errMsg] } {

          ad_util_free_set $value
        }
      }

    } errMsg
  }

  ns_set free $setID
}

proc_doc ad_util_array_to_set { arrayref } "

  Converts an array into an ns_set.

" {

  upvar $arrayref a

  set setID [ns_set create]

  foreach name [array names a] {
    ns_set put $setID $name $a($name)
  }

  return $setID
}

proc_doc ad_util_is_set { setID } "

  Returns 1 if setID is a valid ns_set ID or 0 if not.

" {

  if [catch { set name [ns_set name $setID] } errMsg] {

    return 0

  } else {

    return 1
  }
}

proc_doc ad_util_absolute_url { url ref_url } "

  If the url is absolute, returns it unchanged.  If the url is relative,
  resolves an absolute url relative to the reference url.

" {

  if { [string index $url 0] != "/" } {

    set dir [file dirname [ns_url2file $ref_url]]
    set path "$dir/$url"
    regsub [ns_info pageroot] $path {} url

  }

  return [ns_normalizepath $url]
}

proc_doc ad_util_read_file { path } "

  Returns the contents of a file as a string.

" {

  if { [string index $path 0] != "/" } {

    set dir [file dirname [ns_url2file [ns_conn url]]]
    set path "$dir/$path"
  }

  if {! [file exists $path]} {

    return "No file found at $path"
  }

  # normalize the path and ensure that it is within the page tree
  # of the server.

  set path [ns_normalizepath $path]
#  if { ! [regexp "^[ns_info pageroot]" $path] } {
#    return "Attempt to access file outside page tree."
#  }

  set fd [open $path r]
  set text [read $fd]
  close $fd

  return $text
}

proc_doc ad_util_write_file { text path } "

  Writes text to a file.  Returns a formatted message in
  case of a failure.

" {

  set msg ""

  if { ! [file isdirectory [file dirname $path]] } {

    set msg "<p>The directory <tt>[file dirname $path]</tt> is not 
             accessible.</p>"

  } else {

    if { [catch {

      set fh [open $path w]
      puts $fh $text
      close $fh

    } errMsg] } {

      set msg "<p>The file could not be written to
               <tt>$path</tt>:</p>

               <pre>$errMsg</pre>"
    }
  } 
  
  return $msg
}

proc_doc ad_util_get_source { { path ""} } "

  Returns the source code for a file as HTML.

" {

  if [string match $path {}] {

    set path [ns_url2file [ns_conn url]]
  }

  
  set source [ad_util_read_file $path]

  return "<pre>[ns_quotehtml $source]</pre>"
}

proc_doc ad_util_queryget { args } "

  Returns a list of values from a form submission.  If no values
  are found, returns a single empty string unless the -none
  option is specified.

" {

  ad_util_set_args name

  set form [ns_getform]

  set values [list]

  if { $form == "" } { return $values }

  for { set i 0 } { $i < [ns_set size $form] } { incr i } {

    if { [ns_set key $form $i] == $name } {

      set value [ns_set value $form $i]

      if { [string length $value] > 0 } {
        lappend values $value
      }
    }
  }
  
  if { ! [info exists none_p] && [llength $values] == 0 } {
    lappend values ""
  }

  return $values
}

proc_doc ad_util_parse_keys { keystring } "

  Parse a string of the form KEY=VALUE,KEY=VALUE,...
  into a list of duplets.

" {

  set keylist [list]

  foreach pair [split $keystring ","] {

    lappend keylist [split $pair "="]
  }

  return $keylist
}

proc_doc ad_util_parse_query { query } "

  Parse a CGI query-type string into an ns_set.

" {

  set keyset [ns_set create]

  foreach pair [split $query "&"] {

    set keyvalue [split $pair "="]
    if { [llength $keyvalue] != 2 } { continue }
    ns_set put $keyset [lindex $keyvalue 0] [lindex $keyvalue 1]
  }

  return $keyset
}

proc_doc ad_util_build_query { keyset } "

  Build a CGI query-type string from an ns_set of key-value pairs.

" {

  if { $keyset == "" } { return "" } 

  set argv [list]

  for { set i 0 } { $i < [ns_set size $keyset] } { incr i } { 

    set key [ns_urlencode [ns_set key $keyset $i]]
    set value [ns_urlencode [ns_set value $keyset $i]]

    lappend argv "$key=$value"
  }

  return [join $argv "&"]
}

proc_doc ad_util_unique_list { duplist } "

  Returns a list based on duplist with duplicates removed.

" {

  set result [list]

  foreach val $duplist {

    if { [lsearch -exact $result $val] == -1 } {
      lappend result $val
    }
  }

  return $result
}

proc_doc ad_util_reverse_list { inlist } "

  Returns a list based on inlist in reversed order

" {

  set result [list]

  foreach val $inlist {

    set result [linsert $result 0 $val]
  }

  return $result
}

proc_doc ad_util_empty_list { args } "

  Returns 1 if all items in a list are empty by default, or
  if any are empty if the -any option is used.

" {

  ad_util_set_args inlist

  foreach val $inlist {

    if { [info exists any_p] } {
      if { [string match $val {}] } { 
	return 1 
      }
    } else {
      if { ! [string match {} $val] } { return 0 }
    }
  }

  if { [info exists any_p] } {
    return 0
  } else {
    return 1
  }
}

proc_doc ad_util_intersect_lists { a b } "

  Returns the intersection of two lists

" {

  set result [list]

  foreach val $a {

    if { [lsearch -exact $b $val] != -1 } {
      lappend result $val
    }
  }

  return $result
}

proc_doc ad_util_list_to_set { keys args } "

  Builds a list of ns_sets each containing the keys named in the first
  list argument.  Each remaining argument should be a list of values from
  which to add an ns_set to the list.

" {

  set set_list [list]

  foreach values $args {

    set setID [ns_set create]
    lappend set_list $setID

    for { set i 0 } { $i < [llength $keys] } { incr i } {

      ns_set put $setID [lindex $keys $i] [lindex $values $i]
    }
  }

  return $set_list
}

proc_doc ad_util_set_args { args } "

  Processes proc args given a list of variable names.  
  A boolean variable is set to t for each switch found.  Assumes
  that the calling procedure has received its arguments in the args
  list.

" {

  upvar args proc_args

  set index 0

  foreach arg $proc_args {

    if { [regexp {^-(.*)} $arg x switch] } {

      upvar "${switch}_p" "${switch}_p" 
      set "${switch}_p" "t"

    } else {

      set var [lindex $args $index]
      upvar $var $var
      set $var $arg

      incr index
    }
  }
}
  
proc_doc ad_util_set_cookie { expire_state name value { domain "" } } "

  Create a cookie with specified parameters.  The expiration state 
  may be persistent, session, or a number of minutes from the current
  time.

" {

  if { [string match $domain {}] } { set domain [ad_util_hostname] }

  set cookie "$name=$value; path=/; domain=$domain"
    
  switch $expire_state {

    persistent {
      append cookie ";expires=Fri, 01-Jan-2020 01:00:00 GMT"
    }

    "" -
    session {
    }

    default {
      
      set time [expr [ns_time] + ($expire_state * 60)]
      append cookie ";expires=[ns_httptime $time]"
    }
  }

  ns_set put [ns_conn outputheaders] "Set-Cookie" $cookie
}

proc_doc ad_util_get_cookie { cookie_name { default_value "" } } "

  Look for a cookie with the specified name and return its value.

" {

  foreach cookie [split [ns_set iget [ns_conn headers] cookie] ";"] {

    set pair [split [string trim $cookie] "="]
    set name [lindex $pair 0]
    set value [ns_urldecode [lindex $pair 1]]

    if { [string match $name $cookie_name] } { 

      return $value
    }
  }

  return $default_value
}

proc_doc ad_util_clear_cookie { name domain } "

  Expires a cookie

" {

    set cookie "$name=expired; path=/; domain=$domain;"
    append cookie "expires=Fri, 01-Jan-1980 01:00:00 GMT"

    ns_set put [ns_conn outputheaders] "Set-Cookie" $cookie
}

proc_doc ad_util_directory_files {} "

  Looks up the directory files from the parameters file.
  This procedure does not work correctly in 2.3.3.  It
  only returns the first file.

" {

  set path "ns/server/[ns_info server]"

  set files [list]

  foreach file [split [ns_config $path DirectoryFile] ","] {

    lappend files [string trim $file]
  }

  return $files
}

proc_doc ad_util_hostname {} "

  Looks up the authoritative hostname from the parameters file.

" {

  set path "ns/server/[ns_info server]/module/nssock"
  set hostname [ns_config $path Hostname]

  return $hostname
}

proc_doc ad_util_url { { ext "adp" } { url "" } } "

  Returns the current url and checks whether the URL is to
  a directory.

" {
  
  if { [empty_string_p $url] } {
    set url [ns_conn url]
  }

  # first check for an abstract URL
  set abstract "$url.$ext"

  if { [file exists [ns_info pageroot]$abstract] } { return $abstract }

  if { [regexp {/$} $url] } {

    set path [ns_url2file $url]
    if { ! [regexp {/$} $path] } { set path "$path/" }

    foreach dirfile [list index.adp home.adp] {

      if { [file exists "$path$dirfile"] } {
        
        return "$url$dirfile"
      }
    }
  }

  return $url
}

proc_doc ad_util_url_with_query {} "

  Returns the url with any query parameters if any were passed.

" {

  set url [ns_conn url]
  set formdata [ns_getform]

  if { $formdata != "" } {
    append url "?" [ad_util_build_query $formdata]
  }

  return $url
}

proc_doc ad_util_numeric_range { begin end } "

  Returns a list of numbers inclusive of the specified
  begin and end numbers.

" {

  set range [list]

  for { set i $begin } { $i <= $end } { incr i } {
    lappend range $i
  }

  return $range
}

proc_doc ad_util_possessive { s } "

  Returns the the possessive form of a noun

" {

  if [regexp {s$} $s] {
    return "$s'"
  } else {
    return "$s's"
  }
}

proc_doc ad_util_today {} "

  Returns today's date in the form YYYY-MM-DD.

" {

  return [ad_dbquery onevalue \
    "select to_char(sysdate, 'YYYY-MM-DD HH24:MI:SS') from dual"]
}

proc_doc ad_util_keyword { word } "

  Converts a word to a URL-safe keyword of nothing but letters and digits.

" {

  set word [string tolower $word]

  regsub -all {[^a-z0-9]} $word {} word

  return $word
}

proc_doc ad_util_queryconfirm { name } "

  Checks the value of form elements name and name.confirm.  Returns
  1 if values match or if one or both elements are empty.

" {

  set value [ns_queryget $name]
  set confirm [ns_queryget $name.confirm]

  if { [string match $confirm {}] || [string match $value {}] } {
    return 1
  } elseif { [string match $confirm $value] } {
    return 1
  }

  return 0
}

util_report_successful_library_load
