resource "aws_iam_role" "fastapi_lambda_model_role" {
  name = "fastapi_lambda_model_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "fastapi_lambda_model_policy_attachment" {
  role       = aws_iam_role.fastapi_lambda_model_role.name
  policy_arn = aws_iam_policy.fastapi_lambda_model_policy.arn
}

resource "aws_iam_policy" "fastapi_lambda_model_policy" {
  name = "fastapi_lambda_model_policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    },
		{
			"Action": [
				"verifiedpermissions:IsAuthorizedWithToken",
				"verifiedpermissions:IsAuthorized"
			],
			"Effect": "Allow",
			"Resource": [
				"arn:aws:verifiedpermissions::${data.aws_caller_identity.current.account_id}:policy-store/${aws_verifiedpermissions_policy_store.policy_store.policy_store_id}"
			]
		}
  ]
}
EOF
}
