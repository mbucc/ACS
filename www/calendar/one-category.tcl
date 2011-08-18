# $Id: one-category.tcl,v 3.0 2000/02/06 03:35:55 ron Exp $
#one-category.tcl
#Written by Caroline@arsdigita.com Jan 2000.
#for some reason this page was called but did not exist.
#prints out all items for a category.


set_the_usual_form_variables
#category_id

set db [ns_db gethandle]

set category [database_to_tcl_string $db "select category from calendar_categories where category_id=$category_id"]


set page_title "$category"

ReturnHeaders

ns_write "[ad_header $page_title]

[ad_context_bar_ws_or_index [list "index.tcl" [ad_parameter SystemName calendar "Calendar"]] "$category"]

<h2>$page_title</h2>
<hr>
<ul>

"


set selection [ns_db select $db "select 
calendar_id,
title,
to_char(start_date,'Month DD, YYYY') as pretty_start_date,
to_char(start_date,'J') as j_start_date 
from calendar c
where sysdate < expiration_date
and category_id=$category_id
and approved_p = 't'
order by start_date, creation_date"]

set counter 0
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr counter

       ns_write "<li><a href=\"/calendar/item.tcl?calendar_id=$calendar_id\">$title</a> ($pretty_start_date)\n"
   }
   
   if { $counter == 0 } {
       ns_write "</table>there are no upcoming events"
   }

   if { [ad_parameter ApprovalPolicy calendar] == "open"} {
       ns_write "<p>\n<li><a href=\"post-new.tcl\">post an item</a>\n"
   } elseif { [ad_parameter ApprovalPolicy calendar] == "wait"} {
       ns_write "<p>\n<li><a href=\"post-new.tcl\">suggest an item</a>\n"
   }

  if { [database_to_tcl_string $db "select count(*) from calendar where sysdate > expiration_date"] > 0 } {
     ns_write "<li>To dig up information on an event that you missed, check 
 <a href=\"archives.tcl\">the archives</a>."
 }

ns_write "
</ul>
[calendar_footer]
"








