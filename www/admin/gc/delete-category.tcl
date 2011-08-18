# $Id: delete-category.tcl,v 3.1.2.1 2000/04/28 15:09:02 carsten Exp $
set_the_usual_form_variables

# domain_id, primary_category

set db [gc_db_gethandle]

ns_db dml $db "delete from ad_categories 
where domain_id = $domain_id
and primary_category = '$QQprimary_category'"

ad_returnredirect "manage-categories-for-domain.tcl?domain_id=$domain_id"
