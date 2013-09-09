# www/portals/stocks-personalize.tcl

ad_page_contract {
    page to personalize the stock quotes table in the portal
    
    @author aileen@mit.edu
    @author randyg@arsdigita.com
    @creation-date Jan 2000
    @cvs-id stocks-personalize.tcl,v 3.5.2.5 2000/09/22 01:39:01 kevin Exp
} {
}


set user_id [ad_verify_and_get_user_id]

set sql_query "select symbol from portal_stocks where user_id=:user_id"

set symbol_list ""
set count 0

# we're allowing 5 market indices
set num_indices 5 
set nasdaq_on ""
set djia_on ""
set snp_on ""
set search_on ""
set search_symbol ""

set page_content "
[ad_header "Portals @ ad_system_name"]
<h2>Personalize Stock Quotes</h2>
[ad_context_bar_ws [list /portals/user$user_id-1.ptl "Portal"] "Edit Stock Quotes"]
<hr>
<blockquote>
Your current list of stock symbols: (edit the list by clicking remove)
<p>
"

db_foreach portal_stocks_personalize_list_of_tables $sql_query {
    
    if {[string compare [string toupper $symbol] IXIC]==0} {
	set nasdaq_on "checked"
    } elseif {[string compare [string toupper $symbol] INDU]==0} {
	set djia_on "checked"
    } elseif {[string compare [string toupper $symbol] SPX]==0} {
	set snp_on "checked"
    } else {    
	append page_content "<li> $symbol ( <a href=\"stocks-remove.tcl?[export_url_vars symbol user_id]\">remove</a> )"
	incr count
    }
}

append page_content "

<form method=post action=stocks-personalize-2.tcl>
<input type=text size=30 name=symbol>
<p>
<input type=checkbox name=market_index1 $nasdaq_on value=IXIC>NASDAQ &nbsp;&nbsp;&nbsp;&nbsp;
<input type=checkbox name=market_index2 $djia_on value=INDU>DJIA &nbsp;&nbsp;&nbsp;&nbsp;
<input type=checkbox name=market_index3 $snp_on value=SPX>S&P 500
<p>
[export_form_vars num_indices ]
<input type=submit value=Edit>
Or <a href=\"stocks-search.tcl\">Search for a Stock</a>
</form>
</blockquote>
[ad_footer]
"


doc_return  200 text/html $page_content	









