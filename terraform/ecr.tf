resource "aws_ecr_repository" "fastapi_app" {
  name                 = "fastapi_app"
  image_tag_mutability = "MUTABLE"
}
