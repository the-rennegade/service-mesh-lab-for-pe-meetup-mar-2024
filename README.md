# service-mesh-lab-for-pe-meetup-mar-2024

# Lab Setup

## Pre-Reqs
These steps are assuming you are running a Mac. If you are not, there should be comparable steps available online for your OS.
1. Make sure kubectl is [installed](https://kubernetes.io/docs/tasks/tools/install-kubectl-macos/).
2. Make sure linkerd cli is [installed](https://linkerd.io/2.15/getting-started/#step-1-install-the-cli).
3. Make sure Docker Desktop (personal/free) is [installed](https://docs.docker.com/desktop/install/mac-install/).
4. Make sure kind is [installed](https://kind.sigs.k8s.io/docs/user/quick-start/#installation).

## Cluster Setup, Install Linkerd, and Emoji Vote App
1. Lets create a cluster on our local machine to use for the demo:<br/>
   ```kind create cluster --config kind-cluster-config.yml```
2. Run pre-checks for Linkerd:<br/>
   ```linkerd check --pre```
3. Install the CRDs for Linkerd:<br/>
   ```linkerd install --crds | kubectl apply -f -```
4. Install Linkerd:<br/>
   ```linkerd install | kubectl apply -f -```
5. Run the post install check:<br/>
   ```linkerd check```
6. Install the Linkerd visualization resources:<br/>
   ```linkerd viz install | kubectl apply -f -```
7. Install the emojivoto demo app:<br/>
   ```curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/emojivoto.yml | kubectl apply -f -```

# Demo

## Test Emoji App and Inject It into the Mesh
1. Test the Emojivoto app by going to http://localhost:8080 after you run the port forwarding command below:<br/>
   ```kubectl -n emojivoto port-forward svc/web-svc 8080:80```
2. Let's inject Linkerd into the app:<br/>
   ```kubectl get -n emojivoto deploy -o yaml | linkerd inject - | kubectl apply -f -```
3. Now, let's check the app again by port forwarding. We shouldn't notice any difference:<br/>
   ```kubectl -n emojivoto port-forward svc/web-svc 8080:80```

## Add Dashboard and Metrics to Linkerd
1. View the dashboard:<br/>
   ```linkerd viz dashboard &```
2. Go to web deployment, then look for the "vote donut" api call, then click the microscope next to the call, then expand call and you should see why its erroring. In this demo, there is nothing to do with the error other than to illustrate that you can use the Linkerd dashboard to find errors.

## Restricting Access
1. Apply a server resource in Linkerd to secure the voting service:<br/>
   ```kubectl apply -f server.yaml```
2. Check the statistics for the voting service:<br/>
   ```linkerd viz authz -n emojivoto deploy/voting```
3. See the drop in success for voting grpc because we just restricted traffic without authorizing anything to access the voting service.
4. Now, lets authorize a service to communicate with the voting service:<br/>     
   ```kubectl apply -f server-auth.yaml```
5. See the gradual climb in success for voting grpc service since the calling service is now authorized.
6. If we wanted to, we could also set a default policy to deny all access for anything that doesn't have a server resource and authorization, but we will not do that in this demo.

## Circuit Breaking
1. Lets run the script to setup the circuit breaking demo:<br/> 
   ```./circuit-app.sh```
2. Lets look at statistics for the newly deployed services:<br/>
   ```linkerd viz -n circuit-breaking-demo stat deploy```
3. Notice failure rate and which service is failing its calls.<br/>
4. Lets look at the slow-cooker service that is being called by the "good" and "bad" services:<br/>     
   ```linkerd viz -n circuit-breaking-demo stat deploy/slow-cooker --to svc/bb```
5. Notice failure rate. The "bad" service is dragging down the success rate for "slow-cooker" as well.<br/>
6. Let's add the circuit breaker so that an unhealthy service stops making calls to the "slow-cooker" service:<br/>
   ```kubectl annotate -n circuit-breaking-demo svc/bb balancer.linkerd.io/failure-accrual=consecutive```
7. Let's look at the stats again with the circuit breaker in place:<br/>
   ```linkerd viz -n circuit-breaking-demo stat deploy```<br/>
   ```linkerd viz -n circuit-breaking-demo stat deploy/slow-cooker --to svc/bb```<br/>
8. You should see, gradually, that while "bad" service is still not working correctly, its calls will eventually drop off to the "slow-cooker" service, because of the circuit breaker, which will improve the overall success rate of "slow-cooker".

# References
1. [Troubleshooting](https://linkerd.io/2.15/tasks/debugging-your-service/)
2. [Sample Setup](https://linkerd.io/2.15/getting-started/)
3. [Restricting Access](https://linkerd.io/2.15/tasks/restricting-access/)