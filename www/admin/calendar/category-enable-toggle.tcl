# www/admin/calendar/category-enable-toggle.tcl
ad_page_contract {
    Toggles a category's enabled bit
    
    BUGGY AS HELL!!!!!!!

    Number of dml: 1

    @author Philip Greenspun? (philg@mit.edu)
    @author Sarah Ahmed? (ahmeds@arsdigita.com)
    @creation-date 1998-11-18
    @cvs-id category-enable-toggle.tcl,v 3.1.6.3 2000/07/21 03:56:08 ron Exp
    
} {
    category:nohtml
}


# category


## J fuckin' C man, this proc is going to toggle every category with a given name.  Like Personal,
## for which there are hundreds. Whoever wrote this was asleep at the wheel. -MJS 7/13


db_dml unused "update calendar_categories set enabled_p = logical_negation(enabled_p) where category = :category"

ad_returnredirect "category-one.tcl?[export_url_vars category]"

## END FILE category-enable-toggle.tcl
