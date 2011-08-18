#
# /www/admin/education/term-edit-2.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page allows the admin to edit information about the given term
#

ad_page_variables {
    term_id
    term_name
    {ColValue.end%5fdate.month ""}
    {ColValue.end%5fdate.day ""}
    {ColValue.end%5fdate.year ""}
    {ColValue.start.month ""}
    {ColValue.start%5fdate.day ""}
    {ColValue.start%5fdate.year ""}
}


#This expects term_name, start_date_year, start_date_month, start_date_day,
#end_date_year, end_date_month, end_date_year and term_id

set db [ns_db gethandle]

set exception_count 0
set exception_text ""


if {[empty_string_p $term_name]} {
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



set return_string "
[ad_admin_header "[ad_system_name] Administration - Edit Term"]
<h2>Edit Term</h2>

[ad_context_bar_ws [list "/admin/" "Admin Home"] [list "" "Education Administration"] "Edit Term"]

<hr>
<blockquote>
Are you sure you wish to edit this term?
<br><br>
<table>

<tr><th align=left>Term Name
<td>$term_name
</tr>

<tr><th align=left>Date term begins: 
<td>$actual_start_date
</tr>

<tr><th align=left>Date term ends:
<td>$actual_end_date
</tr>
</table>

<form method=post action=\"term-edit-3.tcl\">
<input type=submit value=\"Create Term\">
[export_form_vars term_name start_date end_date term_id]
</form>

</blockquote>
[ad_admin_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string









