variable rds_credentials {
  type    = object({
    username = string
    password = string
    dbname = string
  })

  default = {
    username = "Insert-Username"
    password = "Insert-DB-pass"
    dbname = "Insert-DB-name"
  }
  
  description = "Master DB username, password and dbname for RDS"
}

variable "ssh_key" {
  type = object({
    keyname = string
  })
  
  default = {
    keyname = "Insert-SSH-key-name"
  }
}

