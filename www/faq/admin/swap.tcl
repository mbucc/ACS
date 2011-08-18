# /faq/admin/swap.tcl
# 
# Swaps a faq entry with the following entry
#
# by dh@arsdigita.com, created on 12/19/99
#
# $Id: swap.tcl,v 3.0.4.2 2000/04/28 15:10:26 carsten Exp $
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

ad_page_variables {entry_id faq_id}

set_the_usual_form_variables 0
# maybe scope, maybe scope related variables (group_id)

ad_scope_error_check
set db [ns_db gethandle]
faq_admin_authorize $db $faq_id

# get the sort_key for this entry_id, faq_id 
set selection [ns_db 1row $db "
select sort_key as current_sort_key, faq_id
from   faq_q_and_a 
where  entry_id = $entry_id"]
set_variables_after_query


ns_db dml $db "begin transaction"

# I want the next sort_key 
set sql "
select entry_id as next_entry, sort_key as next_sort_key
from faq_q_and_a
where sort_key = (select min(sort_key)
                  from faq_q_and_a 
                  where sort_key > $current_sort_key
                  and faq_id = $faq_id)
and faq_id = $faq_id
for update "

set selection [ns_db 1row $db $sql]
set_variables_after_query

ns_db dml $db "
update faq_q_and_a
set sort_key = $next_sort_key
where entry_id = $entry_id"

ns_db dml $db "
update faq_q_and_a
set sort_key = $current_sort_key
where entry_id = $next_entry"

ns_db dml $db "end transaction"

ns_db releasehandle $db

ad_returnredirect "one?[export_url_scope_vars faq_id]" 


