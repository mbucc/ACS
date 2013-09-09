# /wp/presentation-acl.tcl
ad_page_contract {
    Allows an administrator to edit ACL lists.
    @cvs-id presentation-acl.tcl,v 3.3.2.9 2000/09/22 01:39:32 kevin Exp
    @author Jon Salz <jsalz@mit.edu>
    @creation-date  28 Nov 1999
    @param presentation_id is the ID of the presentation
} {
    presentation_id:naturalnum,notnull
}
# modified by jwong@arsdigita.com for ACS 3.4 upgrades

set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $presentation_id $user_id "write"

db_1row pres_select "
select  title, \
	creation_user, \
	public_p, \
	group_id
from wp_presentations where presentation_id = :presentation_id"

set page_output "[wp_header_form "name=f" \
           [list "" "WimpyPoint"] [list "index?show_user=" "Your Presentations"] \
           [list "presentation-top?presentation_id=$presentation_id" "$title"] "Authorization"]

"

set out ""

if { $public_p == "t" } {
    append out "The presentation is public, so anyone is allowed to view it.
You can <nobr><a href=\"presentation-public?presentation_id=$presentation_id&public_p=f\">make the presentation
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
	append out "<p>(or you can <a href=\"presentation-public?presentation_id=$presentation_id&public_p=t\">make the presentation
public</a> so everyone can view it)"
    }
    append out "</td><td>&nbsp;</td><td>
<table border=2 cellpadding=10><tr><td align=center><table cellspacing=0 cellpadding=0>\n"

    set counter 0

    if { $role == "admin" } {
	incr counter
	append out "<tr><td><a href=\"/shared/community-member?user_id=$creation_user\">[db_string creation_user_select "select first_names || '' || last_name from users where user_id = :creation_user" -default "Unknown User"]</a></td>
<td>&nbsp;&nbsp;&nbsp;</td><td>(creator)</td></tr>\n"
    }

    db_foreach name_select "
        select first_names, last_name, u.user_id req_user_id
        from users u, user_group_map m
        where u.user_id = m.user_id
        and m.group_id = :group_id
        and m.role = :role
        order by last_name, first_names
    " {
        append out "<tr><td><a href=\"/shared/community-member?user_id=$req_user_id\">$first_names $last_name</a></td><td>&nbsp;&nbsp;&nbsp;</td>"
	if { $user_id == $req_user_id } {
	    append out "<td>(you)</td>"
	} else {
	    append out "<td>\[ <a href=\"presentation-acl-delete?presentation_id=$presentation_id&user_id=$req_user_id\">remove</a> \]</td>"
	}
	append out "</tr>\n"
	incr counter
    }
    set counter2 0
    db_foreach invitation_select "
        select t.invitation_id, t.name, t.email, t.invite_date, u.first_names, u.last_name, u.user_id req_user_id
        from   wp_user_access_ticket t, users u
        where  t.presentation_id = :presentation_id
        and    t.role = :role
        and    t.secret is not null
        and    t.invite_user = u.user_id
        order by invite_date
    " {
	if { $counter != 0 && $counter2 == 0 } {
	    append out "<tr><td colspan=3><hr></td></tr>"
	}

	append out "<tr><td><a href=\"mailto:$email\">$name</a></td><td>&nbsp;&nbsp;&nbsp;</td><td><a href=\"uninvite?presentation_id=$presentation_id&invitation_id=$invitation_id\">remove</a></td></tr>
<tr><td colspan=4>&nbsp;&nbsp;&nbsp;<nobr>(invited by <a href=\"/shared/community-member?user_id=$req_user_id\">$first_names $last_name</a></nobr> <nobr>on [util_IllustraDatetoPrettyDate $invite_date])</nobr></td></tr>
"
        incr counter
        incr counter2
    }

    if { $counter == 0 } {
	append out "<tr><td><i>No users.</i></td></tr>"
    }
    append out "</table><hr>
<input type=button value=\"Add One\" onClick=\"location.href='presentation-acl-add?presentation_id=$presentation_id&role=$role'\"> <input type=button value=\"Add Group\" onClick=\"location.href='presentation-acl-add-group?presentation_id=$presentation_id&role=$role'\">
</td></tr></table></td></tr>"

    if { $role != "admin" } {
	append out "<tr><td>&nbsp;</td></tr>"
    }
}

db_release_unused_handles

append page_output "$out</td></tr></table></p>

[wp_footer]
"

doc_return  200 "text/html" $page_output