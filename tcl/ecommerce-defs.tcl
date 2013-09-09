# /tcl/ecommerce-defs.tcl
ad_library {
    Definitions for the ecommerce module
    Note: Other ecommerce procedures can be found in ecommerce-*.tcl

    @cvs-id ecommerce-defs.tcl,v 3.16.2.20 2001/01/15 19:51:40 kevin Exp
    @author Eve Andersson (eveander@arsdigita.com)
    @creation-date April, 1999 
}


proc ec_system_name {} {
    return "[ad_parameter SystemName] Store"
}

proc ec_header_image {} {
    return "<font size=+2 face=\"arial\" color=990000>[ec_system_name]</font>"
}

proc ec_system_owner {} {
    return [ad_system_owner]
}

# current_location can be "Shopping Cart", "Your Account", "Home", or
# any category_id
proc ec_footer { {current_location ""} {category_id ""} {search_text ""} } {
    set to_return "<hr>
<center>
[ec_search_widget $category_id $search_text] "
    if { [string compare $current_location "Shopping Cart"] == 0 } {
	append to_return "<b>Shopping Cart</b>"
    } else {
	append to_return "<a href=\"[ec_insecure_url][ad_parameter EcommercePath ecommerce]shopping-cart\">Shopping Cart</a>"
    }
    append to_return " | "
    if { [string compare $current_location "Your Account"] == 0 } {
	append to_return "<b>Your Account</b>"
    } else {
	append to_return "<a href=\"[ec_insecure_url][ad_parameter EcommercePath ecommerce]account\">Your Account</a>"
    }
    append to_return " | "
    if { [string compare $current_location "Home"] == 0 } {
	append to_return "<b>Home</b>"
    } else {
	append to_return "<a href=\"[ec_insecure_url][ad_parameter EcommercePath ecommerce]index\">Home</a>"
    }
    append to_return "<br>
    [ad_site_home_link]
    </center>
    "
    return $to_return
}

# For administrators
proc ec_shipping_cost_summary { base_shipping_cost default_shipping_per_item weight_shipping_cost add_exp_base_shipping_cost add_exp_amount_per_item add_exp_amount_by_weight } {

    set currency [ad_parameter Currency ecommerce]

    if { ([empty_string_p $base_shipping_cost] || $base_shipping_cost == 0) && ([empty_string_p $default_shipping_per_item] || $default_shipping_per_item == 0) && ([empty_string_p $weight_shipping_cost] || $weight_shipping_cost == 0) && ([empty_string_p $add_exp_base_shipping_cost] || $add_exp_base_shipping_cost == 0) && ([empty_string_p $add_exp_amount_per_item] || $add_exp_amount_per_item == 0) && ([empty_string_p $add_exp_amount_by_weight] || $add_exp_amount_by_weight == 0) } {
	return "The customers are not charged for shipping beyond what is specified for each product individually."
    }

    if { [empty_string_p $base_shipping_cost] || $base_shipping_cost == 0 } {
	set shipping_summary "For each order, there is no base cost.  However, "
    } else {
	set shipping_summary "For each order, there is a base cost of [ec_pretty_price $base_shipping_cost $currency].  On top of that,  "
    }

    if { ([empty_string_p $weight_shipping_cost] || $weight_shipping_cost == 0) && ([empty_string_p $default_shipping_per_item] || $default_shipping_per_item == 0) } {
	append shipping_summary "the per-item cost is set using the amount in the \"Shipping Price\" field of each item (or \"Shipping Price - Additional\", if more than one of the same product is ordered).  "
    } elseif { [empty_string_p $weight_shipping_cost] || $weight_shipping_cost == 0 } {
	append shipping_summary "the per-item cost is [ec_pretty_price $default_shipping_per_item $currency], unless the \"Shipping Price\" has been set for that product (or \"Shipping Price - Additional\", if more than one of the same product is ordered).  "
    } else {
	append shipping_summary "the per-item-cost is equal to [ec_pretty_price $weight_shipping_cost $currency] times its weight in [ad_parameter WeightUnits ecommerce], unless the \"Shipping Price\" has been set for that product (or \"Shipping Price - Additional\", if more than one of the same product is ordered).  "
    }

    if { ([empty_string_p $add_exp_base_shipping_cost] || $add_exp_base_shipping_cost == 0) && ([empty_string_p $add_exp_amount_per_item] || $add_exp_amount_per_item == 0) && ([empty_string_p $add_exp_amount_by_weight] || $add_exp_amount_by_weight == 0) } {
	set express_part_of_shipping_summary "There are no additional charges for express shipping.  "
    } else {
	if { ![empty_string_p $add_exp_base_shipping_cost] && $add_exp_base_shipping_cost != 0 } {
	    set express_part_of_shipping_summary "An additional amount of [ec_pretty_price $add_exp_base_shipping_cost $currency] is added to the base cost for Regular Shipping.  "
	}
	if { ![empty_string_p $add_exp_amount_per_item] && $add_exp_amount_per_item != 0 } {
	    append express_part_of_shipping_summary "An additional amount of [ec_pretty_price $add_exp_amount_per_item $currency] is added for each item, on top of the amount charged for Regular Shipping.  "
	}
	if { ![empty_string_p $add_exp_amount_by_weight] && $add_exp_amount_by_weight != 0 } {
	    append express_part_of_shipping_summary "An additional amount of [ec_pretty_price $add_exp_amount_by_weight $currency] times the weight in [ad_parameter WeightUnits ecommerce] of each item is added, on top of the amount charged for Regular Shipping.  "
	}
    }

return "Regular (Non-Express) Shipping:
<p>
<blockquote>
$shipping_summary
</blockquote>
<p>
Express Shipping:
<p>
<blockquote>
$express_part_of_shipping_summary
</blockquote>
"
}

# for one product, displays the sub/sub/category info in a table.
proc_doc ec_category_subcategory_and_subsubcategory_display { category_list subcategory_list subsubcategory_list } "Returns an HTML table of category, subcategory, and subsubcategory information" {

    if { [empty_string_p $category_list] } {
	return "None Defined"
    }

    set to_return "<table border=0 cellspacing=0 cellpadding=0>\n"
    foreach category_id $category_list {
	append to_return "<tr>\n"
	set tr_done 1

	if { ![empty_string_p $subcategory_list] } {
	    set relevant_subcategory_list [db_list subcategories_select "
		select subcategory_id from ec_subcategories where category_id = :category_id and subcategory_id in ([join $subcategory_list ", "]) order by subcategory_name
            "]
	} else {
	    set relevant_subcategory_list [list]
	}

	if { [llength $relevant_subcategory_list] == 0 } {
	    append to_return "<td valign=top>[ec_space_to_nbsp [db_string category_name_select_1 {
                select category_name from ec_categories where category_id = :category_id
            }]]</td><td></td><td></td>\n"
	} else {
	    append to_return "<td valign=top rowspan=[llength $relevant_subcategory_list]>[ec_space_to_nbsp [db_string category_name_select_2 {
                select category_name from ec_categories where category_id = :category_id
            }]]</td>"

	    foreach subcategory_id $relevant_subcategory_list {

		if { $tr_done } {
		    set tr_done 0
		} else {
		    append to_return "<tr>\n"
		}

		append to_return "<td valign=top>&nbsp;--&nbsp;[ec_space_to_nbsp [db_string subcategory_name_select_1 {
                    select subcategory_name from ec_subcategories where subcategory_id = :subcategory_id
                }]]</td><td valign=top>"

		if { ![empty_string_p $subsubcategory_list] } {
		    set relevant_subsubcategory_name_list [db_list subcategory_name_select_2 "
			select subsubcategory_name from ec_subsubcategories where subcategory_id = :subcategory_id and subsubcategory_id in ([join $subsubcategory_list ","]) order by subsubcategory_name
                    "]
		} else {
		    set relevant_subsubcategory_name_list [list]
		}
		
		foreach subsubcategory_name $relevant_subsubcategory_name_list {
		    append to_return "&nbsp;--&nbsp;[ec_space_to_nbsp $subsubcategory_name]<br>\n"
		}

		append to_return "</td></tr>"

	    } ; # end foreach subcategory_id

	} ; # end of case where relevant_subcategory_list is non-empty

    } ; # end foreach category_id
    append to_return "</table>\n"
    return $to_return
}

proc ec_product_name_internal {product_id} {
    return [db_string product_name_select {
	select product_name from ec_products where product_id = :product_id
    } -default ""]
}

proc_doc ec_product_name {product_id {value_if_not_found ""}} "Returns product name from product_id, memoized for efficiency" {
    # throw an error if this isn't an integer (don't want security risk of user-entered
    # data being eval'd)
    validate_integer "product_id" $product_id
    set tentative_name [util_memoize "ec_product_name_internal $product_id" 3600]
    if [empty_string_p $tentative_name] {
	return $value_if_not_found
    } else {
	return $tentative_name
    }
}

# given a category_id, subcategory_id, and subsubcategory_id
# (can be null), displays the full categorization, e.g.
# category_name: subcategory_name: subsubcategory_name.
# If you have a subcategory_id but not a category_id, this
# will look up the category_id to find the category_name.
proc ec_full_categorization_display { {category_id ""} {subcategory_id ""} {subsubcategory_id ""} } {
    if { [empty_string_p $category_id] && [empty_string_p $subcategory_id] && [empty_string_p $subsubcategory_id] } {
	return ""
    } elseif { ![empty_string_p $subsubcategory_id] } {

	if { [empty_string_p $subcategory_id] } {
	    set subcategory_id [db_string subcategory_id_select {
		select subcategory_id from ec_subsubcategories where subsubcategory_id = :subsubcategory_id
	    }]
	}

	if { [empty_string_p $category_id] } {
	    set category_id [db_string category_id_select {
		select category_id from ec_subcategories where subcategory_id = :subcategory_id
	    }]
	}

	return "[db_string category_name_select {select category_name from ec_categories where category_id = :category_id}]: [db_string subcategory_name_select {select subcategory_name from ec_subcategories where subcategory_id = :subcategory_id}]: [db_string subsubcategory_name_select {select subsubcategory_name from ec_subsubcategories where subsubcategory_id = :subsubcategory_id}]"

    } elseif { ![empty_string_p $subcategory_id] } {

	if { [empty_string_p $category_id] } {
	    set category_id [db_string category_id_select {
		select category_id from ec_categories where subcategory_id = :subcategory_id
	    }]
	}

	return "[db_string category_name_select {select category_name from ec_categories where category_id = :category_id}]: [db_string subcategory_name_select {select subcategory_name from ec_subcategories where subcategory_id = :subcategory_id}]"

    } else {

	return "[db_string category_name_select {select category_name from ec_categories where category_id = :category_id}]"

    }
}

# returns a link for the user to add him/herself to the mailing list for whatever category/
# subcategory/subsubcategory a product is in.
# If the product is multiply categorized, this will just use the first categorization that
# Oracle finds for this product.
proc ec_mailing_list_link_for_a_product { product_id } { 
    set category_id ""
    set subcategory_id ""
    set subsubcategory_id ""

	db_foreach category_id_select {
	    select category_id from ec_category_product_map where product_id = :product_id
	}  {
	
	    db_foreach subcategory_id_select {
		select s.subcategory_id
		  from ec_subcategory_product_map m,
		       ec_subcategories s
		 where m.subcategory_id = s.subcategory_id
		   and s.category_id = :category_id
		   and m.product_id = :product_id
	    } {
	
	    db_foreach subsubcategory_id_select {
		select ss.subsubcategory_id
		  from ec_subsubcategory_product_map m,
		       ec_subsubcategories ss
		 where m.subsubcategory_id = ss.subsubcategory_id
		   and ss.subcategory_id = :subcategory_id
		   and m.product_id = :product_id
	    } { }
	}
    }

    if { ![empty_string_p $category_id] || ![empty_string_p $subcategory_id] || ![empty_string_p $subsubcategory_id] } {
	return "<a href=\"[ad_parameter EcommercePath ecommerce]mailing-list-add?[export_url_vars category_id subcategory_id subsubcategory_id]\">Add yourself to the [ec_full_categorization_display $category_id $subcategory_id $subsubcategory_id] mailing list!</a>"
    } else { 
	return ""
    }
}

proc ec_space_to_nbsp { the_string } {
    regsub -all " " $the_string "\\&nbsp;" new_string
    return $new_string
}

# Given a product's rating, if the star gifs exist, it will
# print out the appropriate # (to the nearest half); otherwise
# it will just say what the rating is (to the nearest half).
# The stars should be in the subdirectory /graphics of the ecommerce
# user pages and they should be named star-full.gif, star-empty.gif,
# star-half.gif
proc ec_display_rating { rating } {
    set double_ave_rating [expr $rating * 2]
    set double_rounded_rating [expr round($double_ave_rating)]
    set rating_to_nearest_half [expr double($double_rounded_rating)/2]

    # see if images exist
    set full_dirname "[ad_parameter EcommerceDirectory ecommerce]graphics"
    regexp {/www(.*)} $full_dirname match web_directory 

    set n_full_stars [expr floor($rating_to_nearest_half)]
    if { $n_full_stars == $rating_to_nearest_half } {
       set n_half_stars 0
    } else {
       set n_half_stars 1
    }
    set n_empty_stars [expr 5 - $n_full_stars - $n_half_stars]

    if { [file exists "$full_dirname/star-full.gif"] && 
         [file exists "$full_dirname/star-empty.gif"] && 
         [file exists "$full_dirname/star-half.gif"] } {
	set full_star_gif_size [ns_gifsize "$full_dirname/star-full.gif"]
	set half_star_gif_size [ns_gifsize "$full_dirname/star-half.gif"]
	set empty_star_gif_size [ns_gifsize "$full_dirname/star-empty.gif"]
	
	set rating_to_print ""
	for { set counter 0 } { $counter < $n_full_stars } { incr counter } {
	    append rating_to_print "<img width=[lindex $full_star_gif_size 0] height=[lindex $full_star_gif_size 1] src=\"$web_directory/star-full.gif\" alt=\"Star\">"
	}
	for { set counter 0 } { $counter < $n_half_stars } { incr counter } {
	    append rating_to_print "<img width=[lindex $half_star_gif_size 0] height=[lindex $half_star_gif_size 1] src=\"$web_directory/star-half.gif\" alt=\"Half Star\">"
	}
	for { set counter 0 } { $counter < $n_empty_stars } { incr counter } {
	    append rating_to_print "<img width=[lindex $empty_star_gif_size 0] height=[lindex $empty_star_gif_size 1] src=\"$web_directory/star-empty.gif\" alt=\"Empty Star\">"
	}
    } else {
	# the graphics don't exist
	set rating_to_print "<b><font color=blue size=+2>"
        for { set counter 0 } { $counter < $n_full_stars } { incr counter } {
	    append rating_to_print "*"
	}
	for { set counter 0 } { $counter < $n_half_stars } { incr counter } {
	    append rating_to_print "&#189;"
	}
	append rating_to_print "</font><font color=gray size=+2>"
        for { set counter 0 } { $counter < $n_empty_stars } { incr counter } {
	    append rating_to_print "*"
	}
	append rating_to_print "</font></b>"
    }
    return $rating_to_print
}

proc ec_product_links_if_they_exist { product_id } {
    set to_return "<p>
    <b>We think you may also be interested in:</b>
    <ul>
    "

    set link_counter 0

    db_foreach product_link_info_select {
	select p.product_id, p.product_name from ec_products_displayable p, ec_product_links l where l.product_a = :product_id and l.product_b = p.product_id
    } {
	incr link_counter
	append to_return "<li><a href=\"product?[export_url_vars product_id product_name]\">$product_name</a>\n"
    }

    if { $link_counter == 0 } {
	return ""
    } else {
	return "$to_return</ul>\n<p>\n"
    }
}

proc ec_professional_reviews_if_they_exist { product_id } {

    set product_reviews ""

    db_foreach professional_reviews_info_select {
	select publication, author_name, review_date, review from ec_product_reviews where product_id = :product_id and display_p = 't'
    } {
	if { [empty_string_p $product_reviews] } {
	    append product_reviews "<font size=+1><b>Professional Reviews</b></font>\n<p>\n"
	}
	append product_reviews "$review<br>\n -- [ec_product_review_summary $author_name $publication $review_date]<p>\n"
    }

    if { ![empty_string_p $product_reviews] } {
	return "<hr>
	$product_reviews
	"
    } else {
	return ""
    }
}

# this won't show anything if ProductCommentsAllowP=0
proc ec_customer_comments { product_id {comments_sort_by ""} {prev_page_url ""} {prev_args_list ""} } {

    if { [ad_parameter ProductCommentsAllowP ecommerce] == 0 } {
	return ""
    }

    set end_of_comment_query ""
    set sort_blurb ""

    if { [ad_parameter ProductCommentsNeedApprovalP ecommerce] == 1 } {
	append end_of_comment_query "and c.approved_p = 't'"
    } else {
	append end_of_comment_query "and (c.approved_p = 't' or c.approved_p is null)\n"
    }

    if { $comments_sort_by == "rating" } {
	append end_of_comment_query "\norder by c.rating desc"
	append sort_blurb "sorted by rating | <a href=\"product?[export_url_vars product_id]&comments_sort_by=last_modified\">sort by date</a>"
    } else {
	append end_of_comment_query "\norder by c.last_modified desc"
	append sort_blurb "sorted by date | <a href=\"product?[export_url_vars product_id]&comments_sort_by=rating\">sort by rating</a>"
    }

    set to_return "<hr>
    <b><font size=+1>[ad_system_name] Member Reviews:</font></b>
    "

    set comments_to_print ""

    db_foreach product_comment_info_select "
	select c.one_line_summary,
	       c.rating,
	       c.user_comment,
 	       to_char(c.last_modified,'Day Month DD, YYYY') last_modified_pretty,
	       u.email,
	       u.user_id
	  from ec_product_comments c,
	       users u
	 where c.user_id = u.user_id
	   and c.product_id = :product_id
	   $end_of_comment_query
    " {

	append comments_to_print "<b><a href=\"/shared/community-member?[export_url_vars user_id]\">$email</a></b> rated this product [ec_display_rating $rating] on <i>$last_modified_pretty</i> and wrote:<br>
	<b>$one_line_summary</b><br>
	$user_comment 
	<p>
	"
    }

    if { ![empty_string_p $comments_to_print] } {
	append to_return "average customer review [ec_display_rating [db_string avg_rating_select {
            select avg(rating) from ec_product_comments where product_id = :product_id and approved_p = 't'
        }]]<br>
	Number of reviews: [db_string n_reviews_select "
            select count(*) from ec_product_comments where product_id = :product_id and (approved_p='t' [ec_decode [ad_parameter ProductCommentsNeedApprovalP ecommerce] "0" "or approved_p is null" ""])
        "] ($sort_blurb)

	<p>
	
	$comments_to_print
	
	<p>

	<a href=\"review-submit?[export_url_vars product_id]\">Write your own review!</a>
	"
    } else {
	append to_return "<p>\n<a href=\"review-submit?[export_url_vars product_id]\">Be the first to review this product!</a>\n"
    }
 
    return $to_return
}

proc ec_add_to_cart_link { product_id {add_to_cart_button_text "Add to Cart"} {preorder_button_text "Pre-order This Now!"} {form_action "shopping-cart-add"} {order_id ""} } {

    db_1row get_product_info_1 {
	select decode(sign(sysdate-available_date),1,1,null,1,0) as available_p, color_list, size_list, style_list, no_shipping_avail_p from ec_products where product_id = :product_id
    }

    if { ![empty_string_p $color_list] } {
	set color_widget "Color: <select name=color_choice>
	"
	foreach color [split $color_list ","] {
	    append color_widget "<option value=\"[ad_quotehtml $color]\">$color\n"
	}
	append color_widget "\n</select>\n<br>\n"
    } else {
	set color_widget [philg_hidden_input color_choice ""]
    }

    if { ![empty_string_p $size_list] } {
	set size_widget "Size: <select name=size_choice>
	"
	foreach size [split $size_list ","] {
	    append size_widget "<option value=\"[ad_quotehtml $size]\">$size\n"
	}
	append size_widget "\n</select>\n<br>\n"
    } else {
	set size_widget [philg_hidden_input size_choice ""]
    }

    if { ![empty_string_p $style_list] } {
	set style_widget "Style: <select name=style_choice>
	"
	foreach style [split $style_list ","] {
	    append style_widget "<option value=\"[ad_quotehtml $style]\">$style\n"
	}
	append style_widget "\n</select>\n<br>\n"
    } else {
	set style_widget [philg_hidden_input style_choice ""]
    }

    set warnings ""

    if { $no_shipping_avail_p == "t" } {
      append warnings "(Your order cannot be shipped if it includes this item.)"
    }
    
    if { $available_p } {
	return "<form method=post action=\"$form_action\">
	[export_form_vars product_id]
	[ec_decode $order_id "" "" [export_form_vars order_id]]
	$color_widget $size_widget $style_widget
	<input type=submit value=\"[ad_quotehtml $add_to_cart_button_text]\"><br>
        $warnings
	</form>
	"
    } else {
	set available_date [db_string available_date_select "select to_char(available_date,'Month DD, YYYY') available_date from ec_products where product_id = :product_id"]
	if { [ad_parameter AllowPreOrdersP ecommerce] } {
	    return "<form method=post action=\"$form_action\">
	    [export_form_vars product_id]
	    [ec_decode $order_id "" "" [export_form_vars order_id]]
	    $color_widget $size_widget $style_widget
	    <input type=submit value=\"[ad_quotehtml $preorder_button_text]\"> (Available $available_date)<br>
	    $warnings
	    </form>
	    "
	} else {
	    return "This item cannot yet be ordered.<br>(Available $available_date)"
	}
    }
}

# current_location can be "Shopping Cart", "Your Account", "Home", or
# any category_id
proc ec_navbar {{current_location ""}} {
    set top_links "<table width=100%>
    <tr>
    <td>[ec_header_image]</td>
    <td align=right>
    "
    if { [string compare $current_location "Shopping Cart"] == 0 } {
	append top_links "<b>Shopping Cart</b>"
    } else {
	append top_links "<a href=\"shopping-cart\">Shopping Cart</a>"
    }
    append top_links " | "
    if { [string compare $current_location "Your Account"] == 0 } {
	append top_links "<b>Your Account</b>"
    } else {
	append top_links "<a href=\"account\">Your Account</a>"
    }
    append top_links " | "
    if { [string compare $current_location "Home"] == 0 } {
	append top_links "<b>Home</b>"
    } else {
	append top_links "<a href=\"index\">Home</a>"
    }
    append top_links "</td>
    </tr>
    </table>
    "
    set linked_category_list [list]

    db_foreach category_select {
	select category_id, category_name from ec_categories order by sort_key
    } {
	if { [string compare $category_id $current_location] != 0 } {
	    lappend linked_category_list "<a href=\"category-browse?category_id=$category_id\">$category_name</a>"
	} else {
	    lappend linked_category_list "<b>$category_name</b>"
	}
    }

    return "$top_links
    <center>
    <table><tr><td bgcolor=cccccc>[join $linked_category_list " | "]</td></tr></table>
    </center>
    "
}

# for_customer, as opposed to one for the admins
# if show_item_detail_p is "t", then the user will see the tracking number, etc.
proc ec_order_summary_for_customer { order_id user_id {show_item_detail_p "f"} } {
    # display : 
    # email address
    # shipping address (w/phone #)
    # credit card info
    # items
    # total cost

    # little security check
    set correct_user_id [db_string correct_user_id {
	select user_id as correct_user_id from ec_orders where order_id = :order_id
    }]
    
    if { [string compare $user_id $correct_user_id] != 0 } {
	return "Invalid Order ID"
    }

    db_1row order_info_select {
	select eco.confirmed_date, eco.creditcard_id, eco.shipping_method,
	       u.email,
	       eca.line1, eca.line2, eca.city, eca.usps_abbrev, eca.zip_code, eca.country_code,
	       eca.full_state_name, eca.attn, eca.phone, eca.phone_time
	  from ec_orders eco,
	       users u,
	       ec_addresses eca
	 where eco.order_id = :order_id
	       and eco.user_id = u.user_id(+)
	       and eco.shipping_address = eca.address_id(+)
    }

    set address [ec_pretty_mailing_address_from_args $line1 $line2 $city $usps_abbrev $zip_code $country_code $full_state_name $attn $phone $phone_time]

    if { ![empty_string_p $creditcard_id] } {
	set creditcard_summary [ec_creditcard_summary $creditcard_id]
    } else {
	set creditcard_summary ""
    }

    set items_ul ""

    db_foreach order_details_select {
	select i.price_name, i.price_charged, i.color_choice, i.size_choice, i.style_choice,
	       p.product_name, p.one_line_description, p.product_id,
	       count(*) as quantity
	  from ec_items i,
	       ec_products p
	 where i.order_id = :order_id
	   and i.product_id = p.product_id
         group by p.product_name, p.one_line_description, p.product_id,
	       i.price_name, i.price_charged, i.color_choice, i.size_choice, i.style_choice
    } {

	set option_list [list]
	if { ![empty_string_p $color_choice] } {
	    lappend option_list "Color: $color_choice"
	}
	if { ![empty_string_p $size_choice] } {
	    lappend option_list "Size: $size_choice"
	}
	if { ![empty_string_p $style_choice] } {
	    lappend option_list "Style: $style_choice"
	}
	set options [join $option_list ", "]
	if { ![empty_string_p $options] } {
	    set options "$options; "
	}

	append items_ul "<li>Quantity $quantity: $product_name; $options$price_name: [ec_pretty_price $price_charged [ad_parameter Currency ecommerce]]\n"
	if { $show_item_detail_p == "t" } {
	    append items_ul "<br>
	    [ec_shipment_summary_sub $product_id $color_choice $size_choice $style_choice $price_charged $price_name $order_id]
	    "
	}
    }

    set shipping_method_to_print "[ec_decode $shipping_method "standard" "Standard Shipping" "express" "Express Shipping" "pickup" "Pickup" "no shipping" "No Shipping" "Unknown Shipping Method"]"
    
    set price_summary [ec_formatted_price_shipping_gift_certificate_and_tax_in_an_order $order_id]

    set to_return "<pre>
"
    if { ![empty_string_p $confirmed_date] } {
	append to_return "Order date:\n[util_AnsiDatetoPrettyDate $confirmed_date]\n\n"
    }

    append to_return "E-mail address:
$email

[ec_decode $shipping_method "pickup" "Address:" "no shipping" "Address:" "Ship to:"]
$address
[ec_decode $creditcard_summary "" "" "
Credit card:
$creditcard_summary
"]
Items:
</pre>

<ul>
$items_ul
</ul>

<pre>
Ship via: $shipping_method_to_print

$price_summary
</pre>
"

return $to_return
}

# Eve deleted the procedure ec_gift_certificate_summary_for_customer
# because there's no need to encapsulate something if:
# (a) it's only used once, and
# (b) it's extremely simple

proc ec_item_summary_in_confirmed_order { order_id {ul_p "f"}} {

    set item_list [list]

    db_foreach item_summary_info_select {
	select i.price_charged, i.price_name, i.color_choice, i.size_choice, i.style_choice,
	       p.product_name, p.one_line_description, p.product_id,
	       count(*) as quantity
	  from ec_items i,
	       ec_products p
	 where i.order_id = :order_id
	   and i.product_id = p.product_id
	 group by p.product_name, p.one_line_description, p.product_id,
	       i.price_charged, i.price_name, i.color_choice, i.size_choice, i.style_choice
    } {

	set option_list [list]
	if { ![empty_string_p $color_choice] } {
	    lappend option_list "Color: $color_choice"
	}
	if { ![empty_string_p $size_choice] } {
	    lappend option_list "Size: $size_choice"
	}
	if { ![empty_string_p $style_choice] } {
	    lappend option_list "Style: $style_choice"
	}
	set options [join $option_list ", "]
	if { ![empty_string_p $options] } {
	    set options "$options; "
	}

	lappend item_list "Quantity $quantity: $product_name; $options$price_name: [ec_pretty_price $price_charged]"
    }
    if { $ul_p == "f" } {
	return [join $item_list "\n"]
    } else {
	return "<ul>
	<li>[join $item_list "\n<li>"]
	</ul>"
    }
}

proc ec_item_summary_for_admins { order_id } {

    set item_list [list]

    db_foreach item_summary_info_select {
	select i.price_charged, i.price_name, i.color_choice, i.size_choice, i.style_choice,
	       p.product_name, p.one_line_description, p.product_id,
	       count(*) as quantity
	  from ec_items i,
	       ec_products p
	 where i.order_id = :order_id
	   and i.product_id = p.product_id
	 group by p.product_name, p.one_line_description, p.product_id,
	       i.price_charged, i.price_name, i.color_choice, i.size_choice, i.style_choice
    } {

	set option_list [list]
	if { ![empty_string_p $color_choice] } {
	    lappend option_list "Color: $color_choice"
	}
	if { ![empty_string_p $size_choice] } {
	    lappend option_list "Size: $size_choice"
	}
	if { ![empty_string_p $style_choice] } {
	    lappend option_list "Style: $style_choice"
	}
	set options [join $option_list ", "]
	if { ![empty_string_p $options] } {
	    set options "$options; "
	}

	lappend item_list "Quantity $quantity: $product_name; $options$price_name: [ec_pretty_price $price_charged]"
    }
    if { $ul_p == "f" } {
	return [join $item_list "\n"]
    } else {
	return "<ul>
	<li>[join $item_list "\n<li>"]
	</ul>"
    }
}

# produced a HTML form fragment for administrators to check off items that are fulfilled or received back
proc ec_items_for_fulfillment_or_return { order_id {for_fulfillment_p "t"} } {

    if { $for_fulfillment_p == "t" } {
	set item_view "ec_items_shippable"
    } else {
	set item_view "ec_items_refundable"
    }

    set n_items [db_string n_items_in_an_order_select "select count(*) from $item_view where order_id = :order_id"]

    set sql "
	    select i.item_id, i.color_choice, i.size_choice, i.style_choice, i.price_charged, i.price_name,
	           p.product_name, p.one_line_description, p.product_id
	      from $item_view i,
	           ec_products p
	     where i.order_id = :order_id
	       and i.product_id = p.product_id
    "


    if { $n_items > 1 } {

	set item_list [list]
	
	db_foreach items_in_an_order_select $sql {

	    set option_list [list]
	    if { ![empty_string_p $color_choice] } {
		lappend option_list "Color: $color_choice"
	    }
	    if { ![empty_string_p $size_choice] } {
		lappend option_list "Size: $size_choice"
	    }
	    if { ![empty_string_p $style_choice] } {
		lappend option_list "Style: $style_choice"
	    }
	    set options [join $option_list ", "]
	    if { ![empty_string_p $options] } {
		set options "$options; "
	    }

	    lappend item_list "<input type=checkbox name=item_id value=\"$item_id\"> $product_name; $options$price_name: [ec_pretty_price $price_charged]<br>"
	}
	
	return "<input type=checkbox name=all_items_p value=\"t\" checked> All items
	
	<p>
	[join $item_list "\n"]
	"

    } elseif {$n_items = 1} {
	db_1row item_in_an_order_select $sql
	return "<input type=checkbox name=item_id value=\"$item_id\" checked> $product_name; $price_name: [ec_pretty_price $price_charged]"
    } else {
        return ""
    }
}

proc ec_price_line { product_id user_id {offer_code "" } {order_confirmed_p "f"} } {
    set lowest_price_and_price_name [ec_lowest_price_and_price_name_for_an_item $product_id $user_id $offer_code]

    return "[lindex $lowest_price_and_price_name 1]: [ec_pretty_price [lindex $lowest_price_and_price_name 0] [ad_parameter Currency ecommerce]]"
}

proc_doc ec_product_review_summary {author_name publication review_date} "Returns a one-line user-readable summary of a product review" {
    set result_list [list]
    if ![empty_string_p $author_name] {
	lappend result_list $author_name
    }
    if ![empty_string_p $publication] {
	lappend result_list "<cite>$publication</cite>"
    }
    if ![empty_string_p $review_date] {
	lappend result_list [util_AnsiDatetoPrettyDate $review_date]
    }
    return [join $result_list ", "]
}

proc ec_order_summary_for_admin { order_id first_names last_name confirmed_date order_state user_id} {
    set to_return "<a href=\"/admin/ecommerce/orders/one?order_id=$order_id\">$order_id</a> : <a href=\"/admin/users/one?user_id=$user_id\">$first_names $last_name</a>\n"
    if { [exists_and_not_null confirmed_date] } {
	append to_return " on [util_IllustraDatetoPrettyDate $confirmed_date] "
    }
    if { $order_state == "confirmed" || $order_state == "authorized_plus_avs" || $order_state == "authorized_minus_avs" || $order_state == "partially_fulfilled" } {
	# this is awaiting authorization
	# or needs to be fulfilled, so highlight the order state
	append to_return "<font color=red>($order_state)</font>\n"
    } else {
	append to_return "($order_state)\n"
    }
}

proc ec_all_orders_by_one_user { user_id } {

    set to_return "<ul>\n"

    db_foreach all_orders_one_user_select {
	select o.order_id, o.confirmed_date, o.order_state
	  from ec_orders o
	 where o.user_id = :user_id
	 order by o.order_id
    } {

	append to_return "<li><a href=\"/admin/ecommerce/orders/one?order_id=$order_id\">$order_id</a> : \n"
	if {[info exists confirmed_date] && ![empty_string_p $confirmed_date] } {
	    append to_return " on [util_AnsiDatetoPrettyDate $confirmed_date] "
	}
	if { ($order_state == "confirmed" || [regexp {authorized} $order_state]) } {
	    # this is awaiting authorization
	    # or needs to be fulfilled, so highlight the order state
	    append to_return "<font color=red>($order_state)</font>\n"
	} else {
	    append to_return "($order_state)\n"
	}

    }
    append to_return "</ul>\n"
    return $to_return
}

proc ec_display_product_purchase_combinations { product_id } {
    # we don't want to return anything if either no purchase combinations
    # have been calculated or if no other products have been bought by
    # people who bought this product

    if {
	![db_0or1row get_pp_combs {
	    select * from ec_product_purchase_comb where product_id = :product_id
	}]
    } {
	return ""
    }

    if { [empty_string_p $product_0] } {
	return ""
    }

    set to_return "<p>
    <b>People who bought [db_string product_name_select {select product_name from ec_products where product_id = :product_id}] also bought:</b>

    <ul>
    "

    for { set counter 0 } { $counter < 5 } { incr counter } {
	set product_id [set product_$counter]
	if { ![empty_string_p $product_id] } {
    append to_return "<li><a href=\"product?[export_url_vars product_id]\">[db_string product_name_select {select product_name from ec_products where product_id = :product_id}]</a>\n"
	}
    }
    
    append to_return "</ul>
    "

    return $to_return
}

proc ec_formatted_price_shipping_gift_certificate_and_tax_in_an_order {order_id} {

    set price_shipping_gift_certificate_and_tax [ec_price_shipping_gift_certificate_and_tax_in_an_order $order_id]

    set price [lindex $price_shipping_gift_certificate_and_tax 0]
    set shipping [lindex $price_shipping_gift_certificate_and_tax 1]
    set gift_certificate [lindex $price_shipping_gift_certificate_and_tax 2]
    set tax [lindex $price_shipping_gift_certificate_and_tax 3]

    set currency [ad_parameter Currency ecommerce]
    set price_summary_line_1_list [list "Item(s) Subtotal:" [ec_pretty_price $price $currency]]
    set price_summary_line_2_list [list "Shipping & Handling:" [ec_pretty_price $shipping $currency]]
    set price_summary_line_3_list [list "" "-------"]
    set price_summary_line_4_list [list "Subtotal:" [ec_pretty_price [expr $price + $shipping] $currency]]
    if { $gift_certificate > 0 } {
	set price_summary_line_5_list [list "Tax:" [ec_pretty_price $tax $currency]]
	set price_summary_line_6_list [list "" "-------"]
	set price_summary_line_7_list [list "TOTAL:" [ec_pretty_price [expr $price + $shipping + $tax] $currency]]
	set price_summary_line_8_list [list "Gift Certificate:" "-[ec_pretty_price $gift_certificate $currency]"]
	set price_summary_line_9_list [list "" "-------"]
	set price_summary_line_10_list [list "Balance due:" [ec_pretty_price [expr $price + $shipping + $tax - $gift_certificate] $currency]]
	set n_lines 10
    } else {
	set price_summary_line_5_list [list "Tax:" [ec_pretty_price $tax $currency]]
	set price_summary_line_6_list [list "" "-------"]
	set price_summary_line_7_list [list "TOTAL:" [ec_pretty_price [expr $price + $shipping + $tax] $currency]]
	set n_lines 7
    }

    set price_summary ""
    for {set ps_counter 1} {$ps_counter <= $n_lines} {incr ps_counter} {
	set line_length 45
	set n_spaces [expr $line_length - [string length [lindex [set price_summary_line_${ps_counter}_list] 0]] - [string length [lindex [set price_summary_line_${ps_counter}_list] 1]] ]
	set actual_spaces ""
	for {set lame_counter 0} {$lame_counter < $n_spaces} {incr lame_counter} {
	    append actual_spaces " "
	}
	append price_summary "[lindex [set price_summary_line_${ps_counter}_list] 0]$actual_spaces[lindex [set price_summary_line_${ps_counter}_list] 1]\n"
    }

    return $price_summary
}

# says how the items with a given product_id, color, size, style, price_charged,
# and price_name in a given order shipped; the reason we put in all these parameters
# is that item summaries group items in this manner
proc ec_shipment_summary_sub { product_id color_choice size_choice style_choice price_charged price_name order_id } {

    set shipment_list [list]

    db_foreach items_shipped_select "
	select s.shipment_date, s.carrier, s.tracking_number, s.shipment_id, s.shippable_p, count(*) as n_items
          from ec_items i,
               ec_shipments s
         where i.order_id = :order_id
	   and i.shipment_id = s.shipment_id
	   and i.product_id = :product_id
	   and i.color_choice [ec_decode $color_choice "" "is null" "= :color_choice"]
	   and i.size_choice [ec_decode $size_choice "" "is null" "= :size_choice"]
	   and i.style_choice [ec_decode $style_choice "" "is null" "= :style_choice"]
	   and i.price_charged [ec_decode $price_charged "" "is null" "= :price_charged"]
	   and i.price_name [ec_decode $price_name "" "is null" "= :price_name"]
	 group by s.shipment_date, s.carrier, s.tracking_number, s.shipment_id, s.shippable_p
    " {

 	if { ![empty_string_p $shipment_date] } {
 	    set to_append_to_shipment_list "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; $n_items [ec_decode $shippable_p "t" "shipped" "fullfilled"] on [util_AnsiDatetoPrettyDate $shipment_date]"
	    if { ![empty_string_p $carrier] } {
		append to_append_to_shipment_list " via $carrier"
	    }
 	    if { ![empty_string_p $tracking_number] } {
		if { ([string tolower $carrier] == "fedex" || [string range [string tolower $carrier] 0 2] == "ups") } {
		    append to_append_to_shipment_list " <font size=-1>(<a href=\"track?[export_url_vars shipment_id]\">track</a>)</font>"
		} else {
		    append to_append_to_shipment_list " (tracking # $tracking_number)"
		}
	    }
	    lappend shipment_list $to_append_to_shipment_list
	}
    }
    return "[join $shipment_list "<br>"]"
}

proc_doc ec_return_product_file { } "Returns a file for the product in the calling url." {

    # Get file_path from url
    set url [ns_conn url]
    regexp {/product-file/([^/]+/[^/]+/[^/]+)$} $url match file_path 
    # take any ..'s out of file_path
    regsub -all {\.\.} $file_path "" file_path
    set full_path "[ad_parameter EcommerceDataDirectory ecommerce][ad_parameter ProductDataDirectory ecommerce]$file_path"

    ad_returnfile 200 [ns_guesstype $full_path] $full_path
}

ad_register_proc GET /product-file/* ec_return_product_file 

# Returns HTML and JavaScript for a selection widget and a button
# which will insert canned responses into a text area.
# Takes a database handle, the name associated with a form,
# and the name of the textarea to insert into.

proc ec_canned_response_selector { form_name textarea_name } {

    set selector_text "<select name=ec_canned_response_selector>
<option value=\"\">Select a response</option>\n"
    set javascript_text "<script language=JavaScript>
function insertCannedResponse(selector) \{
    var response_id = selector.options\[selector.selectedIndex\].value;"

    db_foreach canned_response_select {
	select response_id, one_line, response_text
	  from ec_canned_responses
	 order by one_line
    } {

	regsub -all "\r?\n" $response_text {\n} response_text

	append selector_text "<option value=$response_id>$one_line</option>\n"

	append javascript_text "if (response_id == $response_id) \{document.$form_name.$textarea_name.value += \"[ad_quotehtml $response_text]\";\}\n"
    }

    append selector_text "</select>
<input type=button value=\"Insert Response\" onClick=\"insertCannedResponse(document.$form_name.ec_canned_response_selector)\">\n"
append javascript_text "\}\n</script>\n"

    return "$javascript_text$selector_text"
}

proc ec_admin_present_user {user_id name} {
    return "<a href=\"/admin/users/one?user_id=$user_id\">$name</a>"
}

proc_doc ec_user_class_display { user_id { link_p "f" } } "Displays a comma seperated list of the users user classes with a comment on its approval status if approval is required. If link_p is true, then a link is displayed to the admin/ecommerce/user-classes/ page for changing the approval status." {

    set to_return [list]

    db_foreach user_class_info_select {
	select c.user_class_name, m.user_class_approved_p, c.user_class_id
	  from ec_user_classes c, ec_user_class_user_map m
	 where m.user_id = :user_id
	   and m.user_class_id = c.user_class_id
	 order by c.user_class_id
    } {

	if { [string compare $link_p "f"] != 0 } {
	    set to_append "<a href=\"/admin/ecommerce/user-classes/members?user_class_id=$user_class_id\">$user_class_name</a>"
	} else {
	    set to_append "$user_class_name"
	}

	if { [ad_parameter UserClassApproveP ecommerce] } {
	    append to_append " <font size=-1>([ec_decode $user_class_approved_p "t" "approved" "unapproved"])</font>"
	}
	lappend to_return $to_append
    }

    return [join $to_return ", "]
}

#
# This is rerverse engineering the cut-and-paste-and-mutate-and-repeat
# session management stuff.
# 
# These need to be rationalized and combined.
#

proc ec_log_user_as_user_id_for_this_session {} {
    uplevel {
	# Log the user as the user_id for this session
	if { [string compare $user_session_id "0"] != -1 } {
	    db_dml user_session_update {
		update ec_user_sessions 
		set user_id = :user_id 
		where user_session_id = :user_session_id
	    }
	}
    }
}

proc ec_export_entire_form_as_url_vars_maybe {} {
    if {![empty_string_p [ns_conn form]]} {export_entire_form_as_url_vars} else {concat ""}
}

ad_proc -private ec_create_new_session_if_necessary {{more_url_vars_exported ""} {cookie_requirement "cookies_are_required"}} { Create a new session if needed } {
uplevel "set _ec_more_url_vars_exported \"$more_url_vars_exported\""
uplevel "set _ec_cookie_requirement     \"$cookie_requirement\""
uplevel {

    if { $user_session_id == 0 } {
	if {![info exists usca_p]} {
	    # no previous attempt made
	    
	    set user_session_id [db_nextval "ec_user_session_sequence"]

	    set ip_address [ns_conn peeraddr]
	    set http_user_agent [util_GetUserAgentHeader]

	    db_dml insert_user_session {
		insert into ec_user_sessions
		(user_session_id, ip_address, start_time, http_user_agent)
		values
		(:user_session_id, :ip_address , sysdate, :http_user_agent)
	    }

	    set cookie_name "user_session_id"
	    set cookie_value $user_session_id
	    
	    set usca_p "t"
	    set final_page "[ns_conn url]?[export_url_vars usca_p]"
	    if ![empty_string_p $_ec_more_url_vars_exported] {
		append final_page "&" $_ec_more_url_vars_exported
	    }

	    ad_returnredirect "/cookie-chain?[export_url_vars cookie_name cookie_value final_page]"
	    ad_script_abort
	} else {
	    # previous attempt made
	    
	    if {[string compare $_ec_cookie_requirement "cookies_are_required"] ==0} {
		
		ad_return_complaint 1 "You need to have cookies turned on so that we can remember what you have in your shopping cart.  Please turn on cookies in your browser."
		ad_script_abort
		
	    } elseif {[string compare $_ec_cookie_requirement "cookies_are_not_required"] == 0} {
		
		# For this page continue
		
	    } elseif {[string compare $_ec_cookie_requirement "shopping_cart_required"] == 0} {
		
doc_return  200 text/html "[ad_header "No Cart Found"]<h2>No Shopping Cart Found</h2>
<p>
We could not find any shopping cart for you.  This may be because you have cookies 
turned off on your browser.  Cookies are necessary in order to have a shopping cart
system so that we can tell which items are yours.
<p>
<i>In Netscape 4.0, you can enable cookies from Edit -> Preferences -> Advanced. <br>
In Microsoft Internet Explorer 4.0, you can enable cookies from View -> 
Internet Options -> Advanced -> Security. </i>
<p>
[ec_continue_shopping_options]
"

ad_script_abort

		} else {

		    ns_returnerror 500 "bug"
		    ad_script_abort
		}
            }
        }
    }
}

proc ec_secure_url {} {
    set secure_hostname [ns_config ns/server/[ns_info server]/module/nsssl Hostname]
    return "https://$secure_hostname"
}

proc ec_insecure_url {} {
    set insecure_hostname [ns_config ns/server/[ns_info server]/module/nssock Hostname]
    return "http://$insecure_hostname"
}

proc ec_redirect_to_https_if_possible_and_necessary {} {
    uplevel {
	if { [ns_conn driver] == "nsssl" } {
	    # page is already https; do nothing
	    return
	} else {
	    # see if ssl is installed
	    if { ![ad_ssl_available_p] } {
		# there's no ssl
		# if ssl is required return an error message; otherwise, do nothing
		if { [ad_parameter RequireSSLP ecommerce] == "1"} {
		    ad_return_error "No SSL available" "We're sorry, but we cannot display this page because SSL isn't available from this site.  Please contact <a href=\"mailto:[ad_system_owner]\">[ad_system_owner]</a> for assistance."
		    ad_script_abort
		} else {
		    return
		}
	    } else {
		# figure out where we should redirect the user
		set secure_url "[ec_secure_url]/[ns_conn url]"
		set vars_to_export [ec_export_entire_form_as_url_vars_maybe]
		if { ![empty_string_p $vars_to_export] } {
		    set secure_url "$secure_url?$vars_to_export"
		}

		ad_returnredirect $secure_url
		ad_script_abort
	    }
	}
    }
}

proc_doc ec_use_cybercash_p {} {Should we use cybercash? Use ad_parameter UseCyberCashP and default value 1 to find out.} {
    return [ad_parameter UseCyberCashP ecommerce 1]
}
