# $Id: index.tcl,v 3.0 2000/02/06 03:31:53 ron Exp $
ReturnHeaders

ns_write "[ad_admin_header "Merge Users"]

<h2>Merge Users</h2>

<hr>

This is a good place to be if you're interested in undoing the damage
done when the same person registers twice with two different email
addresses.

<p>

It is particularly useful for situations where you've installed the
ArsDigita Community System on top of legacy systems that are keyed by
email address.  In fact, it was written for http://photo.net/photo/
where user-contributed content was keyed by email address for four
years (hence there were many users who'd flowed through three or four
email addresses in that time).

<p>

Start by looking at all users 

<ul>
<li><a href=\"users-all.tcl?order_by=email\">ordered by email</a>
<li><a href=\"users-all.tcl?order_by=last_name\">ordered by last name</a>
<li><a href=\"users-all.tcl?order_by=first_names\">ordered by first name</a>

</ul>

[ad_admin_footer]
"
