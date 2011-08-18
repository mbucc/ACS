#
# /www/education/class/index.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this is the index page for the classes.  Right now, it
# simply lists all of the ongoing classes.  We eventually
# want to list the classes by departments and make it very
# easy for people to browse through them
#

ad_page_variables {
    {return_url "[edu_url]class/one.tcl"} 
}

set user_id [ad_verify_and_get_user_id]
   
if { $user_id == 0 } {
   set return_url "[ns_conn url]?[ns_conn query]"
   ad_returnredirect /register.tcl?return_url=[ns_urlencode $return_url]
    return
}

set db [ns_db gethandle]

set return_string "
[ad_header "[ad_system_name] Classes"]

<h2>[ad_system_name] Classes</h2>

[ad_context_bar_ws Classes]

<hr>
<blockquote>

<h3>Classes</h3>
<ul>
"

set count 0

set selection [ns_db select $db "select class_name, class_id from edu_current_classes order by lower(class_name)"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append return_string "<li><a href=\"../util/group-login.tcl?group_id=$class_id&group_type=edu_class&[export_url_vars return_url]\">$class_name</a>"
    incr count
}

if {$count == 0} {
    append return_string "There are currently no classes in the system."
} else {
    append return_string "<br>"
}

append return_string "
</ul>
</blockquote>
[ad_footer]
"


ns_db releasehandle $db

ns_return 200 text/html $return_string



