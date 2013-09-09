# /www/manual/figure-view.tcl
ad_page_contract {
    Show a figure independently of its section.  This is only used to
    pop up a view of the figure in a new browser window, so the HTML is
    served without any header, footer, or other navigation stuff.

    @param figure_id the ID of the figure we are displaying

    @author Kevin Scaldeferri (kevin@caltech.edu)
    @creation-date Feb 2000
    @cvs-id figure-view.tcl,v 1.3.2.4 2000/09/22 01:38:53 kevin Exp
} {
    figure_id:integer,notnull
}

# -----------------------------------------------------------------------------

page_validation {
    if { ! [db_0or1row info_for_one_figure "
    select manual_id, 
    	   height, 
    	   width, 
    	   caption, 
    	   sort_key, 
    	   label,
    	   numbered_p,
    	   decode(file_type,'image/gif','gif','jpg') as ext
    from   manual_figures 
    where  figure_id = :figure_id"]} {
	
	error "Figure id=$figure_id does not exist.\n"
    }
}

set title ""
set contents "<IMG SRC=\"/manuals/figures/${manual_id}.${figure_id}.$ext\" ALT=\"$label\" 
               HEIGHT=$height WIDTH=$width>"

if {$numbered_p == "t"} {
    append title "Figure $sort_key"
    append contents "\n<br>Figure $sort_key : $caption"
}

db_release_unused_handles

# -----------------------------------------------------------------------------

doc_return  200 text/html "
<html>
<head>
<title>$title</title>
</head>
<body bgcolor=white>
$contents
</body>
</html>"
