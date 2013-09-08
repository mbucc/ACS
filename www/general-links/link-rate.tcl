# File: /general-links/link-rate.tcl

ad_page_contract {
    Updates a link's rating.

    @param link_id the ID of the link to rate
    @param rating the rating of the link

    @author  tzumainn@arsdigita.com
    @creation-date 1 February 2000
    @cvs-id link-rate.tcl,v 3.1.6.4 2000/07/21 04:00:04 ron Exp
} {
    link_id:naturalnum,notnull
    rating:naturalnum,notnull
}

#check for the user cookie
set user_id [ad_maybe_redirect_for_registration]


db_transaction {

db_dml update_link_rating "update general_link_user_ratings set rating = :rating where user_id = :user_id and link_id = :link_id"
if { [db_resultrows] == 0 } {
    db_dml insert_link_rating "insert into general_link_user_ratings (user_id, link_id, rating)
    select :user_id, :link_id, :rating
    from dual
    where 0 = (select count(*) from general_link_user_ratings
               where user_id = :user_id
               and link_id = :link_id)
    "
}

}

db_release_unused_handles

ad_returnredirect "one-link?[export_url_vars link_id]"
