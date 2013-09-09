#/admin/static/exclusion/add-2.tcl

ad_page_contract {
    inserts a row into the static_page_index_exclusion table    
    
    @author philg@mit.edu 
    @creation-date November 6, 1999
    @cvs-id add-2.tcl,v 3.1.6.4 2000/07/25 04:39:36 avni Exp
} {
    match_field
    like_or_regexp
    pattern:notnull
    pattern_comment
}

db_dml static_exclusion_insert "insert into static_page_index_exclusion
(exclusion_pattern_id, match_field, like_or_regexp, pattern, pattern_comment, creation_user, creation_date)
values
(static_page_index_excl_seq.nextval, :match_field, :like_or_regexp, :pattern, :pattern_comment, [ad_verify_and_get_user_id], sysdate)"

db_release_unused_handles

ad_returnredirect "/admin/static/"
