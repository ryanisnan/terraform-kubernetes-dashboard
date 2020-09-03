# terraform-kubernetes-dashboard
The Kubernetes Dashboard in Terraform style

This repo contains TF code (0.13 compatible) that provisions the Kubernetes Dashboard [https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/).

![https://d33wubrfki0l68.cloudfront.net/349824f68836152722dab89465835e604719caea/6e0b7/images/docs/ui-dashboard.png](https://d33wubrfki0l68.cloudfront.net/349824f68836152722dab89465835e604719caea/6e0b7/images/docs/ui-dashboard.png)

The version of the dashboard that this provisions is 2.0.0, and the source yaml is here: [https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml](https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml).

This should be made into a module.
