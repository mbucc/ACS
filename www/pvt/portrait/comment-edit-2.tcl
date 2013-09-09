# /www/pvt/portrait/comment-edit-2.tcl

ad_page_contract {
    writes portrait comment to db
 
    @author mbryzek@arsdigita
    @creation-date Thu Jun 22 16:11:00 2000
    @cvs-id comment-edit-2.tcl,v 3.2.2.3 2000/08/27 19:52:10 mbryzek Exp
} {
    { portrait_comment:html "" }
    { return_url "index" }
}

set user_id [ad_maybe_redirect_for_registration]

if { [string length $portrait_comment] > 4000 } {
    ad_return_complaint 1 "Your portrait comment can only be 4000 characters long."
    return
}

db_dml portrait_comment_update "
update general_portraits
   set portrait_comment = :portrait_comment 
 where on_what_id = :user_id
   and on_which_table = 'USERS'"

db_release_unused_handles

ad_returnredirect $return_url
