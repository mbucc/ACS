# /www/admin/gc/community-view.tcl
ad_page_contract {
    Displays users who have posted at least a certain number of times in a given time period.
    
    @param domain_id which domain
    @param n_postings how many postings
    
    @author philg@mit.edu
    @cvs_id community-view.tcl,v 3.3.2.6 2000/09/22 01:35:18 kevin Exp
} {
    domain_id:integer
    n_postings:integer
    start_date:array,date
    end_date:array,date
}

set d_start $start_date(date)
set d_end $end_date(date)

db_1row domain_info "select full_noun from ad_domains where domain_id = :domain_id"

set page_content "[ad_admin_header "Users who've made $n_postings postings between $d_start and $d_end"]

<h2>Users</h2>

[ad_admin_context_bar [list "index.tcl" "Classifieds"] [list "domain-top.tcl?domain_id=$domain_id" $full_noun] "Users with $n_postings postings"]

<hr>

Here are the participants who've made at least $n_postings postings
between $d_start and $d_end...

<ul>

"

if { $n_postings < 2 } {
    set sql "select users.user_id, email, count(*) as how_many_posts
from classified_ads , users
where classified_ads.user_id = users.user_id
and domain_id = :domain_id
and posted >= to_date(:d_start,'YYYY-MM-DD')
and posted <= to_date(:d_end,'YYYY-MM-DD')
group by users.user_id, email
order by how_many_posts desc"
} else {
    set sql "select users.user_id, email, count(*) as how_many_posts
from classified_ads, users 
where classified_ads.user_id = users.user_id 
and domain_id = :domain_id
and posted >= to_date(:d_start,'YYYY-MM-DD')
and posted <= to_date(:d_end,'YYYY-MM-DD')
group by users.user_id, email
having count(*) >= :n_postings
order by how_many_posts desc"
}

set count 0

db_foreach classified_ads $sql {

    append page_content "<li><a href=\"ads-from-one-user?[export_url_vars user_id domain_id]\">$email</a> ($how_many_posts)\n"
    incr count
}

if { $count == 0 } {
    append page_content "<li>None"
}
append page_content "</ul>

[ad_admin_footer]
"


doc_return  200 text/html $page_content
