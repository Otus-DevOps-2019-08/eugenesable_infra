resource "google_compute_target_pool" "loadbalancer" {
  name          = "reddit-loadbalancer"
  instances     = "${google_compute_instance.app.*.self_link}"
  health_checks = ["${google_compute_http_health_check.healthcheck.name}"]
}

resource "google_compute_forwarding_rule" "loadbalancer-firewall" {
  name                  = "reddit-app"
  port_range            = "9292"
  target                = "${google_compute_target_pool.loadbalancer.self_link}"
  load_balancing_scheme = "EXTERNAL"
}

resource "google_compute_http_health_check" "healthcheck" {
  name                = "healthcheck"
  port                = 9292
  request_path       = "/"
  check_interval_sec  = 1
  timeout_sec         = 1
}
