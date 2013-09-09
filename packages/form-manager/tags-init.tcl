# /packages/form-manager/tags-init.tcl
ad_library {

  Tag handlers for form manager for the ArsDigita Publishing System.

  @author Karl Goldstein (karlg@arsdigita.com)
  @cvs-id tags-init.tcl,v 1.2.6.1 2000/07/18 22:06:41 seb Exp

}

# Copyright (C) 1999-2000 ArsDigita Corporation

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

ns_register_adptag formtemplate "/formtemplate" ad_tag_formtemplate
ns_register_adptag formgroup "/formgroup" ad_tag_formgroup
ns_register_adptag formerror "/formerror" ad_tag_formerror

ns_register_adptag formvalues ad_tag_formvalues

ns_register_adptag formlabel ad_tag_formlabel
ns_register_adptag formwidget ad_tag_formwidget

