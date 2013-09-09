<%
ad_page_contract {
	@author ?
	@creation-date ?
	@cvs-id if.adp,v 1.1.1.1 2000/08/08 07:25:00 ron Exp
}
%>

<h1>IF tag validation</h1>

<hr>

<%
  set x 5.0
  set y 2
  set s "Fred Finkel"
  uplevel #0 {}
%>

<p>X is set to 5.0</p>

<p>Test if X is equal to 5:
  <if %x% eq 5.0>Yes</if>
  <else>No</else>
</p>

<p>Test if X is equal to 5.1:
  <if %x% eq 5.1>Yes</if>
  <else>No</else>
</p>

<p>Test if X is less than 4.0:
  <if %x% lt 4.0>Yes</if>
  <else>No</else>
</p>

<p>Test if X is greater than 4:
  <if %x% gt 4>Yes</if>
  <else>No</else>
</p>

<p>Test if X is greater than or equal to 4:
  <if %x% ge 4>Yes</if>
  <else>No</else>
</p>

<p>Test if X is less than or equal to 5:
  <if %x% ge 5>Yes</if>
  <else>No</else>
</p>

<p>Test if X is less than or equal to 4:
  <if %x% le 4>Yes</if>
  <else>No</else>
</p>

<p>Test if X is between 3 and 6:
  <if %x% between 3 6>Yes</if>
  <else>No</else>
</p>

<p>Test if X is between 7 and 9:
  <if %x% between 7 9>Yes</if>
  <else>No</else>
</p>

<p>Y is set to 2</p>

<p>Test if Y is 2 and X is 5:
  <if %x% eq 5 and %y% eq 2>Yes</if>
  <else>No</else>
</p>

<p>S is set to "Fred Finkel"</p>

<p>Test if S is equal to "Fred Finkel":
  <if %s% eq "Fred Finkel">Yes</if>
  <else>No</else>
</p>

<if that in that there the other>
  Yes it is in there.
</if>

<p>Test if S is not nil:
  <if %s% not nil>Yes</if>
  <else>No</else>
</p>

<p>Test if Z is not nil:
  <if %z% not nil>Yes</if>
  <else>No</else>
</p>








