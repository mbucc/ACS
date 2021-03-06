ad_page_contract {
    allow an admin to add or replace a user's portrait
    
    @cvs-id comment-modify-2.tcl,v 1.1.2.3 2000/08/25 23:56:48 minhngo Exp
    @author philg@mit.edu
    @author rory@arsdigita.com

    @param user_id
    @param portrait_comment
    @param return_url
} {
    user_id:naturalnum,notnull
    {portrait_comment ""}
    {return_url ""}
}

ad_maybe_redirect_for_registration

if { [empty_string_p $portrait_comment] } {
    set complete_portrait_comment [db_null]
} else {
    set complete_portrait_comment $portrait_comment
}

db_dml set_comment {
   update general_portraits 
      set portrait_comment = :complete_portrait_comment
    where on_what_id = :user_id
      and upper(on_which_table) = 'USERS'
}

if { [exists_and_not_null return_url] } {
    ad_returnredirect $return_url
} else {
    ad_returnredirect "index.tcl?[export_url_vars user_id]"
}
