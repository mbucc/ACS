# $Id: lookup.tcl,v 3.0.4.1 2000/04/28 15:08:30 carsten Exp $
set_the_usual_form_variables

# word

if {[empty_string_p $word]} {
    ad_returnredirect "all.tcl"
    return
} 

ReturnHeaders

set title "Tagged Word Results" 

ns_write "[ad_admin_header $title]

<h2>$title</h2>

[ad_admin_context_bar [list "index.tcl" "Naughty Package"] $title]

<hr>

<form action=rate.tcl method=post>
[export_entire_form]
"

set db [ns_db gethandle]
set pretty_tag(0) "Rated G"
set pretty_tag(1) "Rated PG"
set pretty_tag(3) "Rated R"
set pretty_tag(7) "Rated X"

set sql "select tag from content_tags where word='$QQword'"
set selection [ns_db 0or1row $db $sql]

if {![empty_string_p $selection]} {
    set_variables_after_query
    ns_write "<input type=hidden name=todo value=update>\n"
} else {
    set tag 0
    ns_write "<b>$word</b> is not yet rated<P>
    <input type=hidden name=todo value=create>\n"
}

ns_write "<p>Give a rating to <b>$word</b>:<ul>"

foreach potential_tag {0 1 3 7} {
    if { $tag != $potential_tag } {
	ns_write "<li><input type=radio name=tag value=$potential_tag> $pretty_tag($potential_tag)"
    } else {
	ns_write "<li><input type=radio name=tag value=$potential_tag checked> $pretty_tag($potential_tag)"
    }
}
ns_write "
<P> (A \"G\" rating will remove the word from the database)
</ul>
<center>
<input type=submit value=Rate>
</form>
</center>

[ad_admin_footer]
"




