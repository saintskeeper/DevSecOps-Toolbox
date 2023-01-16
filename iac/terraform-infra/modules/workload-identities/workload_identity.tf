resource "kubernetes_service_account" "preexisting" {
  metadata {
    name      = "core-services-sa"
    namespace = "core-services"
  }
}

module "my-app-workload-identity" {
  source              = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  name                = kubernetes_service_account.preexisting.metadata[0].name
  namespace           = kubernetes_service_account.preexisting.metadata[0].namespace
  project_id          = var.project_id
  roles               = ["roles/storage.admin", "roles/compute.admin"]
  use_existing_k8s_sa = true
}