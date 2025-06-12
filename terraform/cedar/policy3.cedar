permit (
  principal in FastapiApp::Tenant::"annotation",
  action in
    [FastapiApp::Action::"get /tenants/{tenant_id}/items",
     FastapiApp::Action::"post /tenants/{tenant_id}/items"],
  resource
)
when
{
  principal in FastapiApp::Tenant::"annotation" &&
  resource in FastapiApp::Tenant::"annotation"
};
