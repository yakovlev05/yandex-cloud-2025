terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
    boundary = {
      source  = "hashicorp/boundary"
      version = "1.2.0"
    }
  }
  required_version = ">= 0.13"
}

# Переменные
variable "folder_id" {
  type        = string
  description = "id директории в облаке. Переменная окружения TF_VAR_folder_id"
}

variable "cloud_id" {
  type        = string
  description = "id облака. Переменная окружения TF_VAR_cloud_id"
}

variable "bucket-images" {
  type        = string
  default     = "yandex-cloud-2025-images"
  description = "Уже созданный бакет"
}

variable "cf_account_id" {
  type        = string
  description = "Id аккаунта Cloudflare"
}

variable "cf_auth_token" {
  type        = string
  description = "Токен от Cloudflare с доступом к Workers AI"
}


## Провайдер
provider "yandex" {
  zone      = "ru-central1-d"
  folder_id = var.folder_id
  cloud_id  = var.cloud_id
}
##


# Настройка IAM
# role DOCKER
resource "yandex_iam_service_account" "docker" {
  name        = "docker"
  description = "service account for web application in docker"
}

resource "yandex_resourcemanager_folder_iam_member" "docker-ydb-editor" {
  folder_id = var.folder_id

  role   = "ydb.editor"
  member = "serviceAccount:${yandex_iam_service_account.docker.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "docker-ymq-reader" {
  folder_id = var.folder_id

  role   = "ymq.reader"
  member = "serviceAccount:${yandex_iam_service_account.docker.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "docker-ymq-writer" {
  folder_id = var.folder_id

  role   = "ymq.writer"
  member = "serviceAccount:${yandex_iam_service_account.docker.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "docker-container" {
  folder_id = var.folder_id

  role   = "container-registry.images.puller"
  member = "serviceAccount:${yandex_iam_service_account.docker.id}"
}

# role DOCKER-GROUP
resource "yandex_iam_service_account" "docker-group" {
  name        = "docker-group"
  description = "service account for web application in docker"
}

resource "yandex_resourcemanager_folder_iam_member" "docker-group-role" {
  folder_id = var.folder_id

  role   = "editor"
  member = "serviceAccount:${yandex_iam_service_account.docker-group.id}"
}

# role FUNC
resource "yandex_iam_service_account" "func" {
  name        = "func"
  description = "service account for cloud function"
}

resource "yandex_resourcemanager_folder_iam_member" "func-role-ymq-reader" {
  folder_id = var.folder_id

  role   = "ymq.reader"
  member = "serviceAccount:${yandex_iam_service_account.func.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "func-role-ymq-writer" {
  folder_id = var.folder_id

  role   = "ymq.writer"
  member = "serviceAccount:${yandex_iam_service_account.func.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "func-role-s3" {
  folder_id = var.folder_id

  role   = "storage.uploader"
  member = "serviceAccount:${yandex_iam_service_account.func.id}"
}

# role TRIGGER
resource "yandex_iam_service_account" "trigger" {
  name        = "trigger"
  description = "service account for trigger - invoke func & read queue"
}

resource "yandex_resourcemanager_folder_iam_member" "trigger-ymq-admin" {
  folder_id = var.folder_id

  role   = "ymq.admin"
  member = "serviceAccount:${yandex_iam_service_account.trigger.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "trigger-invoker" {
  folder_id = var.folder_id

  role   = "functions.functionInvoker"
  member = "serviceAccount:${yandex_iam_service_account.trigger.id}"
}


# Настройка сетей
data "yandex_vpc_network" "common" {
  name = "common"
}

data "yandex_vpc_subnet" "common-a" {
  name = "common-a"
}

data "yandex_vpc_subnet" "common-b" {
  name = "common-b"
}

data "yandex_vpc_subnet" "common-d" {
  name = "common-d"
}

# Настройка ключей доступа
# role FUNC
resource "yandex_iam_service_account_static_access_key" "func-static-key" {
  service_account_id = yandex_iam_service_account.func.id
  description        = "key for serverless function: s3, ymq"
}

# role DOCKER
resource "yandex_iam_service_account_static_access_key" "docker-static-key" {
  service_account_id = yandex_iam_service_account.docker.id
  description        = "key for serverless function: s3, ymq"
}

# for admin
data "yandex_iam_service_account" "terraform" {
  name = "terraform"
}

resource "yandex_iam_service_account_static_access_key" "admin-static-key" {
  service_account_id = data.yandex_iam_service_account.terraform.id
  description        = "key to create queue resource and sending messages"
}


# Настройка YDB
resource "yandex_ydb_database_serverless" "ydb" {
  name        = "ydb"
  description = "database for backend"

  serverless_database {
    storage_size_limit = 50
  }
}


# Настройка очереди
resource "yandex_message_queue" "generate-image" {
  depends_on = [yandex_iam_service_account_static_access_key.admin-static-key]

  name                      = "generate-image"
  message_retention_seconds = 86400
  receive_wait_time_seconds = 20
  access_key                = yandex_iam_service_account_static_access_key.admin-static-key.access_key
  secret_key                = yandex_iam_service_account_static_access_key.admin-static-key.secret_key

}

resource "yandex_message_queue" "image-done" {
  depends_on = [yandex_iam_service_account_static_access_key.admin-static-key]

  name                      = "image-done"
  message_retention_seconds = 86400
  receive_wait_time_seconds = 20
  access_key                = yandex_iam_service_account_static_access_key.admin-static-key.access_key
  secret_key                = yandex_iam_service_account_static_access_key.admin-static-key.secret_key
}


# Настройка VM docker
data "yandex_container_registry" "yandex-cloud-2025" {
  name = "yandex-cloud-2025"
}

resource "yandex_compute_instance_group" "app" {
  depends_on = [
    yandex_resourcemanager_folder_iam_member.docker-ydb-editor,
    yandex_resourcemanager_folder_iam_member.docker-ymq-reader,
    yandex_resourcemanager_folder_iam_member.docker-ymq-writer,
    yandex_resourcemanager_folder_iam_member.docker-container,

    yandex_resourcemanager_folder_iam_member.docker-group-role,
    yandex_ydb_database_serverless.ydb,
    yandex_message_queue.generate-image,
    yandex_iam_service_account_static_access_key.docker-static-key,
    yandex_message_queue.image-done
  ]

  name               = "app"
  description        = "group for backend application"
  service_account_id = yandex_iam_service_account.docker-group.id

  allocation_policy {
    zones = ["ru-central1-a", "ru-central1-b", "ru-central1-d"]
  }

  instance_template {
    boot_disk {
      initialize_params {
        image_id = "fd8gm9cegc39t4nsm8cv"
        type     = "network-hdd"
        size     = 15
      }
    }

    platform_id = "standard-v3"
    resources {
      cores         = 2
      core_fraction = 50
      memory        = 1
    }

    scheduling_policy {
      preemptible = true
    }

    network_interface {
      network_id = data.yandex_vpc_network.common.id
      subnet_ids = [
        data.yandex_vpc_subnet.common-a.id,
        data.yandex_vpc_subnet.common-b.id,
        data.yandex_vpc_subnet.common-d.id
      ]
      ipv4 = true
      nat  = true # УДАЛИТЬ !!!!!!!
    }

    service_account_id = yandex_iam_service_account.docker.id


    metadata = {
      # УДАЛИТЬ
      docker-container-declaration = <<-EOT
        spec:
          containers:
          - image: cr.yandex/crpsqh8ppnu6aup70co3/yandex-cloud-2025:main
            env:
            - name: YDB_URL
              value: ${yandex_ydb_database_serverless.ydb.ydb_full_endpoint}&useMetadata=true
            - name: IS_PROD
              value: true
            - name: AWS_ACCESS_KEY_ID
              value: ${yandex_iam_service_account_static_access_key.docker-static-key.access_key}
            - name: AWS_SECRET_ACCESS_KEY
              value: ${yandex_iam_service_account_static_access_key.docker-static-key.secret_key}
            - name: QUEUE_GENERATE_IMAGE
              value: ${yandex_message_queue.generate-image.name}
            - name: QUEUE_DONE_IMAGE
              value: ${yandex_message_queue.image-done.name}
            - name: S3_BUCKET
              value: ${var.bucket-images}
          restartPolicy: Always
      EOT

      ssh-keys  = "yakovlev:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAbrWizNVeMOhrHoIPvjOr/I5eqcz/iFOpiwOSV6xpea alexe@alex"
      user-data = <<-EOT
        #cloud-config
        datasource:
         Ec2:
          strict_id: false
        ssh_pwauth: no
        users:
        - name: yakovlev
          sudo: ALL=(ALL) NOPASSWD:ALL
          shell: /bin/bash
          ssh_authorized_keys:
          - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAbrWizNVeMOhrHoIPvjOr/I5eqcz/iFOpiwOSV6xpea alexe@alex
      EOT
    }
  }

  deploy_policy {
    max_expansion    = 0
    max_unavailable  = 1
    max_creating     = 2
    max_deleting     = 2
    startup_duration = 60
  }

  scale_policy {
    fixed_scale {
      size = 2
    }
  }

  load_balancer {
    max_opening_traffic_duration = 60
    target_group_description     = "group for list vm with docker"
    target_group_name            = "docker-app-group"
  }

  health_check {
    http_options {
      path = "/"
      port = 8080
    }
    interval            = 2
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 1
  }
}


# Настройка nlb
resource "yandex_lb_network_load_balancer" "app-nlb" {
  depends_on = [yandex_compute_instance_group.app]

  name = "app-network-load-balancer"

  listener {
    name        = "web-listener"
    port        = 80
    target_port = 8080
  }

  attached_target_group {
    target_group_id = yandex_compute_instance_group.app.load_balancer[0].target_group_id

    healthcheck {
      name = "http"
      http_options {
        port = 8080
        path = "/"
      }
    }
  }
}

# Настройка serverless function + trigger
resource "yandex_function" "generate-image" {
  depends_on = [
    yandex_resourcemanager_folder_iam_member.func-role-ymq-reader,
    yandex_resourcemanager_folder_iam_member.func-role-ymq-writer,
    yandex_resourcemanager_folder_iam_member.func-role-s3
  ]

  name               = "generate-image"
  description        = "func for generate image and save in s3"
  runtime            = "python312"
  entrypoint         = "main.handler"
  execution_timeout  = "10"
  memory             = "128"
  service_account_id = yandex_iam_service_account.func.id

  content {
    zip_filename = "func.zip"
  }

  connectivity {
    network_id = data.yandex_vpc_network.common.id
  }

  environment = {
    CF_ACCOUNT_ID            = var.cf_account_id,
    CF_AUTH_TOKEN            = var.cf_auth_token,
    AWS_ACCESS_KEY           = yandex_iam_service_account_static_access_key.func-static-key.access_key,
    AWS_SECRET_KEY           = yandex_iam_service_account_static_access_key.func-static-key.secret_key,
    S3_BUCKET_NAME           = var.bucket-images
    QUEUE_NAME_DONE_GENERATE = yandex_message_queue.image-done.name
  }

  mounts {
    name = "s3_for_images"
    mode = "rw"

    object_storage {
      bucket = var.bucket-images
    }
  }

  user_hash = "v1" # Change this, when modify function
}

resource "yandex_function_trigger" "generate-image" {
  depends_on = [
    yandex_resourcemanager_folder_iam_member.trigger-invoker,
    yandex_resourcemanager_folder_iam_member.trigger-ymq-admin,
    yandex_message_queue.generate-image,
    yandex_function.generate-image,
  ]

  name        = "generate-image-new-message"
  description = "new message for generate image"

  message_queue {
    batch_cutoff       = "0"
    queue_id           = yandex_message_queue.generate-image.arn
    service_account_id = yandex_iam_service_account.trigger.id
    batch_size         = "1"
  }

  function {
    id                 = yandex_function.generate-image.id
    service_account_id = yandex_iam_service_account.trigger.id
    tag                = "$latest"
  }
}
