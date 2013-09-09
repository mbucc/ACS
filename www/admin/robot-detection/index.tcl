# www/admin/robot-detection/index.tcl

ad_page_contract {
    Lists all registered robots and enables the site admin to refresh the list.    

    @author Michael Yoon (michael@yoon.org)
    @creation-date 27-MAY-1999
    @cvs-id index.tcl,v 3.1.6.4 2000/09/22 01:36:03 kevin Exp
} {
}

set page_title "Web Robot Detection"

append doc_body "[ad_admin_header $page_title]

<h2>$page_title</h2>

[ad_admin_context_bar "Robot Detection"]

<hr>

Documentation:  <a href=\"/doc/robot-detection\">/doc/robot-detection.html</a>

<h3>Configuration Settings</h3>

The current configuration settings are:

<pre>
WebRobotsDB=[ad_parameter WebRobotsDB robot-detection]
"

set patterns [ad_parameter_all_values_as_list FilterPattern robot-detection]

if [empty_string_p $patterns] {
    append doc_body "**** no filter patterns spec'd; system is disabled ****\n"
} else {
    append doc_body "FilterPattern=[join  "\nFilterPattern="]"
}

append doc_body "RedirectURL=[ad_parameter RedirectURL robot-detection]
</pre>

<h3>Known Robots</h3>

<p>

Courtesy of the <a href=\"http://info.webcrawler.com/mak/projects/robots/active.html\">Web Robots Database</a>,
this installation of the ACS can recognize the following robots:

<ul>
"

db_foreach all_robots {select robot_name, robot_details_url from robots order by robot_name} {
    if ![empty_string_p $robot_details_url] {
	append doc_body "<li><a href=\"$robot_details_url\">$robot_name</a>\n"
    } else {
	append doc_body "<li>$robot_name\n"
    }
} if_no_rows {
    append doc_body "<li>no robots registered\n";
}

append doc_body "<p>
<li><a href=\"refresh-robot-list\">refresh list from the Web Robots Database</a>
</ul>

[ad_admin_footer]
"

doc_return  200 text/html $doc_body