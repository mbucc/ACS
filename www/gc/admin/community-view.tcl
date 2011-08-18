# $Id: community-view.tcl,v 3.1 2000/03/10 23:58:47 curtisg Exp $
set_the_usual_form_variables

# domain_id, n_postings, hairy AOLserver widgets for start_date, end_date

# pull out start_date, end_date (ANSI format that will make Oracle hurl)

ns_dbformvalue [ns_conn form] start_date date start_date
ns_dbformvalue [ns_conn form] end_date date end_date


set db [ns_db gethandle]
set selection [ns_db 1row $db "select * from ad_domains where domain_id = $domain_id"]
set_variables_after_query

append html "[ad_admin_header "Users who've made $n_postings postings between $start_date and $end_date"]

<h2>Users</h2>

[ad_context_bar_ws_or_index [list "/gc/" "Classifieds"] [list "index.tcl" "Classifieds Admin"] [list "domain-top.tcl?domain=$domain_id" $full_noun] "Users with $n_postings postings"]



<hr>

Here are the participants who've made at least $n_postings postings
between $start_date and $end_date...

<ul>

"

if { $n_postings < 2 } {
    set sql "select users.user_id, email, count(*) as how_many_posts
from classified_ads , users
where classified_ads.user_id = users.user_id
and domain_id = $domain_id
and posted >= to_date('$start_date','YYYY-MM-DD')
and posted <= to_date('$end_date','YYYY-MM-DD')
group by users.user_id, email
order by how_many_posts desc"
} else {
    set sql "select users.user_id, email, count(*) as how_many_posts
from classified_ads, users 
where classified_ads.user_id = users.user_id 
and domain_id = $domain_id
and posted >= to_date('$start_date','YYYY-MM-DD')
and posted <= to_date('$end_date','YYYY-MM-DD')
group by users.user_id, email
having count(*) >= $n_postings
order by how_many_posts desc"
}

set selection [ns_db select $db $sql]
set count 0

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append html "<li><a href=\"ads-from-one-user.tcl?[export_url_vars user_id domain_id]\">$email</a> ($how_many_posts)\n"
    incr count
}

if { $count == 0 } {
    append html "<li>None"
}
append html "</ul>

[ad_admin_footer]
"

ns_db releasehandle $db
ns_return 200 text/html $html
