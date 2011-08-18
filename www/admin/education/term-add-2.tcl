#
# /www/admin/education/term-add-2.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page confirms the information concerning a new term
#

ad_page_variables {
    term_name
    {ColValue.end%5fdate.month ""}
    {ColValue.end%5fdate.day ""}
    {ColValue.end%5fdate.year ""}
    {ColValue.start.month ""}
    {ColValue.start%5fdate.day ""}
    {ColValue.start%5fdate.year ""}
}


set db [ns_db gethandle]

set exception_count 0
set exception_text ""

if {![info exists term_name] || [empty_string_p $term_name]} {
    append exception_text "<li>You must provide a name for the term."
    incr exception_count
}


# put together due_date, and do error checking

set form [ns_getform]

# ns_dbformvalue $form start_date date start_date will give an error
# message if the day of the month is 08 or 09 (this octal number problem
# we've had in other places).  So I'll have to trim the leading zeros
# from ColValue.start%5fdate.day and stick the new value into the $form
# ns_set.

set "ColValue.start%5fdate.day" [string trimleft [set ColValue.start%5fdate.day] "0"]
ns_set update $form "ColValue.start%5fdate.day" [set ColValue.start%5fdate.day]

if [catch  { ns_dbformvalue $form start_date date start_date} errmsg ] {
    incr exception_count
    append exception_text "<li>The date was specified in the wrong format.  The date should be in the format Month DD YYYY.\n"
} elseif { [string length [set ColValue.start%5fdate.year]] != 4 } {
    incr exception_count
    append exception_text "<li>The year needs to contain 4 digits.\n"
} 


set "ColValue.end%5fdate.day" [string trimleft [set ColValue.end%5fdate.day] "0"]
ns_set update $form "ColValue.end%5fdate.day" [set ColValue.end%5fdate.day]

if [catch  { ns_dbformvalue $form end_date date end_date} errmsg ] {
    incr exception_count
    append exception_text "<li>The date was specified in the wrong format.  The date should be in the format Month DD YYYY.\n"
} elseif { [string length [set ColValue.end%5fdate.year]] != 4 } {
    incr exception_count
    append exception_text "<li>The year needs to contain 4 digits.\n"
} elseif {[database_to_tcl_string $db "select round(sysdate) - to_date('$end_date','YYYY-MM-DD') from dual"] > 1} {
    incr exception_count
    append exception_text "<li>The end date must be in the future."
}

if {$exception_count == 0} {
    if {[database_to_tcl_string $db "select to_date('$start_date', 'YYYY-MM-DD') - to_date('$end_date','YYYY-MM-DD') from dual"] > 1} {
	incr exception_count
	append exception_text "<li>The end date must be after the start date."
    }
}

if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}



if {[empty_string_p $start_date]} {
    set actual_start_date "No Start Date"
} else {
    set actual_start_date [util_AnsiDatetoPrettyDate $start_date]
}

if {[empty_string_p $start_date]} {
    set actual_end_date "Does Not End"
} else {
    set actual_end_date [util_AnsiDatetoPrettyDate $end_date]
}


#set the term_id on this page so we avoid double-click errors
set term_id [database_to_tcl_string $db "select edu_term_id_sequence.nextval from dual"]



set return_string "
[ad_admin_header "[ad_system_name] Administration - Add a Term"]
<h2>Add a Term</h2>

[ad_context_bar_ws [list "/admin/" "Admin Home"] [list "" "Education Administration"] "Add a Term"]

<hr>
<blockquote>

Are you sure you wish to add this term?  Once you add it, you will not
be able to remove it (but you will be able to edit it).

<p>
<table>

<tr><th align=left>Term Name:
<td>$term_name
</tr>

<tr><th align=left>Date term begins: 
<td>$actual_start_date
</tr>

<tr><th align=left>Date term ends:
<td>$actual_end_date
</tr>
</table>

<form method=post action=\"term-add-3.tcl\">
<input type=submit value=\"Create Term\">
[export_form_vars term_name start_date end_date term_id]
</form>

</blockquote>
[ad_admin_footer]
"


ns_db releasehandle $db

ns_return 200 text/html $return_string








