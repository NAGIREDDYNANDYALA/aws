# Declare the data source
data "aws_availability_zones" "available" {
  state = "available"
}
data "aws_caller_identity" "account" {
    
}
