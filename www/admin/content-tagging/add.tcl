# File: /www/admin/content-tagging/add.tcl
ad_page_contract {    

    adds a bunch of words to the database (or updates their tags if they 
    are already in Oracle)
    @param words
    @param tag:notnull
    
    @author unknown
    @cvs-id add.tcl,v 3.1.6.6 2000/07/21 03:56:32 ron Exp
} {
    words
    tag:notnull,integer
}

set user_id [ad_get_user_id]

# bash the words down to lowercase
set words [ns_striphtml [string tolower $words ]]
# turn them into a standard Tcl list
regsub -all {[^A-z ]+} $words " " words


foreach word $words {
    # insert if not present 
    db_dml insert_tag "insert into content_tags
    (word, tag, creation_user, creation_date)
    select :word, :tag, :user_id, sysdate
    from dual 
    where 0 = (select count(*) from content_tags where word = :word)" 
    
    set n_rows_inserted [db_resultrows]
    
    if { $n_rows_inserted == 0 } {
	# it was already in the db
	db_dml update_tag "update content_tags set tag = $tag where word = :word" 
	
    }
}

db_release_unused_handles
ad_returnredirect "index.tcl"












