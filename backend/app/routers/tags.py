"""Tag routes."""
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from app.database import get_db, set_user_id_for_audit
from app import crud, schemas
from app.auth import get_current_active_user
from app import models

router = APIRouter(prefix="/api/tags", tags=["tags"])


@router.get("", response_model=List[schemas.TagResponse])
def get_tags(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    current_user: models.User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get list of tags."""
    set_user_id_for_audit(db, current_user.id)
    tags = crud.get_tags(db, user_id=current_user.id, skip=skip, limit=limit)
    return tags


@router.get("/{tag_id}", response_model=schemas.TagResponse)
def get_tag(
    tag_id: int,
    current_user: models.User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get a specific tag."""
    set_user_id_for_audit(db, current_user.id)
    tag = crud.get_tag(db, tag_id, current_user.id)
    if not tag:
        raise HTTPException(status_code=404, detail="Tag not found")
    return tag


@router.post("", response_model=schemas.TagResponse, status_code=status.HTTP_201_CREATED)
def create_tag(
    tag: schemas.TagCreate,
    current_user: models.User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Create a new tag."""
    set_user_id_for_audit(db, current_user.id)
    db_tag = crud.create_tag(db, tag, current_user.id)
    return db_tag


@router.put("/{tag_id}", response_model=schemas.TagResponse)
def update_tag(
    tag_id: int,
    tag_update: schemas.TagUpdate,
    current_user: models.User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Update a tag."""
    set_user_id_for_audit(db, current_user.id)
    db_tag = crud.update_tag(db, tag_id, current_user.id, tag_update)
    if not db_tag:
        raise HTTPException(status_code=404, detail="Tag not found")
    return db_tag


@router.delete("/{tag_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_tag(
    tag_id: int,
    current_user: models.User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Delete a tag."""
    set_user_id_for_audit(db, current_user.id)
    success = crud.delete_tag(db, tag_id, current_user.id)
    if not success:
        raise HTTPException(status_code=404, detail="Tag not found")

