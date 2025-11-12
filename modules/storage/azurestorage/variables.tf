variable "resource_group_name"{
    type = string
}
variable "location" {
    type = string
}
variable "storage_account_details"{
    type = map(string)
}
variable "container_names"{
    type = list(string)
}
variable "blobs"{
    type = map(object(
        {
        container_name = string
        blob_location = string
        }
    ))
}