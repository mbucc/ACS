# /www/admin/wap/add-3

ad_page_contract {
    Target for add-2 -- do the insert.

    @param user_agent_id
    @param name
    @param creation_comment
    @param return_url 
    @author Andrew Grumet (aegrumet@arsdigita.com)
    @creation-date   Wed May 24 08:01:17 2000
    @cvs-id add-3.tcl,v 1.1.6.7 2001/01/12 00:37:28 khy Exp
} {
    user_agent_id:naturalnum,verify,notnull
    name
    {creation_comment {}}
    {return_url {view-list}}
}


page_validation {validate_integer "User Agent Id" $user_agent_id} \
	{ 
            if [empty_string_p $name] {
                error "The User Agent field cannot be left empty."
            }
        } \
        {
            if { [string length $name] > 200 } {
		error "The User Agent name must be 200 characters or less."
	    }
	}

# User input looks relatively good.

ad_maybe_redirect_for_registration
set user_id [ad_verify_and_get_user_id]


set doubleclick_p [db_string wap_admin_add_3_doubleclick "
    select count(*) from wap_user_agents where user_agent_id = :user_agent_id"]

if !$doubleclick_p {
    db_dml wap_user_agent_insert "insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_date,creation_user)
values (:user_agent_id,:name,:creation_comment,sysdate,:user_id)"
    ad_returnredirect $return_url
} else {

    set page_content "[ad_admin_header "WAP User-Agent Added"]

<h2>WAP User-Agent Added</h2>

[ad_admin_context_bar [list "index" "WAP"] [list "view-list" "WAP User-Agents"] [list "add" "Add One"] "Added"]

<hr>

User agent &quot;[ns_quotehtml $name]&quot; has been added.  You can now:
<ul>
<li><a href=\"$return_url\">Return to where you were.</a>
<li><a href=\"add\">Add another user agent.</a>
</ul>
[ad_admin_footer]"

    

    doc_return  200 text/html $page_content
}























