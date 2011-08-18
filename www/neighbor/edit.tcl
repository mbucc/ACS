# $Id: edit.tcl,v 3.0.4.1 2000/04/28 15:11:13 carsten Exp $
set user_id [ad_get_user_id]

if {$user_id == 0} {
   ad_returnredirect /register.tcl?return_url=[ns_urlencode "[ns_conn url]"]
   return
}

set db [neighbor_db_gethandle]

ReturnHeaders

ns_write "[neighbor_header "Your postings"]

<h2>Your postings</h2>

in <a href=index.tcl>[neighbor_system_name]</a>

<hr>

<ul>
"

set selection [ns_db select $db "select neighbor_to_neighbor_id, about, one_line, posted
from neighbor_to_neighbor
where poster_user_id = $user_id
order by posted desc"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    ns_write "<li><a href=\"edit-2.tcl?neighbor_to_neighbor_id=$neighbor_to_neighbor_id\">$about : $one_line</a> (posted $posted)\n"
}

ns_write "</ul>


[neighbor_footer]
"
