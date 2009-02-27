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

This file is part of RelatedEntries 1.0.
--->
<cfcomponent>
	<!--- Create an instance of the JSON Utility, for compatability with older versions of CF --->
	<cfset variables.json = createObject("component", "JSONUtil").init()/>

	<cffunction name="init" output="false" returntype="any">
		<cfreturn this />
	</cffunction>
	
	<cffunction name="getDummyData" access="private">
		<cfset var rtn = ArrayNew(1)/>
		<cfset rtn[1] = StructNew()/>
		<cfset rtn[1].id = "1"/>
		<cfset rtn[1].name="test"/>		
		<cfreturn rtn />
	</cffunction>

	<cffunction name="getEntriesByCatIdList" access="remote" output="false"><!---returnFormat="JSON"--->
		<cfargument name="catIdList" type="string" required="true" />
		
		<cfset var rtn = ArrayNew(1)/>
		<cfset var p = 0 />
		<!--- 
			since this function will be called by AJAX, it has to have access to the blog manager through an external 
			source, so we use the existing applicaiton scoped object
		--->
		<cfset var posts = application.blogManager.getPostsManager().getPostsByCategory(arguments.catIdList) />

		<!--- <cfreturn getDummyData() /> --->
		
		<cfloop from="1" to="#arrayLen(posts)#" index="p">
			<cfset rtn[p] = StructNew()/>
			<cfset rtn[p].id = posts[p].getId()/>
			<cfset rtn[p].name = posts[p].getTitle()/>
		</cfloop>
		
		<cfreturn variables.json.serialize(rtn) />
	</cffunction>

</cfcomponent>