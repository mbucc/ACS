--
-- ecommerce-plsql.sql
--
-- by eveander@arsdigita.com, April 1999
--

--------------- price calculations -------------------
-------------------------------------------------------

-- just the price of an order, not shipping, tax, or gift certificates
-- this is actually price_charged minus price_refunded
create or replace function ec_total_price (v_order_id IN integer) return number
IS
	CURSOR price_cursor IS
		SELECT nvl(sum(price_charged),0) - nvl(sum(price_refunded),0)
		FROM ec_items
		WHERE order_id=v_order_id
		and item_state <> 'void';

	price		number;
BEGIN
	OPEN price_cursor;
	FETCH price_cursor INTO price;
	CLOSE price_cursor;

	RETURN price;
END;
/
show errors


-- just the shipping of an order, not price, tax, or gift certificates
-- this is actually total shipping minus total shipping refunded
create or replace function ec_total_shipping (v_order_id IN integer) return number
IS
	CURSOR order_shipping_cursor IS
		SELECT nvl(shipping_charged,0) - nvl(shipping_refunded,0)
		FROM ec_orders
		WHERE order_id=v_order_id;

	CURSOR item_shipping_cursor IS
		SELECT nvl(sum(shipping_charged),0) - nvl(sum(shipping_refunded),0)
		FROM ec_items
		WHERE order_id=v_order_id
		and item_state <> 'void';

	order_shipping		number;
	item_shipping		number;
BEGIN
	OPEN order_shipping_cursor;
	FETCH order_shipping_cursor INTO order_shipping;
	CLOSE order_shipping_cursor;

	OPEN item_shipping_cursor;
	FETCH item_shipping_cursor INTO item_shipping;
	CLOSE item_shipping_cursor;

	RETURN order_shipping + item_shipping;
END;
/
show errors

-- OK
-- just the tax of an order, not price, shipping, or gift certificates
-- this is tax minus tax refunded
create or replace function ec_total_tax (v_order_id IN integer) return number
IS
	CURSOR order_tax_cursor IS
		SELECT nvl(shipping_tax_charged,0) - nvl(shipping_tax_refunded,0)
		FROM ec_orders
		WHERE order_id=v_order_id;

	CURSOR item_price_tax_cursor IS
		SELECT nvl(sum(price_tax_charged),0) - nvl(sum(price_tax_refunded),0)
		FROM ec_items
		WHERE order_id=v_order_id
		and item_state <> 'void';

	CURSOR item_shipping_tax_cursor IS
		SELECT nvl(sum(shipping_tax_charged),0) - nvl(sum(shipping_tax_refunded),0)
		FROM ec_items
		WHERE order_id=v_order_id;

	order_tax		number;
	item_price_tax		number;
	item_shipping_tax	number;
BEGIN
	OPEN order_tax_cursor;
	FETCH order_tax_cursor INTO order_tax;
	CLOSE order_tax_cursor;

	OPEN item_price_tax_cursor;
	FETCH item_price_tax_cursor INTO item_price_tax;
	CLOSE item_price_tax_cursor;

	OPEN item_shipping_tax_cursor;
	FETCH item_shipping_tax_cursor INTO item_shipping_tax;
	CLOSE item_shipping_tax_cursor;

	RETURN order_tax + item_price_tax + item_shipping_tax;
END;
/
show errors


-- OK
-- just the price of a shipment, not shipping, tax, or gift certificates
-- this is the price charged minus the price refunded of the shipment
create or replace function ec_shipment_price (v_shipment_id IN integer) return number
IS
	shipment_price		number;
BEGIN
	SELECT nvl(sum(price_charged),0) - nvl(sum(price_refunded),0) into shipment_price
	FROM ec_items
	WHERE shipment_id=v_shipment_id
	and item_state <> 'void';

	RETURN shipment_price;
END;
/
show errors

-- OK
-- just the shipping charges of a shipment, not price, tax, or gift certificates
-- note: the base shipping charge is always applied to the first shipment in an order.
-- this is the shipping charged minus the shipping refunded
create or replace function ec_shipment_shipping (v_shipment_id IN integer) return number
IS
	item_shipping		number;
	base_shipping		number;
	v_order_id		ec_orders.order_id%TYPE;
	min_shipment_id		ec_shipments.shipment_id%TYPE;
BEGIN
	SELECT order_id into v_order_id FROM ec_shipments where shipment_id=v_shipment_id;
	SELECT min(shipment_id) into min_shipment_id FROM ec_shipments where order_id=v_order_id;
	IF v_shipment_id=min_shipment_id THEN
		SELECT nvl(shipping_charged,0) - nvl(shipping_refunded,0) into base_shipping FROM ec_orders where order_id=v_order_id;
	ELSE
		base_shipping := 0;
	END IF;
	SELECT nvl(sum(shipping_charged),0) - nvl(sum(shipping_refunded),0) into item_shipping FROM ec_items where shipment_id=v_shipment_id and item_state <> 'void';
	RETURN item_shipping + base_shipping;
END;
/
show errors

-- OK
-- just the tax of a shipment, not price, shipping, or gift certificates
-- note: the base shipping tax charge is always applied to the first shipment in an order.
-- this is the tax charged minus the tax refunded
create or replace function ec_shipment_tax (v_shipment_id IN integer) return number
IS
	item_price_tax		number;
	item_shipping_tax	number;
	base_shipping_tax	number;
	v_order_id		ec_orders.order_id%TYPE;
	min_shipment_id		ec_shipments.shipment_id%TYPE;
BEGIN
	SELECT order_id into v_order_id FROM ec_shipments where shipment_id=v_shipment_id;
	SELECT min(shipment_id) into min_shipment_id FROM ec_shipments where order_id=v_order_id;
	IF v_shipment_id=min_shipment_id THEN
		SELECT nvl(shipping_tax_charged,0) - nvl(shipping_tax_refunded,0) into base_shipping_tax FROM ec_orders where order_id=v_order_id;
	ELSE
		base_shipping_tax := 0;
	END IF;
	SELECT nvl(sum(price_tax_charged),0) - nvl(sum(price_tax_refunded),0) into item_price_tax FROM ec_items where shipment_id=v_shipment_id and item_state <> 'void';
	SELECT nvl(sum(shipping_tax_charged),0) - nvl(sum(shipping_tax_refunded),0) into item_shipping_tax FROM ec_items where shipment_id=v_shipment_id and item_state <> 'void';
	RETURN item_price_tax + item_shipping_tax + base_shipping_tax;
END;
/
show errors


-- OK
-- the gift certificate amount used on one order
create or replace function ec_order_gift_cert_amount (v_order_id IN integer) return number
IS
	CURSOR gift_cert_amount_cursor IS
		SELECT nvl(sum(amount_used),0) - nvl(sum(amount_reinstated),0)
		FROM ec_gift_certificate_usage
		WHERE order_id=v_order_id;

	gift_cert_amount	number;
BEGIN
	OPEN gift_cert_amount_cursor;
	FETCH gift_cert_amount_cursor INTO gift_cert_amount;
	CLOSE gift_cert_amount_cursor;

	return gift_cert_amount;
END;
/
show errors



-- OK
-- tells how much of the gift certificate amount used on the order is to be applied
-- to a shipment (it's applied chronologically)
create or replace function ec_shipment_gift_certificate (v_shipment_id IN integer) return number
IS
	v_order_id		ec_orders.order_id%TYPE;
	gift_cert_amount	number;
	past_ship_amount	number;
BEGIN
	SELECT order_id into v_order_id FROM ec_shipments WHERE shipment_id=v_shipment_id;
	gift_cert_amount := ec_order_gift_cert_amount(v_order_id);
	SELECT nvl(sum(ec_shipment_price(shipment_id)) + sum(ec_shipment_shipping(shipment_id))+sum(ec_shipment_tax(shipment_id)),0) into past_ship_amount FROM ec_shipments WHERE order_id = v_order_id and shipment_id <> v_shipment_id;

	IF past_ship_amount > gift_cert_amount THEN
		return 0;
	ELSE
		return least(gift_cert_amount - past_ship_amount, nvl(ec_shipment_price(v_shipment_id) + ec_shipment_shipping(v_shipment_id) + ec_shipment_tax(v_shipment_id),0));
	END IF;
END;
/
show errors

-- OK
-- this can be used for either an item or order
-- given price and shipping, computes tax that needs to be charged (or refunded)
-- order_id is an argument so that we can get the usps_abbrev (and thus the tax rate),
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

-- OK
-- total order cost (price + shipping + tax - gift certificate)
-- this should be equal to the amount that the order was authorized for
-- (if no refunds have been made)
create or replace function ec_order_cost (v_order_id IN integer) return number
IS
	v_price		number;
	v_shipping	number;
	v_tax		number;
	v_certificate	number;
BEGIN
	v_price := ec_total_price(v_order_id);
	v_shipping := ec_total_shipping(v_order_id);
	v_tax := ec_total_tax(v_order_id);
	v_certificate := ec_order_gift_cert_amount(v_order_id);

	return v_price + v_shipping + v_tax - v_certificate;
END;
/
show errors

-- OK
-- total shipment cost (price + shipping + tax - gift certificate)
create or replace function ec_shipment_cost (v_shipment_id IN integer) return number
IS
	v_price		number;
	v_shipping	number;
	v_certificate	number;
	v_tax		number;
BEGIN
	v_price := ec_shipment_price(v_shipment_id);
	v_shipping := ec_shipment_shipping(v_shipment_id);
	v_tax := ec_shipment_tax(v_shipment_id);
	v_certificate := ec_shipment_gift_certificate(v_shipment_id);

	return v_price + v_shipping - v_certificate + v_tax;
END;
/
show errors

-- OK
-- total amount refunded on an order so far
create or replace function ec_total_refund (v_order_id IN integer) return number
IS
	v_order_refund	number;
	v_items_refund	number;
BEGIN
	select nvl(shipping_refunded,0) + nvl(shipping_tax_refunded,0) into v_order_refund from ec_orders where order_id=v_order_id;
	select sum(nvl(price_refunded,0)) + sum(nvl(shipping_refunded,0)) + sum(nvl(price_tax_refunded,0)) + sum(nvl(shipping_tax_refunded,0)) into v_items_refund from ec_items where order_id=v_order_id;
	return v_order_refund + v_items_refund;
END;
/
show errors

-------------- end price calculations -----------------
-------------------------------------------------------


----------- gift certificate procedures ---------------
-------------------------------------------------------
  
CREATE global temporary TABLE ec_gift_cert_usage_ids (
	gift_certificate_id		INTEGER NOT NULL
);
  
create or replace trigger ec_gift_cert_amount_remains_tr
  before update OF amount_used, amount_reinstated on ec_gift_certificate_usage
  FOR each row
BEGIN
   INSERT INTO ec_gift_cert_usage_ids (gift_certificate_id)
     VALUES (:NEW.gift_certificate_id);
END;
/
show errors
  
CREATE OR replace trigger ec_cert_amount_remains_tr_2
  after UPDATE OF amount_used, amount_reinstated ON ec_gift_certificate_usage
DECLARE
  bal_amount_used 		number;
  original_amount		number;
  gift_cert_amount_remains_p    CHAR;
  cursor gift_certificate_cursor is SELECT DISTINCT gift_certificate_id
    FROM ec_gift_cert_usage_ids;
BEGIN
   FOR gift_certificate_rec IN gift_certificate_cursor LOOP
      SELECT nvl(sum(amount_used), 0) - nvl(sum(amount_reinstated),0)
	INTO bal_amount_used
	FROM ec_gift_certificate_usage
	WHERE gift_certificate_id=gift_certificate_rec.gift_certificate_id;
      
      SELECT amount
	INTO original_amount
	FROM ec_gift_certificates
	WHERE gift_certificate_id=gift_certificate_rec.gift_certificate_id;
      
      IF bal_amount_used >= original_amount THEN
	 gift_cert_amount_remains_p := 'f';
      ELSE
	 gift_cert_amount_remains_p := 't';
      END IF;
      
      
      UPDATE ec_gift_certificates 
	SET amount_remaining_p = gift_cert_amount_remains_p
	WHERE gift_certificate_id = gift_certificate_rec.gift_certificate_id;
   END LOOP;
   DELETE from ec_gift_cert_usage_ids;
END;
/
show errors


-- OK
-- calculates how much a user has in their gift certificate account
create or replace function ec_gift_certificate_balance (v_user_id IN integer) return number
IS
	-- these only look at unexpired gift certificates where amount_remaining_p is 't',
	-- hence the word 'subset' in their names

	CURSOR original_amount_subset_cursor IS
		SELECT nvl(sum(amount),0)
		FROM ec_gift_certificates_approved
		WHERE user_id=v_user_id
		AND amount_remaining_p='t'
		AND expires-sysdate > 0;

	CURSOR amount_used_subset_cursor IS
		SELECT nvl(sum(u.amount_used),0) - nvl(sum(u.amount_reinstated),0) as total_amount_used
		FROM ec_gift_certificates_approved c, ec_gift_certificate_usage u
		WHERE c.gift_certificate_id=u.gift_certificate_id
		AND c.user_id=v_user_id
		AND c.amount_remaining_p='t'
		AND c.expires-sysdate > 0;

	original_amount			number;
	total_amount_used		number;
BEGIN
	OPEN original_amount_subset_cursor;
	FETCH original_amount_subset_cursor INTO original_amount;
	CLOSE original_amount_subset_cursor;

	OPEN amount_used_subset_cursor;
	FETCH amount_used_subset_cursor INTO total_amount_used;
	CLOSE amount_used_subset_cursor;

	RETURN original_amount - total_amount_used;
END;
/
show errors


-- OK
-- Returns price + shipping + tax - gift certificate amount applied
-- for one order.
-- Requirement: ec_orders.shipping_charged, ec_orders.shipping_tax_charged,
-- ec_items.price_charged, ec_items.shipping_charged, ec_items.price_tax_chaged,
-- and ec_items.shipping_tax_charged should already be filled in.

create or replace function ec_order_amount_owed (v_order_id IN integer) return number
IS
	pre_gc_amount_owed		number;
	gc_amount			number;
BEGIN
	pre_gc_amount_owed := ec_total_price(v_order_id) + ec_total_shipping(v_order_id) + ec_total_tax(v_order_id);
	gc_amount := ec_order_gift_cert_amount(v_order_id);

	RETURN pre_gc_amount_owed - gc_amount;
END;
/
show errors

-- OK
-- the amount remaining in an individual gift certificate
create or replace function gift_certificate_amount_left (v_gift_certificate_id IN integer) return number
IS
	CURSOR amount_used_cursor IS
		SELECT nvl(sum(amount_used),0) - nvl(sum(amount_reinstated),0)
		FROM ec_gift_certificate_usage
		WHERE gift_certificate_id = v_gift_certificate_id;

	CURSOR original_amount_cursor IS
		SELECT amount
		FROM ec_gift_certificates
		WHERE gift_certificate_id = v_gift_certificate_id;

	original_amount		number;
	amount_used		number;
BEGIN
	OPEN amount_used_cursor;
	FETCH amount_used_cursor INTO amount_used;
	CLOSE amount_used_cursor;

	OPEN original_amount_cursor;
	FETCH original_amount_cursor INTO original_amount;
	CLOSE original_amount_cursor;

	RETURN original_amount - amount_used;
END;
/
show errors

-- I DON'T USE THIS PROCEDURE ANYMORE BECAUSE THERE'S A MORE
-- FAULT-TOLERANT TCL VERSION
-- This applies gift certificate balance to an entire order
-- by iteratively applying unused/unexpired gift certificates
-- to the order until the order is completely paid for or
-- the gift certificates run out.
-- Requirement: ec_orders.shipping_charged, ec_orders.shipping_tax_charged,
-- ec_items.price_charged, ec_items.shipping_charged, ec_items.price_tax_charged,
-- ec_items.shipping_tax_charged should already be filled in.
-- Call this within a transaction.
create or replace procedure ec_apply_gift_cert_balance (v_order_id IN integer, v_user_id IN integer)
IS
	CURSOR gift_certificate_to_use_cursor IS
		SELECT *
		FROM ec_gift_certificates_approved
		WHERE user_id = v_user_id
		AND (expires is null or sysdate - expires < 0)
		AND amount_remaining_p = 't'
                ORDER BY expires;
	amount_owed			number;
	gift_certificate_balance	number;
	certificate			ec_gift_certificates_approved%ROWTYPE;
BEGIN
	gift_certificate_balance := ec_gift_certificate_balance(v_user_id);
	amount_owed := ec_order_amount_owed(v_order_id);

        OPEN gift_certificate_to_use_cursor;
	WHILE amount_owed > 0 and gift_certificate_balance > 0
		LOOP
			FETCH gift_certificate_to_use_cursor INTO certificate;

	        	INSERT into ec_gift_certificate_usage
			(gift_certificate_id, order_id, amount_used, used_date)
			VALUES
			(certificate.gift_certificate_id, v_order_id, least(gift_certificate_amount_left(certificate.gift_certificate_id), amount_owed), sysdate);

			gift_certificate_balance := ec_gift_certificate_balance(v_user_id);
			amount_owed := ec_order_amount_owed(v_order_id);	
		END LOOP;
        CLOSE gift_certificate_to_use_cursor;
END ec_apply_gift_cert_balance;
/
show errors


-- OK
-- reinstates all gift certificates used on an order (as opposed to
-- individual items), e.g. if the order was voided or an auth failed

create or replace procedure ec_reinst_gift_cert_on_order (v_order_id IN integer)
IS
BEGIN
	insert into ec_gift_certificate_usage
	(gift_certificate_id, order_id, amount_reinstated, reinstated_date)
	select gift_certificate_id, v_order_id, nvl(sum(amount_used),0)-nvl(sum(amount_reinstated),0), sysdate
	from ec_gift_certificate_usage
	where order_id=v_order_id
	group by gift_certificate_id;
END;
/
show errors

-- Given an amount to refund to an order, this tells
-- you how much of that is to be refunded in cash (as opposed to 
-- reinstated in gift certificates).  Then you know you have to
-- go and reinstate v_amount minus (what this function returns)
-- in gift certificates.
-- (when I say cash I'm really talking about credit card
-- payment -- as opposed to gift certificates)

-- Call this before inserting the amounts that are being refunded
-- into the database.
create or replace function ec_cash_amount_to_refund (v_amount IN number, v_order_id IN integer) return number
IS
	amount_paid			number;
	items_amount_paid		number;
	order_amount_paid		number;
	amount_refunded			number;
	curr_gc_amount			number;
	max_cash_refundable		number;
	cash_to_refund			number;
BEGIN
	-- the maximum amount of cash refundable is equal to
	-- the amount paid (in cash + certificates) for shipped items only (since
	--  money is not paid until an item actually ships)
	-- minus the amount refunded (in cash + certificates) (only occurs for shipped items)
	-- minus the current gift certificate amount applied to this order
	-- or 0 if the result is negative

	select sum(nvl(price_charged,0)) + sum(nvl(shipping_charged,0)) + sum(nvl(price_tax_charged,0)) + sum(nvl(shipping_tax_charged,0)) into items_amount_paid from ec_items where order_id=v_order_id and shipment_id is not null and item_state <> 'void';

	select nvl(shipping_charged,0) + nvl(shipping_tax_charged,0) into order_amount_paid from ec_orders where order_id=v_order_id;

	amount_paid := items_amount_paid + order_amount_paid;
	amount_refunded := ec_total_refund(v_order_id);
	curr_gc_amount := ec_order_gift_cert_amount(v_order_id);
	
	max_cash_refundable := amount_paid - amount_refunded - curr_gc_amount;
	cash_to_refund := least(max_cash_refundable, v_amount);

	RETURN cash_to_refund;
END;
/
show errors;

-- The amount of a given gift certificate used on a given order.
-- This is a helper function for ec_gift_cert_unshipped_amount.
create or replace function ec_one_gift_cert_on_one_order (v_gift_certificate_id IN integer, v_order_id IN integer) return number
IS
	bal_amount_used		number;
BEGIN
	select nvl(sum(amount_used),0)-nvl(sum(amount_reinstated),0) into bal_amount_used
	from ec_gift_certificate_usage
	where order_id=v_order_id
	and gift_certificate_id=v_gift_certificate_id;

	RETURN bal_amount_used;

END ec_one_gift_cert_on_one_order;
/
show errors

-- The amount of all gift certificates used on a given order that
-- expire before* a given gift certificate (*in the event that two
-- expire at precisely the same time, the one with a higher
-- gift_certificate_id is defined to expire last).
-- This is a helper function for ec_gift_cert_unshipped_amount.
create or replace function ec_earlier_certs_on_one_order (v_gift_certificate_id IN integer, v_order_id IN integer) return number
IS
	bal_amount_used		number;
BEGIN
	select nvl(sum(u.amount_used),0)-nvl(sum(u.amount_reinstated),0) into bal_amount_used
	from ec_gift_certificate_usage u, ec_gift_certificates g, ec_gift_certificates g2
	where u.gift_certificate_id=g.gift_certificate_id
	and g2.gift_certificate_id=v_gift_certificate_id
	and u.order_id=v_order_id
	and (g.expires < g2.expires or (g.expires = g2.expires and g.gift_certificate_id < g2.gift_certificate_id));

	return bal_amount_used;
END;
/
show errors

-- The amount of a gift certificate that is applied to the upshipped portion of an order.
-- This is a helper function for ec_gift_cert_unshipped_amount.
create or replace function ec_cert_unshipped_one_order (v_gift_certificate_id IN integer, v_order_id IN integer) return number
IS
	total_shipment_cost	number;
	earlier_certs		number;
	total_tied_amount	number;
BEGIN
	select nvl(sum(nvl(ec_shipment_price(shipment_id),0) + nvl(ec_shipment_shipping(shipment_id),0) + nvl(ec_shipment_tax(shipment_id),0)),0) into total_shipment_cost
	from ec_shipments
	where order_id=v_order_id;

	earlier_certs := ec_earlier_certs_on_one_order(v_gift_certificate_id, v_order_id);

	IF total_shipment_cost <= earlier_certs THEN
		total_tied_amount := ec_one_gift_cert_on_one_order(v_gift_certificate_id, v_order_id);
	ELSIF total_shipment_cost > earlier_certs + ec_one_gift_cert_on_one_order(v_gift_certificate_id, v_order_id) THEN
		total_tied_amount := 0;
	ELSE
		total_tied_amount := ec_one_gift_cert_on_one_order(v_gift_certificate_id, v_order_id) - (total_shipment_cost - earlier_certs);
	END IF;

	RETURN total_tied_amount;		
END;
/
show errors

-- Returns the amount of a gift certificate that is applied to the unshipped portions of orders
-- (this amount is still considered "outstanding" since revenue, and thus gift certificate usage,
-- isn't recognized until the items ship).
create or replace function ec_gift_cert_unshipped_amount (v_gift_certificate_id IN integer) return number
IS
	tied_but_unshipped_amount	number;
BEGIN
	select nvl(sum(ec_cert_unshipped_one_order(v_gift_certificate_id,order_id)),0) into tied_but_unshipped_amount
	from ec_orders
	where order_id in (select unique order_id from ec_gift_certificate_usage where gift_certificate_id=v_gift_certificate_id);

	return tied_but_unshipped_amount;
END;
/
show errors;

---------- end gift certificate procedures ------------
-------------------------------------------------------
