# $Id: all.tcl,v 3.0 2000/02/06 03:46:38 ron Exp $
# File:     /homepage/all.tcl
# Date:     Thu Jan 27 06:47:54 EST 2000
# Location: 42Å∞21'N 71Å∞04'W
# Location: 80 PROSPECT ST CAMBRIDGE MA 02139 USA
# Author:   mobin@mit.edu (Usman Y. Mobin)
# Purpose:  Page to show all members


# http headers
ReturnHeaders

set title "Homepages at [ad_parameter SystemName]"

# packet of html
ns_write "
[ad_header $title]
<h2>$title</h2>
[ad_context_bar_ws_or_index $title] 
<hr>
<table width=100%>
<tr>
<td align=right>\[ <a href=neighborhoods.tcl>browse neighborhoods</a> \]
</td></tr></table>
<blockquote>

<center>
\[ <A HREF=\"#A\">A</A> | <A HREF=\"#B\">B</A> | 
<A HREF=\"#C\">C</A> | <A HREF=\"#D\">D</A> | <A HREF=\"#E\">E</A> | 
<A HREF=\"#F\">F</A> | <A HREF=\"#G\">G</A> | <A HREF=\"#H\">H</A> | 
<A HREF=\"#I\">I</A> | <A HREF=\"#J\">J</A> | <A HREF=\"#K\">K</A> | 
<A HREF=\"#L\">L</A> | <A HREF=\"#M\">M</A> | <A HREF=\"#N\">N</A> | 
<A HREF=\"#O\">O</A> | <A HREF=\"#P\">P</A> | <A HREF=\"#Q\">Q</A> | 
<A HREF=\"#R\">R</A> | <A HREF=\"#S\">S</A> | <A HREF=\"#T\">T</A> | 
<A HREF=\"#U\">U</A> | <A HREF=\"#V\">V</A> | <A HREF=\"#W\">W</A> | 
<A HREF=\"#X\">X</A> | <A HREF=\"#Y\">Y</A> | <A HREF=\"#Z\">Z</A> \] 
</center>

<br>

    <table bgcolor=DDEEFF border=0 cellspacing=0 cellpadding=8 width=90%>
    <tr><td>
    <b>These are the members with homepages at [ad_parameter SystemName]</b>
    <ul>
"

set db [ns_db gethandle]

set counter 0

for {set cx 1} {$cx <= 26} {incr cx} {

    set letter [mobin_number_to_letter $cx]

    set selection [ns_db select $db "
    select uh.user_id as user_id,
    u.screen_name as screen_name,
    u.first_names as first_names,
    u.last_name as last_name
    from users_homepages uh, users u
    where uh.user_id=u.user_id
    and upper(u.last_name) like '$letter%'
    order by last_name desc, first_names desc"]
    
    append html "
    <h3><a name=\"$letter\">$letter</a></h3>
    <table>
    "
        
    set sub_counter 0

    while {[ns_db getrow $db $selection]} {
	incr counter
	incr sub_counter
	set_variables_after_query
	append html "
	<tr>
	<td><a href=\"/users/$screen_name\">$last_name, $first_names</a>
	</td>
	</tr>
	"
    }

    if {$sub_counter == 0} {
	append html "
	<tr>
	<td>
	Nobody here
	</td>
	</tr>
	"
    }

    append html "
    </table>
    <hr>"

    ns_write "$html"
    set html ""
}

# And finally, we're done with the database (duh)
ns_db releasehandle $db


ns_write "
</ul>
$counter member(s)
</table>
<p>
<center>

\[ <A HREF=\"#A\">A</A> | <A HREF=\"#B\">B</A> | 
<A HREF=\"#C\">C</A> | <A HREF=\"#D\">D</A> | <A HREF=\"#E\">E</A> | 
<A HREF=\"#F\">F</A> | <A HREF=\"#G\">G</A> | <A HREF=\"#H\">H</A> | 
<A HREF=\"#I\">I</A> | <A HREF=\"#J\">J</A> | <A HREF=\"#K\">K</A> | 
<A HREF=\"#L\">L</A> | <A HREF=\"#M\">M</A> | <A HREF=\"#N\">N</A> | 
<A HREF=\"#O\">O</A> | <A HREF=\"#P\">P</A> | <A HREF=\"#Q\">Q</A> | 
<A HREF=\"#R\">R</A> | <A HREF=\"#S\">S</A> | <A HREF=\"#T\">T</A> | 
<A HREF=\"#U\">U</A> | <A HREF=\"#V\">V</A> | <A HREF=\"#W\">W</A> | 
<A HREF=\"#X\">X</A> | <A HREF=\"#Y\">Y</A> | <A HREF=\"#Z\">Z</A> \] 
</center>

<br>
</blockquote>
[ad_footer]
"


