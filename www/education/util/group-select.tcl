#
# /www/education/util/group-select.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# This page allows the user to select which group to log in as
#


ad_page_variables {
    return_url
    group_type
}

set user_id [ad_verify_and_get_user_id]
   
if { $user_id == 0 } {
   set return_url "[ns_conn url]?[ns_conn query]"
   ad_returnredirect /register.tcl?return_url=[ns_urlencode $return_url]
    return
}

set db [ns_db gethandle]

if {[empty_string_p $group_type]} {
    ns_return_complaint 1 "<li>You must provide the type of the group you want to select for"
    return
}

if {[string compare $group_type edu_department] == 0} {
    set suffix Department
} else {
    set suffix Class
}

# show them a group if they are a member 

if {[ad_administrator_p $db $user_id]} {
    set selection [ns_db select $db "select unique(group_id), group_name from user_groups where lower(group_type) = '$group_type' and active_p = 't' order by lower(group_name)"]
} else {
    set selection [ns_db select $db "select unique(ug.group_id), ug.group_name
from user_group_map map, user_groups ug
where (map.group_id = ug.group_id
  and map.user_id = $user_id)
and active_p = 't'
and lower(group_type) = '$group_type'
order by ug.group_name"]
}

set counter 0
set html ""

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append html "<li><a href=\"group-login.tcl?[export_url_vars group_type group_id return_url]\">$group_name</a>\n"
    incr counter
}

if { $counter == 1 } {
    set url "group-login.tcl?[export_url_vars group_type group_id return_url]"
    ad_returnredirect $url
    return
}


set return_string "

[ad_header "Select a $suffix"]

<h2>Select a $suffix</h2>

[ad_context_bar_ws_or_index "$suffix Selection"]

<hr>
<ul>
"


if { $counter == 0 } {
    append return_string "<li>You are not listed as a member of any ${suffix}es."
} else {
    append return_string "$html"
}

append return_string "
</ul>
If you do not see a $suffix you are involved in,
<a href=\"/groups/\">visit the groups section</a> to find 
and join your $suffix.

[ad_footer]"

ns_db releasehandle $db

ns_return 200 text/html $return_string