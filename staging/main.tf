# Create confluent provider

terraform{
    required_providers {
        confluent = {
            source = "confluentinc/confluent"
            version = "1.47.0"
        }
    }
}

# configure the terraform backend
terraform{
    backend "s3"{
        bucket = "platform-engineering-terraform-state"
        key = "terraform/all-state/data-streaming-platform.tfstate"
        region = "us-east-1"
        encrypt = true
    }
}

# We use a dedicated service account, called 'platform-manager', per environment

resource "confluent_service_account" "platform-manager" {
  display_name = "platform-manager-${confluent_environment.env.display_name}"
  description  = "Service account to manage the platform"
}

# The 'platform-manager' account is a cloud cluster admin.
resource "confluent_role_binding" "platform-manager-kafka-cluster-admin" {
  principal   = "User:${confluent_service_account.platform-manager.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.standard.rbac_crn
}

resource "confluent_api_key" "platform-manager-kafka-api-key" {
  display_name = "platform-manager-kafka-api-key"
  description  = "Kafka API Key that is owned by 'platform-manager' service account"
  owner {
    id          = confluent_service_account.platform-manager.id
    api_version = confluent_service_account.platform-manager.api_version
    kind        = confluent_service_account.platform-manager.kind
  }
anaged_resource {
    id          = confluent_kafka_cluster.standard.id
    api_version = confluent_kafka_cluster.standard.api_version
    kind        = confluent_kafka_cluster.standard.kind

    environment {
      id = confluent_environment.env.id
    }
  }

depends_on = [
    confluent_role_binding.platform-manager-kafka-cluster-admin
  ]
}