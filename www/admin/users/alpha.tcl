# $Id: alpha.tcl,v 3.0 2000/02/06 03:30:53 ron Exp $
# philg notes that this seems to be dead code as of 9/27/99
# it was originally written by some MIT Press folks for Cognet

set_form_variables

# alpha_key

if { $alpha_key == "" } {
    set description "all users"
} else {
    set description "users whose last name begins with $alpha_key"
}

ReturnHeaders

ns_write "[ad_admin_header $description]

<h2>$description</h2>

part of the <a href=index.tcl>[ad_system_name] users admin area</a>
<hr>

<ul>

"

set db [ns_db gethandle]

set selection [ns_db select $db "select user_id, first_names, last_name, email
from users 
where last_name like '$alpha_key\%'
order by upper(last_name), upper(first_names)"]

set deleted_flag 0
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    ns_write "<li><a href=\"one.tcl?user_id=$user_id\">$first_names $last_name ($email)</a>\n"
}

ns_write "
</ul>
[ad_admin_footer]
"
