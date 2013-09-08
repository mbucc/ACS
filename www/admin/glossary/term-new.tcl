# /www/admin/glossary/term-new.tcl

ad_page_contract {
    form new term  postings
    
    @author unknown modified by walter@arsdigita.com, 2000-07-02
    @cvs-id term-new.tcl,v 3.3.2.4 2000/09/22 01:35:27 kevin Exp

} {}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set user_id [ad_maybe_redirect_for_registration]

set whole_page "[ad_admin_header "Add a Term"]
<h2>Add a Term</h2>
to the <a href=index>glossary</a> for [ad_site_home_link]
<hr>
<form method=post action=\"term-new-2\">
<table>
<tr><th>Term <td><input type=text size=40 name=term>
<tr><th>Definition <td><textarea cols=60 rows=6 wrap=soft name=definition></textarea>
</tr>
</table>
<br>
<center>
<input type=\"submit\" value=\"Submit\">
</center>
</form>
[ad_admin_footer]
"
 
doc_return  200 text/html $whole_page
