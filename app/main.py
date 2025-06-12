from typing import Dict, List
from mangum import Mangum
from fastapi import FastAPI, Depends, HTTPException, status
from pydantic import BaseModel
import uvicorn
from app.auth import Client, Principal, User, get_principal_by_oauth2

app = FastAPI()


class Item(BaseModel):
    id: int
    tenant_id: str


# in-memory storage
storage: List[Item] = [
    {
        "id": 1,
        "tenant_id": "classmethod",
    },
    {
        "id": 2,
        "tenant_id": "classmethod",
    },
    {
        "id": 3,
        "tenant_id": "classmethod",
    },
    {
        "id": 4,
        "tenant_id": "annotation",
    },
    {
        "id": 5,
        "tenant_id": "annotation",
    },
    {
        "id": 6,
        "tenant_id": "annotation",
    },
]


@app.get("/")
def read_root():
    return {"Hello": "World"}


@app.get("/items")
def list_items(
    principal: Principal = Depends(get_principal_by_oauth2),

) -> List[Item]:
    if isinstance(principal, Client):
        return storage
    elif isinstance(principal, User):
        return [item for item in storage if item.get("tenant_id") in principal.tenants]
    else:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Invalid principal type"
        )


@app.get("/tenants/{tenant_id}/items")
def list_tenant_items(
    tenant_id: str,
    principal: Principal = Depends(get_principal_by_oauth2)
) -> List[Item]:
    return [item for item in storage if item.get("tenant_id") == tenant_id]


@app.post("/tenants/{tenant_id}/items")
def create_tennat_item(
    tenant_id: str,
    principal: Principal = Depends(get_principal_by_oauth2)
) -> Item:
    item_data = {"id": len(storage)+1, "tenant_id": tenant_id}
    storage.append(item_data)
    return item_data


handler = Mangum(app)

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
