# /www/bboard/admin-update-primary-maintainer-2.tcl
ad_page_contract {
    Changes the maintainer of a forum

    @cvs-id admin-update-primary-maintainer-2.tcl,v 3.0.12.4 2000/09/22 01:36:46 kevin Exp
} {
    topic_id:integer,notnull
    user_id_from_search:integer,notnull
}

# -----------------------------------------------------------------------------
 
if  {[bboard_get_topic_info] == -1} {
    return
}

if {[bboard_admin_authorization] == -1} {
    return
}

db_dml bboard_update "
update bboard_topics 
set primary_maintainer_id = :user_id_from_search 
where topic_id = :topic_id"

doc_return  200 text/html "
[ad_admin_header "Updated primary maintainer for $topic"]

<h2>Primary maintainer updated</h2>

for \"$topic\"

<hr>

New Maintainer:  [db_string maintainer "
select first_names || ' ' || last_name || ' ' || '(' || email || ')' 
from users 
where user_id = :user_id_from_search"]

[ad_admin_footer]
"

