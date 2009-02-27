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
<cfcomponent>

	<cfset variables.package = "com/tuttle/plugins/RelatedEntries"/>
	<cfset variables.id = "" />
	<cfset variables.name = "RelatedEntries" />
	<cfset variables.customFieldKey = "relEntries-b1" />

	<cffunction name="init" access="public" output="false" returntype="any">
		<cfargument name="mainManager" type="any" required="true" />
		<cfargument name="preferences" type="any" required="true" />
		
			<cfset var blogid = arguments.mainManager.getBlog().getId() />
			<cfset variables.path = blogid & "/" & variables.package />
			<cfset variables.prefManager = arguments.preferences />
			<cfset variables.blogManager = arguments.mainManager />
			
		<cfreturn this/>
	</cffunction>

	<cffunction name="getName" access="public" output="false" returntype="string">
		<cfreturn variables.name />
	</cffunction>

	<cffunction name="setName" access="public" output="false" returntype="void">
		<cfargument name="name" type="string" required="true" />
		<cfset variables.name = arguments.name />
		<cfreturn />
	</cffunction>

	<cffunction name="getId" access="public" output="false" returntype="any">
		<cfreturn variables.id />
	</cffunction>
	
	<cffunction name="setId" access="public" output="false" returntype="void">
		<cfargument name="id" type="any" required="true" />
		<cfset variables.id = arguments.id />
		<cfreturn />
	</cffunction>

	<cffunction name="setup" hint="This is run when a plugin is activated" access="public" output="false" returntype="any">
		<cfset copyAssets()/>
		<cfreturn "Related Entries plugin activated"/>
	</cffunction>

	<cffunction name="unsetup" hint="This is run when a plugin is de-activated" access="public" output="false" returntype="any">
		<cfset clearAssets()/>
		<cfreturn "Related Entries plugin de-activated"/>
	</cffunction>

	<cffunction name="handleEvent" hint="Asynchronous event handling" access="public" output="false" returntype="any">
		<cfargument name="event" type="any" required="true" />
		<cfreturn />
	</cffunction>

	<cffunction name="processEvent" hint="Synchronous event handling" access="public" output="false" returntype="any">
		<cfargument name="event" type="any" required="true" />
		
		<cfset var relEntries = ""/>
		<cfset var local = StructNew() />
		
		<cfif arguments.event.name eq "beforeAdminPostFormEnd">
			<cfset local.assetpath = variables.blogManager.getBlog().getBasePath() />
			<cfif len(local.assetPath) gt 0 and right(local.assetPath, 1) neq "/">
				<cfset local.assetPath = local.assetPath & "/" />
			</cfif>
			<cfif len(local.assetPath) gt 0 and left(local.assetPath, 1) neq "/">
				<cfset local.assetPath = "/" & local.assetPath />
			</cfif>
			<!---<cfset local.assetPath = local.assetPath & "assets/plugins/RelatedEntries/relatedEntries.cfc" />--->
			<cfset local.assetPath = local.assetPath & "assets/plugins/RelatedEntries/proxy.cfm" />
			<cfset local.jqueryPath = listDeleteAt(local.assetPath, listLen(local.assetPath, '/'), '/') />
			<cfset local.jqueryPath = local.jqueryPath & "/jquery.js" />
			
			<cfsavecontent variable="relEntries">
				<cfsilent>
					<cfset local.entryId = arguments.event.item.id />
					<cfset local.allCategories = variables.blogManager.getCategoriesManager().getCategories() />
					<cfset local.entryCategories = arguments.event.item.getCategories() />
					<cfset local.entryRelatedEntryIds = ""/>
<!--- 					
					<cfif arguments.event.item.customFieldExists(variables.customFieldKey)>
						<cfset local.entryRelatedEntryIds = arguments.event.item.getCustomField(variables.customFieldKey).value />
					</cfif>
 --->
					<cfif structKeyExists(request, "relatedEntriesRawData")>
						<cfset local.entryRelatedEntryIds = request.relatedEntriesRawData />
						<cfset local.entryRelatedEntryIds = replace(local.entryRelatedEntryIds, "'", "\'", "ALL") />
					</cfif>
				</cfsilent>
				<!--- <cfajaxproxy cfc="#local.assetPath#" jsclassname="relatedEntries" /> --->
				<script type="text/javascript" src="<cfoutput>#local.jqueryPath#</cfoutput>"></script>
				<script type="text/javascript">
					<cfoutput>
					var ajaxPath = '#local.assetPath#';
					var relEntryIdList = '';
					<cfloop from="1" to="#listLen(local.entryRelatedEntryIds, '|')#" index="local.entryNum">
					relEntryIdList += '#listGetAt(local.entryRelatedEntryIds, local.entryNum, "|")#<cfif local.entryNum lt listLen(local.entryRelatedEntryIds, "|")>|</cfif>';
					</cfloop>
					</cfoutput>
				</script>
				<fieldset id="customFieldsFieldset" class="">
					<legend>Related Entries</legend>
					<div>
						<cfinclude template="relatedEntries.cfm">
					</div>
				</fieldset>
			</cfsavecontent>
			<cfset arguments.event.setOutputData(relEntries) />
		
		<cfelseif arguments.event.name eq "beforeAdminPostFormDisplay">
		
			<!--- use this event to hide related entries data from the user... no reason for its raw data to show up ---> 
			<cfif arguments.event.item.customFieldExists(variables.customFieldKey)>
				<cfset request.relatedEntriesRawData = arguments.event.item.getCustomField(variables.customFieldKey).value />
				<cfset arguments.event.item.removeCustomField(variables.customFieldKey) />
			</cfif>

		<cfelseif arguments.event.name eq "showRelatedEntriesList" or arguments.event.name eq "beforePostContentEnd">
			<cfif arguments.event.contextData.currentPost.customFieldExists(variables.customFieldKey)>
				<cfset local.relData = arguments.event.contextData.currentPost.getCustomField(variables.customFieldKey).value />
				<cfset local.relData = replace(local.relData, "@&@&@&@", chr(10), "ALL") />
				<cfsavecontent variable="local.relEntryLinkList"><cfoutput>
					<div class="related">
						<h4>Related Entries:</h4>
						<ul>
							<cfloop list="#local.relData#" index="local.relEntryId" delimiters="#chr(10)#">
								<cftry>
									<cfsilent>
										<cfset local.relEntryObj = blogManager.getPostsManager().getPostById(listFirst(local.relEntryId,'|')) />
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

		<cfelseif arguments.event.name eq "afterPostAdd" or arguments.event.name eq "afterPostUpdate">
			<!--- set related entries for this entry --->
			<cfif structKeyExists(arguments.event.data.rawData, "relatedEntries")><!--- this catches the original form post (add/update entry) --->
				<cfset local.entryId = arguments.event.data.post.id/>
				<!--- add the related entries data for the newly added/updated entry --->
				<cfset arguments.event.data.post.setCustomField(variables.customFieldKey, "Related Entries", arguments.event.data.rawdata.relatedEntries) />
				<!--- save the entry again --->
				<cftry>
<cflog file="Mango-RelatedEntries" text="updating entry: #arguments.event.data.post.getTitle()#">
					<cfset variables.blogManager.getAdministrator().editPost(
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
<cflog file="Mango-RelatedEntries" text="last update successful">
					<cfcatch>
						<cfdump var="#local#" label="local vars">
						<cfdump var="#cfcatch#">
<cflog file="Mango-RelatedEntries" text="last update unsuccessful -- #cfcatch.message# -- #cfcatch.detail#">
						<cfabort>
					</cfcatch>
				</cftry>

				<!--- now update each related entry and add this entry to its related list... --->
				<cfset local.tmp = replace(arguments.event.data.rawdata.relatedEntries, "@&@&@&@", chr(10), "ALL") />
				<cfloop list="#local.tmp#" index="local.refPostId" delimiters="#chr(10)#">
					<cfset local.refPostId = listFirst(local.refPostId, "|") />
					<cfset local.refPost = variables.blogManager.getPostsManager().getPostById(local.refPostId, true) />
					<!--- keep existing related entries of the entry, but add our new one --->
					<cfif local.refPost.customFieldExists(variables.customFieldKey)>
						<cfset local.existingRelentries = local.refPost.getCustomField(variables.customFieldKey).value /> 
					<cfelse>
						<cfset local.existingRelentries = "" /> 
					</cfif>
					<!--- no duplicates --->
					<cftry>
						<cfif not listFind(local.existingRelentries, local.entryId)>
							<cfset local.existingRelentries = listAppend(local.existingRelentries, local.entryId)/>
							<cfset local.refPost.setCustomField(variables.customFieldKey, "Related Entries", local.existingRelentries)/>
<cflog file="Mango-RelatedEntries" text="updating entry: #local.refPost.getTitle()#">
							<cfset variables.blogManager.getAdministrator().editPost(
									local.refPost.getId(),
									local.refPost.getTitle(),
									local.refPost.getContent(),
									local.refPost.getExcerpt(),
									local.refPost.getStatus() eq "published",
									local.refPost.getCommentsAllowed(),
									local.refPost.getPostedOn(),
									"",<!--- user, isn't used --->
									local.refPost.customFields
							)/>
<cflog file="Mango-RelatedEntries" text="last update successful">
						<cfelse>
<cflog file="Mango-RelatedEntries" text="skipping update of related entry: #local.entryId#">
						</cfif>
						<cfcatch>
							<cfdump var="#local#" label="local vars">
							<cfdump var="#cfcatch#">
<cflog file="Mango-RelatedEntries" text="last update unsuccessful -- #cfcatch.message# -- #cfcatch.detail#">
							<cfabort>
						</cfcatch>
					</cftry>
				</cfloop>
<!---
 			<cfelseif not structKeyExists(arguments.event.data.rawData, "relatedEntries")>
				<!--- handle no-entries-selected case (remove all related entries) --->
				<cfset arguments.event.data.post.setCustomField(variables.customFieldKey, "Related Entries", "") />
				<!--- save the entry again --->
				<cftry>
					<cfset variables.blogManager.getAdministrator().editPost(
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
					<cfcatch>
						<cfdump var="#local#" label="local vars">
						<cfdump var="#cfcatch#">
						<cfabort>
					</cfcatch>
				</cftry>
 --->
			</cfif>

		</cfif>
		
		<cfreturn arguments.event />
	</cffunction>

	<cffunction name="copyAssets" access="private" output="false" returntype="void"
	hint="I'm used during plugin activation to copy files to a public location">
		
		<!--- copy assets to correct public folder --->
		<cfset var local = structNew()/>
		<cfset local.src = getCurrentTemplatePath() />
		<cfset local.src = listAppend(listDeleteAt(local.src, listLen(local.src, "\/"), "\/"), "assets", "/")/>
		<cfset local.dest = expandPath('#variables.blogManager.getBlog().getBasePath()#/assets/plugins/#variables.name#')/>
		
		<!--- create the destination folder if it doesn't exist --->
		<cfif not directoryExists(local.dest)>
			<cfdirectory action="create" directory="#local.dest#"/>
		</cfif>
		
		<!--- copy our assets to the root/assets/plugins/RelatedEntries folder so that they are web-accessible --->
		<cfdirectory action="list" directory="#local.src#" name="local.assets"/>
		<cfloop query="local.assets">
			<cffile action="copy" source="#local.assets.directory#/#local.assets.name#" destination="#local.dest#/#local.assets.name#"/>
		</cfloop>

	</cffunction>

	<cffunction name="clearAssets" access="private" output="false" returntype="void"
	hint="I'm used during plugin de-activation to remove public files">

		<cfset var local = StructNew()/>
		<cfset local.dir = expandPath('../assets/plugins/#variables.name#')/>

		<!--- delete assets --->
		<cfdirectory action="delete" directory="#local.dir#" recurse="yes"/>
		
	</cffunction>

</cfcomponent>