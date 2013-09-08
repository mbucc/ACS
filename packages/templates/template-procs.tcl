# /packages/templates/template-procs.tcl
ad_library {

  Core procedures for the ArsDigita Publishing System.

  @author Karl Goldstein (karlg@arsdigita.com)
  @cvs-id template-procs.tcl,v 1.6.2.3 2000/09/22 01:33:54 kevin Exp

}

# Copyright (C) 1999-2000 ArsDigita Corporation

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

# Top-level template processor.  Looks for a master template and
# applies it if one is found.

proc ad_template_filter { url } {

  # Set cgi parameters as a convenience

  ad_util_set_global_variables "cgi." [ns_getform]

  # Prepare the template

  ad_template_init url

  set path [ns_url2file $url]
  upvar #0 content content
  if { [file exists $path] } {
    set content [ad_template_parse -file $path]
  } else {
    set content ""
  }

  # Prepare the master template if one is specified

  set master_template_url [ad_template_get_master $url]

    ns_log Notice "USING MASTER $master_template_url"

  if { ! [string match $master_template_url {}] } {

    ad_template_init master_template_url

    # A master template can have only database content!
    
    set master_template_path [ns_url2file $master_template_url]

    set output [ad_template_parse -file $master_template_path]
    append output " "

    doc_return  200 text/html $output

  } else {

    if { ! [file exists $path] } { 
      ns_log Notice $path
      ad_publish_error_message PUBLISH_FILE_NOT_FOUND 
      return
    }

    doc_return 200 text/html $content
  }
}

# Top-level parse wrapper that checks for errors raised during parsing
# (AOLserver may trap these so we would not hear about them otherwise).

proc ad_template_parse { type template } {

  set output ""

  if {$type == "-file" } {
    set output [ad_template_cache get $template]
  }

  if { [empty_string_p $output] } { 
    set output [eval "uplevel #0 { ns_adp_parse $type $template }"]
    ad_template_cache set $template $output
  } else {
    ns_log Notice "USING CACHED TEMPLATE FOR $template"
  }

  global templateError

  if { [info exists templateError] } {

    set errorCode $templateError
    # Clear the template error variable to avoid loops
    unset templateError
    error $errorCode
  }

  return $output
}

# Reserve an error result in a global variable until adp parsing is complete

proc ad_template_error { errorCode } {

  global templateError
  set templateError $errorCode
}

proc ad_template_redirect { redirect_url } {

  global errorURL
  set errorURL $redirect_url

  ad_template_error REDIRECT
}

# The URL that is passed in the urlvar argument may be altered to
# point to a stylized template instead.

proc ad_template_init { urlvar } {

  upvar $urlvar url

  set spec [ad_template_get_spec $url]

  if { $spec != "" } { 

    if { ! [ad_template_cache exists $url] } {

      ad_template_get_all_data $spec
    }
  } 

  # Check for style application and process additional data if necessary.
  # This may change url to point to a style-specific template

  ad_template_apply_style $spec url
}

# Template cacheing

proc ad_template_cache { command path { output "" } } {

  regsub "^[ns_info pageroot]" $path {} url
  set spec [ad_template_get_spec $url]

  if { $spec != "" } {
    ad_util_set_variables $spec cache timeout
  } else {
    set cache ""
  }

  append url ":[ns_conn url]"

  if { $cache == "query" } { 
    append url "?[ad_util_build_query [ns_getform]]"
  }

  global locale_abbrev
  append url ":$locale_abbrev"

  switch $command {

    exists {

      if { [empty_string_p $cache] } { return 0 }

      if { ! [nsv_exists ad_template_cache_value $url] } { return 0 }

      set timestamp [nsv_get ad_template_cache_timestamp $url]
      if { $timestamp > [ns_time] } { return 1 }  else { return 0 }
    }
    
    get {

      if { [empty_string_p $cache] } { return "" }

      if { ! [nsv_exists ad_template_cache_value $url] } { return "" }

      set timestamp [nsv_get ad_template_cache_timestamp $url]
      if { $timestamp > [ns_time] } { 
	return [nsv_get ad_template_cache_value $url]
      } else {
	return ""
      }
    }

    set {

      if { [empty_string_p $cache] } { return "" }

      nsv_set ad_template_cache_value $url $output
      nsv_set ad_template_cache_timestamp $url [expr [ns_time] + $timeout]
    }

    default {
      error "Invalid subcommand to ad_template_cache: $command"
    }
  }
}

# Gets a template specification or empty string if none exists

proc ad_template_get_spec { url } {

  regsub {\.adp$} $url {.data} spec_url

  set spec [ad_publish_get_spec $spec_url status]

  return $spec
}

proc ad_template_get_master { url } {

  set spec [ad_template_get_spec $url]

  if { $spec != "" } { 

    set master [ns_set get $spec master]

    if { [string match $master "none"] } { return "" }

    if { ! [string match $master {}] } { 
      return [ad_util_absolute_url $master $url]
    }
  }

  upvar #0 sitemap nodeinfo

  if { ! [info exists nodeinfo] } { return "" }

  return [ad_site_get_master_template $nodeinfo]
}

# Get a list of data sources for a template, including those referenced
# in another data specification

proc ad_template_get_datasources { spec } {

  set src [ad_xml_get_node $spec process src]

  if { [string match $src {}] } {

    set datasources [list]
  
    foreach datasource [ad_xml_get_nodes $spec process] {

      ad_util_set_variables $datasource src name

      if { ! [string match $src {}] && ! [string match $name {}] } {
      
        set src [ad_util_absolute_url $src [ns_set get $spec url]]
        set externals [ad_template_get_datasource $src [split $name ","]]
        set datasources [concat $datasources $externals]

      } else {
 
        lappend datasources $datasource
      }
    }

  } else {

    set src [ad_util_absolute_url $src [ns_set get $spec url]]
    set spec [ad_publish_get_spec $src status]
    set datasources [ad_template_get_datasources $spec]
  }

  return $datasources
}

# Look up a single data source (or a list of data sources) in a
# template data spec

proc ad_template_get_datasource { src name } {

  set spec [ad_publish_get_spec $src status]

  set datasources [list]

  if { $spec == "" } {
    ad_template_get_datasource_error $src $name "The named file was not found"
  }

  foreach datasource [ad_template_get_datasources $spec] {

    set this_name [ns_set get $datasource name]
    if { [lsearch -exact $name $this_name] != -1 } {

      lappend datasources $datasource
    }
  }

  if { [llength $datasources] == 0 } {
    ad_template_get_datasource_error $src $name \
	"The data source was not found in the named file."
  }

  return $datasources
}

proc ad_template_get_datasource_error { src name msg } {

  global errorSet
  ns_set put $errorSet src $src
  ns_set put $errorSet name $name
  ns_set put $errorSet msg $msg
  
  error PUBLISH_DATASOURCE_REFERENCE_ERROR
}
