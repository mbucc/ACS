# /www/press/admin/index.tcl

ad_page_contract {
    This page offers the options to create, edit, and delete existing press
    coverage for authorized users.

    @author Ron Henderson (ron@arsdigita.com)
    @created December 1999
    @cvs-id index.tcl,v 3.3.8.8 2000/09/22 01:39:07 kevin Exp
} {
    {orderby "publication_date"}
}

set user_id [ad_maybe_redirect_for_registration]

# Verify that this user is a valid (site-wide or group)
# administrator.  If so, then set up the where clause that will pull
# out all press coverage they can maintain.

if {[press_admin_any_group_p $user_id]} {
    # user is an administrator for at least some group
    # site-wide or group specific?
    if {[ad_administrator_p $user_id]} {
	set where_clause ""
    } else {
	set where_clause "
	where (scope = 'public' and creation_user = :user_id)
        or 't' = ad_group_member_admin_role_p(:user_id, press.group_id)"
    }
} else {
    ad_return_complaint 1 "<li>You are not authorized to access this page"
    return
}

# Helper proc to turn (days_remaining,important_p) into a status message

proc press_status {days_remaining important_p} {
    if {$days_remaining < 0 && $important_p == "f"} {
	set status "<font color=red>Expired</font>"
    } elseif {$important_p == "f"} {
	set status "<font color=green>Active <nobr>($days_remaining days left)</nobr></font>"
    } else {
	set status "Permanent"
    }
    return $status
}

# Get those press items

set active_days [press_active_days]

set table_def [list \
	{none             "Select"      no_sort "<td align=center bgcolor=white><input type=checkbox name=press_items value=$press_id></td>"} \
	{press_id         "ID#"         {}      "<td align=left><a href=edit?press_id=$press_id>$press_id</a></td>"} \
	{publication_date "Date"        {}      "<td align=left>$publication_date</td>"} \
	{publication_name "Publication" {}      ""} \
	{article_title    "Article"     {}      ""} \
	{days_remaining   "Status"      no_sort "<td align=center>[press_status $days_remaining $important_p]"}]

set bind_vars [ad_tcl_vars_to_ns_set user_id active_days]

set sql "
select press_id, 
       scope,
       article_title,
       publication_name,
       publication_date,
       trunc(publication_date+:active_days-sysdate) as days_remaining,
       important_p
from   press
$where_clause
[ad_order_by_from_sort_spec $orderby $table_def]"

# -----------------------------------------------------------------------------
# Ship it out

doc_return  200 text/html "
[ad_header "Press Admin"]

<h2>Press Admin</h2>

[ad_context_bar_ws [list "../" "Press"] "Admin"]

<hr>

<p>The system is currently configured to display a maximum of
[ad_parameter DisplayMax press] press items for up to [ad_parameter ActiveDays press]
days from the date of publication.

<ul>
<li><a href=add>Add a new press item</a></li>
</ul>

<p>

<form method=post action=process>

[ad_table -Torderby $orderby -Ttable_extra_html {width=100%} -Tband_colors [list {} lightgrey] \
	-bind $bind_vars press_items $sql $table_def]


<p>Do the following to the selected items:
<select name=action>
<option value=delete selected>Delete
<option value=importance_high>Make permanent
<option value=importance_low>Allow to expire
</select>
<input type=submit value=Go>
</p>
</form>

[ad_footer]"

