# fleet-gitops-01

1. Create a namespace on your Fleet Manager hub cluster named `aks-store-demo`.

1. Authorize the `flux-applier` user on the hub cluster to manage resources in the newly created namespace. Modify `rules` to meet your requirements. In this configuration Flux can manage any resoure type in the `aks-store-demo` namespace.

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: flux-applier
  namespace: aks-store-demo
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: flux-applier
  namespace: aks-store-demo
rules:
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: flux-applier
  namespace: aks-store-demo
subjects:
  - kind: ServiceAccount
    name: flux-applier
    namespace: aks-store-demo
roleRef:
  kind: Role
  name: flux-applier
  apiGroup: rbac.authorization.k8s.io
```

1. Bootstrap your configuration by applying these resources to the `aks-store-demo` namespace on the Fleet Manager hub cluster.

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: git-repo-fleet-config
  namespace: aks-store-demo
spec:
  interval: 1m
  url: https://github.com/sjwaight/fleet-gitops-01
  ref:
    branch: main
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: kustonize-fleet-config
  namespace: aks-store-demo
spec:
  interval: 1m
  sourceRef:
    kind: GitRepository
    name: git-repo-fleet-config
  path: ./aks-store-demo
  prune: true
  ```

The resources contained in the aks-store-demo folder will be syncronized by Flux to the Fleet Manager hub cluster, then distributed to member clusters using Fleet Manager resource placement.