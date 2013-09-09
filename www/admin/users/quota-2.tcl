ad_page_contract {
    @cvs-id quota-2.tcl,v 3.2.2.3.2.2 2000/07/25 00:59:08 jmp Exp
} {
    user_id:integer,notnull
    new_quota:notnull
}


set exception_text ""
set exception_count 0

set special_p [db_string count_user_special_quota "
select count(*) from users_special_quotas
where user_id = :user_id"]

if {$special_p == 0} {

    if {[empty_string_p $new_quota]} {
	ad_returnredirect "one.tcl?user_id=$user_id"
	return
    } else {
	set sql "
	insert into users_special_quotas
	(user_id, max_quota)
	values
	(:user_id, :new_quota)
	"
    }
    
} else {

    if {[empty_string_p $new_quota]} {
	set sql "
	delete from users_special_quotas
	where user_id = :user_id
	"
    } else {
	set sql "
	update users_special_quotas
	set max_quota = :new_quota
	where user_id = :user_id
	"
    }

}

if [catch { db_dml delete_or_update_special_quota $sql } errmsg] {
    ad_return_error "Ouch!"  "The database choked on our update:
<blockquote>
$errmsg
</blockquote>
"
} else {
    ad_returnredirect "one.tcl?user_id=$user_id"
}

