<table cellspacing=0 cellpadding=4 border=1>

<tr bgcolor=#ffffce>
<list name=":columns">
  <th><var name=":columns.item"></th>
</list>
</tr>

<multiple name=":data">

  <if %:data.rownum% odd> <tr bgcolor=#ffffff> </if>
  <else> <tr bgcolor=#eeeeee> </else>

<list name=":data.items">

  <td> 

    <var name=":data.items.item">

  </td>

</list>

</tr>
</multiple>

</table>
