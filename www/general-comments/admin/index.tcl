# www/general-comments/admin/index.tcl

ad_page_contract {
    general comments administration main page

    @author philg@mit.edu
    @author tarik@arsdigita.com
    @creation-date 01/06/99
    @cvs-id index.tcl,v 3.2.2.4 2000/09/22 01:38:03 kevin Exp

    @param time_dimension_value Show comments made within the last n days
    @param section_dimension_value Show comments from a specified section
    @param approval_dimension_value Show all or unapproved comments

} {
    {time_dimension_value 30}
    {section_dimension_value all}
    {approval_dimension_value all}
}

# Note: if page is accessed through /groups pages then group_id and 
#   group_vars_set are already set up in the environment by the ug_serve_section. 
# group_vars_set contains group related variables (group_id, group_name, 
#   group_short_name, group_admin_email, group_public_url, group_admin_url, 
#   group_public_root_url, group_admin_root_url, group_type_url_p, 
#   group_context_bar_list and group_navbar_list)

# the idea here is to present the newer comments, separated by 
# section, with dimensional controls up top to control
# how much is displayed within each section, we sort by date descending


ad_scope_error_check 
ad_scope_authorize $scope admin group_admin none

# return_url to be passed to various helper pages so that we return to
# this page with the proper parameters
set return_url [ns_urlencode index.tcl?[export_ns_set_vars url]]

# the dimensions:
#  time (limit to 1 7 30 days or "all")
#  section ("all" or limit to one section), presented as a select box
#  approval ("all" or "unapproved only") 

set n_days_possible [list 1 7 30 all]
foreach n_days $n_days_possible {
    if { [string compare $n_days $time_dimension_value] == 0 } {
	# current choice, just the item
	lappend time_widget_items $n_days
    } else {
	lappend time_widget_items "<a href=\"index?time_dimension_value=$n_days&[export_ns_set_vars "url" [list time_dimension_value]]\">$n_days</a>"
    }
}

set time_widget [join $time_widget_items]

set individual_section_options [ad_db_optionlist option_get "
select section_name, table_name 
from table_acs_properties
order by upper(section_name)" $section_dimension_value]

if { [string compare $section_dimension_value "all"] == 0 } {
    set where_clause_for_section ""
    set all_sections_option "<option value=\"all\" SELECTED>All Sections</option>\n"
} else {
    set where_clause_for_section "and gc.on_which_table = :section_dimension_value"
    set all_sections_option "<option value=\"all\">All Sections</option>\n"
}

set section_widget "
<form action=\"index\" method=POST>
[export_ns_set_vars "form" [list section_dimension_value]]
<select name=section_dimension_value>
$all_sections_option
$individual_section_options
</select>
<input type=submit value=\"Go\">
</form>
"

if { [string compare $approval_dimension_value "all"] == 0 } {
    set where_clause_for_approval ""
    set approval_widget "all | <a href=\"index?approval_dimension_value=unapproved_only&[export_ns_set_vars "url" [list approval_dimension_value]]\">unapproved only</a>"
} else {
    # we're currently looking at unapproved
    set where_clause_for_approval "and gc.approved_p = 'f'"
    set approval_widget "<a href=\"index?approval_dimension_value=all&[export_ns_set_vars "url" [list approval_dimension_value]]\">all</a> | unapproved only"
}

set html "
[ad_scope_admin_header "General Comments Administration"]
[ad_scope_admin_page_title "General Comments Administration"]
[ad_scope_admin_context_bar "General Comments"]
<hr>
<p>

<table width=100%><tr><td align=left valign=top>$section_widget
<td align=center valign=top>$approval_widget
<td align=right valign=top>$time_widget
</table>
"


if { [string compare $time_dimension_value "all"] == 0 } {
    set where_clause_for_time ""
} else {
    set where_clause_for_time "and gc.comment_date > sysdate - :time_dimension_value"
}

set sql "
select on_which_table, on_what_id, one_line_item_desc, content,
       client_file_name, file_type, file_extension, original_width, original_height,
       caption, html_p, comment_id, comment_date, approved_p, gc.user_id as user_id,
       first_names || ' ' || last_name as commenter_name,
       tm.admin_url_stub, tm.section_name
from general_comments gc, users, table_acs_properties tm
where users.user_id = gc.user_id 
and gc.on_which_table = tm.table_name(+)
and [ad_scope_sql]
$where_clause_for_section
$where_clause_for_approval
$where_clause_for_time
order by gc.on_which_table, gc.comment_date desc"

set the_comments ""
set last_section_name ""

db_foreach comment_list $sql {
    if { [string compare $section_name $last_section_name] != 0 } {
	if ![empty_string_p $section_name] {
	    append the_comments "<h3>Comments within $section_name</h3>\n"
	} else {
	    append the_comments "<h3>Comments on $on_which_table</h3>\n"
	}
	set last_section_name $section_name
    }
    if { [empty_string_p $one_line_item_desc] } {
	set best_item_description "$section_name ID#$on_what_id"
    } else {
	set best_item_description $one_line_item_desc
    }
    append the_comments "<table width=90%>
<tr><td><blockquote>
[format_general_comment $comment_id $client_file_name $file_type $original_width $original_height $caption $content $html_p]
<br><br>-- <a href=\"/admin/users/one?user_id=$user_id\">$commenter_name</a> ([util_AnsiDatetoPrettyDate $comment_date])
on <a href=\"${admin_url_stub}$on_what_id\">$best_item_description</a>
</blockquote>
</td>
<td align=right>
"
    if { [string compare $approved_p "f"] == 0 } {
	append the_comments "<a href=\"toggle-approved-p?comment_id=$comment_id&return_url=$return_url\">Approve</a>\n<br>\n"
    }
    append the_comments "<a href=\"edit?comment_id=$comment_id&return_url=$return_url\" target=working>edit</a>
<br>
<a href=\"delete?comment_id=$comment_id&return_url=$return_url\" target=working>delete</a>
</td>
</table>\n"
}

if [empty_string_p $the_comments] {
    append html "there aren't any comments in this ACS installation that fit your criteria"
} else {
    append html $the_comments
}

append html [ad_scope_admin_footer]

db_release_unused_handles
doc_return 200 text/html $html
