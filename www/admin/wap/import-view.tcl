# /www/admin/wap/import-view

ad_page_contract {
    View results of import.

    @param view
    @author Andrew Grumet (aegrumet@arsdigita.com)
    @creation-date  Wed May 24 11:25:53 2000
    @cvs-id import-view.tcl,v 1.3.2.5 2000/09/22 01:36:34 kevin Exp
} {
    { view new }
}

switch $view {
    new {
	set pretty_view "New User-Agents not currently in your database:"
	set import_msg "<a href=\"import-actually\">Import</a>"
	set nav {View: [ new | <a href="import-view?view=all">all</a> ]}
    }
    default {
	set view all
	set pretty_view "All User-Agents:"
	set import_msg "<a href=\"import-actually\">Import new strings (shown in black)</a>"
	set nav {View: [ <a href="import-view?view=new">new</a> | all ]}
    }
}

set new_agents_list [wap_import_agent_list]



set old_agents_list [db_list wap_import_view_old_agents_list "
    select name from wap_user_agents where deletion_date is null"]

set agent_count 0
set new_agent_count 0
foreach agent $new_agents_list {
    if { [lsearch $old_agents_list $agent] < 0 } {
	incr agent_count
	incr new_agent_count
	append display_list "<li>$agent\n"
    } else {
	if { [string compare $view all] == 0 } {
	    incr agent_count
	    append display_list "<li><font color=green>$agent</font>\n"
	}
    }
}

if !$agent_count {
    set display_list "<li>Sorry, no user-agents were found."
}

if !$new_agent_count {
    set import_msg {}
}

set page_content "[ad_admin_header "View Import Results"]

<h2>View Import Results</h2>

[ad_admin_context_bar [list "index" "WAP"] [list "view-list" "WAP User-Agents"] [list "import" "Import"] "Results"]

<hr>

<table width=100%>
  <tr>
    <td>
      <strong>$pretty_view</strong> ($agent_count total)
      $import_msg
    </td>
    <td align=right>$nav</td>
 </tr>
</table>

<ul>
$display_list
</ul>

<p>
    
[ad_admin_footer]"



doc_return  200 text/html $page_content




