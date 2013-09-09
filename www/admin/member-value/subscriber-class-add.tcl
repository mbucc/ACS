# /www/admin/member-value/subscriber-class-add.tcl

ad_page_contract {
    Form to add a new subscriber class to mv_monthly_rates table.

    @author tony@arsdigita.com
    @creation-date Tue Jul 11 20:47:10 2000
    @cvs-id subscriber-class-add.tcl,v 1.1.2.3 2000/09/22 01:35:32 kevin Exp

} {

}

set page_content "[ad_admin_header "Add subscriber class for [ad_system_name]"]

<h2>Add subscriber class</h2>

[ad_admin_context_bar [list "" "Member Value"] "Add Subscriber Class"]

<hr>

<form method=GET action=\"subscriber-class-add-2\">

[im_format_number 1] Subscriber class name:
<input type=text size=30 name=subscriber_class [export_form_value subscriber_class]>

<p>[im_format_number 2] Rate:
<input type=text size=30 name=rate [export_form_value rate]>

<p>[im_format_number 3] Currency:
<input type=text size=30 name=currency [export_form_value currency]>

<p><center><input type=submit value=\"Add\">
</form>

[ad_admin_footer]
"

doc_return  200 text/html $page_content
