# /groups/group-type-view.tcl
#
# just like /groups/index.tcl but specific to one input group_type
#
# aileen@arsdigita.com, randyg@arsdigita.com
#
# January, 2000

# group_type
set_the_usual_form_variables
set db [ns_db gethandle]

set user_id [ad_verify_and_get_user_id]

#ns_log Notice "group type: $group_type"

set selection [ns_db 0or1row $db "select pretty_plural, pretty_name from user_group_types where group_type='$group_type'"]

if {$selection!=""} {
    set_variables_after_query
} else {
    ad_return_complaint 1 "<li>You must call this page with a valid group type $group_type"
    return
}

set html "
[ad_header "$pretty_plural @ [ad_system_name]"]

<h2>Select a $pretty_name to Join</h2>
[ad_context_bar_ws_or_index "$pretty_plural"]

<hr>
<ul>"

# basically an augmented version of the query in /groups/index.tcl specific for the classes group type
set selection [ns_db select $db "
select unique ug.group_name, ug.short_name, ug.group_id
from user_groups ug, user_group_types ugt, edu_current_classes c
where ug.group_type=ugt.group_type
and ugt.group_type='$group_type'
and c.class_id=ug.group_id
and (select count(*) from user_group_map 
        where user_id=$user_id 
        and group_id=ug.group_id)=0
order by upper(ug.group_name)"]

set count 0

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    
    append html "<li><a href=\"[ug_url]/[ad_urlencode $short_name]/member-add.tcl?role=student\">$group_name</a>\n"
    incr count
}

if {!$count} {
    append html "<li>There are currently no classes that you can join"
}

append html "</ul>
[ad_footer]"

ns_return 200 text/html $html




