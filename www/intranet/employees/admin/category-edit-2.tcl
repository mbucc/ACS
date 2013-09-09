# /www/intranet/employees/admin/category-edit-2.tcl

ad_page_contract {

    Overview: Name-change or delete for categories.

    Updates the category column in the categories table, for a particular 
    category_type. Also performs deletes.

    In future versions of the ACS, each category_type should be its own table.  Using
    subsets of a table (category_types) as if they were their own tables causes 
    massive headaches.  Counting child records for deletes becomes difficult, db 
    contraints become lax, and constraint-checking is forced into programmer-space.

    Based on source-edit-2.tcl by teadams@arsdigita.com 4/24/00

    @author mshurpik@arsdigita.com
    @creation-date August 1, 2000
    @cvs-id category-edit-2.tcl,v 1.1.2.5 2000/08/16 21:24:46 mbryzek Exp

    @param new_name         The category's new name.  If it is null, we perform a 
                            delete.
    
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
    category_html:notnull
    category_id:naturalnum
    new_name:trim

    return_url:notnull
}

im_validate_and_set_category_type


## Get the name of the object we are editing/deleting
if { ! [db_0or1row original_name "
select category as original_name
from categories
where category_id = :category_id
and category_type = :category_type" ] } {
    

    ## No rows found - Abort (prolly url surgery, or concurrency)
    ad_returnredirect [ad_build_url return_url category_html]
    return

}


## Abort if no changes are to be made
 
if { ![string compare $original_name $new_name]} {

    ad_returnredirect [ad_build_url return_url category_html]
    return

}

 
## If the new name is null, perform a delete.  Otherwise, perform an update.

if {[empty_string_p $new_name]} {
      

    if { [ catch { db_dml delete_category "
    delete from categories 
    where category_id = :category_id
    and category_type = :category_type" } catch_error ] } { 

	## Foreign key constraint

	## We do not try to hunt down and display/delete references to this item,
	## because there are way too many places in the data model where the 
	## categories table is referenced. Instead, we simply fail. -MJS 8/2

	set exception_text "<i>$original_name</i> cannot be deleted.  
	It is linked to other data, which must be deleted first."


    } else {
	
	if {[db_resultrows]} {
	    
	    set exception_text "<i>$original_name</i> has been deleted."
	    
	} else {
	    
	    ## If the category_id did not match the category_type
	    ## So far I can't get this case to execute, which is a good thing
	    ## I suppose it might trip in a race condition
	    
	    set exception_text "You tried to do something naughty."
	    
	}
	
    }
    
} else {
    
    ## Preserve uniqueness:
    ## Perform the update only if other entries with the same name don't exist  

    db_dml update_category "update categories
    set category = :new_name 
    where category_id = :category_id and category_type = :category_type 
    and not exists 
    (select 1 from categories 
     where category = :new_name and category_id <> :category_id 
     and category_type = :category_type)"


    if {![db_resultrows]} {
	
	## Failure
	
	set exception_text "
	You can't change <i>$original_name</i> to <i>$new_name</i>.
	Another category already has that name"
	
    } else {
	
	## Success
	
	set exception_text "
	Changed <i>$original_name</i> to <i>$new_name</i>
	"
    }

}

ad_returnredirect [ad_build_url return_url exception_text category_html]

return

## END FILE category-edit-2.tcl 


