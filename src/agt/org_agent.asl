// organization agent

/* Initial beliefs and rules */
org_name("lab_monitoring_org"). // the agent beliefs that it can manage organizations with the id "lab_monitoting_org"
group_name("monitoring_team"). // the agent beliefs that it can manage groups with the id "monitoring_team"
sch_name("monitoring_scheme"). // the agent beliefs that it can manage schemes with the id "monitoring_scheme"

has_enough_players_for(R) :-
  role_cardinality(R,Min,Max) &
  .count(play(_,R,_),NP) &
  NP >= Min.

/* Initial goals */
!start. // the agent has the goal to start

/* 
 * Plan for reacting to the addition of the goal !start
 * Triggering event: addition of goal !start
 * Context: the agent believes that it can manage a group and a scheme in an organization
 * Body: greets the user
*/
@start_plan
+!start : org_name(OrgName) & group_name(GroupName) & sch_name(SchemeName) <-
  createWorkspace(OrgName); // creates a workspace for the organization
  joinWorkspace(OrgName, WspID1);    // joins the workspace for the organization
  makeArtifact(OrgName, "ora4mas.nopl.OrgBoard",["src/org/org-spec.xml"], OrgArtId)[wid(WspID1)]; // creates an organizational board artifact
  focus(OrgArtId)[wid(WspID1)]; // focuses on the organizational board artifact
  createGroup(GroupName, "monitoring_team" , GroupArtId)[wid(WspID1)]; // creates a group board artifact
  focus(GroupArtId)[wid(WspID1)]; // focuses on the group board artifact
  createScheme(SchemeName, "monitoring_scheme", SchemeArtId)[wid(WspID1)]; // creates a scheme board artifact
  focus(SchemeArtId)[wid(WspID1)]; // focuses on the scheme board artifact
  .broadcast(tell, new_org(OrgName)); // broadcasts the creation of the organization
  ?formationStatus(ok)[artifact_id(GroupArtId)];  // tests the formation status of the group;
  !inspect(GroupArtId)[wid(WspID1)]; // inspects the group board artifact
  !inspect(SchemeArtId)[wid(WspID1)]; // inspects the scheme board artifact
  .print("Hello world").

/* 
 * Plan for reacting to the addition of the test-goal ?formationStatus(ok)
 * Triggering event: addition of goal ?formationStatus(ok)
 * Context: the agent beliefs that there exists a group G whose formation status is being tested
 * Body: if the belief formationStatus(ok)[artifact_id(G)] is not already in the agents belief base
 * the agent waits until the belief is added in the belief base
*/
@test_formation_status_is_ok_plan
+?formationStatus(ok)[artifact_id(G)] : group(GroupName,_,GroupArtId)[artifact_id(OrgName)] <-
  .print("Waiting for group ", GroupName," to become well-formed");
  .wait(15000); // waits for 15 seconds
  !complete_group_formation(GroupName); // tests the formation status of the group
  .wait({+formationStatus(ok)[artifact_id(GroupArtId)]}). // waits until the belief is added to the belief base

@formation_status_is_ok_plan
+formationStatus(ok)[artifact_id(GroupArtId)] : group(GroupName,_,G)[artifact_id(OrgName)] <-
  .print("Group with name:", GroupName, " is now well-formed");
  addSchemeWhenFormationIsOk(GroupName)[artifact_id(GroupArtId)].

/* 
 * Plan for reacting to the addition of the belief formationStatus(ok)[artifact_id(G)]
 * Triggering event: addition of belief formationStatus(ok)[artifact_id(G)]
 * Context: the agent beliefs that there exists a group G whose formation status is ok
 * Body: the agent adds a scheme to the scheme board artifact of the organization
*/
@complete_group_formation_plan
+!complete_group_formation(GroupName) : formationStatus(nok) & group(GroupName,GroupType,GroupArtId) & org_name(OrgName) & specification(group_specification(GroupName,Roles,_,_)) <-
  for ( .member(Role,Roles) ) {
    !verify_roles_and_agents(Role);
  }
  .wait(15000);
  !complete_group_formation(GroupArtId).

/* 
 * Plan for reacting to the addition of the test-goal ?complete_group_formation(GroupArtId)
 * Triggering event: addition of test-goal ?complete_group_formation(GroupArtId)
 * Context: the agent beliefs that there exists a group G whose formation status is being tested
 * Body: if the belief formationStatus(nok)[artifact_id(G)] is not already in the agents belief base
 * the agent waits until the belief is added in the belief base
*/
@complete_group_formation_plan_fail
+!complete_group_formation(GroupName) : true <-
  true.

/*
  * Plan for reacting to the addition of the goal !verify_roles_and_agents(Role)
  * Triggering event: addition of the goal !verify_roles_and_agents(Role)
  * Context: the agent beliefs that there exists a role Role in the group GroupName
  * Body: the agent verifies if there are enough agents to fulfill the role Role
  */
@verify_roles_and_agents_plan
+!verify_roles_and_agents(role(Role,_,_,MinCard,MaxCard,_,_)) : not has_enough_players_for(Role) & org_name(OrgName) & group_name(GroupName) <-
  .print("Not enough agents for role: ", Role, " found");
  .broadcast(tell, ask_fulfill_role(Role, GroupName, OrgName)).


/* 
 * Plan for reacting to the addition of the test-goal ?verify_roles_and_agents(Role)
 * Triggering event: addition of test-goal ?verify_roles_and_agents(Role)
 * Context: the agent beliefs that there exists a role Role in the group GroupName
 * Body: if the belief formationStatus(nok)[artifact_id(G)] is not already in the agents belief base
 * the agent waits until the belief is added in the belief base
*/
@verify_roles_and_agents_plan_fail
+!verify_roles_and_agents(role(Role,_,_,MinCard,MaxCard,_,_)) : true <-
  true.

/* 
 * Plan for reacting to the addition of the goal !inspect(OrganizationalArtifactId)
 * Triggering event: addition of goal !inspect(OrganizationalArtifactId)
 * Context: true (the plan is always applicable)
 * Body: performs an action that launches a console for observing the organizational artifact 
 * identified by OrganizationalArtifactId
*/
@inspect_org_artifacts_plan
+!inspect(OrganizationalArtifactId) : true <-
  // performs an action that launches a console for observing the organizational artifact
  // the action is offered as an operation by the superclass OrgArt (https://moise.sourceforge.net/doc/api/ora4mas/nopl/OrgArt.html)
  debug(inspector_gui(on))[artifact_id(OrganizationalArtifactId)]. 

/* 
 * Plan for reacting to the addition of the belief play(Ag, Role, GroupId)
 * Triggering event: addition of belief play(Ag, Role, GroupId)
 * Context: true (the plan is always applicable)
 * Body: the agent announces that it observed that agent Ag adopted role Role in the group GroupId.
 * The belief is added when a Group Board artifact (https://moise.sourceforge.net/doc/api/ora4mas/nopl/GroupBoard.html)
 * emmits an observable event play(Ag, Role, GroupId)
*/
@play_plan
+play(Ag, Role, GroupId) : true <-
  .print("Agent ", Ag, " adopted the role ", Role, " in group ", GroupId).

/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }

/* Import behavior of agents that work in MOISE organizations */
{ include("$jacamoJar/templates/common-moise.asl") }

/* Import behavior of agents that reason on MOISE organizations */
{ include("$moiseJar/asl/org-rules.asl") }