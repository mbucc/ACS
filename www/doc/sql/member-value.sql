--
-- member-value.sql 
-- 
-- defined by philg@mit.edu on 8/18/98; 
--  augmented for release into toolkit on February 12, 1999
--
-- some of the tables here will be prefixed "mv_" ("mv" = "member value")
-- 

-- if there is a monthly charge, we set different rates for different classes 
-- of subscribers, these classes are arbitrary strings, though we suggest
-- 'default' (the standard rate) and 'comp' (complimentary, often for 
-- people at other publishing houses)

-- if [ad_parameter "ChargeMonthlyP" "member-value"] is 0 
-- then this table need not exist in the database

create table mv_monthly_rates (
	subscriber_class	varchar(30) not null primary key,
	rate			number not null,
	-- we use three digits because Cybercash does
	currency	char(3) default 'USD'
);

-- one row per user

create table users_payment (
	user_id		integer not null unique references users,
	-- this might be NULL for systems in which monthly billing
	-- is disabled, or maybe not (perhaps we'll use this to give
	-- people across-the-board discounts)
	subscriber_class	varchar(30) references mv_monthly_rates,
	name_on_card		varchar(100),
	-- only really useful for US cardholders, but maybe useful in 
	-- long run too
	card_zip		varchar(20),
	card_number		varchar(20),
	-- store this in CyberCash format, e.g., "08/99"
	card_exp		varchar(10)
);

-- we use this to collect up user charges

create sequence users_order_id_sequence;

-- you can't type this table into SQL*Plus 8.0.5 interactively; you 
-- have to make sure that you're loading this file or this table
-- via sqlplus / < member-value.sql 

create table users_orders (
        -- Goes into table at confirmation time:
	order_id	integer primary key,
	user_id		integer not null references users,
	confirmed_date	date,
	order_state	varchar(50) not null,
	price_charged	number,
	currency	char(3) default 'USD',
	-- Goes into table at authorization time (columns named
	-- cc_* refer to output from CyberCash):
	authorized_date	date,
	cc_auth_status	varchar(100),
	cc_auth_txn_id	varchar(100),
	cc_auth_errloc	varchar(100),
	cc_auth_errmsg	varchar(200),
	cc_auth_aux_msg	varchar(200),
	cc_auth_auth_code	varchar(100),
	cc_auth_action_code	char(3),
	cc_auth_avs_code	varchar(3),
	-- processor-specific and not obviously useful for cybercash
	-- perhaps useful when looking at statements from 
	-- merchant's bank 
	cc_auth_ref_code	varchar(100),
	-- Goes into table after querying for "settled" transaction type:
	cc_sett_date	date,
	cc_sett_status	varchar(100),
	cc_sett_txn_id	varchar(100),
	cc_sett_auth_code	varchar(100),
	cc_sett_batch_id	varchar(100),
	cc_sett_action_code	char(3),
	cc_sett_avs_code	varchar(3),
	cc_sett_ref_code	varchar(100),
	-- Goes into table at return time (i.e. when we use
	-- the API message "return" to mark the orders for return).
	-- tried_to_return_date exists in case CyberCash doesn't
	-- respond to our return attempt (in which case we can
	-- retry later).  
	-- Important note: "return" has no implicit connection with 
	-- the product being received back (that would recorded in
	-- the received_back_date column). 
	tried_to_return_date  date,
	return_date	date,
	refunded_amount		number,
	cc_retn_status	varchar(100),
	cc_retn_txn_id	varchar(100),
	cc_retn_errloc	varchar(100),
	cc_retn_errmsg	varchar(200),
	cc_retn_aux_msg	varchar(200),
	cc_retn_auth_code	varchar(100),
	cc_retn_action_code	char(3),
	cc_retn_avs_code	varchar(3),
	cc_retn_ref_code	varchar(100),
	-- Goes into table after querying for "setlret" transaction type
	-- (for returns that have been settled):
	-- NOTE: I'm assuming that CyberCash is automatically settling
	-- orders of type "markret" as it is orders of type "marked", since
	-- we are in auto settle mode.  We will find out shortly.
	cc_sret_date	date,
	cc_sret_status	varchar(100),
	cc_sret_txn_id	varchar(100),
	cc_sret_auth_code	varchar(100),
	cc_sret_batch_id	varchar(100),
	cc_sret_action_code	char(3),
	cc_sret_avs_code	varchar(3),
	cc_sret_ref_code	varchar(100),
	-- Goes into table when voiding a "marked" transaction
	-- The CyberCash manual states that all of the standard
	-- output fields are returned, although I've only witnessed
	-- aux-msg, Mstatus, MErrMsg, and MErrLoc
	tried_to_void_marked_date  date,
	void_marked_date	date,
	cc_vdmk_status	varchar(100),
	cc_vdmk_txn_id	varchar(100),
	cc_vdmk_errloc	varchar(100),
	cc_vdmk_errmsg	varchar(200),
	cc_vdmk_aux_msg	varchar(200),
	cc_vdmk_auth_code	varchar(100),
	cc_vdmk_action_code	char(3),
	cc_vdmk_avs_code	varchar(3),
	cc_vdmk_ref_code	varchar(100),
	-- Goes into table when voiding a "markret" transaction
	tried_to_void_markret_date  date,
	void_markret_date	date,
	cc_vdrn_status	varchar(100),
	cc_vdrn_txn_id	varchar(100),
	cc_vdrn_errloc	varchar(100),
	cc_vdrn_errmsg	varchar(200),
	cc_vdrn_aux_msg	varchar(200),
	cc_vdrn_auth_code	varchar(100),
	cc_vdrn_action_code	char(3),
	cc_vdrn_avs_code	varchar(3),
	cc_vdrn_ref_code	varchar(100),
	-- did the consumer initiate a dispute from his end?
        disputed_p              char(1) check (disputed_p in ('t','f')),
        -- date on which we discovered the dispute
        dispute_discovery_date  date,
        -- if the consumer's bank got his money back from us forcibly
        charged_back_p          char(1) check (charged_back_p in ('t','f')),
	comments	varchar(4000)
); 

-- transaction charges

-- charge_type will generally be one of the column names from
-- member-values parameters with the "Rate" chopped off, e.g., "ClassifiedAd"
-- for posting an ad, and then we change the style to our 
-- standard DB key (lowercase words, underscores), e.g., "classified_ad"

-- for the standard monthly subscription charge (if any), the 
-- charge_type will be "monthly"

-- charge_key will vary depending on charge_type; for something
-- like a classified ad, it would be the classified_ad_id (an integer)
-- for a bboard posting it would be the msg_id (char(6)).

-- the amount is theoretically derivable from the charge_type but we
-- keep it here because (1) rates might change over time, (2) the admins
-- might decide to charge someone a non-standard rate

create table users_charges (
	user_id		integer not null references users,
	-- if a human being decided to charge this person
	admin_id	integer references users,
	charge_type	varchar(30) not null,	
	charge_key	varchar(100),
	amount		number not null,
	currency	char(3) default 'USD',
	entry_date	date not null,
	charge_comment	varchar(4000),
	-- if we're trying to bill this out, order_id will be non-null
	order_id	integer references users_orders
);

create index users_charges_by_user on users_charges(user_id);

-- billing them all out every month (or whatever)

-- we write a row in this table whenever the billing proc was
-- completely successful (i.e., billed everyone who needed to be
-- billed).  That way we know we don't have to sweep for 
-- users who need to be billed

-- we generate sweep_id with select max+1 rather than an Oracle
-- sequence because we want them guaranteed sequential

create table mv_billing_sweeps (
	sweep_id	integer primary key,
	start_time	date,
	success_time	date,
	n_orders	integer	
);

-- to bill correctly, we often need to query for charges that
-- accumulated until the end of the last month, so we use < 1st of
-- this month at midnight

create or replace function mv_first_of_month
return date
as
 current_year varchar(30);
 current_month varchar(30);
begin
  current_year := to_char(sysdate,'YYYY');
  current_month := to_char(sysdate,'MM');
  return to_date(current_year || '-' || current_month || '-01 00:00:00','YYYY-MM-DD HH24:MI:SS');
end mv_first_of_month;
/
show errors
