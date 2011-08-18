# /portals/stocks-personalize.tcl
#
# aileen@mit.edu, randyg@arsdigita.com
#
# Jan 2000
#
# page to personalize the stock quotes table in the portal

set user_id [ad_verify_and_get_user_id]
set db [ns_db gethandle]

set selection [ns_db select $db "select symbol from portal_stocks where user_id=$user_id"]

ReturnHeaders

set symbol_list ""
set count 0

# we're allowing 5 market indices
set num_indices 5 
set nasdaq_on ""
set djia_on ""
set snp_on ""

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    
    if {[string compare [string toupper $symbol] IXIC]==0} {
	set nasdaq_on "checked"
    } elseif {[string compare [string toupper $symbol] INDU]==0} {
	set djia_on "checked"
    } elseif {[string compare [string toupper $symbol] SPX]==0} {
	set snp_on "checked"
    } else {    
	if {$count} {
	    append symbol_list ","
	}
	
	append symbol_list [string toupper $symbol]
    }
    incr count
}

ns_write "
[ad_header "Portals @ [ad_system_name]"]
<h2>Personalize Stock Quotes</h2>
[ad_context_bar_ws [list /portals/user$user_id-1.ptl "Portal"] "Edit Stock Quotes"]
<hr>
<blockquote>
Your current list of stock symbols: (edit the list by adding/deleting comma-separated stock symbols)
<p>
<form method=post action=stocks-personalize-2.tcl>
[edu_textarea symbols $symbol_list 80 5]
<p>
<input type=checkbox name=market_index1 $nasdaq_on value=IXIC>NASDAQ &nbsp;&nbsp;&nbsp;&nbsp;
<input type=checkbox name=market_index2 $djia_on value=INDU>DJIA &nbsp;&nbsp;&nbsp;&nbsp;
<input type=checkbox name=market_index3 $snp_on value=SPX>S&P 500
<p>
[export_form_vars num_indices]
<input type=submit value=Edit>
</form>
</blockquote>
[ad_footer]
"

	