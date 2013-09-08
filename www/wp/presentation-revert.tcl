# /wp/presentation-revert.tcl

ad_page_contract {
    Reverts a presentation to a previous version, after confirming.

    @param presentation_id id of the prsentation to revert
    @param checkpoint checkpoint to which to revert

    @creation-date  28 Nov 1999
    @author Jon Salz <jsalz@mit.edu>
    @cvs-id presentation-revert.tcl,v 3.0.12.6 2000/09/22 01:39:33 kevin Exp
} {
    presentation_id:naturalnum,notnull
    checkpoint:naturalnum,notnull
}

set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $presentation_id $user_id "admin"

db_1row wp_title_select "
select title from wp_presentations where presentation_id = :presentation_id"

db_1row wp_sel_ck_pt_info "
    select description, TO_CHAR(checkpoint_date, 'Month DD, YYYY, HH:MI A.M.') checkpoint_date
    from wp_checkpoints
    where checkpoint = :checkpoint
    and presentation_id = :presentation_id
"



doc_return  200 text/html "[wp_header_form "action=presentation-revert-2" \
           [list "" "WimpyPoint"] [list "index?show_user=" "Your Presentations"] \
           [list "presentation-top?presentation_id=$presentation_id" "$title"] "Revert Presentation"]
[export_form_vars presentation_id checkpoint]

<p>Do you really want to revert $title to the version entitled &quot;$description,&quot; made
at $checkpoint_date? You will permanently lose any change made to your presentation since then.

<p><center>
<input type=button value=\"No, I want to cancel.\" onClick=\"location.href='presentation-top?presentation_id=$presentation_id'\">
<spacer type=horizontal size=50>
<input type=submit value=\"Yes, proceed.\">
</p></center>

[wp_footer]
"

