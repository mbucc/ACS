# /faq/admin/swap.tcl
# 

ad_page_contract {
    Swaps a faq entry with the following entry

    @author dh@arsdigita.com
    @creation-date 12/19/99
    @cvs-id swap.tcl,v 3.3.2.6 2000/07/23 20:15:45 luke Exp

    Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
    the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
    group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
    group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)
} {
    entry_id:integer,notnull
    faq_id:integer,notnull
    scope:optional
    group_id:integer,optional
}


ad_scope_error_check

faq_admin_authorize $faq_id


# get the sort_key for this entry_id, faq_id 
db_1row faq_sortkey_get "
select sort_key as current_sort_key, faq_id
from   faq_q_and_a 
where  entry_id = :entry_id"

db_transaction {
    # I want the next sort_key
    db_1row faq_nextsortkey_get "
    select entry_id as next_entry, sort_key as next_sort_key
    from faq_q_and_a
    where sort_key = (select min(sort_key)
    from faq_q_and_a 
    where sort_key > :current_sort_key
    and faq_id = :faq_id)
    and faq_id = :faq_id
    for update"

    db_dml faq_sortkey_update "
    update faq_q_and_a
    set sort_key = :next_sort_key
    where entry_id = :entry_id"

    db_dml faq_sortkey_update "
    update faq_q_and_a
    set sort_key = :current_sort_key
    where entry_id = :next_entry"
}

db_release_unused_handles

ad_returnredirect "one?[export_url_vars faq_id]" 

