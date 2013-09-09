<if %x% eq 5>True</if>
<if %x% eq "Greta">True</if>

<if %x% ne 5>True</if>
<if %x% ne "Greta">True</if>

<if %x% lt 5>True</if>
<if %x% le 5>True</if>

<if %x% gt 5>True</if>
<if %x% ge 5>True</if>

<if %x% odd>True</if>
<if %x% even>True</if>

<if %x% between 3 6>True</if>
<if %x% not between 3 6>True</if>

<if %x% eq 5 and %y% eq 2>True</if>
<if %x% ge 5 or %y% le 2>True</if>

<if %s% nil>True</if>
<if %s% not nil>True</if>

<if %z% in "Greta" "Fred" "Sam">True</if>
<if %z% not in "Greta" "Fred" "Sam">True</if>