# /www/intranet/employees/admin/category-add.tcl

ad_page_contract {
    
    Overview: Insert a new row in the categories table.

    Inserts a row in the categories table using only the name, id.nextval,
    and category_type.

    In future versions of the ACS, each category_type should be its own table.  
    Using subsets of a table (category_types) as if they were their own tables 
    causes massive headaches.  Counting child records for deletes becomes 
    difficult, db contraints become lax, and constraint-checking is forced into 
    programmer-space.

    Based on source-add-2.tcl by teadams@arsdigita.com 4/24/00
    
    @author mshurpik@arsdigita.com
    @creation-date August 1, 2000 
    @cvs-id category-add.tcl,v 1.1.2.6 2000/08/16 21:24:46 mbryzek Exp
    
    @param new_category     The new category's name.
    
    @param category_html    Unique plural pretty name for the category_type.  
                            We avoid passing the actual category_type, mostly for 
                            security.  We use our security proc to set it in the 
                            calling environment.
                            
    @param category_id      The item's id.  Since we are operating on a subset of 
                            the categories table, we have to be careful to check the
                            category_type at each operation.  Otherwise a user could
                            start addressing memory outside his designated block, so
                            to speak.  
    
    @param return_url       Where to redirect.  This is a full url and not the usual
                            stub...it may contain a return_url of its own.  Thus, we 
                            must anticipate that it may already contain a 
                            question-mark.

    
    
} {
    category_html:trim,notnull
    new_category:trim

    return_url:notnull    
}


im_validate_and_set_category_type


## This is intentional.  It is cleaner behavior than using the notnull filter.
if { [empty_string_p $new_category] } {

    ad_returnredirect [ad_build_url return_url category_html]
    return

}


## The database needs to remain clean, otherwise db_0or1row will fail returning 
## more than one row.  Since we are using a subset (view) of the categories table, 
## we can't enforce this in the data model with a constraint. -MJS 7/26

db_transaction {

    if {![db_0or1row already_exists "select 1 as one from categories 
    where category = :new_category and category_type = :category_type"]} {
	
	db_dml add_category "
	insert into categories 
	(category_id,category,category_type) 
	values 
	(category_id_sequence.nextval, :new_category, :category_type)"
	
	set exception_text "Added <i>$new_category</i>"
	

    } else {

	set exception_text "<i>$new_category</i> already exists"
	
    }
}



ad_returnredirect "[ad_build_url return_url exception_text category_html]"

return

## END FILE category-add.tcl

