# /www/admin/adserver/delete-adv-2.tcl

ad_page_contract {
    @param adv_key:notnull
    @author modified 07/13/200 by mchu@arsdigita.com
    @cvs-id delete-adv-2.tcl,v 3.1.6.5 2000/11/20 23:55:17 ron Exp
} {
    adv_key:notnull
}

set page_content "[ad_admin_header "Deleting $adv_key"]

<h2>Deleting $adv_key</h2>

a rarely used part of <a href=\"index\">AdServer Administration</a>

<hr>

<ul>
"

db_transaction {

    db_dml adv_delete_query_1 "delete from adv_log where adv_key = :adv_key"

    append page_content "<li>Deleted [db_resultrows] rows from adv_log.\n"

    db_dml adv_delete_query_2 "delete from adv_user_map where adv_key = :adv_key"
    
    append page_content "<li>Deleted [db_resultrows] rows from adv_user_map.\n"
    
    db_dml adv_delete_query_3 "delete from adv_categories where adv_key = :adv_key"
    
    append page_content "<li>Deleted [db_resultrows] rows from adv_categories.\n"
    
    db_dml adv_delete_query_4 "delete from adv_group_map where adv_key = :adv_key"
    
    append page_content "<li>Deleted [db_resultrows] rows from adv_group_map.\n"
    
    db_dml adv_delete_query_5 "delete from advs where adv_key = :adv_key"
    
    append page_content "<li>Deleted the ad itself from advs.\n"   
}

db_release_unused_handles

append page_content "</ul>

Transaction complete.

<p><a href=\"\">Return to adserver administration</a></p>

[ad_admin_footer]
"

doc_return 200 text/html $page_content




