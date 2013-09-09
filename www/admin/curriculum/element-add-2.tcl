# /www/admin/curriculum/element-add-2.tcl

ad_page_contract {
    This file should be called element-add-2.tcl

    @cvs-id element-add-2.tcl,v 3.2.2.8 2001/01/10 17:05:25 khy Exp
    @author unknown
    @param element_index The element to edit.
    @param url The url for this element
    @param very_very_short_name A name used on the curriculum bar
    @param one_line_description A one line description of this item.
    @param full_description A longer (less than 4001 characters) description
    @param curriculum_element_id The curriculum ID
} {
    element_index:integer,notnull 
    url:notnull 
    very_very_short_name:notnull 
    one_line_description:notnull
    full_description:html
    curriculum_element_id:notnull,naturalnum,verify
}


set exception_count 0
set exception_text ""

# we were directed to return an error for element_index
if {[string length $full_description] > 4000} {
    incr exception_count
    append exception_text "<LI>\"full_description\" is too long\n"
}

if {![philg_url_valid_p $url]} {
    incr exception_count
    append exception_text "<LI>\"URL\" is invalid.  For external URLs, be 
                           sure to add 'http://'\n"
}

if {[catch {ns_httpget $url 10} url_content]} {
    incr exception_count
    append exception_text "<LI>\"URL\" is unreachable at this time or 
                           does not exist\n"
}





if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}


# So the input is good --
# Now we'll do the insertion in the curriculum table.

if [catch {db_dml add_new_curr_item "insert into curriculum
      (curriculum_element_id, element_index, url, very_very_short_name, one_line_description, full_description)
      values
      (:curriculum_element_id, :element_index, :url, :very_very_short_name, :one_line_description, :full_description)" } errmsg] {

    # Oracle choked on the insert
    if { [ db_string checkifworked "select count(*) from curriculum where curriculum_element_id = :curriculum_element_id"] == 0 } { 

    # there was an error with the insert other than a duplication
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
} 
ad_returnredirect element-list
