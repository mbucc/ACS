# /www/bboard/admin-edit-msg-2.tcl
ad_page_contract {
    Makes changes to a posting by the admin

    @param msg_id the ID of the message to change
    @param one_line the new subject line of the message
    @param message the new message
    @param html_p is the message html?

    @cvs-id admin-edit-msg-2.tcl,v 3.2.2.5 2000/11/11 00:50:44 lars Exp
} {
    msg_id:notnull
    one_line:notnull
    message:allhtml,notnull
    {html_p:notnull "f"}
} -validate {
    html_p_ok { 
	if { ![string equal $html_p "t"] && ![string equal $html_p "f"] } {
	    ad_complain "html_p should be 't' for html-format, or 'f' for plaintext"
	}
    }
    html_security_check -requires { message:notnull } {
	if { [string equal $html_p "t"] } { 
	    set security_check [ad_html_security_check $message]
	    if { ![empty_string_p $security_check] } {
		ad_complain $security_check
	    }
	}
    }
}

# -----------------------------------------------------------------------------

db_1row message_info "
select bboard_topics.topic, 
       bboard.topic_id, 
       users.first_names || ' ' || users.last_name as name, 
       users.email 
from   bboard, 
       users, 
       bboard_topics
where  bboard.user_id = users.user_id
and    bboard_topics.topic_id = bboard.topic_id
and    msg_id = :msg_id"

if  {[bboard_get_topic_info] == -1} {
    return
}

if {[bboard_admin_authorization] == -1} {
    return
}

db_transaction {

    # is this usgeospatial?
    if { [info exists usgeospatial_p] } {
	set other_columns "epa_region = :epa_region,
	usps_abbrev = :usps_abbrev,
	fips_county_code = :fips_county_code,
	"
    } else {
	set other_columns ""
    }

    # Does this actually save any time/work?

    if { [string length $message] < 4000 } {
	db_dml update_no_clob "update bboard 
	set one_line = :one_line,
	html_p = :html_p,
	$other_columns
	message = :message
	where msg_id = :msg_id"
    } else {
	db_dml $db "update bboard 
	set one_line = :one_line,
	html_p = :html_p,
	$other_columns
	message = empty_clob()
	where msg_id = :msg_id
	returning message into :1" -clobs [list $message]
    }

}


append page_content "
[bboard_header "\"$one_line\" updated"]

<h3>Message $one_line</h3>

Updated in the database - 
(<a href=\"admin-home?[export_url_vars topic topic_id]\">main admin page</a>)



<hr>

<ul>
<li>subject line:  $one_line
<li>from:  $name ($email)
"

if { [info exists usgeospatial_p] } {
    append page_content "<li>EPA Region: $epa_region
<li>USPS: $usps_abbrev
<li>FIPS: $fips_county_code
"
}

append page_content "<li>message: [util_maybe_convert_to_html $message $html_p]
</ul>




[bboard_footer]
"

doc_return  200 text/html $page_content