job "profit" {
	region = "us-west-2"

	datacenters = ["us-west-2a","us-west-2b","us-west-2c"]

	type = "service"

	priority = 50

	constraint {
		attribute = "${attr.kernel.name}"
		value = "linux"
	}
	update {
		# Stagger updates every 10 seconds
		stagger = "10s"

		# Update a single task at a time
		max_parallel = 1
	}
	group "magenta" {
		count = 1
		restart {
			attempts = 2
			interval = "1m"
			delay = "10s"
			mode = "fail"
		}

		task "profitapp" {
			driver = "docker"
			config {
                image = "arodd/spork-backendsvc:latest"
                force_pull = true
                port_map {
                    http = 8080
                }
            }
			service {
				name = "profitapp"
				tags = ["profit", "${attr.consul.datacenter}", "${NOMAD_GROUP_NAME}", "${node.datacenter}"]
				port = "http"
				check {
				  name = "alive"
				  type = "http"
				  interval = "10s"
				  timeout = "3s"
				  path = "/"
				}
			}
			resources {
				cpu = 500 # 500 MHz
				memory = 128 # 128MB
				network {
					mbits = 1
					port "http" {
                        static = 8080
					}
				}
			}
			logs {
			    max_files = 10
			    max_file_size = 15
			}
                        template {
                          data = <<EOH
KV_FRUIT="{{key "service/profitapp/magenta/fruit"}}"
{{ with secret "aws/creds/s3access" }}
VAULT_AWS_ACCESS="{{ .Data.access_key }}"
VAULT_AWS_SECRET="{{ .Data.secret_key }}"
{{ end }}
EOH
                          destination = "secrets/file.env"
                          env = true
                        }
                        vault {
                          policies = ["vault-admin"]
                        }
			kill_timeout = "30s"
		}

 		task "consul_proxy" {
                        driver = "raw_exec"
                        config {
                                # When running a binary that exists on the host, the path must be absolute/
                                command = "consul"
                                args    = ["connect", "proxy","-service","profitapp_connect","-register","-service-addr","${attr.unique.network.ip-address}:8080","-listen",":8443"]
                        }
                }	

	}
	group "yellow" {
		count = 2
		restart {
			attempts = 2
			interval = "1m"
			delay = "10s"
			mode = "fail"
		}

		task "profitapp" {
			driver = "docker"
			config {
                image = "arodd/spork-backendsvc:latest"
                force_pull = true
                port_map {
                    http = 8080
                }
            }
			service {
				name = "profitapp"
				tags = ["profit", "${attr.consul.datacenter}", "${NOMAD_GROUP_NAME}", "${node.datacenter}"]
				port = "http"
				check {
				  name = "alive"
				  type = "http"
				  interval = "10s"
				  timeout = "3s"
				  path = "/"
				}
			}
			resources {
				cpu = 500 # 500 MHz
				memory = 128 # 128MB
				network {
					mbits = 1
					port "http" {
                        static = 8080
					}
				}
			}
			logs {
			    max_files = 10
			    max_file_size = 15
			}
                        template {
                          data = <<EOH
KV_FRUIT="{{key "service/profitapp/yellow/fruit"}}"
{{ with secret "aws/creds/s3access" }}
VAULT_AWS_ACCESS="{{ .Data.access_key }}"
VAULT_AWS_SECRET="{{ .Data.secret_key }}"
{{ end }}
EOH
                          destination = "secrets/file.env"
                          env = true
                        }
                        vault {
                          policies = ["vault-admin"]
                        }
			kill_timeout = "30s"
		}

		 task "consul_proxy" {
                        driver = "raw_exec"
                        config {
                                # When running a binary that exists on the host, the path must be absolute/
                                command = "consul"
                                args    = ["connect", "proxy","-service","profitapp_connect","-register","-service-addr","${attr.unique.network.ip-address}:8080","-listen",":8443"]
                        }
                }
	}
}
