# /packages/templates/tags-init.tcl
ad_library {

  Markup tag handlers for the form manager component of the
  ArsDigita Publishing System.

  @author Karl Goldstein (karlg@arsdigita.com)
  @cvs-id tags-init.tcl,v 1.1.6.1 2000/07/18 21:53:29 seb Exp

}

# Copyright (C) 1999-2000 ArsDigita Corporation

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

ns_register_adptag include ad_tag_include
ns_register_adptag data ad_tag_data
ns_register_adptag datasource ad_tag_datasource

ns_register_adptag enclose "/enclose" ad_tag_enclose

ns_register_adptag if "/if" ad_tag_if
ns_register_adptag else "/else" ad_tag_else

ns_register_adptag subif "/subif" ad_tag_if

ns_register_adptag list "/list" ad_tag_list

ns_register_adptag grid "/grid" ad_tag_grid

ns_register_adptag multiple "/multiple" ad_tag_multiple
ns_register_adptag separator "/separator" ad_tag_separator

ns_register_adptag submultiple "/submultiple" ad_tag_multiple

ns_register_adptag var ad_tag_var
ns_register_adptag encvar ad_tag_encvar
