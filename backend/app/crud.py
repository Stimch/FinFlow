"""CRUD operations for database models."""
from sqlalchemy.orm import Session
from sqlalchemy import func, and_, or_
from typing import List, Optional
from datetime import date, datetime
from decimal import Decimal
from app import models, schemas


# User CRUD
def get_user(db: Session, user_id: int) -> Optional[models.User]:
    return db.query(models.User).filter(models.User.id == user_id).first()


def get_user_by_email(db: Session, email: str) -> Optional[models.User]:
    return db.query(models.User).filter(models.User.email == email).first()


def create_user(db: Session, user: schemas.UserCreate, password_hash: str) -> models.User:
    db_user = models.User(
        email=user.email,
        password_hash=password_hash,
        full_name=user.full_name,
        currency=user.currency,
        timezone=user.timezone
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user


def update_user(db: Session, user_id: int, user_update: schemas.UserUpdate) -> Optional[models.User]:
    db_user = get_user(db, user_id)
    if not db_user:
        return None
    
    update_data = user_update.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_user, field, value)
    
    db.commit()
    db.refresh(db_user)
    return db_user


# Account CRUD
def get_account(db: Session, account_id: int, user_id: int) -> Optional[models.Account]:
    return db.query(models.Account).filter(
        models.Account.id == account_id,
        models.Account.user_id == user_id
    ).first()


def get_accounts(db: Session, user_id: int, skip: int = 0, limit: int = 100) -> List[models.Account]:
    return db.query(models.Account).filter(
        models.Account.user_id == user_id
    ).offset(skip).limit(limit).all()


def create_account(db: Session, account: schemas.AccountCreate, user_id: int) -> models.Account:
    db_account = models.Account(**account.model_dump(), user_id=user_id)
    db.add(db_account)
    db.commit()
    db.refresh(db_account)
    return db_account


def update_account(db: Session, account_id: int, user_id: int, account_update: schemas.AccountUpdate) -> Optional[models.Account]:
    db_account = get_account(db, account_id, user_id)
    if not db_account:
        return None
    
    update_data = account_update.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_account, field, value)
    
    db.commit()
    db.refresh(db_account)
    return db_account


def delete_account(db: Session, account_id: int, user_id: int) -> bool:
    db_account = get_account(db, account_id, user_id)
    if not db_account:
        return False
    
    db.delete(db_account)
    db.commit()
    return True


# Category CRUD
def get_category(db: Session, category_id: int, user_id: int) -> Optional[models.Category]:
    return db.query(models.Category).filter(
        models.Category.id == category_id,
        models.Category.user_id == user_id
    ).first()


def get_categories(db: Session, user_id: int, skip: int = 0, limit: int = 100) -> List[models.Category]:
    return db.query(models.Category).filter(
        models.Category.user_id == user_id
    ).offset(skip).limit(limit).all()


def create_category(db: Session, category: schemas.CategoryCreate, user_id: int) -> models.Category:
    db_category = models.Category(**category.model_dump(), user_id=user_id)
    db.add(db_category)
    db.commit()
    db.refresh(db_category)
    return db_category


def update_category(db: Session, category_id: int, user_id: int, category_update: schemas.CategoryUpdate) -> Optional[models.Category]:
    db_category = get_category(db, category_id, user_id)
    if not db_category:
        return None
    
    update_data = category_update.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_category, field, value)
    
    db.commit()
    db.refresh(db_category)
    return db_category


def delete_category(db: Session, category_id: int, user_id: int) -> bool:
    db_category = get_category(db, category_id, user_id)
    if not db_category:
        return False
    
    db.delete(db_category)
    db.commit()
    return True


# Transaction CRUD
def get_transaction(db: Session, transaction_id: int, user_id: int) -> Optional[models.Transaction]:
    return db.query(models.Transaction).join(models.Account).filter(
        models.Transaction.id == transaction_id,
        models.Account.user_id == user_id
    ).first()


def get_transactions(
    db: Session, 
    user_id: int, 
    skip: int = 0, 
    limit: int = 100,
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    transaction_type: Optional[models.TransactionType] = None,
    category_id: Optional[int] = None
) -> List[models.Transaction]:
    query = db.query(models.Transaction).join(models.Account).filter(
        models.Account.user_id == user_id
    )
    
    if start_date:
        query = query.filter(models.Transaction.date >= start_date)
    if end_date:
        query = query.filter(models.Transaction.date <= end_date)
    if transaction_type:
        query = query.filter(models.Transaction.type == transaction_type)
    if category_id:
        query = query.filter(models.Transaction.category_id == category_id)
    
    return query.order_by(models.Transaction.date.desc()).offset(skip).limit(limit).all()


def create_transaction(db: Session, transaction: schemas.TransactionCreate, user_id: int) -> models.Transaction:
    # Verify account belongs to user
    account = get_account(db, transaction.account_id, user_id)
    if not account:
        raise ValueError("Account not found or doesn't belong to user")
    
    # Create transaction
    transaction_data = transaction.model_dump(exclude={"tag_ids"})
    db_transaction = models.Transaction(**transaction_data)
    db.add(db_transaction)
    db.flush()
    
    # Add tags if provided
    if transaction.tag_ids:
        for tag_id in transaction.tag_ids:
            # Verify tag belongs to user
            tag = db.query(models.Tag).filter(
                models.Tag.id == tag_id,
                models.Tag.user_id == user_id
            ).first()
            if tag:
                db_transaction.tags.append(tag)
    
    db.commit()
    db.refresh(db_transaction)
    return db_transaction


def update_transaction(
    db: Session, 
    transaction_id: int, 
    user_id: int, 
    transaction_update: schemas.TransactionUpdate
) -> Optional[models.Transaction]:
    db_transaction = get_transaction(db, transaction_id, user_id)
    if not db_transaction:
        return None
    
    update_data = transaction_update.model_dump(exclude_unset=True, exclude={"tag_ids"})
    for field, value in update_data.items():
        setattr(db_transaction, field, value)
    
    # Update tags if provided
    if "tag_ids" in transaction_update.model_dump(exclude_unset=True):
        db_transaction.tags.clear()
        for tag_id in transaction_update.tag_ids or []:
            tag = db.query(models.Tag).filter(
                models.Tag.id == tag_id,
                models.Tag.user_id == user_id
            ).first()
            if tag:
                db_transaction.tags.append(tag)
    
    db.commit()
    db.refresh(db_transaction)
    return db_transaction


def delete_transaction(db: Session, transaction_id: int, user_id: int) -> bool:
    db_transaction = get_transaction(db, transaction_id, user_id)
    if not db_transaction:
        return False
    
    db.delete(db_transaction)
    db.commit()
    return True


# Tag CRUD
def get_tag(db: Session, tag_id: int, user_id: int) -> Optional[models.Tag]:
    return db.query(models.Tag).filter(
        models.Tag.id == tag_id,
        models.Tag.user_id == user_id
    ).first()


def get_tags(db: Session, user_id: int, skip: int = 0, limit: int = 100) -> List[models.Tag]:
    return db.query(models.Tag).filter(
        models.Tag.user_id == user_id
    ).offset(skip).limit(limit).all()


def create_tag(db: Session, tag: schemas.TagCreate, user_id: int) -> models.Tag:
    db_tag = models.Tag(**tag.model_dump(), user_id=user_id)
    db.add(db_tag)
    db.commit()
    db.refresh(db_tag)
    return db_tag


def update_tag(db: Session, tag_id: int, user_id: int, tag_update: schemas.TagUpdate) -> Optional[models.Tag]:
    db_tag = get_tag(db, tag_id, user_id)
    if not db_tag:
        return None
    
    update_data = tag_update.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_tag, field, value)
    
    db.commit()
    db.refresh(db_tag)
    return db_tag


def delete_tag(db: Session, tag_id: int, user_id: int) -> bool:
    db_tag = get_tag(db, tag_id, user_id)
    if not db_tag:
        return False
    
    db.delete(db_tag)
    db.commit()
    return True


# Budget CRUD
def get_budget(db: Session, budget_id: int, user_id: int) -> Optional[models.Budget]:
    return db.query(models.Budget).filter(
        models.Budget.id == budget_id,
        models.Budget.user_id == user_id
    ).first()


def get_budgets(db: Session, user_id: int, skip: int = 0, limit: int = 100) -> List[models.Budget]:
    return db.query(models.Budget).filter(
        models.Budget.user_id == user_id
    ).offset(skip).limit(limit).all()


def create_budget(db: Session, budget: schemas.BudgetCreate, user_id: int) -> models.Budget:
    db_budget = models.Budget(**budget.model_dump(), user_id=user_id)
    db.add(db_budget)
    db.commit()
    db.refresh(db_budget)
    return db_budget


def update_budget(db: Session, budget_id: int, user_id: int, budget_update: schemas.BudgetUpdate) -> Optional[models.Budget]:
    db_budget = get_budget(db, budget_id, user_id)
    if not db_budget:
        return None
    
    update_data = budget_update.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_budget, field, value)
    
    db.commit()
    db.refresh(db_budget)
    return db_budget


def delete_budget(db: Session, budget_id: int, user_id: int) -> bool:
    db_budget = get_budget(db, budget_id, user_id)
    if not db_budget:
        return False
    
    db.delete(db_budget)
    db.commit()
    return True


# Goal CRUD
def get_goal(db: Session, goal_id: int, user_id: int) -> Optional[models.Goal]:
    return db.query(models.Goal).filter(
        models.Goal.id == goal_id,
        models.Goal.user_id == user_id
    ).first()


def get_goals(db: Session, user_id: int, skip: int = 0, limit: int = 100) -> List[models.Goal]:
    return db.query(models.Goal).filter(
        models.Goal.user_id == user_id
    ).offset(skip).limit(limit).all()


def create_goal(db: Session, goal: schemas.GoalCreate, user_id: int) -> models.Goal:
    db_goal = models.Goal(**goal.model_dump(), user_id=user_id)
    db.add(db_goal)
    db.commit()
    db.refresh(db_goal)
    return db_goal


def update_goal(db: Session, goal_id: int, user_id: int, goal_update: schemas.GoalUpdate) -> Optional[models.Goal]:
    db_goal = get_goal(db, goal_id, user_id)
    if not db_goal:
        return None
    
    update_data = goal_update.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_goal, field, value)
    
    db.commit()
    db.refresh(db_goal)
    return db_goal


def delete_goal(db: Session, goal_id: int, user_id: int) -> bool:
    db_goal = get_goal(db, goal_id, user_id)
    if not db_goal:
        return False
    
    db.delete(db_goal)
    db.commit()
    return True


# Recurring Transaction CRUD
def get_recurring_transaction(db: Session, recurring_id: int, user_id: int) -> Optional[models.RecurringTransaction]:
    return db.query(models.RecurringTransaction).filter(
        models.RecurringTransaction.id == recurring_id,
        models.RecurringTransaction.user_id == user_id
    ).first()


def get_recurring_transactions(db: Session, user_id: int, skip: int = 0, limit: int = 100) -> List[models.RecurringTransaction]:
    return db.query(models.RecurringTransaction).filter(
        models.RecurringTransaction.user_id == user_id
    ).offset(skip).limit(limit).all()


def create_recurring_transaction(
    db: Session, 
    recurring: schemas.RecurringTransactionCreate, 
    user_id: int
) -> models.RecurringTransaction:
    # Verify account belongs to user
    account = get_account(db, recurring.account_id, user_id)
    if not account:
        raise ValueError("Account not found or doesn't belong to user")
    
    db_recurring = models.RecurringTransaction(**recurring.model_dump(), user_id=user_id)
    db.add(db_recurring)
    db.commit()
    db.refresh(db_recurring)
    return db_recurring


def update_recurring_transaction(
    db: Session, 
    recurring_id: int, 
    user_id: int, 
    recurring_update: schemas.RecurringTransactionUpdate
) -> Optional[models.RecurringTransaction]:
    db_recurring = get_recurring_transaction(db, recurring_id, user_id)
    if not db_recurring:
        return None
    
    update_data = recurring_update.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_recurring, field, value)
    
    db.commit()
    db.refresh(db_recurring)
    return db_recurring


def delete_recurring_transaction(db: Session, recurring_id: int, user_id: int) -> bool:
    db_recurring = get_recurring_transaction(db, recurring_id, user_id)
    if not db_recurring:
        return False
    
    db.delete(db_recurring)
    db.commit()
    return True





