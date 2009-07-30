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

This file is part of RelatedEntries.
--->
<cfcomponent extends="BasePlugin">

	<cffunction name="init" access="public" output="false" returntype="any">
		<cfargument name="mainManager" type="any" required="true" />
		<cfargument name="preferences" type="any" required="true" />
		
		<cfset setManager(arguments.mainManager) />
		<cfset setPreferencesManager(arguments.preferences) />
		<cfset setPackage("com/fusiongrokker/plugins/RelatedEntries") />
		
		<cfset variables.customFieldKey = "relEntries-b1" />
		<cfset variables.entryDelim = "@&@&@&@" />
		<cfset variables.titleDelim = "|" />
		<cfset variables.entryDelimShort = chr(10) />
		<cfset variables.titleDelimShort = chr(13) />
		<cfset variables.logFile = "Mango-RelatedEntries" />
	
		<cfreturn this/>
	</cffunction>

	<cffunction name="setup" hint="This is run when a plugin is activated" access="public" output="false" returntype="any">
		<cfreturn "Related Entries plugin activated"/>
	</cffunction>
	<cffunction name="unsetup" hint="This is run when a plugin is de-activated" access="public" output="false" returntype="any">
		<cfreturn "Related Entries plugin de-activated"/>
	</cffunction>

	<cffunction name="handleEvent" hint="Asynchronous event handling" access="public" output="false" returntype="any">
		<cfargument name="event" type="any" required="true" />
		<!--- no asynchronous events for this plugin --->
		<cfreturn />
	</cffunction>

	<cffunction name="processEvent" hint="Synchronous event handling" access="public" output="false" returntype="any">
		<cfargument name="event" type="any" required="true" />
		
		<cfset var relEntries = ""/>
		<cfset var local = StructNew() />
		
		<cfswitch expression="#arguments.event.name#">

			<cfcase value="beforeAdminPostFormEnd">

				<cfset local.assetPath = getAdminAssetPath() & "ajax/proxy.cfm" />
				<cfsavecontent variable="relEntries">
					<cfsilent>
						<cfset local.entryId = arguments.event.item.id />
						<cfset local.allCategories = getManager().getCategoriesManager().getCategories() />
						<cfset local.entryCategories = arguments.event.item.getCategories() />
						<cfset local.entryRelatedEntryIds = ""/>
						<cfif structKeyExists(request, "relatedEntriesRawData")>
							<cfset local.entryRelatedEntryIds = request.relatedEntriesRawData />
							<cfset local.entryRelatedEntryIds = replace(local.entryRelatedEntryIds, "'", "\'", "ALL") />
						</cfif>
						<!--- convert delimiters to a single character --->
						<cfset local.entryRelatedEntryIds = replace(local.entryRelatedEntryIds,variables.entryDelim,variables.entryDelimShort, "ALL")/>
					</cfsilent>
					<script type="text/javascript">
						<cfoutput>
						var ajaxPath = '#local.assetPath#';
						var relEntryIdList = '';
						<cfloop from="1" to="#listLen(local.entryRelatedEntryIds, variables.entryDelimShort)#" index="local.entryNum">
						relEntryIdList += '#listGetAt(local.entryRelatedEntryIds, local.entryNum, variables.entryDelimShort)#<cfif local.entryNum lt listLen(local.entryRelatedEntryIds, variables.entryDelimShort)>#variables.entryDelim#</cfif>';
						</cfloop>
						</cfoutput>
					</script>
					<fieldset id="customFieldsFieldset" class="">
						<legend>Related Entries</legend>
						<div>
							<cfset local.entryRelatedEntryIds = replace(local.entryRelatedEntryIds,variables.entryDelimShort,variables.entryDelim, "ALL")/>
							<cfif len(local.entryRelatedEntryIds) gt len(variables.entryDelim) and left(local.entryRelatedEntryIds, len(variables.entryDelim)) eq variables.entryDelim>
								<cfset local.entryRelatedEntryIds = right(local.entryRelatedEntryIds, len(local.entryRelatedEntryIds) - len(variables.entryDelim)) />
							<cfelseif local.entryRelatedEntryIds eq variables.entryDelim>
								<cfset local.entryRelatedEntryIds = "" />
							</cfif>
							<cfinclude template="relatedEntries.cfm">
						</div>
					</fieldset>
				</cfsavecontent>
				<cfset arguments.event.setOutputData(arguments.event.getOutputData() & relEntries) />

			</cfcase>

			<cfcase value="beforeAdminPostFormDisplay">
				<!--- use this event to hide related entries data from the user in the "custom fields" section... no reason for its raw data to show up ---> 
				<cfif arguments.event.item.customFieldExists(variables.customFieldKey)>
					<cfset request.relatedEntriesRawData = arguments.event.item.getCustomField(variables.customFieldKey).value />
					<cfset arguments.event.item.removeCustomField(variables.customFieldKey) />
				</cfif>

			</cfcase>

			<cfcase value="showRelatedEntriesList,beforePostContentEnd">
			
				<cfif arguments.event.contextData.currentPost.customFieldExists(variables.customFieldKey)>
					<cfset local.relData = arguments.event.contextData.currentPost.getCustomField(variables.customFieldKey).value />
					<cfset local.relData = replace(local.relData, variables.entryDelim, variables.entryDelimShort, "ALL") />
					<cfif listLen(local.relData, variables.entryDelimShort)>
						<cfsavecontent variable="local.relEntryLinkList"><cfoutput>
							<div class="related">
								<h4>Related Entries:</h4>
								<ul>
									<cfloop list="#local.relData#" index="local.relEntryId" delimiters="#variables.entryDelimShort#">
										<cftry>
											<cfsilent>
												<cfset local.relEntryObj = variables.mainManager.getPostsManager().getPostById(listFirst(local.relEntryId,'|')) />
											</cfsilent>
											<li><a href="#local.relEntryObj.getPermalink()#">#local.relEntryObj.getTitle()#</a></li>
											<cfcatch>
												<!--- post not found because it is a draft/etc --->
											</cfcatch>
										</cftry>
									</cfloop>
								</ul>
							</div>
						</cfoutput></cfsavecontent>
						<cfset arguments.event.setOutputData(local.relEntryLinkList)/>
					</cfif>
				</cfif>

			</cfcase>

			<cfcase value="afterPostAdd,afterPostUpdate">
			
				<!--- set related entries for this entry --->
				<cfif structKeyExists(arguments.event.data.rawData, "relatedEntries")><!--- this catches the original form post (add/update entry) --->
					<cfset local.entryId = arguments.event.data.post.id />
					<cfset local.entryTitle = arguments.event.data.post.getTitle() />
					<!--- add the related entries data for the newly added/updated entry --->
					<cfset arguments.event.data.post.setCustomField(variables.customFieldKey, "Related Entries", arguments.event.data.rawdata.relatedEntries) />
					<!--- save the entry again --->
					<cftry>
						<cflog file="#variables.logFile#" text="updating entry: #arguments.event.data.post.getTitle()#">
						<cfset getManager().getAdministrator().editPost(
								arguments.event.data.post.getId(),
								arguments.event.data.post.getTitle(),
								arguments.event.data.post.getContent(),
								arguments.event.data.post.getExcerpt(),
								arguments.event.data.post.getStatus() eq "published",
								arguments.event.data.post.getCommentsAllowed(),
								arguments.event.data.post.getPostedOn(),
								"",<!--- user, isn't used --->
								arguments.event.data.post.customFields
						)/>
						<cflog file="#variables.logFile#" text="last update successful">
						<cfcatch>
							<cfdump var="#local#" label="local vars">
							<cfdump var="#cfcatch#">
							<cflog file="#variables.logFile#" text="last update unsuccessful -- #cfcatch.message# -- #cfcatch.detail#">
							<cfabort>
						</cfcatch>
					</cftry>
	
					<!--- now update each related entry and add this entry to its related list... --->
					<cfset local.tmp = arguments.event.data.rawdata.relatedEntries />
					<cfset local.tmp = replace(local.tmp, variables.entryDelim, variables.entryDelimShort, "ALL") />
					<cfset local.tmp = replace(local.tmp, variables.titleDelim, variables.titleDelimShort, "ALL") />
					<cfloop list="#local.tmp#" index="local.refPost" delimiters="#variables.entryDelimShort#">
						<cfset local.refPostTitle = listLast(local.refPost, variables.titleDelimShort) />
						<cfset local.refPostId = listFirst(local.refPost, variables.titleDelimShort) />
						<cfset local.refPostObj = getManager().getPostsManager().getPostById(local.refPostId, true) />
						<!--- keep existing related entries of the entry, but add our new one --->
						<cfif local.refPostObj.customFieldExists(variables.customFieldKey)>
							<cfset local.existingRelentries = local.refPostObj.getCustomField(variables.customFieldKey).value /> 
						<cfelse>
							<cfset local.existingRelentries = "" /> 
						</cfif>
						<!--- no duplicates --->
						<cftry>
							<!--- don't care that it's a list, just can we find the id of the original post in the relation data --->
							<cfif not findNoCase(local.entryId, local.existingRelentries)>
								<cfif len(local.existingRelentries) gt 0>
									<cfset local.existingRelentries = local.existingRelEntries & variables.entryDelim />
								</cfif>
								<cfset local.existingRelentries = local.existingRelEntries & local.entryId & variables.titleDelim & local.entryTitle />
								<cfset local.refPostObj.setCustomField(variables.customFieldKey, "Related Entries", local.existingRelentries)/>
								<cflog file="#variables.logFile#" text="updating entry: #local.refPostObj.getTitle()#">
								<cfset getManager().getAdministrator().editPost(
										local.refPostObj.getId(),
										local.refPostObj.getTitle(),
										local.refPostObj.getContent(),
										local.refPostObj.getExcerpt(),
										local.refPostObj.getStatus() eq "published",
										local.refPostObj.getCommentsAllowed(),
										local.refPostObj.getPostedOn(),
										"",<!--- user, isn't used --->
										local.refPostObj.customFields
								)/>
								<cflog file="#variables.logFile#" text="last update successful">
							<cfelse>
								<cflog file="#variables.logFile#" text="skipping update of related entry: #local.entryId#">
							</cfif>
							<cfcatch>
								<cfdump var="#local#" label="local vars">
								<cfdump var="#cfcatch#">
								<cflog file="#variables.logFile#" text="last update unsuccessful -- #cfcatch.message# -- #cfcatch.detail#">
								<cfabort>
							</cfcatch>
						</cftry>
					</cfloop>
				</cfif>
	
			</cfcase>

		</cfswitch>

		<cfreturn arguments.event />
	</cffunction>

</cfcomponent>