# /packages/form-manager/dict-init.tcl
ad_library {

  Registers ad_form_dictionary_filter on *.form

  @author Karl Goldstein (karlg@arsdigita.com)
  @cvs-id dict-init.tcl,v 1.2.2.1 2000/07/18 22:06:40 seb Exp

}
ad_register_filter postauth GET *.form ad_form_dictionary_filter

