# /www/intranet/employees/admin/qualification-list.tcl

ad_page_contract {

    @author teadams@arsdigita.com
    @creation-date April 24, 2000
    @cvs-id qualification-list.tcl,v 3.2.6.6 2000/09/22 01:38:35 kevin Exp
    @param return_url The url we return to
} {
    {return_url ""}
}




set qualification_list ""
db_foreach getquals "select qualification_id, qualification from im_qualification_processes" {
    lappend qualification_list "$qualification - <a href=qualification-edit?[export_url_vars qualification_id]>edit</a>"

}

doc_return  200 text/html "
[ad_header "Qualifications"]
<h2>Qualifications</h2>
[ad_context_bar_ws [list "/intranet/employees/admin" "Employees Admin"] "Qualifications"]
<hr>
<ul>
<li>[join $qualification_list "<li>"]
</ul>
<form action=qualification-add-2 method=post>
Qualification: <input type=text name=qualification maxlength=100>
<p>
<center>
<input type=submit name=submit value=\"Add\">
</center>
<form>
[ad_footer]
"