# /www/admin/partner/partner-proc-delete

ad_page_contract {
    Confirms removal of mapping of procedure name

    @param proc_id Integer ID of the procedure we're looking at

    @author mbryzek@arsdigita.com
    @creation-date 10/1999

    @cvs-id partner-proc-delete.tcl,v 3.2.2.3 2000/09/22 01:35:45 kevin Exp
} {
    proc_id:integer,notnull
}


db_1row partner_proc_url_join \
	"select p.proc_name, trim(p.proc_type) as proc_type, p.url_id, u.partner_id
           from ad_partner_procs p, ad_partner_url u
          where p.proc_id=:proc_id
            and p.url_id=u.url_id"

set page_title "Delete procedure"
set context_bar [ad_context_bar_ws [list "index" "Partner manager"] [list "partner-view?[export_url_vars partner_id]" "One partner"] [list "partner-url?[export_url_vars url_id]" URL] "$page_title"]

set page_body "
Are you sure you want to unassociate the $proc_type procedure \"$proc_name\"?

<table>
<tr>
  <td><form method=post action=\"partner-proc-delete-2\">
      [export_form_vars proc_id]
      <input type=submit name=operation value=\"Yes\"></FORM>
  </td>
  <td><form method=post action=\"partner-proc-delete-2\">
      [export_form_vars proc_id]
      <input type=submit name=operation value=\"No\"></FORM>
  </td>
</tr>
</table>
"

# ad_partner_return_template releases the db handles

doc_return  200 text/html [ad_partner_return_template]
