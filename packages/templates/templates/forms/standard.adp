<if %form.help% not nil>
  <p><var name="form.help"></p>
</if>

<multiple name="form.elements">
<if %form.elements.widget% eq "hidden">
  <?formwidget name="<var name="form.elements.name">">
</if>
</multiple>

<table border=0 cellpadding=2>

<multiple name="form.elements">
<if %form.elements.widget% not in hidden none>
  <tr>
    <td valign=top>

      <subif %form.elements.status% eq required>
        <font color="#AA0000"><b>
      </subif>

      <subif %form.elements.status% eq optional>
        <font color="#000021"><b>
      </subif>

      <subif %form.elements.label% not nil>
        <var name="form.elements.label">
      </subif>

      <subif %form.elements.help% not nil>
       </b></font>
       <br>
          <em><var name="form.elements.help"></em>
       </subif>

       &nbsp;

    </td>

    <td valign=top>

      <subif %form.elements.widget% not in radio checkbox>
        <?formwidget name="<var name="form.elements.name">">
      </subif>

      <subif %form.elements.widget% in radio checkbox>
        <?formgroup name="<var name="form.elements.name">">
          <?formwidget name="<var name="form.elements.name">">
          <?formlabel name="<var name="form.elements.name">">

        <?/formgroup>
      </subif>


    </td>

    </tr>

    <?if %form.error.<var name="form.elements.name">% not nil>
    <tr>
    <td>&nbsp;</td>
    <td>
      
        <font color="#AA0000">
        <?var name="form.error.<var name="form.elements.name">">
        </font><p>
  
    </td>
    </tr>
  <?/if>
</if>
</multiple>

<if %form.submit% not nil>
<tr>
  <td>&nbsp;</td>
  <td>
    <br>
    <input type=submit value="<var name="form.submit">">
  </td>
</tr>
</if>

</table>












