# /wp/outline-adjust-2.tcl
ad_page_contract {
    Saves changes made to the outline.
    @cvs-id outline-adjust-2.tcl,v 3.1.6.8 2000/09/12 03:51:40 dennis Exp
    @creation-date  28 Nov 1999
    @author Jon Salz <jsalz@mit.edu>
    @param presentation_id is the ID of the presentation
    @param context_break_after checkbox vars
    @param include_in_outline checkbox vars
} {
    presentation_id:naturalnum,notnull
    { context_break_after:naturalnum,multiple "" }
    { include_in_outline:naturalnum,multiple "" }
}
# modified by jwong@arsdigita.com on 11 Jul 2000 for ACS 3.4 upgrade

set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $presentation_id $user_id "write"

if [empty_string_p $context_break_after] {
    set context_break_sql "'f'"
} else {
    set context_break_sql "decode((select 1 
                                     from dual 
                                    where slide_id in ([join $context_break_after ","])), 1, 't', 'f')"
}

if [empty_string_p $include_in_outline] {
    set include_in_outline_sql "'f'"
} else {
    set include_in_outline_sql "decode((select 1 
                                          from dual 
                                         where slide_id in ([join $include_in_outline ","])), 1, 't', 'f')"
}

db_dml slides_update "
    update wp_slides
       set context_break_after_p = $context_break_sql,
           include_in_outline_p = $include_in_outline_sql
    where presentation_id = :presentation_id"

ad_returnredirect "presentation-top.tcl?presentation_id=$presentation_id"
