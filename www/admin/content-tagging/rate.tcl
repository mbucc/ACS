# File: /www/admin/content-tagging/rate.tcl
ad_page_contract {
    
    Adds tag and word or updates tag of an existing word.
    
    @param word
    @param tag
    @param todo

    @author unknown
    @cvs-id rate.tcl,v 3.1.6.5 2000/07/21 03:56:33 ron Exp
} {
    word:notnull
    tag:notnull,integer
    todo:notnull
}
set user_id [ad_get_user_id]

if { $todo == "create" } {   

    db_dml insert_tag "insert into content_tags
(word, tag, creation_user, creation_date)
values
(:word, :tag, :user_id, sysdate)"
} else {
   
    if { $tag == 0 } {
	db_dml update_tag "delete from content_tags where word=:word"
    } else {
	db_dml update_tag "update content_tags set tag = :tag where word = :word"
    }
}

db_release_unused_handles
ad_returnredirect "index.tcl"


