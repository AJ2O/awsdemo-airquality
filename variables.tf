variable "region" {
  type    = string
  default = "us-east-1"
}
variable "tags" {
  type = map(any)
  default = {
    "Project" : "AWS Demos",
    "Demo" : "Air Quality Analysis"
  }
}
