ad_page_contract {
    the idea here is to present the newer comments, separated by 
    section, with dimensional controls up top to control
    how much is displayed
    
    @author philg@mit.edu on September 5, 1999
    @cvs-id index.tcl,v 3.2.2.8 2000/09/22 01:35:24 kevin Exp
    @param time_dimension_value View comments from the last n days
    @param section_dimension_value View comments from a specific section
    @param approval_dimension_value View all or unapproved comments

} {
    time_dimension_value:optional
    section_dimension_value:optional
    approval_dimension_value:optional
    {limit:optional,integer 1}
}

# within each section, we sort by date descending

# the dimensions:
#  time (limit to 1 7 30 days or "all")
#  section ("all" or limit to one section), presented as a select box
#  approval ("all" or "unapproved only") 

# removing spacing from the dimensional values to prevent security
# breaches

if { ![info exists time_dimension_value] || [empty_string_p $time_dimension_value] } {
    set time_dimension_value "30"
} else {
    regsub -all " " $time_dimension_value "" time_dimension_value
}

if { ![info exists section_dimension_value] || [empty_string_p $section_dimension_value] } {
    set section_dimension_value "all"
} else {
    regsub -all " " $section_dimension_value "" section_dimension_value
}


if { ![info exists approval_dimension_value] || [empty_string_p $approval_dimension_value] } {
    set approval_dimension_value "all"
} else {
    regsub -all " " $approval_dimension_value "" approval_dimension_value
}

# return_url to be passed to various helper pages so that we return to
# this page with the proper parameters

set return_url "[ns_urlencode "index.tcl?[export_ns_set_vars "url"]"]"

set n_days_possible [list 1 7 30 all]

foreach n_days $n_days_possible {
    if { $n_days == $time_dimension_value } {
	# current choice, just the item
	lappend time_widget_items $n_days
    } else {
	lappend time_widget_items "<a href=\"index?time_dimension_value=$n_days&[export_ns_set_vars "url" [list time_dimension_value]]\">$n_days</a>"
    }
}

set time_widget [join $time_widget_items]

db_with_handle {db} {
    set individual_section_options [ad_db_optionlist  $db "select section_name, table_name 
from table_acs_properties
order by upper(section_name)" $section_dimension_value]

}

if { $section_dimension_value == "all" } {
    set all_sections_option "<option value=\"all\" SELECTED>All Sections</option>\n"
} else {
    set all_sections_option "<option value=\"all\">All Sections</option>\n"
}

set section_widget "<form action=\"index\" method=POST>
[export_ns_set_vars "form" [list section_dimension_value]]
<select name=section_dimension_value>
$all_sections_option
$individual_section_options
</select>
<input type=submit value=\"Go\">
</form>
"

if { $approval_dimension_value == "all" } {
    set approval_widget "all | <a href=\"index?approval_dimension_value=unapproved_only&[export_ns_set_vars "url" [list approval_dimension_value]]\">unapproved only</a>"
} else {
    # we're currently looking at unapproved
    set approval_widget "<a href=\"index?approval_dimension_value=all&[export_ns_set_vars "url" [list approval_dimension_value]]\">all</a> | unapproved only"
}




set doc_body "[ad_admin_header "General Comments Administration"]

<h2>General Comments Administration</h2>
[ad_admin_context_bar "General Comments"]
<hr>

[help_upper_right_menu [list "integrity-check.tcl" "check comments' referential integrity"]]

[ad_style_bodynote "Due to some ugly software history, if you're interested in comments on
static .html pages, you have to visit 
<a href=\"/admin/comments/\">/admin/comments/</a>"]

<p>

<table width=100%><tr><td align=left valign=top>$section_widget
<td align=center valign=top>$approval_widget
<td align=right valign=top>$time_widget
</table>
"

if { $section_dimension_value == "all" } {
    set where_clause_for_section ""
} else {
    set where_clause_for_section "and gc.on_which_table = '$section_dimension_value'"
}

if { $approval_dimension_value == "all" } {
    set where_clause_for_approval ""
} else {
    set where_clause_for_approval "and gc.approved_p = 'f'"
}

if { $time_dimension_value == "all" } {
    set where_clause_for_time ""
} else {
    set where_clause_for_time "and gc.comment_date > sysdate - $time_dimension_value"
}

set the_comments ""
set last_section_name ""

set from_where_orderby_clauses "
    from general_comments gc, users, table_acs_properties tm
    where users.user_id = gc.user_id 
    and gc.on_which_table = tm.table_name(+)
    $where_clause_for_section
    $where_clause_for_approval
    $where_clause_for_time
    order by gc.on_which_table, gc.comment_date desc
"

set gc_sql_query "
    select gc.*, first_names || ' ' || last_name as commenter_name,
           tm.admin_url_stub,
           tm.section_name
    $from_where_orderby_clauses
"

set number_of_comments [db_string number_of_comments "select count(*) $from_where_orderby_clauses"]
set limiting_display_text ""
if { $limit != 0 && $number_of_comments > 1000 } {
    # We've got an insane number of comments to display, so we'll wrap it in
    # a "show me the first 1000" query -- note this will take just as long
    # on query time... just save on display time/space.  If we used rownum
    # in the raw query, we'd save time, but we'd lose the ability to order
    # by.
    set gc_sql_query "select * from ($gc_sql_query) where rownum <= 1000"
    set limiting_display_text "<i>Limiting display to the most recent 1000 of the $number_of_comments comments in the database.</i> \[<a href=index?[export_ns_set_vars]&limit=0>show all</a>\]<br>
<i>Warning: show all will take a long time</i>
<p>
"
}


db_foreach general_comments_by_section $gc_sql_query {
    if { $section_name != $last_section_name } {
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
    if { $approved_p == "f" } {
	append the_comments "<a href=\"toggle-approved-p?comment_id=$comment_id&return_url=$return_url\">Approve</a>\n<br>\n"
    }
    append the_comments "<a href=\"edit?comment_id=$comment_id\" target=working>edit</a>
<br>
<a href=\"delete?comment_id=$comment_id\" target=working>delete</a>
</td>
</table>\n"
}

if [empty_string_p $the_comments] {
    append doc_body "there aren't any comments in this ACS installation that fit your criteria"
} else {
    append doc_body "$limiting_display_text$the_comments"
}

append doc_body [ad_admin_footer]

doc_return 200 text/html $doc_body