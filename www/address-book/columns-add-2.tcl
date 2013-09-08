ad_page_contract {
    
    @param column_name
    @param extra_select
    @param pretty_name
    @param sort_order

    @cvs-id columns-add-2.tcl,v 3.1.2.5 2000/10/10 14:46:34 luke Exp
    This file should be called columns-add-2.tcl
} {
    column_name:notnull
    extra_select
    pretty_name:notnull
    sort_order:notnull
}

set user_id [ad_verify_and_get_user_id]


#Now check to see if the input is good as directed by the page designer

set exception_count 0
set exception_text ""

if {[string length $extra_select] > 4000} {
    incr exception_count
    append exception_text "<LI>\"extra_select\" is too long\n"
}

if {[string length $pretty_name] > 4000} {
    incr exception_count
    append exception_text "<LI>\"pretty_name\" is too long\n"
}

if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}

# So the input is good --
# Now we'll do the insertion in the address_book_viewable_columns table.

if [catch {db_dml adress_book_insert_new_column "insert into 
      address_book_viewable_columns
      (column_name, extra_select, pretty_name, sort_order)
      values
      (:column_name, :extra_select, :pretty_name, :sort_order)" } errmsg] {

# Oracle choked on the insert    

ad_return_error "Error in insert" "We were unable to do your insert in the database. 

Here is the error that was returned:
<p>
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>"
return
}
db_release_unused_handles

ad_returnredirect columns-list.tcl
