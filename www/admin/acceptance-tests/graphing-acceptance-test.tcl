# /www/admin/acceptance-test/graphing-acceptance-test.tcl

ad_page_contract {
    @author ?
    @creation-date ?
    @cvs-id graphing-acceptance-test.tcl,v 1.2.2.3 2000/09/22 01:34:17 kevin Exp
} 

set legend [list "1997" "1998" "1999" "2000"]

set subcategory_category_and_value_list [list [list "Dog" "Favorite Animal" [list "45" "47" "40" "45"]] \
	[list "Cat" "Favorite Animal" [list "20" "21" "19" "21"]] \
	[list "Other" "Favorite Animal" [list "35" "32" "41" "34"]] \
	[list "Pizza" "Favorite Food" [list "34" "33" "35" "35"]] \
	[list "Chocolate" "Favorite Food" [list "24" "25" "24" "25"]] \
	[list "Other" "Favorite Food" [list "42" "42" "41" "40"]]]


doc_return  200 text/html "<font face=arial size=+2>Madrona Elementary School Annual Poll Results</font>
<p>
[gr_sideways_bar_chart -legend $legend $subcategory_category_and_value_list]
"