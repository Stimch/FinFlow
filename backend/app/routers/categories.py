"""Category routes."""
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from app.database import get_db, set_user_id_for_audit
from app import crud, schemas
from app.auth import get_current_active_user
from app import models

router = APIRouter(prefix="/api/categories", tags=["categories"])


@router.get("", response_model=List[schemas.CategoryResponse])
def get_categories(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    current_user: models.User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get list of categories."""
    set_user_id_for_audit(db, current_user.id)
    categories = crud.get_categories(db, user_id=current_user.id, skip=skip, limit=limit)
    return categories


@router.get("/{category_id}", response_model=schemas.CategoryResponse)
def get_category(
    category_id: int,
    current_user: models.User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get a specific category."""
    set_user_id_for_audit(db, current_user.id)
    category = crud.get_category(db, category_id, current_user.id)
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")
    return category


@router.post("", response_model=schemas.CategoryResponse, status_code=status.HTTP_201_CREATED)
def create_category(
    category: schemas.CategoryCreate,
    current_user: models.User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Create a new category."""
    set_user_id_for_audit(db, current_user.id)
    db_category = crud.create_category(db, category, current_user.id)
    return db_category


@router.put("/{category_id}", response_model=schemas.CategoryResponse)
def update_category(
    category_id: int,
    category_update: schemas.CategoryUpdate,
    current_user: models.User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Update a category."""
    set_user_id_for_audit(db, current_user.id)
    db_category = crud.update_category(db, category_id, current_user.id, category_update)
    if not db_category:
        raise HTTPException(status_code=404, detail="Category not found")
    return db_category


@router.delete("/{category_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_category(
    category_id: int,
    current_user: models.User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Delete a category."""
    set_user_id_for_audit(db, current_user.id)
    success = crud.delete_category(db, category_id, current_user.id)
    if not success:
        raise HTTPException(status_code=404, detail="Category not found")





