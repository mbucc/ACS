# www/calendar/admin/category-new.tcl
ad_page_contract {
    Performs an insert of a new category

    Number of queries: not enough
    Number of dml: too many

    @author Philip Greenspun? (philg@mit.edu)
    @author Sarah Ahmed? (ahmeds@arsdigita.com)
    @creation-date 1998-11-18
    @cvs-id category-new.tcl,v 3.2.2.4 2001/01/10 16:06:30 khy Exp
    
} {
    category_id:verify,naturalnum
    category:nohtml,notnull
}

set user_id [ad_verify_and_get_user_id]

set exception_count 0
set exception_text ""

## This proc doesn't check for existing category as a separate step like its counterpart
## in user-space.  It cleverly does it right in the insert. 

## what's wrong with primary keys, people?  id?  anyone heard of it?   -MJS 7/13


# add the new category
db_transaction {
    
    set dml_insert_category "
    insert into calendar_categories (
	category ,
	scope	 ,
	user_id  ,
	category_id 
    ) values (
	:category ,
	'public'  ,
	:user_id  ,
	:category_id
    )"
	 
    db_dml insert_category $dml_insert_category
    
    # if a new row was not inserted, make sure that the exisitng category entry is enabled
    if { [db_resultrows] == 0 } {
	
	## This presupposes that category is a primary key, which it's not!!!!!! -MJS 7/13
	
	set dml_category_enable "update calendar_categories set enabled_p = 't' where category = :category"
	
	db_dml category_enable $dml_category_enable 
	
    }
    
} on_error {
    
    # there was some other error with the category
    ad_return_error "Error inserting category" "We couldn't insert your category. Here is what the database returned:
    <p>
    <blockquote>
    <pre>
    $errmsg
    </pre>
    </blockquote>
    "
    return
}

ad_returnredirect "category-one.tcl?[export_url_vars category_id]"

## END FILE category-new.tcl











