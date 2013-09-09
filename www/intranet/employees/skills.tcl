# /www/intranet/employees/skills.tcl

ad_page_contract {
    
    @param none
 
    @cvs-id skills.tcl,v 3.5.6.6 2000/09/22 01:38:31 kevin Exp
} {
    
}

set page_title "Special Skills"
set context_bar [ad_context_bar_ws [list ./ "Employees"] $page_title]

set page_body "
<p>Employees who wrote something under \"special skills\":

<ul>
"


set skill_set_sql "
select user_id, last_name, first_names, skills 
from im_employees_active
where skills is not null
order by last_name, first_names"


db_foreach skill_set $skill_set_sql {
    append page_body "<p><li><a href=../users/view?[export_url_vars user_id]>$last_name, $first_names</a>
<ul>
$skills
</ul>
"
}
append page_body "</ul>\n"



doc_return  200 text/html [im_return_template]


