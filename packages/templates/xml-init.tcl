# /packages/templates/xml-init.tcl
ad_library {

  Dynamic XML filters.

  @author Karl Goldstein (karlg@arsdigita.com)
  @cvs-id xml-init.tcl,v 1.2.2.1 2000/07/18 21:53:31 seb Exp

}

# Copyright (C) 1999-2000 ArsDigita Corporation

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

ad_register_filter postauth GET *.xdp ad_xml_filter
ad_register_filter postauth POST *.xdp ad_xml_filter
