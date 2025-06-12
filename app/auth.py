import os
from typing import List, Literal, Optional, Protocol, Tuple, Union
from fastapi import Depends, HTTPException, Request, status
from fastapi.security import OAuth2, OAuth2AuthorizationCodeBearer
from fastapi.security.oauth2 import OAuthFlowsModel
from fastapi.security.utils import get_authorization_scheme_param
from pydantic import BaseModel
from starlette.status import HTTP_401_UNAUTHORIZED
import jwt
import logging
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

POLICY_STORE_ID = os.environ.get("POLICY_STORE_ID")
SWAGGER_AUTHORIZATION_URL = os.environ.get("SWAGGER_AUTHORIZATION_URL")
SWAGGER_TOKEN_URL = os.environ.get("SWAGGER_TOKEN_URL")
ISSUER_URL = os.environ.get("ISSUER_URL")

avp_client = boto3.client('verifiedpermissions')


class Principal(Protocol):
    kind: Literal["user", "client"]


class User(BaseModel):
    sub: str
    tenants: List[str]
    kind: Literal["user"] = "user"


class Client(BaseModel):
    id: str
    kind: Literal["client"] = "client"


class Oauth2ClientCredentials(OAuth2):
    def __init__(
        self,
        tokenUrl: str,
        scheme_name: str = None,
        scopes: dict = None,
        auto_error: bool = True,
    ):
        if not scopes:
            scopes = {}
        flows = OAuthFlowsModel(
            clientCredentials={"tokenUrl": tokenUrl, "scopes": scopes}
        )
        super().__init__(flows=flows, scheme_name=scheme_name, auto_error=auto_error)

    async def __call__(self, request: Request) -> Optional[str]:
        authorization: str = request.headers.get("Authorization")
        scheme, param = get_authorization_scheme_param(authorization)
        if not authorization or scheme.lower() != "bearer":
            if self.auto_error:
                raise HTTPException(
                    status_code=HTTP_401_UNAUTHORIZED,
                    detail="Not authenticated",
                    headers={"WWW-Authenticate": "Bearer"},
                )
            else:
                return None
        return param


oauth2_code = OAuth2AuthorizationCodeBearer(
    authorizationUrl=SWAGGER_AUTHORIZATION_URL,
    tokenUrl=SWAGGER_TOKEN_URL,
)
oauth2_client = Oauth2ClientCredentials(
    tokenUrl=SWAGGER_TOKEN_URL,
)


def get_principal_by_oauth2(
    request: Request,
    token_code: str = Depends(oauth2_code),
    token_client: str = Depends(oauth2_client),
) -> User | Client:
    try:
        token = token_code or token_client

        # avp authorization with token verification
        # avp_result = avp_client.is_authorized_with_token(
        #     policyStoreId=POLICY_STORE_ID,
        #     accessToken=token,
        #     action={
        #         "actionType": "FastapiApp::Action",
        #         "actionId": action_id,
        #     },
        #     resource={
        #         "entityType": "FastapiApp::Application",
        #         "entityId": "FastapiApp"
        #     }
        # )

        # separate token verification and acl authorization
        jwks_client = jwt.PyJWKClient(
            f"{ISSUER_URL}/.well-known/jwks.json")
        signing_key = jwks_client.get_signing_key_from_jwt(token)
        payload = jwt.decode(
            token,
            signing_key.key,
            algorithms=["RS256"],
            issuer=ISSUER_URL,
        )

        action_id = f"{request.method.lower()} {request.scope["route"].path}"
        path_tenant_id = request.path_params.get("tenant_id")
        is_user_access = payload.get("username")

        if is_user_access:
            avp_input = {
                "policyStoreId": POLICY_STORE_ID,
                "principal": {
                    "entityType": "FastapiApp::User",
                    "entityId": payload.get("sub"),
                },
                "action": {
                    "actionType": "FastapiApp::Action",
                    "actionId": action_id
                },
                "resource": {
                    "entityType": "FastapiApp::Application",
                    "entityId": "Any"
                },
                "entities": {
                    "entityList": [
                        {
                            "identifier": {
                                "entityType": "FastapiApp::User",
                                "entityId": payload.get("sub")
                            },
                            "parents": list(map(
                                lambda tenant_id: {
                                    "entityType": "FastapiApp::Tenant",
                                    "entityId": tenant_id
                                },
                                payload.get("cognito:groups", [])
                            ))
                        },
                        {
                            "identifier": {
                                "entityType": "FastapiApp::Application",
                                "entityId": "Any"
                            },
                            "parents": [
                                {
                                    "entityType": "FastapiApp::Tenant",
                                    "entityId": path_tenant_id
                                }] if path_tenant_id else []
                        }
                    ]
                }
            }
            logger.info("AVP input: %s", avp_input)
            avp_result = avp_client.is_authorized(**avp_input)
            logger.info("AVP result: %s", avp_result)
            if avp_result.get("decision") != "ALLOW":
                logger.error("User is not authorized to access %s on %s",
                             action_id, path_tenant_id)
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Not authorized",
                    headers={"WWW-Authenticate": "Bearer"}
                )
            return User(
                sub=payload.get("sub"),
                tenants=payload.get("cognito:groups", [])
            )
        else:
            avp_input = {
                "policyStoreId": POLICY_STORE_ID,
                "principal": {
                    "entityType": "FastapiApp::Client",
                    "entityId": payload.get("client_id"),
                },
                "action": {
                    "actionType": "FastapiApp::Action",
                    "actionId": action_id
                },
                "resource": {
                    "entityType": "FastapiApp::Application",
                    "entityId": "Any"
                }
            }
            logger.info("AVP input: %s", avp_input)
            avp_result = avp_client.is_authorized(**avp_input)
            logger.info("AVP result: %s", avp_result)
            if avp_result.get("decision") != "ALLOW":
                logger.error("User is not authorized to access %s on %s",
                             action_id, path_tenant_id)
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Not authorized",
                    headers={"WWW-Authenticate": "Bearer"}
                )
            return Client(
                id=payload.get("client_id")
            )
    except jwt.PyJWTError as e:
        logger.error("JWT decode error: %s", e)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"}
        ) from e
