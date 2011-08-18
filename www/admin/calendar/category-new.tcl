# $Id: category-new.tcl,v 3.0.4.1 2000/04/28 15:08:26 carsten Exp $
set_the_usual_form_variables

# category_new


set exception_count 0
set exception_text ""

if { ![info exists category_new] || [empty_string_p $category_new] } {
    incr exception_count
    append exception_text "<li>Please enter a category."
}

if {$exception_count > 0} { 
    ad_return_complaint $exception_count $exception_text
    return
}

set db [ns_db gethandle]

if [catch {
    # add the new category
    ns_db dml $db "begin transaction"

    ns_db dml $db "insert into calendar_categories (category) select '$QQcategory_new' from dual where 0 = (select count(category) from calendar_categories where category='$QQcategory_new')" 

    # if a new row was not inserted, make sure that the exisitng  category entry is enabled
    if { [ns_ora resultrows $db] == 0 } {
	ns_db dml $db "update calendar_categories set enabled_p = 't' where category = '$QQcategory_new'"
    } 

    ns_db dml $db "end transaction"
} errmsg] {

    # there was some other error with the category
    ad_return_error "Error inserting category" "We couldn't insert your category. Here is what the database returned:
<p>
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>
"
return
}


ad_returnredirect "category-one.tcl?category=[ns_urlencode $category_new]"

