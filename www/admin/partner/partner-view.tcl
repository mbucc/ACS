# /www/admin/partner/partner-view.tcl

ad_page_contract {
    Displays all the information about one partner

    @param partner_id ID of partner we're viewing

    @author mbryzek@arsdigita.com
    @creation-date 10/1999

    @cvs-id partner-view.tcl,v 3.2.2.3 2000/09/22 01:35:46 kevin Exp
} {
    partner_id:integer,notnull
}

set return_url "partner-view?[export_url_vars partner_id]"

if { ![db_0or1row partner_from_id \
	"select partner_name, partner_cookie, default_font_face, default_font_color, 
                title_font_face, title_font_color, group_id
           from ad_partner 
          where partner_id=:partner_id"] } {
    ad_partner_return_error "Partner doesn't exist" \
	    "There is no partner with a partner_id of $partner_id"
    return
}

set page_title $partner_name
set context_bar [ad_context_bar_ws [list "index" "Partner manager"] "One partner"]

set url_string ""
set sql "select distinct url_stub, url_id
	   from ad_partner_url
          where partner_id=:partner_id
          order by upper(url_stub)"

db_foreach partner_by_url $sql {
    append url_string "  <LI>$url_stub | 
<a href=\"partner-url?[export_url_vars url_id]\">View</a> | 
<a href=\"partner-url-ae?[export_url_vars url_id]\">Edit</a> | 
<a href=\"partner-url-delete?[export_url_vars url_id]\">Delete</a> |
<a href=\"partner-url-sample?[export_url_vars url_id]\">Preview</a>
"
} 

if { [empty_string_p $url_string] } {
    set url_string "  <LI> There are no registered urls"
}

append page_body "

<b>Registered URL's</b>
<UL>
 $url_string
<P>
  <LI><a href=\"partner-url-ae?[export_url_vars partner_id]\">Add a url</a>
</UL>
<p> 

<b>Variables | <a href=\"partner-ae?[export_url_vars partner_id return_url]\">Edit</A></b>
<UL> 
"

if { ![empty_string_p $group_id] } {
    set user_groups_name [db_string partner_user_group_name \
	    "select group_name from user_groups where group_id=:group_id"]
} else {
    set user_groups_name ""
}
set partner_vars [ad_partner_list_all_vars] 

foreach pair $partner_vars {
    set variable [lindex $pair 0]
    set text [lindex $pair 1]
    append page_body "  <li> <b>$text ($variable)</b>: [set $variable]\n"
}

append page_body " 
  <li> <b>Group</b>: $user_groups_name
</ul>
"

# ad_partner_return_template releases the db handles
doc_return  200 text/html [ad_partner_return_template]
