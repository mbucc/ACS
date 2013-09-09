# /www/intranet/employees/aim.tcl

ad_page_contract {
    Top level page to select an AIM format

    @param none
    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id aim.tcl,v 1.9.2.5 2000/09/22 01:38:30 kevin Exp
} {
    
}

set page_title "Employee AIM Buddy Lists"
set context_bar [ad_context_bar_ws [list ./ "Employees"] "AIM Lists"]

set page_body "
All Employees:
<ul>
  <li> <a href=aim-blt>blt</a> - standard, windows format
  <li> <a href=aim-tik>Tik</a> (for linux)
  <li> <a href=everybuddy>everybuddy</a> ( linux: save as .everybuddy/contacts)
</ul>

By Office:
<ul>
  <li> <a href=aim-blt-by-office>blt</a> - standard, windows format
  <li> <a href=aim-tik-by-office>Tik</a> (for linux)
  <li> <a href=everybuddy-by-office>everybuddy</a> (linux: save as .everybuddy/contacts)
</ul>

"
doc_return  200 text/html [im_return_template]