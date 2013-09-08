# /www/admin/curriculum/element-edit-2.tcl

ad_page_contract {
    This file should be called element-edit-2.tcl

    @author unknown
    @cvs-id element-edit-2.tcl,v 3.2.2.8 2000/07/27 22:55:32 avni Exp
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
    curriculum_element_id
}

set user_id [ad_get_user_id]

set exception_count 0
set exception_text ""

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
# Now we'll do the update of the curriculum table.

if [catch {db_dml update_curric_element "update curriculum 
      set element_index = :element_index, url = :url, very_very_short_name = :very_very_short_name, one_line_description = :one_line_description, full_description = :full_description
      where curriculum_element_id = :curriculum_element_id" } errmsg] {

	  # Oracle choked on the update
	  ad_return_error "Error in update" "We were unable to do your update in the database. 
Here is the error that was returned:
<p>
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>"
    return
}

ad_returnredirect element-list
