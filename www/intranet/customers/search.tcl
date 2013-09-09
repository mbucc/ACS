# /www/intranet/customers/search.tcl

ad_page_contract {
    Searches through intranet customers.

    @param keywords what we're searching for
    @param target where to link the results to

    @author mbryzek@arsdigita.com
    @creation-date Sat May 20 23:11:34 2000

    @cvs-id search.tcl,v 3.2.2.8 2000/09/22 01:38:28 kevin Exp

} {
    { keywords:trim "" }
    { target "view" }
}

if { [empty_string_p $target] } {
    set target "view"
}

if { [empty_string_p $keywords] } {
    # Show all customers
    ad_returnredirect index
    return
}

# Get target ready to use
if { [regexp {\?} $target] } {
    append target "&"
} else {
    append target "?"
}

set upper_keywords [string toupper $keywords]
# Convert * to oracle wild card
regsub -all {\*} $upper_keywords {%} upper_keywords
set upper_keywords "%$upper_keywords%"

# Search all customers
set sql "select ug.group_id, ug.group_name
           from im_customers c, user_groups ug
          where ug.group_id = c.group_id
            and upper(ug.group_name) like :upper_keywords
          order by lower(ug.group_name)"

set number 0
set results ""
set last_employee_p ""
db_foreach customer_search $sql  {
    incr number    
    append results "  <li> <a href=$target[export_url_vars group_id]>$group_name</a>\n"
}

db_release_unused_handles

if { [empty_string_p $results] } {
    set page_body "
<blockquote>
<b>No customers found.</b>
Look at all <a href=index>customers</a>
</blockquote>
"
} else {
    append results "</ul>\n"
    set page_body "
<b>[util_commify_number $number] [util_decode $number 1 "customer was" "customers were"] found</b>
<ul>
$results
</ul>

"
}

set page_title "Customer Search"
set context_bar [ad_context_bar_ws [list index "Customers"] Search]

doc_return  200 text/html [im_return_template]
