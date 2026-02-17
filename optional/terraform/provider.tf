terraform {
  required_providers {
    local = {
      source = "hashicorp/local"
    }
  }
}

provider "local" {} #If deploying to production(AWS) ,we switch provider
#This is to test locally
