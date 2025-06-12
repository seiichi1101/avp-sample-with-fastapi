resource "aws_lambda_function" "fastapi_lambda_function" {
  function_name = "fastapi_lambda"

  role = aws_iam_role.fastapi_lambda_model_role.arn

  image_uri    = "${aws_ecr_repository.fastapi_app.repository_url}:latest"
  package_type = "Image"

  memory_size = 128
}
