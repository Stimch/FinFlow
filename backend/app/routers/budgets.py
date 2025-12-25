"""Budget routes."""
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db, set_user_id_for_audit
from app import crud, schemas
from app.auth import get_current_active_user
from app import models

router = APIRouter(prefix="/api/budgets", tags=["budgets"])


@router.get("", response_model=List[schemas.BudgetResponse])
def get_budgets(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    current_user: models.User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get list of budgets."""
    set_user_id_for_audit(db, current_user.id)
    budgets = crud.get_budgets(db, user_id=current_user.id, skip=skip, limit=limit)
    return budgets


@router.get("/{budget_id}", response_model=schemas.BudgetResponse)
def get_budget(
    budget_id: int,
    current_user: models.User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get a specific budget."""
    set_user_id_for_audit(db, current_user.id)
    budget = crud.get_budget(db, budget_id, current_user.id)
    if not budget:
        raise HTTPException(status_code=404, detail="Budget not found")
    return budget


@router.post("", response_model=schemas.BudgetResponse, status_code=status.HTTP_201_CREATED)
def create_budget(
    budget: schemas.BudgetCreate,
    current_user: models.User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Create a new budget."""
    set_user_id_for_audit(db, current_user.id)
    db_budget = crud.create_budget(db, budget, current_user.id)
    return db_budget


@router.put("/{budget_id}", response_model=schemas.BudgetResponse)
def update_budget(
    budget_id: int,
    budget_update: schemas.BudgetUpdate,
    current_user: models.User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Update a budget."""
    set_user_id_for_audit(db, current_user.id)
    db_budget = crud.update_budget(db, budget_id, current_user.id, budget_update)
    if not db_budget:
        raise HTTPException(status_code=404, detail="Budget not found")
    return db_budget


@router.delete("/{budget_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_budget(
    budget_id: int,
    current_user: models.User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Delete a budget."""
    set_user_id_for_audit(db, current_user.id)
    success = crud.delete_budget(db, budget_id, current_user.id)
    if not success:
        raise HTTPException(status_code=404, detail="Budget not found")


@router.get("/reports/status", response_model=List[schemas.BudgetStatusResponse])
def get_budget_status(
    year: int = Query(...),
    month: int = Query(..., ge=1, le=12),
    current_user: models.User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get budget status report using database function."""
    result = db.execute(
        text("SELECT * FROM get_budget_status_report(:user_id, :year, :month)"),
        {"user_id": current_user.id, "year": year, "month": month}
    )
    return [dict(row) for row in result]





