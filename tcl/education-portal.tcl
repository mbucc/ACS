##
## /tcl/education-portal.tcl
##
## Procs used on Sloan Portal
## 
## written by Aileen Tang aileen@arsdigita.com
##
## Jan. 24, 2000
##

proc_doc DisplayStockQuotes {db} "Displays the table of stock quotes stored for the user id. if no user id, just return a default set of quotes" {
    set memoize_timeout 1200

    set user_id [ad_verify_and_get_user_id]

    set html "
    <a href=/portals/stocks-personalize.tcl>Edit</a>
    <p>
    <table border=1 cellpadding=2>
    <tr><th>Symbol</th><th>Price</th><th>Change</th><th>Percent Change</th>
    </tr>"

    if {$user_id!=""} {
	set selection [ns_db select $db "select symbol, default_p from portal_stocks where user_id=$user_id order by default_p desc"]

	while {[ns_db getrow $db $selection]} {
	    set_variables_after_query
	    
	    set url "http://quotes.nasdaq-amex.com/Quote.dll?page=quick&mode=Stock&symbol=$symbol"
	    set page [string tolower [util_memoize "ns_geturl $url" $memoize_timeout]]
	    set price ""
	    set up_down ""
	    set change "-"
	    set percent_change ""
	    set volume ""

#	    regexp {<nobr><b>([^a-z]*)</b></nobr></td>.*<td nowrap valign="top" align="right"> <font face=arial,helvetica size=-1><nobr><b><font color="(.*)">(.*)</font><img src=.* border=0 width=11 height=10></b></nobr></td>.*<td nowrap valign="top" align="right"> <font face=arial,helvetica size=-1><nobr><b><font color=".*">(.*)</b></nobr></td>.*<td nowrap valign="top" align="right"> <font face=arial,helvetica size=-1>(.*)</td>.*<td} $page match price up_down change percent_change volume 
	    
	    if {$default_p=="f"} {
		regexp {\$ *([0-9\.]+)} $page match price
	    } else {
		regexp {<nobr><b>([0-9\.]+)</b></nobr></td>} $page match price	
	    }	

	    #		regexp {<nobr><b>(.*)</b></nobr>} $page match price
	    regexp {<nobr><b><font color="(.*)">[^0-9]*([0-9\.]*)[^0-9]*</font><img src=} $page match up_down change
	    regexp {<td nowrap valign="top" align="right">.*<nobr><b><font color=".*">[^0-9]*([0-9\.]*)[^0-9]*\%</b></nobr></td>} $page match percent_change

	    #	<td nowrap valign="top" align="right"> <font face=arial,helvetica size=-1>n/a</td>
	    #	<td> <font face=arial,helvetica size=-1>&nbsp;</td>
	    
#	    regexp {<nobr><b>([^a-z]*)</b></nobr></td>} $page match price
	    #	    regexp {<font face=arial,helvetica size=-1><nobr><b><font color="(.*)">([^a-z]*)</font><img src=.* border=0 width=11 height=10></b></nobr></td>} $page match up_down change
		#	    regexp {<nobr><b><font color=".*">([^a-z]*)</b></nobr></td>} $page match percent_change
	    #	    regexp {<td nowrap valign="top" align="right"> <font .*>(.*)</td>.*<td nowrap valign="top" align="left">&nbsp;</td>} $page match volume
	    
	    append html "
	    <tr><td align=center>"

	    if {$default_p=="t"} {
		append html "<b>"
	    }

	    append html "[string toupper $symbol]</td>
	    <td align=center nowrap>\$ $price</td>
	    <td align=center><font color=$up_down>$change</td>
	    <td align=center><font color=$up_down>$percent_change \%</TD>
	    </TR>
	    "
	}
    } else {
	append html ""
    }

    append html "</table>"

    return $html
}

proc_doc DisplayWeather {db} "Displays the weather information that the given user has requested (or default info if the user does not have any entries)." {
    set memoize_timeout 3600

    set user_id [ad_verify_and_get_user_id]

    if {$user_id!=""} {
	set selection [ns_db select $db "
	select * from portal_weather where user_id=$user_id"]

	set count 0
	set html "
	<a href=/portals/weather-personalize.tcl>Edit</a>
	<p>
	<table border=1>
	<tr><th bgcolor=[ad_parameter HeaderBGColor portals] colspan=2><b><font color=white>Current Conditions:</font></th></tr>
	"

	while {[ns_db getrow $db $selection]} {
	    set_variables_after_query
	    
	    if {![empty_string_p $zip_code]} {
		set url "http://www.weather.com/weather/us/zips/[set zip_code].html"
	    } else {
		# replace the spaces in city with underscores
		regsub -all {[ ]+} $city "_" underscored_city
		
		set url [string tolower "http://www.weather.com/weather/cities/us_[set usps_abbrev]_[set underscored_city].html"]
	    }
		
	    set page [util_memoize "ns_geturl $url" $memoize_timeout]

	    regexp {Last updated.*at (.*) time.*<BR>[^0-z]*</FONT><BR>} $page match date_time

	    regexp {<FONT FACE="Arial, Helvetica, Chicago, Sans Serif" SIZE="2">[^0-9]*([0-9]*)&deg;F.*</FONT></TD>} $page match temperature
	    regexp {<FONT FACE="Arial, Helvetica, Chicago, Sans Serif" SIZE=5><B>([A-z]*), [A-z][A-z] \([0-9]*\)</B></FONT><BR>} $page match city
	    regexp {<FONT FACE="Arial, Helvetica, Chicago, Sans Serif" SIZE=3>
            <B>([^0-9]*)</B>} $page match condition

#	    set date_time ""
#	    set time_zone ""
	    append html "
	    <tr><th>$city</th>
	    <td>$condition: $temperature &deg;F <i>($date_time)</i></td></tr>
	    "
	}

	append html "</table>"
    } else {
	set html "Please log in and customize your table"
    }

    return $html
}

proc_doc RawQuoteToDecimal {raw_quote} "Converts a raw stock quote into a decimal for a bettter UI" {

    if { [regexp {(.*) (.*)} $raw_quote match whole fraction] } {

	# there was a space

	if { [regexp {(.*)/(.*)} $fraction match num denom] } {

	    # there was a "/"

	    set extra [expr double($num) / $denom]

	    return [expr $whole + $extra]

	}

	# we couldn't parse the fraction
	return $whole
    } else {
	# we couldn't find a space, assume integer
	return $raw_quote
    }
}


proc_doc AddCityWeatherWidget {db} "returns the html form for adding a city to the weather table by city/state or zip code" {
    set weather_id [database_to_tcl_string $db "select weather_id_sequence.nextval from dual"]
    
    return "
    <form method=post action=weather-personalize-2.tcl>
    [export_form_vars weather_id]
    <table cellpadding=2>
    <tr><th align=right>City</th>
    <td><input type=text size=30 name=city></td>
    </tr>
    <tr>
    <th align=right>State</th>
    <td>[state_widget $db]</td>
    </tr>
    <tr>
    <th colspan=2>or</th>
    </tr>
    <tr>
    <th align=right>Zip Code</th>
    <td><input name=zip_code type=text size=5 maxsize=5></td>
    </tr>
    <tr>
    <th colspan=2><hr></th>
    </tr>
    <tr>
    <th colspan=2><input type=checkbox name=current_p value=t checked>Current Conditions &nbsp;&nbsp;&nbsp;&nbsp; 
    </th>
    </tr>
    <tr>
    <th></th>
    <td><input type=submit value=Add></td>
    </tr>
    </table>
    </form>
    "

#<input type=checkbox name=next_day_p value=t>Next Day Forecast &nbsp;&nbsp;&nbsp;&nbsp; <input type=checkbox name=five_day_p value=t>Five Day Forecast
}


proc_doc GetClassHomepages {db} "returns the list of class homepages/admin pages that the user is a member of" {
    set user_id [ad_verify_and_get_user_id]

    set selection [ns_db select $db "
    select c.class_id, c.class_name, chat_room_id, topic_id, admin_group_id
    from edu_current_classes c, user_group_map m, 
    chat_rooms chat, bboard_topics t,
    (select ugm.group_id as admin_group_id 
     from user_group_action_role_map arm, user_group_map ugm
     where ugm.user_id=$user_id
     and ugm.group_id=arm.group_id
     and arm.role=ugm.role
     and arm.action='View Admin Pages') admin_group
    where m.group_id=c.class_id
    and m.group_id=chat.group_id(+)
    and m.user_id=$user_id
    and c.class_id=t.group_id(+)
    and m.group_id=admin_group.admin_group_id(+)
    order by class_name"]
    
    set class_info "<a href=[edu_url]util/group-type-view.tcl?group_type=edu_class>Join a Class</a> | <a href=/pvt/home.tcl>Profile</a> | <a href=/register/logout.tcl>Log Out</a>
    <ul>
    "

    set old_class_id ""
    set return_url "[edu_url]class/one.tcl"
    set return_admin_url "[edu_url]class/admin/index.tcl"

    while {[ns_db getrow $db $selection]} {
	set_variables_after_query

	# skip the repeat rows of classes because these classes have > 1 bboard_topic
	if {$class_id!=$old_class_id} {	    
	    set old_class_id $class_id
	    
	    append class_info "<li><a href=\"/education/util/group-login.tcl?group_id=$class_id&group_type=edu_class&[export_url_vars return_url]\">$class_name</a>"

	    # user has view admin page priviledges to this group
	    if {$admin_group_id!=""} {
		append class_info "
		| <a href=/education/util/group-login.tcl?return_url=[ns_urlencode $return_admin_url]&group_type=edu_class&group_id=$class_id>Admin page</a>"
	    }
	    
	    if {$topic_id!=""} {
		append class_info "
		| <a href=/bboard/index.tcl?group_id=$class_id>Discussion board</a>"
	    }
	    
	    if {$chat_room_id!=""} {
		append class_info "
		| <a href=/chat/enter-room.tcl?chat_room_id=$chat_room_id>Chat room</a>"
	    }
	}
    }

    append class_info "</ul>"

    return $class_info
}

proc_doc GetNewsItems {db} "returns the list of news items relevant to the user" {
    set user_id [ad_verify_and_get_user_id]
    
    set selection [ns_db select $db "
    select distinct news.title, news_item_id, ng.scope,
           news.newsgroup_id, g.group_name 
    from user_groups g, user_group_map m, users, news_items news, newsgroups ng
    where users.second_to_last_visit < creation_date
    and release_date <= sysdate
    and expiration_date > sysdate
    and news.approval_state = 'approved'
    and m.group_id = g.group_id
    and users.user_id=30
    and m.user_id=users.user_id
    and g.group_id in (select group_id
                       from news_items n2, newsgroups ng2 
                       where n2.newsgroup_id = ng2.newsgroup_id 
                       and m.group_id=ng2.group_id) 
    and g.group_id=ng.group_id(+)
    order by news_item_id
    "]

    set html ""

    set old_news_id "NULL"
    set old_group_id "NULL"
    set count 0

    while {[ns_db getrow $db $selection]} {
	set_variables_after_query

	if {$old_group_id != $group_id} {
	    set old_group_id $group_id
	    
	    if {$count} {
		append html "</ul>"
	    }

	    if {$group_id != ""} {
		append html "
		<p><b>$group_name</b></p>"
	    } elseif {$user_id!=""} {
		append html "
		<p><b>Personal News</b></p>"
	    } else {
		append html "
		<p><b>Public News</b></p>"
	    }

	    append html "<ul>"
	}

	
	if {$old_news_id!=$news_id} {
	    set old_news_id $news_id
	    append html "
	    <li><a href=/news/item.tcl?news_id=$news_id>$title</a>"
	    incr count
	}
    }

    if {$count} {
	append html "</ul>"
    } else {
	append html "There are no new announcements since your last login"
    }

    return $html
}


