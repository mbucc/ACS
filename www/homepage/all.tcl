# File:     /homepage/all.tcl

ad_page_contract {
    Page to show all members.

    @author Usman Y. Mobin (mobin@mit.edu)
    @author jmp@arsdigita.com
    @creation-date Thu Jan 27 06:47:54 EST 2000
    @cvs-id all.tcl,v 3.3.2.9 2000/09/22 01:38:16 kevin Exp
} {
}

# Figure out what letters should be linked to
set letters [db_list homepage_letters {
    select distinct upper(substr(last_name, 1, 1)) as letter
      from users
      where screen_name is not null
      order by letter
}]

proc letter_to_url {letter} {
    return "<a href='#$letter'>$letter</a>"
}

set title "Homepages at [ad_parameter SystemName]"

# A packet of html
set page_content "
[ad_header $title]
<h2>$title</h2>
[ad_context_bar_ws_or_index $title] 
<hr>
<table width=100%>
<tr>
<td align=right>\[ <a href=neighborhoods>browse neighborhoods</a> \]
</td></tr></table>
<blockquote>

<center>
\[ [join [map letter_to_url $letters] " | "] \]
</center>

<br>

    <table bgcolor=DDEEFF border=0 cellspacing=0 cellpadding=8 width=90%>
    <tr><td>
    <b>These are the members with homepages at [ad_parameter SystemName]</b>
    <ul>
"

set old_letter ""
set counter 0

db_foreach select_all_by_letter {
    select upper(substr(u.last_name, 1, 1)) as letter,
           uh.user_id as user_id,
           u.screen_name as screen_name,
           u.first_names as first_names,
           u.last_name as last_name
      from users_homepages uh, users u
      where uh.user_id = u.user_id
        and u.screen_name is not null
      order by upper(u.last_name)
} {
    # Starting new letter?
    if ![string equal $old_letter $letter] {
	# In a letter before?
	if ![empty_string_p $old_letter] {
	    append page_content "
	        </table>
	        <hr>
	    "
	}
	append page_content "
	    <h3><a name='$letter'>$letter</a></h3>
	    <table>
	"
	set old_letter $letter
    }
    incr counter
    append page_content "
        <tr>
         <td><a href='/users/$screen_name'>$last_name, $first_names</a></td>
        </tr>
    "
}

if { $counter > 0 } {
    append page_content "
        </table>
        <hr>
    "
}

# And finally, we're done with the database
db_release_unused_handles

append page_content "
</ul>
$counter member(s)
</table>
<p>
<center>
\[ [join [map letter_to_url $letters] " | "] \]
</center>

<br>
</blockquote>
[ad_footer]
"

# Show them the page
doc_return  200 text/html $page_content
