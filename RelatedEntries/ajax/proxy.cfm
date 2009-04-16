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

This file is part of RelatedEntries 1.1.
--->
<cfparam name="url.catIdList" default=""/>
<cfset result = createObject("component", "RelatedEntries").getEntriesByCatIdList(url.catIdList)/>
<cfcontent type="text/plain" reset="true"><cfoutput>#variables.result#</cfoutput>