# /www/admin/wap/index

ad_page_contract {

    Admin page for WAP.  First incarnation is viewing and modifying
    a list of known wap user agents. 

    @author Andrew Grumet (aegrumet@arsdigita.com)
    @creation-date Wed May 24 05:47:29 2000
    @cvs-id index.tcl,v 1.3.2.4 2000/09/22 01:36:35 kevin Exp
} {

}

set page_content "[ad_admin_header "WAP"]

<h2>WAP</h2>

[ad_admin_context_bar "WAP"]

<hr>

Documentation: <a href=\"/doc/wap\">/doc/wap</a>

<h3>Known WAP User Agents</h3>

One important task is to manage a list of known
user agents to aid in content negotiation using <a
href=\"http://acs-staging.arsdigita.com/api-doc/proc-view?proc=util%5fguess%5fdoctype\">util_guess_doctype</a>.

<ul>
<li>total known agents: "

set n_agents [db_string wap_user_agent_count "select count(*) from wap_user_agents where deletion_date is null"]

if $n_agents {
    set agent_text "${n_agents}&nbsp;(<a href=\"view-list\">view</a>)"
} else {
    set agent_text $n_agents
}

append page_content "$agent_text
</ul>
[ad_admin_footer]"



doc_return  200 text/html $page_content

