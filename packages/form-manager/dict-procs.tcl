# /packages/form-manager/dict-procs.tcl
ad_library {

  Documentation procedures for the ArsDigita Publishing System.

  @author Karl Goldstein (karlg@arsdigita.com)
  @cvs-id dict-procs.tcl,v 1.2.2.3 2000/09/22 01:33:53 kevin Exp

}

# Copyright (C) 1999 Karl Goldstein (karlg@arsdigita.com)

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

proc ad_form_dictionary_filter { why } {

  if [catch {

    set path [ns_url2file [ns_conn url]]
    if { ! [file exists $path] } {
      error PUBLISH_SPECIFICATION_NOT_FOUND
    }
    
    set url "/templates/define/form.adp"
    ad_template_init url

    doc_return  200 text/html [ns_adp_parse -file [ns_url2file $url]]
  
  } errCode] {

    ad_publish_error_message $errCode
  }

  return "filter_return"
}

