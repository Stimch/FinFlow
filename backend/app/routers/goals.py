"""Goal routes."""
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db, set_user_id_for_audit
from app import crud, schemas
from app.auth import get_current_active_user
from app import models

router = APIRouter(prefix="/api/goals", tags=["goals"])


@router.get("", response_model=List[schemas.GoalResponse])
def get_goals(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    current_user: models.User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get list of goals."""
    set_user_id_for_audit(db, current_user.id)
    goals = crud.get_goals(db, user_id=current_user.id, skip=skip, limit=limit)
    return goals


@router.get("/{goal_id}", response_model=schemas.GoalResponse)
def get_goal(
    goal_id: int,
    current_user: models.User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get a specific goal."""
    set_user_id_for_audit(db, current_user.id)
    goal = crud.get_goal(db, goal_id, current_user.id)
    if not goal:
        raise HTTPException(status_code=404, detail="Goal not found")
    return goal


@router.post("", response_model=schemas.GoalResponse, status_code=status.HTTP_201_CREATED)
def create_goal(
    goal: schemas.GoalCreate,
    current_user: models.User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Create a new goal."""
    set_user_id_for_audit(db, current_user.id)
    db_goal = crud.create_goal(db, goal, current_user.id)
    return db_goal


@router.put("/{goal_id}", response_model=schemas.GoalResponse)
def update_goal(
    goal_id: int,
    goal_update: schemas.GoalUpdate,
    current_user: models.User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Update a goal."""
    set_user_id_for_audit(db, current_user.id)
    db_goal = crud.update_goal(db, goal_id, current_user.id, goal_update)
    if not db_goal:
        raise HTTPException(status_code=404, detail="Goal not found")
    return db_goal


@router.delete("/{goal_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_goal(
    goal_id: int,
    current_user: models.User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Delete a goal."""
    set_user_id_for_audit(db, current_user.id)
    success = crud.delete_goal(db, goal_id, current_user.id)
    if not success:
        raise HTTPException(status_code=404, detail="Goal not found")


@router.get("/{goal_id}/progress")
def get_goal_progress(
    goal_id: int,
    current_user: models.User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get goal progress using database function."""
    # Verify goal belongs to user
    goal = crud.get_goal(db, goal_id, current_user.id)
    if not goal:
        raise HTTPException(status_code=404, detail="Goal not found")
    
    result = db.execute(
        text("SELECT get_goal_progress(:goal_id) as progress"),
        {"goal_id": goal_id}
    )
    row = result.first()
    return {"progress_percent": float(row[0]) if row else 0.0}





