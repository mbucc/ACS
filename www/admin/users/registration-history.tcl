ad_page_contract {
    @cvs-id registration-history.tcl,v 3.2.2.3.2.3 2000/09/22 01:36:20 kevin Exp
 
    /admin/users/registration-history.tcl

    by philg@mit.edu, January 1999
    (substantially modified on October 30, 1999 to turn it into a graph)
 
    displays a table of number of registrations by month
} {
}
 

append whole_page "[ad_admin_header "User Registration History"]

<h2>Registration History</h2>

[ad_admin_context_bar [list "index.tcl" "Users"] "Registration History"]

<hr>

<blockquote>

"



# we have to query for pretty month and year separately because Oracle pads
# month with spaces that we need to trim

set sql "select to_char(registration_date,'YYYYMM') as sort_key, rtrim(to_char(registration_date,'Month')) as pretty_month, to_char(registration_date,'YYYY') as pretty_year, count(*) as n_new
from users
where registration_date is not null
group by to_char(registration_date,'YYYYMM'), to_char(registration_date,'Month'), to_char(registration_date,'YYYY')
order by 1"

set accumulated_sublists [list]

db_foreach users_pretty_number_new $sql {
    set drilldown_url "action-choose.tcl?registration_during_month=$sort_key"
    lappend accumulated_sublists [list $pretty_month $pretty_year $n_new $drilldown_url]
}


append whole_page "
[gr_sideways_bar_chart -non_percent_values_p "t" -compare_non_percents_across_categories "t" -display_scale_p "f" -display_values_p "t" $accumulated_sublists]

</blockquote>

[ad_admin_footer]
"


doc_return  200 text/html $whole_page



