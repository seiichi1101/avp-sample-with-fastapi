resource "aws_cognito_user_pool" "fastapi_auth" {
  name              = "fastapi_auth"
  mfa_configuration = "OFF"
  alias_attributes  = ["email"]
}
