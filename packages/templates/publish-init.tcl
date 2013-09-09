# /packages/templates/publish-init.tcl
ad_library {

  Master filter for the ArsDigita Dynamic Publishing System.

  @author Karl Goldstein (karlg@arsdigita.com)
  @cvs-id publish-init.tcl,v 1.4.2.1 2000/07/18 21:53:28 seb Exp

}

# Copyright (C) 1999-2000 ArsDigita Corporation

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

ad_register_filter postauth GET * ad_publish_filter
ad_register_filter postauth POST * ad_publish_filter

# ad_register_filter postauth GET */ ad_publish_filter
# ad_register_filter postauth POST */ ad_publish_filter
