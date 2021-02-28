# Tailhook
Tailhook is a webhook server that injects a sidecar during MutatingWebhook phase a sidecar of your choice to any of the Deployments annotated with a certain label.
![alt text](https://github.com/4lane-legit/tailhook/logo.png)

## Build

1. Build binary

```
# make build
```

2. Build docker image
   
```
# make build-image
```

3. push docker image

```
# make push-image
```

> Note: log into the docker registry before pushing the image.

## Deploy

1. Create namespace `tailhook` in which the webhook server will get deployed:

```
# kubectl create ns tailhook
```

2. Create a signed cert/key pair and store it in a Kubernetes `secret` that will be consumed by sidecar injector deployment:

```
# make create-signed-cert 
```

3. Patch the `MutatingWebhookConfiguration` by set `caBundle` with correct value from Kubernetes cluster:

```
# make patch-ca
```

4. Deploy resources:

```
# helm install tailhook -n tailhook
```
you can use your own namespace and value file and configure as many containers as you want, all of em will get injected as sidecars.

## Test the POC

1. The sidecar inject webhook should be in running state:

```
# kubectl -n tailhook get po
NAME                                                   READY   STATUS    RESTARTS   AGE
tailhook-webhook-deployment-7c8bc5f4c9-28c84   1/1     Running   0          10s
# kubectl -n sidecar-injector get deploy
NAME                                  READY   UP-TO-DATE   AVAILABLE   AGE
tailhook-webhook-deployment   1/1     1            1           50s
```

2. Create new namespace `test` and label it with `sidecar-injector=enabled`:

```
# kubectl create ns injection
# kubectl label namespace injection sidecar-injection=enabled
# kubectl get namespace -l sidecar-injection
NAME                 STATUS   AGE   SIDECAR-INJECTION
default              Active   26m
injection            Active   13s   enabled
kube-public          Active   26m
kube-system          Active   26m
tailhook             Active   17m
```

3. Deploy an app in Kubernetes cluster, take `alpine` app as an example

```
# kubectl run alpine --image=alpine --restart=Never -n injection --overrides='{"apiVersion":"v1","metadata":{"annotations":{"tailhook-webhook.4lane.legit/inject":"yes"}}}' --command -- sleep infinity
```

4. Verify sidecar container is injected:

```
# kubectl get pod
NAME                     READY     STATUS        RESTARTS   AGE
alpine                   2/2       Running       0          1m
# kubectl -n injection get pod alpine -o jsonpath="{.spec.containers[*].name}"

alpine sidecar-nginx
```
