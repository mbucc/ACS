# File:     /homepage/neighborhoods.tcl

ad_page_contract {
    User Content Main Page

    @param neighborhood_node System variable to get us back to the start

    @author Usman Y. Mobin (mobin@mit.edu)
    @creation-date Thu Jan 27 00:30:05 EST 2000
    @cvs-id neighborhoods.tcl,v 3.3.2.8 2000/09/22 01:38:17 kevin Exp
} {
    neighborhood_node:optional,naturalnum
}

# ------------------------------ initialization codeBlock ----

# First, we need to get the user_id
set user_id [ad_verify_and_get_user_id]

# ------------------------ initialDatabaseQuery codeBlock ----

# This will tell us whether the user has a page or not.
set haspage_p [db_string select_haspage_p "
select count(*)
from users_homepages
where user_id=:user_id"]

# This query will extract information about the user from the
# database
set screen_name_p [db_0or1row select_screen_name "
select screen_name
from users
where user_id=:user_id"]

if { !$screen_name_p } {
    set screen_name ""
}

# Checking for site-wide administration status
set admin_p [ad_administrator_p $user_id]

set adminhtml "You are not an administrator and cannot add/delete neighborhoods"

if {$admin_p} {
    set adminhtml "You are an administrator and can add/delete neighborhoods"
}

# If neighborhood node is not specified, go to user's root directory
if {![info exists neighborhood_node] || [empty_string_p $neighborhood_node]} {
    set neighborhood_node [db_string select_default_nh_node "
    select hp_get_neighborhood_root_node from dual"]
}

set cookies [ns_set get [ns_conn headers] Cookie]
if {[regexp {.*neighborhood_view=([^ ;]*).*} $cookies match cookie_view]} {
    # we have a match
    set view $cookie_view
} else {
    set view [ad_parameter DefaultView users]
}

if {![info exists view] || [empty_string_p $view]} {
    set view "tree"
}

set userhtml ""
if {$haspage_p} {

    set nh_id_p [db_0or1row select_nh_id "
    select neighborhood_id 
    from users_homepages
    where user_id=:user_id
    "]

    if { !$nh_id_p } {
	set your_nh "&lt you haven't joined one &gt"
    } else {
	set your_nh [db_string select_your_nh "
	select hp_relative_neighborhood_name(:neighborhood_id)
	from dual"]
	append your_nh "[ad_space 3]<a href=joinnh?neighborhood_node=$neighborhood_node>leave it!</a>"
    }
    
    set userhtml "Your neighborhood - $your_nh"
    
}

# And off with the handle!
db_release_unused_handles

# ----------------------- initialHtmlGeneration codeBlock ----

# Set the page title
set title "Neighborhoods"

if {[empty_string_p $screen_name]} {
    set screenhtml "Your screen name: &lt none set up &gt -  Click <a href=/pvt/basic-info-update>here</a> to set one up."
} else {
    set screenhtml "Your screen name: $screen_name"
}

# We're not doing things that way anymore, unless this turns out to be
# really, really slow
#  # Send the first packet of html. The reason for sending the
#  # first packet (with the page heading) as early as possible
#  # is that otherwise the user might find the system somewhat
#  # unresponsive if it takes too long to query the database.

set page_content "
[ad_header $title]
<h2>$title</h2>
[ad_context_bar_ws_or_index $title]
<hr>
[help_upper_right_menu_b]
$screenhtml<br>
$adminhtml<br>
<p>
$userhtml<br>
<blockquote>
"

set sql "
select (select parent_id
from users_neighborhoods
where neighborhood_id=:neighborhood_node) as parent_node
from dual
"

db_1row select_parent_node $sql

if {![info exists parent_node] || [empty_string_p $parent_node]} {
    set parent_html ""
} else {
    
    set parent_html "
    <tr><td><img src=back.gif>
    <a href=neighborhoods?neighborhood_node=$parent_node>Parent Neighborhood</a>
    </td></tr>
    <tr><td>&nbsp;</td></tr>
    "
}

set curr_neighborhood [db_string select_curr_neighborhood "
select hp_true_neighborhood_name(:neighborhood_node) from dual"]

set child_count [db_string select_child_count "
select hp_get_nh_child_count(:neighborhood_node) from dual"]

# This menu displays a list of options which the user has
# available for the current neighborhood_node (directory).
if { $admin_p } {
    set options_menu "\[ <a href=mknh-1?neighborhood_node=$neighborhood_node>create neighborhood</a> \]"
} else {
    set options_menu ""
}

# View Selection

if {$view == "tree"} {

    append page_content "
    <br>
    <table border=0 cellspacing=0 cellpadding=0 width=90%>
    <tr><td>$options_menu
    <td align=right>\[ <a href=set-view-nh?view=normal&neighborhood_node=$neighborhood_node>normal view</a> | tree view \]
    </tr>
    </table>
    <br>
    <table bgcolor=DDEEFF border=0 cellspacing=0 cellpadding=8 width=90%>
    <tr><td>
    <b>You are browsing $curr_neighborhood</b>
    <ul>
    <table border=0>
    $parent_html
    "

    set counter 0
    
    if {$child_count==0} {
	#append page_content "
	#<tr><td>There are no sub-neighborhoods in this neighborhood</td></tr>"
	append page_content ""
    } else {
	set nh_qry  "
	select neighborhood_id as nid, neighborhood_name, level, description,
               parent_id,
	hp_neighborhood_sortkey_gen(neighborhood_id) as generated_sort_key
	from users_neighborhoods
	where level > 1
	connect by prior neighborhood_id = parent_id
	start with neighborhood_id=:neighborhood_node
	order by generated_sort_key asc"

	db_foreach select_tree_view $nh_qry {
	    incr counter
	    set level [expr $level - 2]

	    set neighborhood_menu "<font size=-1><a href=\"dialog-class?title=Neighborhood Management&text=This will delete the Neighborhood `$neighborhood_name' and all its sub-neighborhoods permanently.<br>Are you certain you would like to do that?&btn1=Yes&btn2=No&btn2target=neighborhoods.tcl&btn2keyvalpairs=neighborhood_node $neighborhood_node&btn1target=rmnh-1.tcl&btn1keyvalpairs=neighborhood_node $neighborhood_node dir_node $nid\">remove</a> | <a href=\"renamenh-1?neighborhood_node=$neighborhood_node&rename_node=$nid\">rename</a> | <a href=movenh-1?neighborhood_node=$neighborhood_node&move_node=$nid>move</a> | <a href=members?neighborhood_node=$neighborhood_node&nid=$nid>members</a> | <a href=joinnh?neighborhood_node=$neighborhood_node&nid=$nid>join</a></font>
	    "
				
	    append page_content "<tr><td valign=top>[ad_space [expr $level * 8]]
	    <a href=neighborhoods?neighborhood_node=$nid>$neighborhood_name</a>
	    </td>
	    <td valign=top align=left>&nbsp<font size=-1>$description</font></td>
	    <td valign=top>&nbsp$neighborhood_menu</td></tr>"
	    
	}
    }
    
} else {
    
    # This is when the view is normal
    append page_content "
    <br>
    <table border=0 cellspacing=0 cellpadding=0 width=90%>
    <tr><td>$options_menu
    <td align=right>\[ normal view | <a href=set-view-nh?view=tree&neighborhood_node=$neighborhood_node>tree view</a> \]
    </tr>
    </table>
    <br>
    <table bgcolor=DDEEFF cellpadding=8 width=90%>
    <tr><td>
    <b>You are browsing $curr_neighborhood</b>
    <ul>
    <table border=0>
    $parent_html
    "
    
    if {$child_count==0} {
	#append page_content "
	#<tr><td>There are no files in this directory</td></tr>"
	append page_content ""
    } else {
	set nh_qry "
	select neighborhood_id as nid, neighborhood_name,
	       description
	from users_neighborhoods
	where parent_id=:neighborhood_node
	order by neighborhood_name asc"

	db_foreach select_normal_view $nh_qry {
	    set neighborhood_menu "<font size=-1><a href=\"dialog-class?title=Neighborhood Management&text=This will delete the Neighborhood `$neighborhood_name' and all its sub-neighborhoods permanently.<br>Are you certain you would like to do that?&btn1=Yes&btn2=No&btn2target=neighborhoods.tcl&btn2keyvalpairs=neighborhood_node $neighborhood_node&btn1target=rmnh-1.tcl&btn1keyvalpairs=neighborhood_node $neighborhood_node dir_node $nid\">remove</a> | <a href=\"renamenh-1?neighborhood_node=$neighborhood_node&rename_node=$nid\">rename</a> | <a href=movenh-1?neighborhood_node=$neighborhood_node&move_node=$nid>move</a> | <a href=members?neighborhood_node=$neighborhood_node&nid=$nid>members</a> | <a href=joinnh?neighborhood_node=$neighborhood_node&nid=$nid>join</a></font>
	    "
				
	    append page_content "<tr><td valign=top>
	    <a href=neighborhoods?neighborhood_node=$nid>$neighborhood_name</a>
	    </td>
	    <td valign=top align=left>&nbsp<font size=-1>$description</font></td>
	    <td valign=top>&nbsp$neighborhood_menu</td></tr>"
	    
	}   
    }
}

append page_content "</table></ul>"

# And off with the handle!
db_release_unused_handles

if {$view == "tree"} {
    set child_count $counter
}

append page_content "
$child_count neighborhood(s)
</td></tr></table>
<p>
<table border=0 cellspacing=0 cellpadding=0 width=90%>
<tr><td>$options_menu</td>
<td align=right>\[ <a href=all>list all homepages</a> \]
</td></tr>
</table>
<br>
"

# To escape out of the blockquote mode
append page_content "
</blockquote>
[ad_footer]"

# Return the page for viewing
doc_return  200 text/html $page_content

