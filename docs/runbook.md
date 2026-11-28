# Runbook: web app alerts

This covers what to do when an alert for the web app fires in Slack (#alerts).

## WebPodRestarting

A web pod has restarted more than 2 times in 10 minutes.

1. See which pod and how many restarts:
   `kubectl get pods -n web`
2. Read why the last run crashed:
   `kubectl logs POD_NAME -n web --previous`
3. Check the logs in Grafana (Explore, Loki):
   `{namespace="web", pod="POD_NAME"}`
4. Check events for memory kills (OOMKilled) or failed probes:
   `kubectl describe pod POD_NAME -n web`
5. If a recent change caused it, roll back in Git:
   `git revert HEAD` then `git push`

Users are usually not affected while other pods are healthy.

## WebRolloutStuck

A new version has not finished rolling out after 5 minutes.

1. Find the pod that will not start:
   `kubectl get pods -n web`
2. Read the Events at the bottom:
   `kubectl describe pod POD_NAME -n web`
   Common causes are a wrong image tag (ImagePullBackOff) or the app crashing on start.
3. Roll back in Git. Do not fix it in the cluster, because Argo CD will put it back to match Git:
   `git revert HEAD` then `git push`
4. In Argo CD, click Refresh and check the app is Healthy and Synced.

Old pods keep serving users during a stuck rollout, so there is time to fix it properly.

## WebPodsUnavailable

Fewer web pods are ready than expected for 2 minutes.

1. `kubectl get pods -n web` to see which pods are not ready.
2. `kubectl describe pod POD_NAME -n web` and check the Events.
3. Check the nodes are healthy: `kubectl get nodes`
4. Follow the steps for WebPodRestarting or WebRolloutStuck, depending on what you find.

## WebDown (critical)

No web pods are ready. The site is down for users.

1. Confirm: `kubectl get pods -n web` and `kubectl get nodes`
2. If the last deploy caused it, roll back straight away with `git revert HEAD` and `git push`.
3. If nodes are not Ready, check the node group in the AWS console (EKS, Compute).
4. Post updates in #alerts until the site is back.

## Game days run

| Test | What happened | What we learned |
|---|---|---|
| Crashed a pod 3 times | WebPodRestarting fired in Slack, then resolved 10 minutes later. Other 2 pods kept serving traffic. | Running 3 replicas kept users safe. |
| Deployed an image tag that does not exist | New pod stuck in ImagePullBackOff. Old pods kept serving. No alert fired. | Added the WebRolloutStuck alert to close the gap. Rolled back with git revert. |