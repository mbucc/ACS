# /packages/templates/publish-spec-procs.tcl

ad_library {

  Procedures for handling cached specification files.

  @author Karl Goldstein (karlg@arsdigita.com)
  @cvs-id publish-spec-procs.tcl,v 1.2.2.2 2000/08/08 05:08:02 karl Exp

}

# Copyright (C) 1999-2000 ArsDigita Corporation

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

ad_proc ad_publish_get_spec { args } {

    Returns a specification data structure as nested ns_sets.  If the
    specification at the given url is in the cache and has changed
    since it was cached, then the cached copy is returned.  If the
    specification is not in the cache or if the file has changed, then
    the specification is read from disk and stored in the cache before
    returning.  By default the spec is validated before being
    committed to the cache. 

} {

  ad_util_set_args url status_var

  # Grab a status var in the caller frame
  upvar $status_var spec_status

  # First check cache for an up-to-date version of the spec
  ns_share ad_publish_cache
  set spec [ns_set get $ad_publish_cache $url]

  if { $spec == "" } {
    set last_mtime ""
  } else {
    set last_mtime [ns_set get $spec mtime]
  }

  set path [ad_util_url2file $url]
  ns_log Notice "PATH is $path"

  if {! [file exists $path] } {

    ns_set put $ad_publish_cache $url ""
    set spec_status "NONE"
    return "" 
  }

  # If cached version of spec is up-to-date than return it
  set mtime [file mtime $path]
  if { $mtime == $last_mtime } {
    set spec_status "CURRENT"
    return $spec 
  }

  # Otherwise release the cached copy and reparse.  Delete
  # the key in the event an error occurs during parsing.
  if { $spec != "" } {
    ad_util_free_set $spec
    ns_set delkey $ad_publish_cache $url
  }    

  ns_log Notice "Updating spec cache for $url"

  # Parse the spec
  set spec [ad_publish_parse_spec $path]
  ns_set update $spec url $url

  # Optionally validate the parsed spec
  if { ! [info exists novalidate_p] } {

    # Let the extension determine the type of specification
    regexp {\.([^.]*)$} $path x type
    ad_publish_validate_spec $spec $type
  }

  # Create a persistent copy to place in cache
  set p_spec [ad_util_create_persistent_set -empty $spec]

  # Remember the modification time to ensure cache is current
  ns_set update $p_spec mtime $mtime

  # Store the persistent copy in the cache
  ns_set update $ad_publish_cache $url $p_spec

  set spec_status "UPDATE"

  return $p_spec
}

# Flush the specified spec from the cache if it exists

proc ad_publish_flush_spec { url } {

  ns_share ad_publish_cache
  set spec [ns_set get $ad_publish_cache $url]

  if { $spec != "" } {
    ad_util_free_set $spec
    ns_set delkey $ad_publish_cache $url
  }    
}

# Parses a specification file (an XML document) to create a
# persistent, validated data structure consisting of nested ns_sets.

proc ad_publish_parse_spec { path } {

  global errMsg

  if [catch { set text [ad_util_read_file $path] } errMsg] {

    error PUBLISH_READ_ERROR
  }

  if [catch { set spec [ad_xml_parse $text] } errMsg] {

    global errorInfo
    ns_log Notice $errorInfo

    error PUBLISH_PARSE_ERROR
  }

  return $spec
}

# Perform general validation of a specification according to the
# definitions stored in /templates/define on the server.

proc ad_publish_validate_spec { spec type } {

  set messages [list]

  set def_url "/templates/define/$type.def"
  set def_spec [ad_publish_get_spec -novalidate $def_url status]

  ad_publish_validate_spec_block $spec $def_spec

  if [llength $messages] {

    ns_log Notice "Spec validation error(s): $messages"

    # make sure the spec is deleted from the cache
    ns_share ad_publish_cache
    ns_set delkey $ad_publish_cache [ns_set get $spec url]

    global errList
    set errList [list]

    foreach message $messages {
      set errSet [ns_set create]
      ns_set put $errSet errMsg $message
      lappend errList $errSet      
    }

    error PUBLISH_SPEC_VALIDATION_FAILED
  }
}

# Validate a block of a specification data structure by
# comparing it to a canonical definition.

proc ad_publish_validate_spec_block { block def_block } {

  set name [ns_set name $block]
  upvar messages messages

  if { $def_block == "" } {
    lappend messages "No definition block for $name block"
    return
  }

  # Check that all required elements are present in the block

  foreach child [ad_util_get_values $def_block] {

    if { ! [ad_util_is_set $child] } { continue }

    set key [ns_set name $child]
    ad_util_set_variables $child status default

    if { [ns_set find $block $key] == -1 } {

      if { $status == "required" } {

        lappend messages "Missing required property $key in $name block"

      } else {

        if { ! [string match $default {}] } {
          ns_set put $block $key $default
        }
      }
    } 
  }

  ad_util_set_variables $def_block validate

  if { $validate == "false" } { return }

  # Validate the content of the block itself

  set size [ns_set size $block]
  for { set i 0 } { $i < $size } { incr i } {

    set key [ns_set key $block $i]
    set value [ns_set value $block $i]

    # Do not check plain text content
    if { $key == "text" } { continue }

    set def [ns_set get $def_block $key]
    
    if { [string match $def {}] } {    
      lappend messages "Invalid property $key in $name block"
      continue
    }

    if { [ad_util_is_set $def] } {

      set options [ns_set get $def options]

      if { [llength $options] > 1 && [lsearch $options $value] == -1 } {
	lappend messages "Invalid option <b>$value</b> for property 
                          <b>$key</b> in <b>$name</b> block"
	continue
      }
    }

    if { [ad_util_is_set $value] } {
      ad_publish_validate_spec_block $value $def
    }
  }
}

ns_share -init { 
  set ad_publish_cache [ns_set create -persist ad_publish_cache] 
} ad_publish_cache

