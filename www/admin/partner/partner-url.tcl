# /www/admin/partner/partner-url

ad_page_contract {
    Displays information about one url

    @param url_id integer id of the URL we are looking at

    @author mbryzek@arsdigita.com
    @creation-date 10/1999

    @cvs-id partner-url.tcl,v 3.2.2.3 2000/09/22 01:35:46 kevin Exp
} {
    url_id:integer,notnull
}

proc local_ad_partner_proc_html { url_id proc_type} {
    set sql "select proc_name, proc_id
               from ad_partner_${proc_type}_procs
              where url_id=:url_id"
 
    set str ""
    db_foreach partner_local_name_id $sql {
	append str "  <LI>$proc_name | <A HREF=\"/doc/proc-one?proc_name=[ns_urlencode $proc_name]\">view</A> | <A HREF=\"partner-proc-ae?[export_url_vars proc_id]\">edit</a> | <A HREF=\"partner-proc-delete?[export_url_vars proc_id]\">delete</a>\n"
    } 

    if { [empty_string_p $str] } { 
	set str "<UL>  <LI> No procedures have been registered.</UL>"
    } else {
	set str "<OL>$str</OL>"
    }

    return "
    <b>$proc_type calling order</b>
    $str
<UL>  
<LI><A HREF=\"partner-proc-ae?[export_url_vars partner_id proc_type url_id]\">Add a $proc_type procedure</A>
</UL>
"
}


db_1row partner_id_stub \
	"select url.partner_id, url.url_stub, p.partner_name
           from ad_partner_url url, ad_partner p
          where url.partner_id=p.partner_id
            and url_id=:url_id"

set page_title "$partner_name ($url_stub)"
set context_bar [ad_context_bar_ws [list "index" "Partner manager"] [list "partner-view?[export_url_vars partner_id]" "One partner"] "URL"]

set return_url [ad_partner_url_with_query]

set page_body "
[local_ad_partner_proc_html $url_id header]
[local_ad_partner_proc_html $url_id footer]

<b>Administration</b>
<ul>
  <li> <a href=\"partner-url-sample?[export_url_vars url_id]\">Preview</a> what this template looks like
  <li> <a href=\"partner-url-ae?[export_url_vars url_id return_url]\">Edit</a> the URL for this template
</ul>
"

# ad_partner_return_template releases the db handles

doc_return  200 text/html [ad_partner_return_template]