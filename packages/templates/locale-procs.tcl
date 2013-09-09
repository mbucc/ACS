# /packages/templates/locale-procs.tcl
ad_library {

  Localization procedures for the ArsDigita Publishing System.

  @author Karl Goldstein (karlg@arsdigita.com)
  @cvs-id locale-procs.tcl,v 1.1.6.1 2000/07/18 21:53:27 seb Exp

}

# Copyright (C) 1999-2000 ArsDigita Corporation

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

# Establish a global locale environment for the request

proc ad_locale_init {} {
  
  set default_locale [ad_parameter DefaultLocale template us]

  global locale_abbrev
  set locale_abbrev [ad_preference get locale $default_locale]

  ns_log Notice "LOCALE: $locale_abbrev"
}
