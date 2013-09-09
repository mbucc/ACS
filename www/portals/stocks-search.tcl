# /www/portal/stocks-search.tcl

ad_page_contract {
    This takes in a string to search and
    passes it to stock-search-2.tcl

    @author spears@arsdigita.com 
    @creation-date May 2000
    @cvs-id  stocks-search.tcl,v 3.1.2.3 2000/09/22 01:39:02 kevin Exp
} {

}

set user_id [ad_verify_and_get_user_id]

set search_symbol ""

set return_string "

	[ad_header "Stock Symbol Search @ [ad_system_name]"]
	<h2> Search for Stock Symbols </h2>
	[ad_context_bar_ws [list /portals/user$user_id-1.ptl "Portal"] "Search for Symbol"]
        <hr>
	<blockquote>
	To Search for a Stock Sybmol enter it in the box and click on search
	<p>
	<form method=post action=stocks-search-2.tcl>
        <input type=text name=search_symbol>	
	<p>
 	<input type=submit value=Search>
	</form>
	</blockquote>
	[ad_footer]
"	
		
doc_return  200 text/html $return_string





