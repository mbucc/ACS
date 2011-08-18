#
# /press/admin/index.tcl
#
# Author: ron@arsdigita.com, December 1999
#
# This offers the options to create, edit, and delete existing press
# coverage for authorized users.
#
# $Id: index.tcl,v 3.1.2.1 2000/03/15 20:29:59 aure Exp $
#

set user_id [ad_maybe_redirect_for_registration]

set db [ns_db gethandle]

# Verify that this user is a valid (site-wide or group)
# administrator.  If so, then set up the where clause that will pull
# out all press coverage they can maintain.

if {[press_admin_any_group_p $db $user_id]} {
    # user is an administrator for at least some group
    # site-wide or group specific?
    if {[ad_administrator_p $db $user_id]} {
	set where_clause ""
    } else {
	set where_clause "
	where (scope = 'public' and creation_user = $user_id)
        or 't' = ad_group_member_admin_role_p($user_id, press.group_id)"
    }
} else {
    ad_return_complaint 1 "<li>You are not authorized to access this page"
    return
}

# Get those press items

set selection [ns_db select $db "
select press_id, 
       scope,
       article_title,
       publication_name,
       publication_date,
       trunc(creation_date+[press_active_days]-sysdate) as days_remaining,
       important_p
from   press
$where_clause
order  by publication_date desc"]

set avail_press_count 0
set avail_press_items ""

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr avail_press_count

    if {$days_remaining < 0 && $important_p == "f"} {
	set status "<font color=red>Expired</font>"
    } elseif {$important_p == "f"} {
	set status "<font color=green>Active <nobr>($days_remaining days left)</nobr></font>"
    } else {
	set status "Permanent"
    }

    append avail_press_items "
    <tr valign=top>
    <td><nobr>[util_AnsiDatetoPrettyDate $publication_date]</nobr></td>
    <td>$publication_name</td>
    <td>$article_title</td>
    <td align=center>$status</td>
    <td align-center><nobr>
      <a href=edit?press_id=$press_id>edit</a> | 
      <a href=delete?press_id=$press_id>delete</a></nobr>
    </td>
    </tr>"
}

# Done with the database
ns_db releasehandle $db

if {$avail_press_count == 0} {
    set avail_press_list "
    <p>There is no press coverage currently in the database that you are 
    authorized to maintain."
} else {
    set avail_press_list "
    <table bgcolor=black cellpadding=0 cellspacing=1 border=0><tr><td>
    <table bgcolor=white cellpadding=3 cellspacing=1 border=0>
    <tr bgcolor=#dddddd>
    <td align=center><b>Date</b></td>
    <td align=center><b>Publication</b></td>
    <td align=center><b>Article</b></td>
    <td align=center><b>Status</b></td>
    <td align=center><b>Actions</b></td>
    </tr>
    $avail_press_items
    </table></td></tr></table>"
}

# -----------------------------------------------------------------------------
# Ship it out

ns_return 200 text/html "
[ad_header "Admin"]

<h2>Admin: Press</h2>

[ad_context_bar_ws [list "../" "Press"] "Admin"]

<hr>
<ul>
<li><a href=add>Add a new press item</a></li>
</ul>
</p>

<p>$avail_press_list</p>

[ad_footer]"

