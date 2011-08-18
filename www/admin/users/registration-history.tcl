# $Id: registration-history.tcl,v 3.1 2000/03/09 00:01:36 scott Exp $
# 
# /admin/users/registration-history.tcl
#
# by philg@mit.edu, January 1999
# (substantially modified on October 30, 1999 to turn it into a graph)
# 
# displays a table of number of registrations by month
# 


append whole_page "[ad_admin_header "User Registration History"]

<h2>Registration History</h2>

[ad_admin_context_bar [list "index.tcl" "Users"] "Registration History"]

<hr>

<blockquote>

"

set db [ns_db gethandle]

# we have to query for pretty month and year separately because Oracle pads
# month with spaces that we need to trim

set selection [ns_db select $db "select to_char(registration_date,'YYYYMM') as sort_key, rtrim(to_char(registration_date,'Month')) as pretty_month, to_char(registration_date,'YYYY') as pretty_year, count(*) as n_new
from users
where registration_date is not null
group by to_char(registration_date,'YYYYMM'), to_char(registration_date,'Month'), to_char(registration_date,'YYYY')
order by 1"]

set accumulated_sublists [list]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    set drilldown_url "action-choose.tcl?registration_during_month=$sort_key"
    lappend accumulated_sublists [list $pretty_month $pretty_year $n_new $drilldown_url]
}

ns_db releasehandle $db

append whole_page "
[gr_sideways_bar_chart -non_percent_values_p "t" -compare_non_percents_across_categories "t" -display_scale_p "f" -display_values_p "t" $accumulated_sublists]

</blockquote>

[ad_admin_footer]
"
ns_return 200 text/html $whole_page
