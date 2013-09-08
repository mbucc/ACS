#packages/acs-core/api-doc/www/proc-search.tcl

ad_page_contract {
    Searches for procedures with containing query_string
    if lucky redirects to best match
    Weight the different hits with the propper weights

    Shows a list of returned procs with links to proc-view

    0 database queries
    Note: api documentation information taken from nsv array

    @author Todd Nightingale (tnight@arsdigita.com)
    @date Jul 14, 2000
    @cvs-id proc-search.tcl,v 1.1.2.7 2000/07/27 21:51:06 tnight Exp
} {
    {name_weight:optional 0}
    {doc_weight:optional 0}
    {param_weight:optional 0}
    {source_weight:optional 0}
    {search_type:optional 0}
    query_string
}


##########################################################
##  Begin Page



set quick_view [string equal $search_type "Feeling Lucky"]
#########################
## Optimizes quick search
if {$quick_view && [nsv_exists api_proc_doc $query_string]} {
    ad_returnredirect [api_proc_url $query_string]
}


###########################
# No weighting use default:
if { ($name_weight == 0) && ($doc_weight == 0) && ($param_weight == 0) && ($source_weight ==0) } {
    set name_weight 1
}

set counter 0
set matches ""



# place a [list proc_name score positionals] into matches for every proc
foreach proc [nsv_array names api_proc_doc] { 

    set score 0
    array set doc_elements [nsv_get api_proc_doc $proc]

    ###############
    ## Name Search:
    ###############
    if {$name_weight} {
	##Exact match:
	if {[string tolower $query_string] == [string tolower $proc]} {
	    incr score $name_weight
	}
	incr score [expr $name_weight * [ad_keywords_score $query_string $proc]] 
    }
   
    ################
    ## Param Search:
    ################
    if {$param_weight} {
	incr score [expr $param_weight * [ad_keywords_score $query_string "$doc_elements(positionals) $doc_elements(switches)"]]
    }
    

    ##############
    ## Doc Search:
    ##############
    if {$doc_weight} {
	
	set doc_string "[lindex $doc_elements(main) 0]"
	if [info exists doc_elements(param)] {
	    foreach parameter $doc_elements(param) {
		append doc_string " $parameter"
	    }
	}
	if [info exists doc_elements(return)] {
	    append doc_string " $doc_elements(return)"
	}
	incr score [expr $doc_weight * [ad_keywords_score $query_string $doc_string]]
	
    }
    
    #################
    ## Source Search:
    #################
    if {$source_weight} {
	if {![catch {set source [info body $proc]}]} {
	    incr score [expr $source_weight * [ad_keywords_score $query_string $source]] 
	}    
    }

    #####
    ## Place Needed info in matches
    if {$score} {
	lappend matches [list $proc $score $doc_elements(positionals)]
    }
}

set matches [lsort -command ad_sort_by_score_proc $matches]

if {$quick_view && ![empty_string_p $matches]} {
    ad_returnredirect [api_proc_url [lindex [lindex $matches 0] 0]]
}

doc_set_property title "Procedure Search for: \"$query_string\""
doc_set_property navbar [list [list "" "API Browser"] "Search: $query_string"]
doc_set_property author "tnight@mit.edu"
doc_body_append "<h3>Procedure Matches:</h3><ul>"

foreach output $matches {
    incr counter
    set proc [lindex $output 0]    

    doc_body_append "
      <li>[lindex $output 1]: 
          <a href=[api_proc_url $proc]>$proc</a> 
          <i>[lindex $output 2]</i>"
}
doc_body_append "</ul>"

if {$counter == 0} {
    doc_body_append "Sorry, no procedures were found"
}


####################################
# Place another search box at bottom

doc_body_append "
<form action=proc-search method=get>
<table bgcolor=#DDDDDD cellpadding=15 border=0 cellspacing=0><tr><td valign=top>
   <b>ACS API Search:</b><br>
   <input type=text name=query_string value=$query_string><br>
   <input type=submit value=Search name=search_type>
   <input type=submit value=\"Feeling Lucky\" name=search_type>
 </td>
 <td><table cellspacing=0 cellpadding=0>
      <font size=-1>
      <tr><td align=right>Name:</td>
          <td><input type=checkbox name=name_weight value=5 [ad_decode $name_weight 0 "" "checked"]> </td>
      <tr><td align=right>Parameters:</td>
          <td><input type=checkbox name=param_weight value=3 [ad_decode $param_weight 0 "" "checked"]></td>
      <tr><td align=right>Documentation:</td>
          <td><input type=checkbox name=doc_weight value=2 [ad_decode $doc_weight 0 "" "checked"]></td>
      <tr><td align=right>Source:</td>
          <td><input type=checkbox name=source_weight value=1 [ad_decode $source_weight 0 "" "checked"]></td>
      </tr>
      </font>
      </table>
 </td>
</form></table>"







