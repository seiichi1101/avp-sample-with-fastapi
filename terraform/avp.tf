resource "aws_verifiedpermissions_policy_store" "policy_store" {
  validation_settings {
    mode = "STRICT"
  }
}

resource "aws_verifiedpermissions_schema" "schema" {
  policy_store_id = aws_verifiedpermissions_policy_store.policy_store.policy_store_id

  definition {
    value = file("cedar/cedarschema.json")
  }
}

resource "aws_verifiedpermissions_policy" "policy1" {
  policy_store_id = aws_verifiedpermissions_policy_store.policy_store.id

  definition {
    static {
      statement   = file("cedar/policy1.cedar")
      description = "For ALL"
    }
  }
}

resource "aws_verifiedpermissions_policy" "policy2" {
  policy_store_id = aws_verifiedpermissions_policy_store.policy_store.id

  definition {
    static {
      statement   = file("cedar/policy2.cedar")
      description = "For Classmethod"
    }
  }
}

resource "aws_verifiedpermissions_policy" "policy3" {
  policy_store_id = aws_verifiedpermissions_policy_store.policy_store.id

  definition {
    static {
      statement   = file("cedar/policy3.cedar")
      description = "For Annotation"
    }
  }
}

resource "aws_verifiedpermissions_policy" "policy_4" {
  policy_store_id = aws_verifiedpermissions_policy_store.policy_store.id

  definition {
    template_linked {
      policy_template_id = aws_verifiedpermissions_policy_template.template1.policy_template_id
      principal {
        entity_type = "FastapiApp::Client"
        entity_id   = "6tpsbt0o9hbjrso9at1m59g74j"
      }
    }
  }
  depends_on = [aws_verifiedpermissions_policy_template.template1]
}

resource "aws_verifiedpermissions_policy_template" "template1" {
  policy_store_id = aws_verifiedpermissions_policy_store.policy_store.id
  statement       = file("cedar/template1.cedar")
  description     = "Read-only policy template"
}



resource "aws_verifiedpermissions_identity_source" "source" {
  policy_store_id = aws_verifiedpermissions_policy_store.policy_store.id
  configuration {
    cognito_user_pool_configuration {
      user_pool_arn = aws_cognito_user_pool.fastapi_auth.arn
      group_configuration {
        group_entity_type = "FastapiApp::Tenant"
      }
    }
  }
  principal_entity_type = "FastapiApp::User"
}
