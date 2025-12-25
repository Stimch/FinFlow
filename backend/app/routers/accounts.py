"""Account routes."""
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db, set_user_id_for_audit
from app import crud, schemas
from app.auth import get_current_active_user
from app import models

router = APIRouter(prefix="/api/accounts", tags=["accounts"])


@router.get("", response_model=List[schemas.AccountResponse])
def get_accounts(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    current_user: models.User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get list of accounts."""
    set_user_id_for_audit(db, current_user.id)
    accounts = crud.get_accounts(db, user_id=current_user.id, skip=skip, limit=limit)
    return accounts


@router.get("/{account_id}", response_model=schemas.AccountResponse)
def get_account(
    account_id: int,
    current_user: models.User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get a specific account."""
    set_user_id_for_audit(db, current_user.id)
    account = crud.get_account(db, account_id, current_user.id)
    if not account:
        raise HTTPException(status_code=404, detail="Account not found")
    return account


@router.post("", response_model=schemas.AccountResponse, status_code=status.HTTP_201_CREATED)
def create_account(
    account: schemas.AccountCreate,
    current_user: models.User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Create a new account."""
    set_user_id_for_audit(db, current_user.id)
    db_account = crud.create_account(db, account, current_user.id)
    return db_account


@router.put("/{account_id}", response_model=schemas.AccountResponse)
def update_account(
    account_id: int,
    account_update: schemas.AccountUpdate,
    current_user: models.User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Update an account."""
    set_user_id_for_audit(db, current_user.id)
    db_account = crud.update_account(db, account_id, current_user.id, account_update)
    if not db_account:
        raise HTTPException(status_code=404, detail="Account not found")
    return db_account


@router.delete("/{account_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_account(
    account_id: int,
    current_user: models.User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Delete an account."""
    set_user_id_for_audit(db, current_user.id)
    success = crud.delete_account(db, account_id, current_user.id)
    if not success:
        raise HTTPException(status_code=404, detail="Account not found")


@router.get("/summary/total-balance")
def get_total_balance(
    current_user: models.User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get total balance using database function."""
    result = db.execute(
        text("SELECT get_user_total_balance(:user_id) as total_balance"),
        {"user_id": current_user.id}
    )
    row = result.first()
    return {"total_balance": float(row[0]) if row else 0.0}





