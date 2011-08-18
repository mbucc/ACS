# $Id: presentation-acl.tcl,v 3.0 2000/02/06 03:55:13 ron Exp $
# File:        presentation-acl.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Allows an administrator to edit ACL lists.
# Inputs:      presentation_id, role

set_the_usual_form_variables

set db [ns_db gethandle]
set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $db $presentation_id $user_id "write"

set selection [ns_db 1row $db "select * from wp_presentations where presentation_id = $presentation_id"]
set_variables_after_query

ReturnHeaders
ns_write "[wp_header_form "name=f" \
           [list "" "WimpyPoint"] [list "index.tcl?show_user=" "Your Presentations"] \
           [list "presentation-top.tcl?presentation_id=$presentation_id" "$title"] "Authorization"]

"

set out ""

if { $public_p == "t" } {
    append out "The presentation is public, so anyone is allowed to view it.
You can <nobr><a href=\"presentation-public.tcl?presentation_id=$presentation_id&public_p=f\">make the presentation
private</a></nobr> if you want only certain users to be able to view it.
<p>"
}

append out "
<p>
<table cellpadding=0 cellspacing=0>
"

foreach role { read write admin } {
    if { $role == "read" && $public_p == "t" } {
	# Don't bother showing the read list if the presentation is public.
	continue
    }

    append out "<tr valign=top><td align=right width=30%><br>The following users may [wp_role_predicate $role]:"
    if { $role == "read" } {
	append out "<p>(or you can <a href=\"presentation-public.tcl?presentation_id=$presentation_id&public_p=t\">make the presentation
public</a> so everyone can view it)"
    }
    append out "</td><td>&nbsp;</td><td>
<table border=2 cellpadding=10><tr><td align=center><table cellspacing=0 cellpadding=0>\n"

    set counter 0

    if { $role == "admin" } {
	incr counter
	append out "<tr><td><a href=\"/shared/community-member.tcl?user_id=$creation_user\">[database_to_tcl_string $db "select first_names || ' ' || last_name from users where user_id = $creation_user"]</a></td>
<td>&nbsp;&nbsp;&nbsp;</td><td>(creator)</td></tr>\n"
    }

    wp_select $db "
        select first_names, last_name, u.user_id req_user_id
        from users u, user_group_map m
        where u.user_id = m.user_id
        and m.group_id = $group_id
        and m.role = '$role'
        order by last_name, first_names
    " {
        append out "<tr><td><a href=\"/shared/community-member.tcl?user_id=$req_user_id\">$first_names $last_name</a></td><td>&nbsp;&nbsp;&nbsp;</td>"
	if { $user_id == $req_user_id } {
	    append out "<td>(you)</td>"
	} else {
	    append out "<td>\[ <a href=\"presentation-acl-delete.tcl?presentation_id=$presentation_id&user_id=$req_user_id\">remove</a> \]</td>"
	}
	append out "</tr>\n"
	incr counter
    }
    set counter2 0
    wp_select $db "
        select t.invitation_id, t.name, t.email, t.invite_date, u.first_names, u.last_name, u.user_id
        from   wp_user_access_ticket t, users u
        where  t.presentation_id = $presentation_id
        and    t.role = '$role'
        and    t.secret is not null
        and    t.invite_user = u.user_id
        order by invite_date
    " {
	if { $counter != 0 && $counter2 == 0 } {
	    append out "<tr><td colspan=3><hr></td></tr>"
	}

	append out "<tr><td><a href=\"mailto:$email\">$name</a></td><td>&nbsp;&nbsp;&nbsp;</td><td><a href=\"uninvite.tcl?presentation_id=$presentation_id&invitation_id=$invitation_id\">remove</a></td></tr>
<tr><td colspan=4>&nbsp;&nbsp;&nbsp;<nobr>(invited by <a href=\"/shared/community-member.tcl?user_id=$req_user_id\">$first_names $last_name</a></nobr> <nobr>on [util_IllustraDatetoPrettyDate $invite_date])</nobr></td></tr>
"
        incr counter
        incr counter2
    }

    if { $counter == 0 } {
	append out "<tr><td><i>No users.</i></td></tr>"
    }
    append out "</table><hr>
<input type=button value=\"Add One\" onClick=\"location.href='presentation-acl-add.tcl?presentation_id=$presentation_id&role=$role'\">
</td></tr></table></td></tr>"

    if { $role != "admin" } {
	append out "<tr><td>&nbsp;</td></tr>"
    }
}

ns_write "$out</td></tr></table></p>

[wp_footer]
"
