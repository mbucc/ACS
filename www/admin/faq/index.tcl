# admin/faq/index.tcl
#
# presents a list of all the FAQs and gives option to add a FAQ
#
# by dh@arsdigita.com,   Created on Dec 20, 1999
#
# $Id: index.tcl,v 3.0.4.1 2000/03/16 03:15:52 dh Exp $
#-----------------------------------------------------------

set db [ns_db gethandle]

set selection [ns_db select $db "
select f.faq_name, 
       f.faq_id,
       f.scope,
       count(fqa.entry_id) as number_of_questions
from   faqs f, faq_q_and_a fqa
where  f.faq_id = fqa.faq_id(+)
group by f.faq_name, f.faq_id, f.scope
order  by faq_name" ]

set faqs_list ""
set faq_count 0
set old_faq_id ""

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr faq_count
    
    append faqs_list "<li><a href=one?faq_id=$faq_id>$faq_name</a> - [expr {$number_of_questions==0?"No Questions":"$number_of_questions question(s)"}], [expr {$scope=="group"?"Private":"Public"}] \n"
	
}

ns_db releasehandle $db

if { $faq_count == 0 } {
    set faqs_list "There are no FAQs in the database."
}
    
# --serve the page ----------------------------------

ns_return 200 text/html "
[ad_admin_header "Admin: FAQs"]

<h2>Admin: FAQs</h2>

[ad_admin_context_bar "FAQs"]

<hr>
Documentation: <a href=/doc/faq>/doc/faq</a></br>
User pages: <a href=/faq/ >/faq</a>

<p>

<ul>
$faqs_list

<p>
<li><a href=faq-add>Add</a> a new FAQ.
</ul>
[ad_admin_footer]
"




