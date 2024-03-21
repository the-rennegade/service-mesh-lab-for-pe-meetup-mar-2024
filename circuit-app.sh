cat <<EOF | linkerd inject - | kubectl apply -f -
---
apiVersion: v1
kind: Namespace
metadata:
  name: circuit-breaking-demo
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: good
  namespace: circuit-breaking-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      class: good
  template:
    metadata:
      labels:
        class: good
        app: bb
    spec:
      containers:
      - name: terminus
        image: buoyantio/bb:v0.0.6
        args:
        - terminus
        - "--h1-server-port=8080"
        ports:
        - containerPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bad
  namespace: circuit-breaking-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      class: bad
  template:
    metadata:
      labels:
        class: bad
        app: bb
    spec:
      containers:
      - name: terminus
        image: buoyantio/bb:v0.0.6
        args:
        - terminus
        - "--h1-server-port=8080"
        - "--percent-failure=100"
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: bb
  namespace: circuit-breaking-demo
spec:
  ports:
  - name: http
    port: 8080
    targetPort: 8080
  selector:
    app: bb
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: slow-cooker
  namespace: circuit-breaking-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: slow-cooker
  template:
    metadata:
      labels:
        app: slow-cooker
    spec:
      containers:
      - args:
        - -c
        - |
          sleep 5 # wait for pods to start
          /slow_cooker/slow_cooker --qps 10 http://bb:8080
        command:
        - /bin/sh
        image: buoyantio/slow_cooker:1.3.0
        name: slow-cooker
EOF