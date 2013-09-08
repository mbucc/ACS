# /wp/presentation-edit-2.tcl
ad_page_contract {
    Create or apply changes to a presentation.
    @cvs-id presentation-edit-2.tcl,v 3.2.2.14 2001/01/12 00:45:30 khy Exp
    @author Jon Salz <jsalz@mit.edu>
    @creation-date  28 Nov 1999
    @param presentation_id ID of the presentation
} {
    presentation_id:naturalnum,notnull,verify
    title:html,optional
    { page_signature:html "" }
    { copyright_notice:html "" }
    show_modified_p:notnull
    public_p:notnull
    style:notnull
    creating:optional
    { audience:html "" }
    { background:html "" }
}
# modified by jwong on 10 Jul 2000 for ACS 3.4

set user_id [ad_maybe_redirect_for_registration]

set exception_count 0
set exception_text ""

if { ![exists_and_not_null title] } {
    append exception_text "<li>Your title was blank.  We need a title to generate the user interface."
    incr exception_count
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

# We're OK to insert.
if { ![info exists creating] } {
    set condition "presentation_id = :presentation_id"
    wp_check_authorization $presentation_id $user_id "write"
} else {
    if { [db_string pres_cnt_select "
        select count(*) from wp_presentations where presentation_id = :presentation_id" ]
       } {
	# Double-click!
	if { $style == "upload" } {
	    # User requested to upload a style - send to the style editor.
	    ad_returnredirect "style-edit?presentation_id=$presentation_id"
	} else {
	    ad_returnredirect "presentation-top?presentation_id=$presentation_id"
	}
	return
    }
#from user_groups 

    set condition ""
    set group_id [db_string nextval_select "select user_group_sequence.nextval from dual"]
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

set names [list presentation_id title copyright_notice show_modified_p page_signature creation_date creation_user style public_p audience background]
set values [list $presentation_id $title $copyright_notice $show_modified_p $page_signature sysdate $user_id $style $public_p $audience $background]

if { $condition == "" } {
    ad_user_group_add -group_id $group_id -approved_p "t" \
	    -existence_public_p "f" -multi_role_p "f" \
	    -new_member_policy "closed"  "wp" "WimpyPoint Presentation $title" 

    lappend names "group_id"
    lappend values $group_id
}

wp_try_dml_or_break [wp_prepare_dml "wp_presentations" $names $values $condition]

if { $condition == "" } {
    # We're inserting - create the first checkpoint.
    db_dml checkpoint_insert "insert into wp_checkpoints(presentation_id, checkpoint, wp_checkpoints_id) values(:presentation_id, 0, wp_checkpoints_seq.nextval)"
}

#}

db_release_unused_handles

if { $upload } {
    # User requested to upload a style - send to the style editor.
    ad_returnredirect "style-edit?presentation_id=$presentation_id"
} else {
    ad_returnredirect "presentation-top?presentation_id=$presentation_id"
}


