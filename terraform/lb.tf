resource "google_compute_forwarding_rule" "lb-fw" {
  name                  = "reddit-app"
  description           = "Forwarding rule for Reddit apps"
  port_range            = "9292"
  target                = "${google_compute_target_pool.lb.self_link}"
  load_balancing_scheme = "EXTERNAL"
}

resource "google_compute_target_pool" "lb" {
  name          = "reddit-lb"
  description   = "Load balancer for Reddit apps"
  instances     = "${google_compute_instance.app.*.self_link}"
  health_checks = ["${google_compute_http_health_check.default.name}"]
}

resource "google_compute_http_health_check" "default" {
  name                = "reddit-app-hc"
  port                = 9292
  check_interval_sec  = 10
  timeout_sec         = 5
  unhealthy_threshold = 5
}
