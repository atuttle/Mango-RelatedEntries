<!---
LICENSE INFORMATION:

Copyright 2008, Adam Tuttle
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not 
use this file except in compliance with the License. 

You may obtain a copy of the License at 

	http://www.apache.org/licenses/LICENSE-2.0 
	
Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR 
CONDITIONS OF ANY KIND, either express or implied. See the License for the 
specific language governing permissions and limitations under the License.

VERSION INFORMATION:

This file is part of RelatedEntries Beta 1 (0.2).

The version number in parenthesis is in the format versionNumber.subversionRevisionNumber.
--->
<script type="text/javascript">
	// array find function from: 
	// http://snippets.dzone.com/posts/show/3631
	Array.prototype.find = function(searchStr) {
		var returnArray = false;
		for (i=0; i<this.length; i++) {
			if (typeof(searchStr) == 'function') {
				if (searchStr.test(this[i])) {
					if (!returnArray) { returnArray = [] }
						returnArray.push(i);
					}
				} else {
					if (this[i]===searchStr) {
						if (!returnArray) { returnArray = [] }
							returnArray.push(i);
						}
				}
		}
		return returnArray;
	}
	// Array Remove - By John Resig (MIT Licensed)
	// http://ejohn.org/blog/javascript-array-remove/
	Array.prototype.remove = function(from, to) {
		this.splice(from, (to || from || 1) + (from < 0 ? this.length : 0));
		return this.length;
	};
	//================================================================
	$(document).ready(function(){
		$('#relEntCat').bind("mouseup",function(){
			handleClick(this);
		});
		$('#relEntPotentials').bind("mouseup",function(){
			if (this.options.length > 0){
				var sel = '';
				$('#relEntPotentials option:selected').each(function(){
					addRelEntry(this.value, this.text);
				});
			}
		});
		$('#relatedEntriesBox').bind("dblclick",function(){
			if (this.options.length > 0){
				removeRelEntry(this.options[this.selectedIndex].value, this.options[this.selectedIndex].text);
			}
		});
		document.getElementById('relatedEntries').value = relEntryIdList;
		refreshRelEntriesBox();
	});
	//================================================================
	var entryId = <cfoutput>'#local.entryId#';</cfoutput>
	var entrySep = '@&@&@&@';
	function handleClick(catBox){
		//get list of selected id's
		var sel = '';
		for(i=0; i < catBox.options.length; i++){
			if (catBox.options[i].selected){
				sel = sel + ',' + catBox.options[i].value;
			}
		}
		sel = sel.substr(1); //delete first comma
		//make ajax request for entries with the given categories
		//relEntryMgr.getEntriesByCatIdList(sel);
		$.getJSON(ajaxPath, "method=getEntriesByCatIdList&catIdList="+sel, relEntryResponse);
	}
	function relEntryResponse(response){
//		alert(response);
		//loop over response array, creating items in the 2nd select box
		var sb = document.getElementById('relEntPotentials');
		sb.options.length = 0;
		for (i=0; i < response.length; i++){
			if (entryId != response[i].ID){
				lbAddOption(sb, response[i].NAME, response[i].ID);//struct key names must be in upper case
			}
		}
		selectDefaultOpts(sb);
	}
	function lbAddOption(selectbox,text,value){
		var opt = document.createElement("option");
		opt.text = text;
		opt.value = value;
		selectbox.options.add(opt);
	}
	function selectDefaultOpts(selectbox){
		var relEntry = relEntryIdList.split(entrySep);
		for (var j = 0; j < relEntry.length; j++){
			for (var i = 0; i < selectbox.options.length; i++){
				if (selectbox.options[i].value == relEntry[j]){
					selectbox.options[i].selected = true;
					break;
				}
			}
		}
	}
	function addRelEntry(id,title){
		if (!relEntryIdList.split(entrySep).find(id + '|' + title)){
			relEntryIdList = relEntryIdList + entrySep + id + '|' + title;
			if (relEntryIdList.indexOf(',') == 0){ relEntryIdList = relEntryIdList.substr(1); }//drop leading comma (if it's there)
			document.getElementById('relatedEntries').value = relEntryIdList;
			refreshRelEntriesBox();
		}
	}
	function removeRelEntry(id,title){
		var regex1 = new RegExp('' + id + '\\|' + title + '');
		var regex2 = new RegExp('(' + entrySep + '){2}');
		relEntryIdList = relEntryIdList.replace(regex1, '');
		relEntryIdList = relEntryIdList.replace(regex2, entrySep);
		document.getElementById('relatedEntries').value = relEntryIdList;
		refreshRelEntriesBox();
	}
	function refreshRelEntriesBox(){
		if (relEntryIdList.length > 0){
			var box = document.getElementById('relatedEntriesBox');
			var vals = '';
			box.options.length = 0;
			pairs = relEntryIdList.split(entrySep);
			for (var pair = 0; pair < pairs.length; pair++){
				vals = pairs[pair].split('|');
				if (vals.length > 1){ //ignore no-title (added in older version)
					lbAddOption(box, vals[1], vals[0]);
				}
			}
		}
	}
</script>

<cfoutput>
	<div style="width:auto; float:left;">
		<strong>Find Related Entries:</strong><br />
		<small><em>Click to add</em></small><br />
		<select name="relEntCat" id="relEntCat" multiple="true" size="10">
			<cfloop from="1" to="#arrayLen(local.allCategories)#" index="local.cat">
				<option value="#local.allCategories[local.cat].name#">#local.allCategories[local.cat].title#</option>
			</cfloop>
		</select>
		<select name="relEntPotentials" id="relEntPotentials" multiple="true" size="10"></select>
	</div>
	<div style="margin-left: 10px; width:auto; float:left;">
		<strong>Selected Entries:</strong><br />
		<small><em>Double-click to remove</em></small><br />
		<input type="hidden" name="relatedEntries" id="relatedEntries" value="<cfoutput>#local.entryRelatedEntryIds#</cfoutput>" />
		<select name="relatedEntriesBox" id="relatedEntriesBox" multiple="true" size="10"></select>
	</div>
</cfoutput>