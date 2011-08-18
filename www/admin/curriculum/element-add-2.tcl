# $Id: element-add-2.tcl,v 3.0.4.1 2000/04/28 15:08:32 carsten Exp $
#This file should be called element-add-2.tcl
set_the_usual_form_variables

# element_index, url, very_very_short_name, one_line_description, full_description, curriculum_element_id
set user_id [ad_get_user_id]


#Now check to see if the input is good as directed by the page designer

set exception_count 0
set exception_text ""


# we were directed to return an error for element_index
if {![info exists element_index] || [empty_string_p $element_index]} {
    incr exception_count
    append exception_text "<li>You did not enter a value for element_index.<br>"
} 

# we were directed to return an error for very_very_short_name
if {![info exists very_very_short_name] || [empty_string_p $very_very_short_name]} {
    incr exception_count
    append exception_text "<li>You did not enter a value for very_very_short_name.<br>"
} 
if {[string length $full_description] > 4000} {
    incr exception_count
    append exception_text "<LI>\"full_description\" is too long\n"
}

if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}

# So the input is good --
# Now we'll do the insertion in the curriculum table.
set db [ns_db gethandle]
if [catch {ns_db dml $db "insert into curriculum
      (curriculum_element_id, element_index, url, very_very_short_name, one_line_description, full_description)
      values
      ($curriculum_element_id, '$QQelement_index', '$QQurl', '$QQvery_very_short_name', '$QQone_line_description', '$QQfull_description')" } errmsg] {

    # Oracle choked on the insert
    if { [ database_to_tcl_string $db "select count(*) from curriculum where curriculum_element_id = $curriculum_element_id"] == 0 } { 

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
ad_returnredirect element-list.tcl
