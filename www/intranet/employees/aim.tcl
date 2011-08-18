# $Id: aim.tcl,v 1.2.2.1 2000/03/17 07:25:50 mbryzek Exp $
#
# File: /www/intranet/employees/aim.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Top level page to select an AIM format
# 


set page_title "Employee AIM Buddy Lists"
set context_bar [ad_context_bar [list "/" Home] [list ../index.tcl "Intranet"] [list index.tcl "Employees"] "AIM Lists"]

set page_body "
All Employees:
<ul>
  <li> <a href=aim-blt.tcl>blt</a> - standard, windows format
  <li> <a href=aim-tik.tcl>Tik</a> (for linux)
</ul>

By Office:
<ul>
  <li> <a href=aim-blt-by-office.tcl>blt</a> - standard, windows format
  <li> <a href=aim-tik-by-office.tcl>Tik</a> (for linux)
</ul>

"
ns_return 200 text/html [ad_partner_return_template]