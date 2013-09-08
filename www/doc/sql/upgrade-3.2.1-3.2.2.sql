-- /www/doc/sql/upgrade-3.2.1-3.2.2.sql
--
-- Script to upgrade an ACS 3.2.1 database to 3.2.2.
-- 
-- upgrade-3.2.1-3.2.2.sql,v 3.2 2000/07/07 23:34:46 ron Exp

-- BEGIN INTRANET --

--- note; add all of /doc/sql/ischecker.sql

-- add customer status

-- What type of customers can we have
create sequence im_customer_types_seq start with 1;
create table im_customer_types (
	customer_type_id	integer primary key,
	customer_type		varchar(100) not null unique,
	display_order		integer default 1
);

 alter table im_customers add ( customer_type_id	references im_customer_types);


-- removed by lars@pinds.com on 18 June 2000
-- it seems the is_machines table weren't part of 3.2.1, so we can't 
-- reference it here.
--alter table im_project_url_map add (
--	machine_id 	references is_machines);

alter table im_employee_info add (termination_date          date);

-- END INTRANET --

-- BEGIN ECOMMERCE --
-- rhs: 13 Apr 2000
alter table ec_products add
    no_shipping_avail_p	char(1) default 'f' check(no_shipping_avail_p in ('t', 'f'));

alter table ec_products add
    email_on_purchase_list	varchar(4000);

alter table ec_shipments add
    shippable_p         char(1) default 't' check(shippable_p in ('t', 'f'));

alter table ec_orders add
    tax_exempt_p	char(1) default 'f' check(tax_exempt_p in ('t', 'f'));

create or replace function ec_tax (v_price IN number, v_shipping IN number, v_order_id IN integer) return number
IS
	taxes			ec_sales_tax_by_state%ROWTYPE;
	tax_exempt_p		ec_orders.tax_exempt_p%TYPE;
BEGIN
	SELECT tax_exempt_p INTO tax_exempt_p
	FROM ec_orders
	WHERE order_id = v_order_id;

	IF tax_exempt_p = 't' THEN
		return 0;
	END IF;	
	
	SELECT t.* into taxes
	FROM ec_orders o, ec_addresses a, ec_sales_tax_by_state t
	WHERE o.shipping_address=a.address_id
	AND a.usps_abbrev=t.usps_abbrev(+)
	AND o.order_id=v_order_id;

	IF nvl(taxes.shipping_p,'f') = 'f' THEN
		return nvl(taxes.tax_rate,0) * v_price;
	ELSE
		return nvl(taxes.tax_rate,0) * (v_price + v_shipping);
	END IF;
END;
/
show errors
-- END ECOMMERCE --

