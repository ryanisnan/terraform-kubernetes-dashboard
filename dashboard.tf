locals {
    k8s_db = "kubernetes-dashboard"
}

resource "kubernetes_namespace" "dashboard" {
    metadata {
        name = local.k8s_db
    }
}

resource "kubernetes_service_account" "dashboard" {
    metadata {
        name = local.k8s_db
        labels = {
            k8s-app = local.k8s_db
        }
        namespace = local.k8s_db
    }

    automount_service_account_token = true
}

resource "kubernetes_service" "dashboard" {
    metadata {
        name = local.k8s_db
        labels = {
            k8s-app = local.k8s_db
        }
        namespace = local.k8s_db
    }
    spec {
        port {
            port = 443
            target_port = 8443
        }
        selector = {
            k8s-app = local.k8s_db
        }
    }
}

resource "kubernetes_secret" "dashboard_cert" {
    metadata {
        name = "${local.k8s_db}-certs"
        labels = {
            k8s-app = local.k8s_db
        }
        namespace = local.k8s_db
    }
    type = "Opaque"
}

resource "kubernetes_secret" "dashboard_csrf" {
    metadata {
        name = "${local.k8s_db}-csrf"
        labels = {
            k8s-app = local.k8s_db
        }
        namespace = local.k8s_db
    }
    type = "Opaque"
    data = {
        csrf = ""
    }
}

resource "kubernetes_secret" "dashboard_key_holder" {
    metadata {
        name = "${local.k8s_db}-key-holder"
        labels = {
            k8s-app = local.k8s_db
        }
        namespace = local.k8s_db
    }
    type = "Opaque"
}

resource "kubernetes_config_map" "dashboard" {
    metadata {
        name = "${local.k8s_db}-settings"
        labels = {
            k8s-app = local.k8s_db
        }
        namespace = local.k8s_db
    }
}

resource "kubernetes_role" "dashboard" {
    metadata {
        name = local.k8s_db
        labels = {
            k8s-app = local.k8s_db
        }
        namespace = local.k8s_db
    }

    rule {
        api_groups = [""]
        resources = ["secrets"]
        resource_names = ["${local.k8s_db}-key-holder", "${local.k8s_db}-certs", "${local.k8s_db}-csrf"]
        verbs = ["get", "update", "delete"]
    }

    rule {
        api_groups = [""]
        resources = ["configmaps"]
        resource_names = ["${local.k8s_db}-settings"]
        verbs = ["get", "update"]
    }

    rule {
        api_groups = [""]
        resources = ["services"]
        resource_names = ["heapster", "dashboard-metrics-scraper"]
        verbs = ["proxy"]
    }

    rule {
        api_groups = [""]
        resources = ["services/proxy"]
        resource_names = ["heapster", "http:heapster:", "https:heapster:", "dashboard-metrics-scraper", "http:dashboard-metrics-scraper"]
        verbs = ["get"]
    }
}

resource "kubernetes_cluster_role" "dashboard" {
    metadata {
        name = local.k8s_db
        labels = {
            k8s-app = local.k8s_db
        }
    }
    
    rule {
        api_groups = ["metrics.k8s.io"]
        resources = ["pods", "nodes"]
        verbs = ["get", "list", "watch"]
    }
}

resource "kubernetes_role_binding" "dashboard" {
    metadata {
        name = local.k8s_db
        labels = {
            k8s-app = local.k8s_db
        }
        namespace = local.k8s_db
    }

    role_ref {
        api_group = "rbac.authorization.k8s.io"
        kind = "Role"
        name = local.k8s_db
    }
    subject {
        kind = "ServiceAccount"
        name = local.k8s_db
        namespace = local.k8s_db
    }
}

resource "kubernetes_cluster_role_binding" "dashboard" {
    metadata {
        name = local.k8s_db
    }

    role_ref {
        api_group = "rbac.authorization.k8s.io"
        kind = "ClusterRole"
        name = local.k8s_db
    }
    subject {
        kind = "ServiceAccount"
        name = local.k8s_db
        namespace = local.k8s_db
    }
}

resource "kubernetes_deployment" "dashboard" {
    metadata {
        name = local.k8s_db
        labels = {
            k8s-app = local.k8s_db
        }
        namespace = local.k8s_db
    }

    spec {
        replicas = 1
        revision_history_limit = 10

        selector {
            match_labels = {
                k8s-app = local.k8s_db
            }
        }

        template {
            metadata {
                labels = {
                    k8s-app = local.k8s_db
                }
            }

            spec {
                container {
                    name = local.k8s_db
                    image = "kubernetesui/dashboard:v2.0.0"
                    image_pull_policy = "Always"
                    port {
                        container_port = 8443
                        protocol = "TCP"
                    }

                    args = ["--auto-generate-certificates", "--namespace=${local.k8s_db}"]

                    volume_mount {
                        name = "${local.k8s_db}-certs"
                        mount_path = "/certs"
                    }

                    volume_mount {
                        name = "tmp-volume"
                        mount_path = "/tmp"
                    }

                    liveness_probe {
                        http_get {
                            scheme = "HTTPS"
                            path = "/"
                            port = 8443
                        }
                        initial_delay_seconds = 30
                        timeout_seconds = 30
                    }

                    security_context {
                        allow_privilege_escalation = false
                        read_only_root_filesystem = true
                        run_as_user = 1001
                        run_as_group = 2001
                    }
                }

                volume {
                    name = "${local.k8s_db}-certs"
                    secret {
                        secret_name = "${local.k8s_db}-certs"
                    }
                }

                volume {
                    name = "tmp-volume"
                    empty_dir {}
                }

                service_account_name = local.k8s_db
                automount_service_account_token = true

                toleration {
                    key = "node-role.kubernetes.io/master"
                    effect = "NoSchedule"
                }
            }
        }
    }
}

resource "kubernetes_service" "dashboard_scraper" {
    metadata {
        name = "dashboard-metrics-scraper"
        labels = {
            k8s-app = "dashboard-metrics-scraper"
        }
        namespace = local.k8s_db
    }
    spec {
        port {
            port = 8000
            target_port = 8000
        }
        selector = {
            k8s-app = "dashboard-metrics-scraper"
        }
    }
}

resource "kubernetes_deployment" "dashboard_scraper" {
    metadata {
        name = "dashboard-metrics-scraper"
        labels = {
            k8s-app = "dashboard-metrics-scraper"
        }
        namespace = local.k8s_db
    }

    spec {
        replicas = 1
        revision_history_limit = 10

        selector {
            match_labels = {
                k8s-app = "dashboard-metrics-scraper"
            }
        }

        template {
            metadata {
                labels = {
                    k8s-app = "dashboard-metrics-scraper"
                }
                annotations = {
                    "seccomp.security.alpha.kubernetes.io/pod" = "runtime/default"
                }
            }

            spec {
                container {
                    name = "dashboard-metrics-scraper"
                    image = "kubernetesui/metrics-scraper:v1.0.4"
                    port {
                        container_port = 8000
                        protocol = "TCP"
                    }

                    volume_mount {
                        name = "tmp-volume"
                        mount_path = "/tmp"
                    }

                    liveness_probe {
                        http_get {
                            scheme = "HTTP"
                            path = "/"
                            port = 8000
                        }
                        initial_delay_seconds = 30
                        timeout_seconds = 30
                    }

                    security_context {
                        allow_privilege_escalation = false
                        read_only_root_filesystem = true
                        run_as_user = 1001
                        run_as_group = 2001
                    }
                }

                volume {
                    name = "tmp-volume"
                    empty_dir {}
                }

                service_account_name = local.k8s_db
                automount_service_account_token = true

                toleration {
                    key = "node-role.kubernetes.io/master"
                    effect = "NoSchedule"
                }
            }
        }
    }
}
