# /packages/templates/template-init.tcl
ad_library {

  Cache setup and data file filter for templating component
  of ArsDigita Dynamic Publishing System.

  @author Karl Goldstein (karlg@arsdigita.com)
  @cvs-id template-init.tcl,v 1.2.2.1 2000/07/18 21:53:30 seb Exp

}

# Copyright (C) 1999-2000 ArsDigita Corporation

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

# Top-level template processor.  Looks for a master template and
# applies it if one is found.

nsv_set ad_template_cache_value "" ""
nsv_set ad_template_cache_timestamp "" ""
ad_register_filter postauth GET *.data ad_template_dictionary_filter

