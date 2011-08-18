# $Id: presentation-edit-2.tcl,v 3.0.4.1 2000/04/28 15:11:40 carsten Exp $
# File:        presentation-edit-2.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Create or apply changes to a presentation.
# Inputs:      presentation_id (if editing)
#              title, page_signature, copyright_notice, show_modified_p, public_p, style

set user_id [ad_maybe_redirect_for_registration]

set_the_usual_form_variables

set exception_count 0
set exception_text ""

if { ![info exists title] || $title == "" } {
    append exception_text "<li>Your title was blank.  We need a title to generate the user interface."
    incr exception_count
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

# We're OK to insert.

set db [ns_db gethandle]

if { ![info exists creating] } {
    set condition "presentation_id = $presentation_id"
    wp_check_authorization $db $presentation_id $user_id "write"
} else {
    if { [database_to_tcl_string $db "
        select count(*) from wp_presentations where presentation_id = $presentation_id
    "] } {
	# Double-click!
	if { $style == "upload" } {
	    # User requested to upload a style - send to the style editor.
	    ad_returnredirect "style-edit.tcl?presentation_id=$presentation_id"
	} else {
	    ad_returnredirect "presentation-top.tcl?presentation_id=$presentation_id"
	}
	return
    }

    set condition ""
    set group_id [database_to_tcl_string $db "select user_group_sequence.nextval from dual"]
}

if { $style == "upload" } {
    # User requested to upload a style.
    set upload 1
    set style "null"
} else {
    set upload 0
}
if { $style == -1 || $style == "" } {
    # Default style.
    set style "null"
}
if { $style != "null" } {
    wp_check_numeric $style
}

set names [list presentation_id title copyright_notice page_signature creation_date creation_user style public_p audience background]
set values [list $presentation_id "'$QQtitle'" "'$QQcopyright_notice'" "'$QQpage_signature'" sysdate $user_id $style "'$QQpublic_p'" "'$QQaudience'" "'$QQbackground'"]

if { $condition == "" } {
    ad_user_group_add $db "wp" "WimpyPoint Presentation $title" "t" "f" "closed" "f" "" $group_id
#    ns_db dml $db "
#        insert into user_groups(group_id, group_type, group_name, creation_user, creation_ip_address,
#                                approved_p, active_p, existence_public_p, new_member_policy, multi_role_p, group_admin_permissions_p)
#        values($group_id, 'wp', $presentation_id, $user_id, '[ns_conn peeraddr]',
#               't', 't', 'f', 'closed', 't', 't')
#    "
    lappend names "group_id"
    lappend values $group_id
}

wp_try_dml_or_break $db [wp_prepare_dml "wp_presentations" $names $values $condition]

if { $condition == "" } {
    # We're inserting - create the first checkpoint.
    ns_db dml $db "insert into wp_checkpoints(presentation_id, checkpoint) values($presentation_id, 0)"
}

ns_db dml $db "end transaction"

if { $upload } {
    # User requested to upload a style - send to the style editor.
    ad_returnredirect "style-edit.tcl?presentation_id=$presentation_id"
} else {
    ad_returnredirect "presentation-top.tcl?presentation_id=$presentation_id"
}

