# /www/intranet/hours/other-projects.tcl

ad_page_contract {
    Lets a user choose a project on which to log hours

    @param on_which_table table we're adding hours
    @param julian_date day in julian format for which we're adding hours
    @param user_id The user for which we're logging hours
 
    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date January, 2000
    @cvs-id other-projects.tcl,v 3.9.2.7 2000/09/22 01:38:38 kevin Exp
   
} {
    { user_id:integer "" }
    { on_which_table "" } 
    { julian_date "" } 
}

# Choose between daily/weekly time entry screen
if { [string compare [ad_parameter TimeEntryScreen intranet "daily"] "weekly"] == 0 } {
    set target "time-entry"
} else {
    set target "ae"
}

set context_bar [ad_context_bar_ws [list index?[export_url_vars on_which_table] Hours] [list $target?[export_url_vars user_id on_which_table julian_date] "Add hours"] "Choose project"]


# Create a form to allow people to select multiple projects
set page_body "
<form method=post action=$target>
[export_form_vars user_id on_which_table julian_date]
<ul>
"


# Give the user a list of all the projects from which to choose
# Note that they have two ways to select a project:
#  1. Click the link for the group name to select one project
#  2. Checkoff a set of projects and hit the submit button at 
#     the end of the page

set sql "select g.group_name, g.group_id 
           from user_groups g, im_projects p
          where g.group_id=p.group_id
       order by upper(group_name)"

db_foreach projects_list $sql {
    append page_body "<li><input type=checkbox name=on_what_id_list value=$group_id> <a href=$target?on_what_id=$group_id&[export_url_vars on_which_table julian_date]>$group_name</a>\n"
} if_no_rows {
    # offer the user the option of adding a project. We set return url to this page
    set return_url [im_url_with_query]
    append page_body "  <li> There are no projects for which to add hours. You can <a href=../projects/ae?[export_url_vars return_url]>add a project</a> if you want.\n"
}

append page_body "
</ul>

<p>
<center><input type=submit value=\" Log hours on selected projects \"></center>
</form>

"


doc_return  200 text/html [im_return_template]

