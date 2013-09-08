# /www/portal/stock-search-2.tcl


ad_page_contract {

    This takes in a string to search for 
    goes out to yahoo and preforms a search for the
    correct sybmol.

    @author spears@arsdigita.com 
    @creation-date May 2000
    @param search_symbol search for stock symbol based on this string
    @cvs-id stocks-search-2.tcl,v 3.1.2.4 2000/09/22 01:39:01 kevin Exp
} { 
    search_symbol:notnull
}

set user_id [ad_verify_and_get_user_id]
set page_content ""
set count 0
set stock_html [ns_httpget "http://finance.yahoo.com/l?s=$search_symbol"]

if {[empty_string_p $stock_html]} {
    ad_complaint 1 "<li> Nothing was returned by our stock search engine"
    return
}

set rest $stock_html
append page_content " 
	[ad_header "Search Results @ [ad_system_name]"]
	<h2> Search Results for $search_symbol </h2>
	[ad_context_bar_ws [list /portals/user$user_id-1.ptl "Portal"] [list "stocks-search.tcl" "Search for Symbol"] "Search Results for $search_symbol"]
	<hr>
	<blockquote>
	Click on a stock symbol to add it to your stock list
	<br>
	"

while {![empty_string_p $rest] && $count < 20} {
	if { [regexp {<td>.+?s=(.+?)&d.+?<td>(.+?)\n(.*\n</table>)} $rest match symbol desc rest] } {
		if { ![empty_string_p $symbol] } {
			append page_content  "
				<li> Symbol: <a href=\"stocks-add.tcl?symbol=$symbol\">$symbol</a> - $desc <br>
			"
		}
	}
	incr count
}

append page_content "
	</blockquote>
	<br>
	[ad_footer]
  "


doc_return  200 text/html $page_content






