"""Transaction routes."""
from typing import List, Optional
from datetime import date
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db, set_user_id_for_audit
from app import crud, schemas
from app.auth import get_current_active_user
from app import models

router = APIRouter(prefix="/api/transactions", tags=["transactions"])


@router.get("", response_model=List[schemas.TransactionResponse])
def get_transactions(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    transaction_type: Optional[str] = None,
    category_id: Optional[int] = None,
    current_user: models.User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get list of transactions."""
    set_user_id_for_audit(db, current_user.id)
    
    # Convert string to enum if provided
    trans_type = None
    if transaction_type:
        try:
            trans_type = models.TransactionType(transaction_type)
        except ValueError:
            raise HTTPException(
                status_code=400, 
                detail=f"Invalid transaction type. Must be one of: {[e.value for e in models.TransactionType]}"
            )
    
    transactions = crud.get_transactions(
        db, 
        user_id=current_user.id,
        skip=skip,
        limit=limit,
        start_date=start_date,
        end_date=end_date,
        transaction_type=trans_type,
        category_id=category_id
    )
    return transactions


@router.get("/{transaction_id}", response_model=schemas.TransactionResponse)
def get_transaction(
    transaction_id: int,
    current_user: models.User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get a specific transaction."""
    set_user_id_for_audit(db, current_user.id)
    transaction = crud.get_transaction(db, transaction_id, current_user.id)
    if not transaction:
        raise HTTPException(status_code=404, detail="Transaction not found")
    return transaction


@router.post("", response_model=schemas.TransactionResponse, status_code=status.HTTP_201_CREATED)
def create_transaction(
    transaction: schemas.TransactionCreate,
    current_user: models.User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Create a new transaction."""
    set_user_id_for_audit(db, current_user.id)
    try:
        db_transaction = crud.create_transaction(db, transaction, current_user.id)
        return db_transaction
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.put("/{transaction_id}", response_model=schemas.TransactionResponse)
def update_transaction(
    transaction_id: int,
    transaction_update: schemas.TransactionUpdate,
    current_user: models.User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Update a transaction."""
    set_user_id_for_audit(db, current_user.id)
    db_transaction = crud.update_transaction(db, transaction_id, current_user.id, transaction_update)
    if not db_transaction:
        raise HTTPException(status_code=404, detail="Transaction not found")
    return db_transaction


@router.delete("/{transaction_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_transaction(
    transaction_id: int,
    current_user: models.User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Delete a transaction."""
    set_user_id_for_audit(db, current_user.id)
    success = crud.delete_transaction(db, transaction_id, current_user.id)
    if not success:
        raise HTTPException(status_code=404, detail="Transaction not found")


@router.post("/batch-import", response_model=schemas.BatchImportResponse)
def batch_import_transactions(
    batch_data: schemas.BatchImportRequest,
    current_user: models.User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Batch import transactions with error logging."""
    set_user_id_for_audit(db, current_user.id)
    
    successful = 0
    failed = 0
    errors = []
    
    for idx, item in enumerate(batch_data.transactions):
        try:
            transaction = schemas.TransactionCreate(**item.model_dump())
            crud.create_transaction(db, transaction, current_user.id)
            successful += 1
        except Exception as e:
            failed += 1
            errors.append({
                "index": idx,
                "data": item.model_dump(),
                "error": str(e)
            })
    
    return schemas.BatchImportResponse(
        total=len(batch_data.transactions),
        successful=successful,
        failed=failed,
        errors=errors
    )


@router.get("/reports/financial", response_model=List[schemas.FinancialReportResponse])
def get_financial_report(
    start_date: date = Query(...),
    end_date: date = Query(...),
    current_user: models.User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get financial report using database function."""
    result = db.execute(
        text("SELECT * FROM get_user_financial_report(:user_id, :start_date, :end_date)"),
        {"user_id": current_user.id, "start_date": start_date, "end_date": end_date}
    )
    return [dict(row) for row in result]


@router.get("/reports/top-expenses", response_model=List[schemas.TopExpenseCategoryResponse])
def get_top_expense_categories(
    limit: int = Query(10, ge=1, le=50),
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    current_user: models.User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get top expense categories using database function."""
    result = db.execute(
        text("""
            SELECT * FROM get_top_expense_categories(
                :user_id, 
                :limit, 
                :start_date, 
                :end_date
            )
        """),
        {
            "user_id": current_user.id,
            "limit": limit,
            "start_date": start_date,
            "end_date": end_date
        }
    )
    return [dict(row) for row in result]

