# $Id: add.tcl,v 3.0.4.1 2000/04/28 15:08:30 carsten Exp $
# adds a bunch of words to the database (or updates their tags if they 
# are already in Oracle)

set_the_usual_form_variables

# words, tag

set db [ns_db gethandle]

set user_id [ad_get_user_id]

# bash the words down to lowercase
set words [ns_striphtml [string tolower $words ]]
# turn them into a standard Tcl list
regsub -all {[^A-z ]+} $words " " words

foreach word $words {
    # insert if not present 
    ns_db dml $db "insert into content_tags
(word, tag, creation_user, creation_date)
select '$word', $tag, $user_id, sysdate
from dual 
where 0 = (select count(*) from content_tags where word = '$word')"
    set n_rows_inserted [ns_ora resultrows $db]
    if { $n_rows_inserted == 0 } {
	# it was already in the db
	ns_db dml $db "update content_tags set tag = $tag where word = '$word'"
    }
}

ad_returnredirect "index.tcl"

