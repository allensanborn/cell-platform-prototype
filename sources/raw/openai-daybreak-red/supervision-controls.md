---
resource: https://cdn.openai.com/pdf/49112a33-7dc9-4fa7-89ea-095a57552ed2/supervised-investigations-with-daybreak-red-a-reference-architecture.pdf
fetched: 2026-11-23
fetch_note: "curl of the 11-page PDF ('Deploying Daybreak Red: A reference architecture for supervised security investigations', OpenAI, dated November 9, 2026), then pdftotext -layout. Excerpts only: the component table rows for the isolated environment and telemetry, the network, review and telemetry controls, the preflight's verify step, and the supervise and end steps. Hyperlink targets are lost in extraction."
---

<!-- pages 4-5: architecture components (two rows) and safety controls -->

```
 Isolated investigation   This is a logical separation of the environment. In this reference architecture,
 environment              we’re describing hosted VMs in an isolated VPC. The specifics of this
                          environment will depend on your infrastructure.
 Network controls         A logical configuration point to control resource access. This can be
                          accomplished with iptables on the agent VM, a firewall, or security groups
                          configured within your infrastructure

 Target                   The non-prod application you will be running your investigation against

 Telemetry                A data store outside the target and agent VM that persists logs which establish
                          what happened and when

Network access controls
The Codex network proxy can narrow where sandboxed commands can connect. For example, the VM may be
allowed to reach three staging apps while the Codex allowlist permits just the one in scope. Beyond the Codex
allowlist, you will want to implement network controls restricting access outside the investigation environment.
As a best practice, limit network connectivity to only required destinations. Check network access separately
for any browsers, connectors, or MCP tools you enable.

Reviewing sensitive actions
When an action needs approval and is eligible for Auto-review, a separate reviewer decides whether it can
proceed. The analyst sets the investigation’s scope and supervises the run. If Codex needs to use a new target
or account, or take an action outside the agreed scope, pause the run and have the analyst confirm
authorization before continuing.

Telemetry and controls
Keep Codex tool activity, target request logs, and application sign-in events in a log store outside the Codex
account’s control.

```

<!-- pages 8-9: verify the preflight, supervise the run, end the investigation -->

```
Verify the results. Check these before starting the investigation.
    ●​ Workspace. The write inside the workspace matches your permission profile. The write outside it is
       blocked.
    ●​ Network. The approved health request succeeds. The request outside the allowlist is blocked.
    ●​ Logs. Find the successful codex.tool_result event for pwd and the approved health request in
       your independent logs.

Describe the investigation
Once the preflight passes, fill in the brackets and send this brief in the remote Codex project. Name any
specific routes or accounts the investigation requires.

  None‎
     On [approved target], investigate [question] using [test identity or anonymous access]. Stay
     within [permitted actions] and exclude [systems or data]. Collect [evidence]. Stop at [end
     time] or sooner if [stop condition].



Supervise the run
Continue. Let routine work proceed within the agreed scope.
Pause. If Codex reaches a different host, encounters real user data, or asks for broader permissions, inspect
what happened before continuing.
Stop. End the run if a required control or its monitoring fails.
Before the first run, verify that you can stop the agent VM or block its access to the target from outside Codex.
Use that control if you lose monitoring, need to stop immediately, or can’t confirm that the run has stopped.




Deploying Daybreak Red​                                                                                             8
End the investigation
    1.​ Send the stop prompt below in the remote chat.
    2.​ Check the agent VM for background jobs and the target logs for further requests. Verify that both have
        stopped.
    3.​ End the remote Codex session from your workstation.
    4.​ Revoke temporary credentials.

```
