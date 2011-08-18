# $Id: quota-2.tcl,v 3.0.4.1 2000/04/28 15:09:37 carsten Exp $
set_the_usual_form_variables

# user_id, new_quota

set db [ns_db gethandle]

set exception_text ""
set exception_count 0

set special_p [database_to_tcl_string $db "
select count(*) from users_special_quotas
where user_id=$user_id"]

if {$special_p == 0} {

    if {[empty_string_p $new_quota]} {
	ad_returnredirect "one.tcl?user_id=$user_id"
	return
    } else {
	set sql "
	insert into users_special_quotas
	(user_id, max_quota)
	values
	($user_id, $new_quota)
	"
    }
    
} else {

    if {[empty_string_p $new_quota]} {
	set sql "
	delete from users_special_quotas
	where user_id=$user_id
	"
    } else {
	set sql "
	update users_special_quotas
	set max_quota = $new_quota
	where user_id = $user_id
	"
    }


}

if [catch { ns_db dml $db $sql } errmsg] {
    ad_return_error "Ouch!"  "The database choked on our update:
<blockquote>
$errmsg
</blockquote>
"
} else {
    ad_returnredirect "one.tcl?user_id=$user_id"
}

