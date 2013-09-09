# /shared/confirm.tcl

ad_page_contract {
    General confirmation script

    @author lars@pinds.com
    @creation-date June 5, 2000
    @cvs-id confirm.tcl,v 3.1.2.3 2000/09/22 01:39:18 kevin Exp
} {
    { header "Confirm" } 
    message
    yes_url
    no_url 
    { yes_label "Yes, Proceed" }
    { no_label "No, Cancel" }
}

set yes_list [split $yes_url "?"]
set yes_path [lindex $yes_list 0]
set yes_args_set [ns_parsequery [lindex $yes_list 1]]

set no_list [split $no_url "?"]
set no_path [lindex $no_list 0]
set no_args_set [ns_parsequery [lindex $no_list 1]]

db_release_unused_handles

doc_return  200 text/html "
[ad_header $header]

<h2>$header</h2>

<hr>

$message

<p>

<table align=center>
<tr>

<td>
<form method=get action=\"$yes_path\">
[export_ns_set_vars form {} $yes_args_set]
<input type=submit value=\"$yes_label\">
</form>
</td>

<td>
<form method=get action=\"$no_path\">
[export_ns_set_vars form {} $no_args_set]
<input type=submit value=\"$no_label\">
</form>
</td>

</tr>
</table>

[ad_footer]
"
