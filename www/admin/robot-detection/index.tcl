# $Id: index.tcl,v 3.0 2000/02/06 03:28:10 ron Exp $
# Created by michael@yoon.org, 05/27/1999
#
# Lists all registered robots and enables the site admin
# to refresh the list.

ReturnHeaders

set page_title "Web Robot Detection"

ns_write "[ad_admin_header $page_title]

<h2>$page_title</h2>

[ad_admin_context_bar "Robot Detection"]

<hr>

Documentation:  <a href=\"/doc/robot-detection.html\">/doc/robot-detection.html</a>

<h3>Configuration Settings</h3>

The current configuration settings are:

<pre>
WebRobotsDB=[ad_parameter WebRobotsDB robot-detection]
"

set patterns [ad_parameter_all_values_as_list FilterPattern robot-detection]

if [empty_string_p $patterns] {
    ns_write "**** no filter patterns spec'd; system is disabled ****\n"
} else {
    ns_write "FilterPattern=[join  "\nFilterPattern="]"
}

ns_write "RedirectURL=[ad_parameter RedirectURL robot-detection]
</pre>

<h3>Known Robots</h3>

<p>

Courtesy of the <a href=\"http://info.webcrawler.com/mak/projects/robots/active.html\">Web Robots Database</a>,
this installation of the ACS can recognize the following robots:

<ul>
"

set counter 0
set db [ns_db gethandle]
set selection [ns_db select $db "select robot_name, robot_details_url from robots order by robot_name"]
while {[ns_db getrow $db $selection]} {
    incr counter
    set_variables_after_query
    if ![empty_string_p $robot_details_url] {
	ns_write "<li><a href=\"$robot_details_url\">$robot_name</a>\n"
    } else {
	ns_write "<li>$robot_name\n"
    }
}

if {0 == $counter} {
    ns_write "<li>no robots registered\n";
}

ns_write "<p>
<li><a href=\"refresh-robot-list.tcl\">refresh list from the Web Robots Database</a>
</ul>

[ad_admin_footer]
"

