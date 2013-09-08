# /wp/presentation-delete.tcl
ad_page_contract  {
    Confirms the deletion of a presentation, requiring the user to enter his password.
    @cvs-id presentation-delete.tcl,v 3.0.12.12 2000/09/22 01:39:32 kevin Exp
    @author Jon Salz <jsalz@mit.edu>
    @creation-date  28 Nov 1999
    @param presentation_id the ID of the WP presentation to delete
} {
    presentation_id:naturalnum,notnull
} -errors {
    presentation_id:naturalnum { "$presentation_id" is an invalid entry for presentation ID. }
    presentation_id:notnull { Presentation ID cannot be null. }
}

# modified by jwong@arsdigita.com on 10 Jul 2000 for ACS 3.4 upgrade

set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $presentation_id $user_id "admin" 

db_1row wp_title_select "
select title from wp_presentations where presentation_id = :presentation_id"

set page_output "[wp_header_form "method=post action=presentation-delete-2" \
           [list "" "WimpyPoint"] [list "index?show_user=" "Your Presentations"] \
           [list "presentation-top?presentation_id=$presentation_id" "$title"] "Delete Presentation"]
[export_form_vars presentation_id]

Do you really want to delete $title?
All [db_string pres_cnt_select "select count(*) from wp_slides where presentation_id = :presentation_id"] slides will be permanently deleted.

<p>If you're really sure, please reenter your password.

<p><b>Password:</b> <input type=password size=20 name=password> <input type=submit value=\"Delete Presentation\">

</p>
[wp_footer]
"


doc_return  200 "text/html" $page_output
