# $Id: ecommerce-styles.tcl,v 3.0 2000/02/06 03:13:23 ron Exp $
## Styles for the ecommerce module
## Started April, 1999 by Eve Andersson (eveander@arsdigita.com)
## Other ecommerce procedures can be found in ecommerce-*.tcl

## Note: the style module documentation recommends releasing the
## database handle before returning the template BUT we actually
## need a database connection to do the page footer, so don't
## release it.

util_report_library_entry 

ad_register_styletag "ec_header" "insert the standard ecommerce header" {
    eval "uplevel { ad_header \[subst \"$string\"\] }"
}

ad_register_styletag "ec_header_image" "insert the standard ecommerce header image" {
    uplevel { ec_header_image }
}

ad_register_styletag "ec_navbar" "insert the standard ecommerce navigation bar; the location parameter can be used to specify the current location, either \"Shopping Cart\" or \"Your Account\" or \"Home\"" {
#    upvar db db
    
    eval "uplevel { ec_navbar \$db \[subst \"$string\"\] }"
}

ad_register_styletag "ec_footer" "insert the standard ecommerce section footer;  the location parameter can be used to specify the current location, either \"Shopping Cart\" or \"Your Account\" or \"Home\", the category parameter can be used to specify the category that is selected in by default, and the text parameter can be used to specify the default search string." { 
    upvar db db
    upvar category_id category_id
    upvar search_text search_text

    if { ![info exists category_id] || $category_id == ""} {
	set category [DoubleApos [ns_set get $tagset "category"]]
	if {$category == ""} {
	    set category_id ""
	} else {
	    set category_id [database_to_tcl_string $db "select category_id from ec_categories where category_name = '$category'"]
	}
    }
    if { ![info exists search_text] || $search_text == ""} {
	set search_text [ns_set get $tagset "text"]
    }

    ec_footer $db $string $category_id $search_text
}

ad_register_styletag "ec_search" "insert the standard ecommerce search bar; the category parameter can be used to specify the category that is selected in by default, and the text parameter can be used to specify the default search string." { 
    upvar db db
    upvar category_id category_id

    if { ![info exists category_id] || $category_id == ""} {
	set category [DoubleApos [ns_set get $tagset "category"]]
	if {$category == ""} {
	    set category_id ""
	} else {
	    set category_id [database_to_tcl_string $db "select category_id from ec_categories where category_name = '$category'"]
	}
    }

    ec_search_widget $db $category_id $string
}

ad_register_styletag "ec_dbresults" "insert the formatted results of a database query" {
    upvar db db
    upvar ec_dbresults ec_dbresults

    if { [info exists ec_dbresults] } {
	return $ec_dbresults
    } else {
	return "<blockquote>
<pre>
<b>No database results available.</b>
We can't find any database query results for this style template.
Please contact <a href=\"mailto:[ad_host_administrator]\">[ad_host_administrator]</a>
</pre>
</blockquote>"
    }
}

ad_register_styletag "ec_user_string" "insert a user-specific string" {
    upvar db db
    upvar ec_user_string ec_user_string

    if { [info exists ec_user_string] } {
	return $ec_user_string
    } else {
	return "<blockquote>
<pre>
<b>No user string.</b>
We can't find a user-specific string for this style template.
Please contact <a href=\"mailto:[ad_host_administrator]\">[ad_host_administrator]</a>
</pre>
</blockquote>"
    }
}

ad_register_styletag "ec_parameter" "insert an ecommerce ini file parameter" {
    ad_parameter $string ecommerce
}

util_report_successful_library_load


















