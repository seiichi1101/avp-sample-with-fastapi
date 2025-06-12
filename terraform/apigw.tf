resource "aws_apigatewayv2_api" "fastapi_api" {
  name          = "fastapi_api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "fastapi_stage" {
  api_id      = aws_apigatewayv2_api.fastapi_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "fastapi_integration" {
  api_id               = aws_apigatewayv2_api.fastapi_api.id
  integration_type     = "AWS_PROXY"
  integration_method   = "POST"
  integration_uri      = aws_lambda_function.fastapi_lambda_function.invoke_arn
  passthrough_behavior = "WHEN_NO_MATCH"
}

resource "aws_apigatewayv2_route" "fastapi_route" {
  api_id    = aws_apigatewayv2_api.fastapi_api.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.fastapi_integration.id}"
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.fastapi_lambda_function.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.fastapi_api.execution_arn}/*"
}
