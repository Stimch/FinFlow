"""Recurring transaction routes."""
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from app.database import get_db, set_user_id_for_audit
from app import crud, schemas
from app.auth import get_current_active_user
from app import models

router = APIRouter(prefix="/api/recurring-transactions", tags=["recurring-transactions"])


@router.get("", response_model=List[schemas.RecurringTransactionResponse])
def get_recurring_transactions(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    current_user: models.User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get list of recurring transactions."""
    set_user_id_for_audit(db, current_user.id)
    recurring = crud.get_recurring_transactions(db, user_id=current_user.id, skip=skip, limit=limit)
    return recurring


@router.get("/{recurring_id}", response_model=schemas.RecurringTransactionResponse)
def get_recurring_transaction(
    recurring_id: int,
    current_user: models.User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get a specific recurring transaction."""
    set_user_id_for_audit(db, current_user.id)
    recurring = crud.get_recurring_transaction(db, recurring_id, current_user.id)
    if not recurring:
        raise HTTPException(status_code=404, detail="Recurring transaction not found")
    return recurring


@router.post("", response_model=schemas.RecurringTransactionResponse, status_code=status.HTTP_201_CREATED)
def create_recurring_transaction(
    recurring: schemas.RecurringTransactionCreate,
    current_user: models.User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Create a new recurring transaction."""
    set_user_id_for_audit(db, current_user.id)
    try:
        db_recurring = crud.create_recurring_transaction(db, recurring, current_user.id)
        return db_recurring
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.put("/{recurring_id}", response_model=schemas.RecurringTransactionResponse)
def update_recurring_transaction(
    recurring_id: int,
    recurring_update: schemas.RecurringTransactionUpdate,
    current_user: models.User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Update a recurring transaction."""
    set_user_id_for_audit(db, current_user.id)
    db_recurring = crud.update_recurring_transaction(db, recurring_id, current_user.id, recurring_update)
    if not db_recurring:
        raise HTTPException(status_code=404, detail="Recurring transaction not found")
    return db_recurring


@router.delete("/{recurring_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_recurring_transaction(
    recurring_id: int,
    current_user: models.User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Delete a recurring transaction."""
    set_user_id_for_audit(db, current_user.id)
    success = crud.delete_recurring_transaction(db, recurring_id, current_user.id)
    if not success:
        raise HTTPException(status_code=404, detail="Recurring transaction not found")





