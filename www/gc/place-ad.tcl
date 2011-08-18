# $Id: place-ad.tcl,v 3.1.2.1 2000/04/28 15:10:32 carsten Exp $
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set_the_usual_form_variables

# domain_id

if { [ad_get_user_id] == 0 } {
    ad_returnredirect "/register/index.tcl?return_url=[ns_urlencode "[ns_conn url]?[export_url_vars domain_id]"]"
    return
}

set db [gc_db_gethandle]
set selection [ns_db 1row $db [gc_query_for_domain_info $domain_id "user_extensible_cats_p, "]]
set_variables_after_query

append html "[gc_header "Place Ad"]

[ad_decorate_top "<h2>Place an Ad</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [gc_system_name]] [list "domain-top.tcl?[export_url_vars domain_id]" $full_noun] "Place Ad"]
" [ad_parameter PlaceAdDecoration gc]]


<hr>

<h3>Choose a Category</h3>

<ul>
"

set selection [ns_db select $db "select primary_category
from ad_categories
where domain_id = $domain_id
order by primary_category"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    set url "place-ad-2.tcl?domain_id=$domain_id&primary_category=[ns_urlencode $primary_category]"
    append html "<li><a href=\"$url\">$primary_category</a>"
}

if { $user_extensible_cats_p == "t" } {

    append html "<p>
<li>None of these categories fit my ad; I'd like to 
<a href=\"define-new-category.tcl?domain_id=$domain_id\">
define a new one</a>"

}

append html "

</ul>

[gc_footer $maintainer_email]
"

ns_return 200 text/html $html
