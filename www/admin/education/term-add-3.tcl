#
# /www/admin/education/term-add-3.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# This page inserts the new term into the database
#

ad_page_variables {
    term_id
    term_name
    start_date
    end_date
}


#make sure we got all of the correct input
set exception_text ""
set exception_count 0

if {[empty_string_p $term_name]} {
    incr exception_count
    append exception_text "<li>You must provide a term name"
}

if {[empty_string_p $term_id]} {
    incr exception_count
    append exception_text "<li>You must provide a term id"
}

if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}


set db [ns_db gethandle]

#check and make sure it was not a double click...if it was, redirect them to the terms page
if {[database_to_tcl_string $db "select count(term_id) from edu_terms where term_id = $term_id"] > 0} {
    ad_returnredirect terms.tcl
    return   
}


#now that the input is taken care of, lets insert the term

if [catch { ns_db dml $db "insert into edu_terms (term_id, term_name, start_date, end_date)
                     values
                     ($term_id, '$QQterm_name', to_date('$start_date', 'YYYY-MM-DD'), to_date('$end_date', 'YYYY-MM-DD'))"} errmsg] {
			 # something went wrong
			 ad_return_error "database choked" "The database choked on your insert:
			 <blockquote>
			 <pre>
			 $errmsg
			 </pre>
			 </blockquote>
			 You can back up, edit your data, and try again"
			 return
		     }

# insert went OK

ns_db releasehandle $db

ad_returnredirect "terms.tcl"

