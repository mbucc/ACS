# /www/wp/presentation-acl-add.tcl

ad_page_contract {
    Allows an administrator to add a member to an ACL list.
    @creation-date 28 Nov 1999
    @author Jon Salz <jsalz@mit.edu>

    @param presentation_id the ID of the presentation
    @param role the type of permission being granted (read, write, admin)

    @cvs-id presentation-acl-add.tcl,v 3.1.6.6 2000/09/22 01:39:31 kevin Exp
} {
    presentation_id:integer
    role
}
# modified by psc@arsdigita.com for ACS 3.4 upgrades

set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $presentation_id $user_id "admin"

db_1row select_presentation "select presentation_id, \
                                    title \
                             from wp_presentations where presentation_id = :presentation_id" 

# accomodations for variable {passthrough} in user-search.tcl
set passthrough_array.1 $presentation_id 
set passthrough_array.2 $role


doc_return  200 "text/html" "[wp_header_form "action=/user-search" \
           [list "" "WimpyPoint"] [list "index?show_user=" "Your Presentations"] \
           [list "presentation-top?presentation_id=$presentation_id" "$title"] \
           [list "presentation-acl?presentation_id=$presentation_id" "Authorization"] "Add User"]

<input type=hidden name=target value=\"/[ns_quotehtml [join [lreplace [ns_conn urlv] end end "presentation-acl-add-2"] "/"]]\">
<input type=hidden name=passthrough value=\"passthrough_array.1 passthrough_array.2\">
[export_form_vars passthrough_array.1 passthrough_array.2]

<center>

<p><table border=2 cellpadding=10 width=60%><tr><td>
<table cellspacing=0 cellpadding=0>
<tr><td colspan=2>Please enter part of the E-mail address or last name of the user
you wish to give permission to [wp_role_predicate $role $title].<p>If you can't find the person you're looking for,
he or she probably hasn't yet registered on [ad_system_name], but you can <a href=\"invite?[export_ns_set_vars]\">invite him or her to
[wp_only_if { $role == "read" } "view" "work on"] your presentation</a>.</p>
<hr></td></tr>
<tr><th align=right>Last Name:&nbsp;</th><td><input name=last_name size=30></td></tr>
<tr><th align=right><i>or</i> E-mail:&nbsp;</th><td><input name=email size=30></td></tr>
<tr><td colspan=2 align=center>
<hr>
<input type=submit value=Search>
</td></tr>
</table></td></tr></table></p></center>

[wp_footer]
"





