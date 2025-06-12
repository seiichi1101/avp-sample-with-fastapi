permit (
  principal in FastapiApp::Tenant::"classmethod",
  action in
    [FastapiApp::Action::"get /tenants/{tenant_id}/items",
     FastapiApp::Action::"post /tenants/{tenant_id}/items"],
  resource
)
when
{
  principal in FastapiApp::Tenant::"classmethod" &&
  resource in FastapiApp::Tenant::"classmethod"
};
