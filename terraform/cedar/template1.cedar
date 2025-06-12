permit (
  principal == ?principal,
  action in [FastapiApp::Action::"get /tenants/{tenant_id}/items"],
  resource
);
