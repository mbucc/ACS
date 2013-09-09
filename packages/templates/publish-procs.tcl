# /packages/templates/publish-procs.tcl
ad_library {

  Master filter and associated procedures for the ArsDigita Publishing
  System.

  @author Karl Goldstein (karlg@arsdigita.com)
  @cvs-id publish-procs.tcl,v 1.6.2.6 2000/09/22 01:33:53 kevin Exp

}

# Copyright (C) 1999-2000 ArsDigita Corporation

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

# Executes a standard litany of setup and filtering procedures for each ADP
# request. Any procedure may throw an error that results in an error page
# or redirect being written to the connection rather than the requested page

proc ad_publish_filter { why } {

  set url [ad_util_url adp]

  # Only filter ADP
  if { ! [regexp {\.adp$} $url] } { return "filter_ok" }

  ns_log Debug "DPS filter processing $url"

  if { [catch {

      global errorSet
      set errorSet [ns_set create]

      ad_locale_init
      ad_form_filter
      ad_template_filter $url

  } errCode] } {

    ad_publish_error_message $errCode
  }

  return "filter_return"
}

proc ad_publish_redirect { redirect_url } {

  global errorURL
  set errorURL $redirect_url

  error REDIRECT
}

proc ad_publish_error_message { errCode } {

  global errList

  ad_publish_system_message $errCode
}

proc ad_publish_system_message { msgCode } {

  switch $msgCode {

    REDIRECT {

      global errorURL
      ns_returnredirect $errorURL
    } 
    RETURN {

      global errorURL
      ad_template_init errorURL
      set path [ns_url2file $errorURL]
      doc_return  200 text/html [ns_adp_parse -file $path]
    } 
    default {

      if { ! [regexp {PUBLISH_(.*)} $msgCode x msgPage] } {
        set msgPage "unknown_message"
	global errorInfo 
	if { [info exists errorInfo] } { ns_log Notice $errorInfo }
      }

      global errorSet
      if { [info exists errorSet] } {
	ad_util_set_global_variables "errorSet." $errorSet
      }

      set msgPage [string tolower $msgPage]
      set msgPath [ad_util_url2file /templates/sysmsg/LOCAL/$msgPage.adp]

      if { ! [file exists $msgPath] } {
	set msgTemplate "No local page found for system message $msgCode"
      } else {
	set msgTemplate [ns_adp_parse -file $msgPath]
      }

      doc_return 200 text/html $msgTemplate
    }
  }
}
