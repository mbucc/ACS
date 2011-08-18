# domain-add-2.tcl
# Create new domain.
# Written by jsc@arsdigita.com.

ad_page_variables {full_name short_name}

set db [ns_db gethandle]

ns_db dml $db "insert into wm_domains (short_name, full_domain_name)
 values ('$QQshort_name', '$QQfull_name')"

ad_returnredirect "index.tcl"