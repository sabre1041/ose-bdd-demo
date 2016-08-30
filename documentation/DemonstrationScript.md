OpenShift Behavior Driven Development Demo - Demonstration Script
======================================


## Overview

This document describes how to run the demonstration to highlight all the key technologies and concepts (refer to the README).
This assumes that the project is up and running on a local machine as per the [setup document](Setup.md).


## Demo Agenda

This section provides a high-level agenda for the demo. The parenthesis after each discuss what concepts are highlighted in that portion.

1. Discuss what the application is. (*BPMS, Behavior Driven Development*)
2. Show that the application is up and running in a stable state. (*OpenShift Enterprise, Jenkins, CI/CD, DevOps*)
3. Change the business requirements. (*Behavior Driven Development*)
4. Change the logic. (*BRMS*)
5. See the changes get applied. (*OpenShift Enterprise, CI/CD, DevOps*)
6. Deploy to a higher environment. (*OpenShift Enterprise, CI/CD, DevOps*)


## Step by Step Instructions

TODO: This section needs to be cleaned up and expanded upon

This section provides a step-by-step guide on how to run the demonstration.

To get the url for all of these projects reference perform the following actions with the *oc client *in the appropriate projects

1. `oc project ${project name}`
2. `oc get routes`

The following denote the location of project components

* Jenkins, Gogs, Business Central and Nexus all live in the *ci* project
*  The application lives in *coolstore-bdd-dev* and *coolstore-bdd-prod*
*  Business Central will be at the {route}/business-central, all other apps live at the root of the url

## Username/Passwords

* Jenkins
	* username: admin
	* password: password
* Business Central
	* username: brmsuser
	* password: redhat#1
* Gogs
	* username: gogs
	* password: bddgogs

## Setup initialization

1. Go to jenkins and trigger a build for both the rules and the ui application (better to do them one at a time if running in the CDK).
2. Go into the jobs and click the promote to production button for the currently in progress jobs.

## Demo walkthrough

This section detail a typical workflow for executing the demonstration 

1. Describe the application and use case.
	* Discuss the basic architecture of the application.
	* Mention how the application talks to BPMS.
2. Show the application up and running in OpenShift Enterprise. (Show both dev and prod)
3. Change the business requirements.
	* Open up Business Central and log in
	* Update the cost of shipping for orders under $25 in the BDD scenarios only.
		* To update the files you have to go to **Administration** view.  There is no editor for feature files in authoring view.
		* The file is located at coolstore/src/test/resources/features/ShippingCost.txt
		* You will want to update the first two scenarios
		* Save the file
	* Switch the business logic to match the change in the scenario
        	* Switch to the authoring mode and go to the guided decision table called ShippingRules
		* Update the first row and change the value to be one penny off from the value specified in the scenario
		* Tell the observer of the demo that we are mimicking a developer or rules analysts mistake and we are going to show how a build catches it
		* Save the file
		* Click open project editor in the upper right hand corner
		* Update the version 
		* Save this file to trigger a build (Only a change to the pom will trigger a build by pushing to the deployments branch in gogs)	
4. Go over the Jenkins pipelines.
	* Show how Jenkins lets us deploy the application to environments.
	* Explain each stage of the rules pipeline
	* Wait for build to fail
	* Enter the failed build and show the cucumber jvm reports that show the failed scenarios
	* Go to *dev* and *prod* for the app and show how the logic is now different and that *dev* is wrong
	* Highlight that since the build failed it does not allow you to promote this bad logic to production
5. Fix the logic.
	* Now that we know our application doesn't match our requirements, fix the application.
		* Repeat steps 3, bullet point 3, except make the value correct this time
	* Watch Jenkins pass.
	* Show the cucumber reports passing
	* Go to dev and show the correct logic
	* Promote to prod from the pipeline
	* Show prod has the new rules
