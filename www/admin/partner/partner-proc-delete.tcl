# $Id: partner-proc-delete.tcl,v 3.0 2000/02/06 03:26:42 ron Exp $
set_the_usual_form_variables
# proc_id 

set db [ns_db gethandle]

set selection [ns_db 1row $db \
	"select p.proc_name, trim(p.proc_type) as proc_type, p.url_id, u.partner_id
           from ad_partner_procs p, ad_partner_url u
          where p.proc_id='$QQproc_id'
            and p.url_id=u.url_id"]
set_variables_after_query

set page_title "Delete procedure"
set context_bar [ad_context_bar_ws [list "index.tcl" "Partner manager"] [list "partner-view.tcl?[export_url_vars partner_id]" "One partner"] [list "partner-url.tcl?[export_url_vars url_id]" URL] "$page_title"]

set page_body "
Are you sure you want to unassociate the $proc_type procedure \"$proc_name\"?

<table>
<tr>
  <td><form method=post action=\"partner-proc-delete-2.tcl\">
      [export_form_vars proc_id]
      <input type=submit name=operation value=\"Yes\"></FORM>
  </td>
  <td><form method=post action=\"partner-proc-delete-2.tcl\">
      [export_form_vars proc_id]
      <input type=submit name=operation value=\"No\"></FORM>
  </td>
</tr>
</table>
"

ns_return 200 text/html [ad_partner_return_template]
