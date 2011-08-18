# $Id: neighborhoods.tcl,v 3.0 2000/02/06 03:47:01 ron Exp $
# File:     /homepage/neighborhoods.tcl
# Date:     Thu Jan 27 00:30:05 EST 2000
# Location: 42Å∞21'N 71Å∞04'W
# Location: 80 PROSPECT ST CAMBRIDGE MA 02139 USA
# Author:   mobin@mit.edu (Usman Y. Mobin)
# Purpose:  User Content Main Page

set_form_variables 0
# neighborhood_node

# ------------------------------ initialization codeBlock ----

# First, we need to get the user_id
set user_id [ad_verify_and_get_user_id]

# ------------------------ initialDatabaseQuery codeBlock ----

# The database handle (a thoroughly useless comment)
set db [ns_db gethandle]

# This will tell us whether the user has a page or not.
set haspage_p [database_to_tcl_string $db "
select count(*)
from users_homepages
where user_id=$user_id"]

# This query will extract information about the user from the
# database
set selection [ns_db 0or1row $db "
select screen_name
from users
where user_id=$user_id"]

if {[empty_string_p $selection]} {
    set screen_name ""
} else {
    # This will assign the appropriate values to the appropriate
    # variables based on the query results.
    set_variables_after_query
}    

# Checking for site-wide administration status
set admin_p [ad_administrator_p $db $user_id]

set adminhtml "You are not an administrator and cannot add/delete neighborhoods"

if {$admin_p} {
    set adminhtml "You are an administrator and can add/delete neighborhoods"
}

# If neighborhood node is not specified, go to user's root directory
if {![info exists neighborhood_node] || [empty_string_p $neighborhood_node]} {
    set neighborhood_node [database_to_tcl_string $db "
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

    set selection [ns_db 0or1row $db "
    select neighborhood_id 
    from users_homepages
    where user_id=$user_id
    "]

    set_variables_after_query

    if {![info exists neighborhood_id] || [empty_string_p $neighborhood_id]} {
	set your_nh "&lt you haven't joined one &gt"
    } else {
	set your_nh [database_to_tcl_string $db "
	select hp_relative_neighborhood_name($neighborhood_id)
	from dual"]
	append your_nh "[ad_space 3]<a href=joinnh.tcl?neighborhood_node=$neighborhood_node>leave it!</a>"
    }
    
    set userhtml "Your neighborhood - $your_nh"
    
}

# And off with the handle!
ns_db releasehandle $db


# ----------------------- initialHtmlGeneration codeBlock ----

# Set the page title
set title "Neighborhoods"

# Return the http headers. (an awefully useless comment)
ReturnHeaders

if {[empty_string_p $screen_name]} {
    set screenhtml "Your screen name: &lt none set up &gt -  Click <a href=/pvt/basic-info-update.tcl>here</a> to set one up."
} else {
    set screenhtml "Your screen name: $screen_name"
}


# Send the first packet of html. The reason for sending the
# first packet (with the page heading) as early as possible
# is that otherwise the user might find the system somewhat
# unresponsive if it takes too long to query the database.
ns_write "
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

# The database handle (a thoroughly useless comment)
set db [ns_db gethandle]

set sql "
select (select parent_id
from users_neighborhoods
where neighborhood_id=$neighborhood_node) as parent_node
from dual
"

# Extract results from the query
set selection [ns_db 1row $db $sql]

# This will  assign the  variables their appropriate values 
# based on the query.
set_variables_after_query

if {![info exists parent_node] || [empty_string_p $parent_node]} {
    set parent_html ""
} else {
    
    set parent_html "
    <tr><td><img src=back.gif>
    <a href=neighborhoods.tcl?neighborhood_node=$parent_node>Parent Neighborhood</a>
    </td></tr>
    <tr><td>&nbsp;</td></tr>
    "
}

set curr_neighborhood [database_to_tcl_string $db "
select hp_true_neighborhood_name($neighborhood_node) from dual"]

set child_count [database_to_tcl_string $db "
select hp_get_nh_child_count($neighborhood_node) from dual"]

# This menu displays a list of options which the user has
# available for the current neighborhood_node (directory).
set options_menu "\[ <a href=mknh-1.tcl?neighborhood_node=$neighborhood_node>create neighborhood</a> \]"

# View Selection



if {$view == "tree"} {

    append html "
    <br>
    <table border=0 cellspacing=0 cellpadding=0 width=90%>
    <tr><td>$options_menu
    <td align=right>\[ <a href=set-view-nh.tcl?view=normal&neighborhood_node=$neighborhood_node>normal view</a> | tree view \]
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
	#append html "
	#<tr><td>There are no sub-neighborhoods in this neighborhood</td></tr>"
	append html ""
    } else {
	set selection [ns_db select $db "
	select neighborhood_id as nid, neighborhood_name, level, description,
               parent_id,
	hp_neighborhood_sortkey_gen(neighborhood_id) as generated_sort_key
	from users_neighborhoods
	where level > 1
	connect by prior neighborhood_id = parent_id
	start with neighborhood_id=$neighborhood_node
	order by generated_sort_key asc"]
	while {[ns_db getrow $db $selection]} {
	    incr counter
	    set_variables_after_query
	    set level [expr $level - 2]

	    set neighborhood_menu "<font size=-1><a href=\"dialog-class.tcl?title=Neighborhood Management&text=This will delete the Neighborhood `$neighborhood_name' and all its sub-neighborhoods permanently.<br>Are you certain you would like to do that?&btn1=Yes&btn2=No&btn2target=neighborhoods.tcl&btn2keyvalpairs=neighborhood_node $neighborhood_node&btn1target=rmnh-1.tcl&btn1keyvalpairs=neighborhood_node $neighborhood_node dir_node $nid\">remove</a> | <a href=\"renamenh-1.tcl?neighborhood_node=$neighborhood_node&rename_node=$nid\">rename</a> | <a href=movenh-1.tcl?neighborhood_node=$neighborhood_node&move_node=$nid>move</a> | <a href=members.tcl?neighborhood_node=$neighborhood_node&nid=$nid>members</a> | <a href=joinnh.tcl?neighborhood_node=$neighborhood_node&nid=$nid>join</a></font>
	    "
				
	    append html "<tr><td valign=top>[ad_space [expr $level * 8]]
	    <a href=neighborhoods.tcl?neighborhood_node=$nid>$neighborhood_name</a>
	    </td>
	    <td valign=top align=left>&nbsp<font size=-1>$description</font></td>
	    <td valign=top>&nbsp$neighborhood_menu</td></tr>"
	    
	}
    }
    

} else {
    
    # This is when the view is normal
    append html "
    <br>
    <table border=0 cellspacing=0 cellpadding=0 width=90%>
    <tr><td>$options_menu
    <td align=right>\[ normal view | <a href=set-view-nh.tcl?view=tree&neighborhood_node=$neighborhood_node>tree view</a> \]
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
	#append html "
	#<tr><td>There are no files in this directory</td></tr>"
	append html ""
    } else {
	set selection [ns_db select $db "
	select neighborhood_id as nid, neighborhood_name,
	       description
	from users_neighborhoods
	where parent_id=$neighborhood_node
	order by neighborhood_name asc"]
	while {[ns_db getrow $db $selection]} {
	    set_variables_after_query

	    set neighborhood_menu "<font size=-1><a href=\"dialog-class.tcl?title=Neighborhood Management&text=This will delete the Neighborhood `$neighborhood_name' and all its sub-neighborhoods permanently.<br>Are you certain you would like to do that?&btn1=Yes&btn2=No&btn2target=neighborhoods.tcl&btn2keyvalpairs=neighborhood_node $neighborhood_node&btn1target=rmnh-1.tcl&btn1keyvalpairs=neighborhood_node $neighborhood_node dir_node $nid\">remove</a> | <a href=\"renamenh-1.tcl?neighborhood_node=$neighborhood_node&rename_node=$nid\">rename</a> | <a href=movenh-1.tcl?neighborhood_node=$neighborhood_node&move_node=$nid>move</a> | <a href=members.tcl?neighborhood_node=$neighborhood_node&nid=$nid>members</a> | <a href=joinnh.tcl?neighborhood_node=$neighborhood_node&nid=$nid>join</a></font>
	    "
				
	    append html "<tr><td valign=top>
	    <a href=neighborhoods.tcl?neighborhood_node=$nid>$neighborhood_name</a>
	    </td>
	    <td valign=top align=left>&nbsp<font size=-1>$description</font></td>
	    <td valign=top>&nbsp$neighborhood_menu</td></tr>"
	    
	}   
    }
}


append html "</table></ul>"

# And off with the handle!
ns_db releasehandle $db

if {$view == "tree"} {
    set child_count $counter
}

append html "
$child_count neighborhood(s)
</td></tr></table>
<p>
<table border=0 cellspacing=0 cellpadding=0 width=90%>
<tr><td>$options_menu</td>
<td align=right>\[ <a href=all.tcl>list all homepages</a> \]
</td></tr>
</table>
<br>
"

# To escape out of the blockquote mode
append html "
</blockquote>"

# ------------------------ htmlFooterGeneration codeBlock ----

# And here is our footer. Were you expecting someone else?
ns_write "
$html
[ad_footer]
"











