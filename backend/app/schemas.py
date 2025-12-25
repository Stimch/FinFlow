"""Pydantic schemas for request/response validation."""
from pydantic import BaseModel, EmailStr, Field, ConfigDict
from typing import Optional, List
from datetime import date, datetime
from decimal import Decimal
from app.models import (
    AccountType, TransactionType, CategoryType, 
    BudgetPeriod, RecurringInterval
)


# User Schemas
class UserBase(BaseModel):
    email: EmailStr
    full_name: Optional[str] = None
    currency: str = "RUB"
    timezone: str = "Europe/Moscow"


class UserCreate(UserBase):
    password: str = Field(..., min_length=8)


class UserUpdate(BaseModel):
    email: Optional[EmailStr] = None
    full_name: Optional[str] = None
    currency: Optional[str] = None
    timezone: Optional[str] = None


class UserResponse(UserBase):
    id: int
    is_active: bool
    created_at: datetime
    updated_at: datetime
    
    model_config = ConfigDict(from_attributes=True)


# Account Schemas
class AccountBase(BaseModel):
    name: str
    type: AccountType
    balance: Decimal = Decimal("0.00")
    currency: str = "RUB"
    bank_name: Optional[str] = None
    account_number: Optional[str] = None


class AccountCreate(AccountBase):
    pass


class AccountUpdate(BaseModel):
    name: Optional[str] = None
    type: Optional[AccountType] = None
    currency: Optional[str] = None
    bank_name: Optional[str] = None
    account_number: Optional[str] = None
    is_active: Optional[bool] = None


class AccountResponse(AccountBase):
    id: int
    user_id: int
    is_active: bool
    created_at: datetime
    updated_at: datetime
    
    model_config = ConfigDict(from_attributes=True)


# Category Schemas
class CategoryBase(BaseModel):
    name: str
    type: CategoryType
    parent_id: Optional[int] = None
    budget_limit: Optional[Decimal] = None
    icon: Optional[str] = None
    color: Optional[str] = None


class CategoryCreate(CategoryBase):
    pass


class CategoryUpdate(BaseModel):
    name: Optional[str] = None
    type: Optional[CategoryType] = None
    parent_id: Optional[int] = None
    budget_limit: Optional[Decimal] = None
    icon: Optional[str] = None
    color: Optional[str] = None
    is_active: Optional[bool] = None


class CategoryResponse(CategoryBase):
    id: int
    user_id: int
    is_active: bool
    created_at: datetime
    
    model_config = ConfigDict(from_attributes=True)


# Transaction Schemas
class TransactionBase(BaseModel):
    account_id: int
    category_id: Optional[int] = None
    amount: Decimal = Field(..., gt=0)
    type: TransactionType
    date: date
    description: Optional[str] = None
    payee: Optional[str] = None
    location: Optional[str] = None
    tag_ids: Optional[List[int]] = None


class TransactionCreate(TransactionBase):
    pass


class TransactionUpdate(BaseModel):
    account_id: Optional[int] = None
    category_id: Optional[int] = None
    amount: Optional[Decimal] = Field(None, gt=0)
    type: Optional[TransactionType] = None
    date: Optional[date] = None
    description: Optional[str] = None
    payee: Optional[str] = None
    location: Optional[str] = None
    tag_ids: Optional[List[int]] = None


class TransactionResponse(TransactionBase):
    id: int
    is_recurring: bool
    created_at: datetime
    updated_at: datetime
    tags: Optional[List["TagResponse"]] = None
    
    model_config = ConfigDict(from_attributes=True)


# Tag Schemas
class TagBase(BaseModel):
    name: str
    color: Optional[str] = None


class TagCreate(TagBase):
    pass


class TagUpdate(BaseModel):
    name: Optional[str] = None
    color: Optional[str] = None


class TagResponse(TagBase):
    id: int
    user_id: int
    created_at: datetime
    
    model_config = ConfigDict(from_attributes=True)


# Budget Schemas
class BudgetBase(BaseModel):
    category_id: Optional[int] = None
    amount: Decimal = Field(..., gt=0)
    period: BudgetPeriod
    start_date: date
    end_date: Optional[date] = None


class BudgetCreate(BudgetBase):
    pass


class BudgetUpdate(BaseModel):
    category_id: Optional[int] = None
    amount: Optional[Decimal] = Field(None, gt=0)
    period: Optional[BudgetPeriod] = None
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    is_active: Optional[bool] = None


class BudgetResponse(BudgetBase):
    id: int
    user_id: int
    is_active: bool
    created_at: datetime
    updated_at: datetime
    
    model_config = ConfigDict(from_attributes=True)


# Goal Schemas
class GoalBase(BaseModel):
    name: str
    description: Optional[str] = None
    target_amount: Decimal = Field(..., gt=0)
    current_amount: Decimal = Field(default=Decimal("0.00"), ge=0)
    deadline: Optional[date] = None
    priority: int = Field(default=5, ge=1, le=10)


class GoalCreate(GoalBase):
    pass


class GoalUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    target_amount: Optional[Decimal] = Field(None, gt=0)
    current_amount: Optional[Decimal] = Field(None, ge=0)
    deadline: Optional[date] = None
    priority: Optional[int] = Field(None, ge=1, le=10)


class GoalResponse(GoalBase):
    id: int
    user_id: int
    is_completed: bool
    completed_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime
    
    model_config = ConfigDict(from_attributes=True)


# Recurring Transaction Schemas
class RecurringTransactionBase(BaseModel):
    account_id: int
    category_id: Optional[int] = None
    description: str
    amount: Decimal = Field(..., gt=0)
    type: TransactionType
    interval: RecurringInterval
    next_date: date
    end_date: Optional[date] = None


class RecurringTransactionCreate(RecurringTransactionBase):
    pass


class RecurringTransactionUpdate(BaseModel):
    account_id: Optional[int] = None
    category_id: Optional[int] = None
    description: Optional[str] = None
    amount: Optional[Decimal] = Field(None, gt=0)
    type: Optional[TransactionType] = None
    interval: Optional[RecurringInterval] = None
    next_date: Optional[date] = None
    end_date: Optional[date] = None
    is_active: Optional[bool] = None


class RecurringTransactionResponse(RecurringTransactionBase):
    id: int
    user_id: int
    is_active: bool
    created_at: datetime
    updated_at: datetime
    
    model_config = ConfigDict(from_attributes=True)


# Batch Import Schemas
class BatchTransactionItem(BaseModel):
    account_id: int
    category_id: Optional[int] = None
    amount: Decimal
    type: TransactionType
    date: date
    description: Optional[str] = None
    payee: Optional[str] = None
    tag_ids: Optional[List[int]] = None


class BatchImportRequest(BaseModel):
    transactions: List[BatchTransactionItem]


class BatchImportResponse(BaseModel):
    total: int
    successful: int
    failed: int
    errors: List[dict]


# Report Schemas
class FinancialReportResponse(BaseModel):
    category_name: str
    category_type: CategoryType
    total_income: Decimal
    total_expense: Decimal
    transaction_count: int
    avg_amount: Decimal


class TopExpenseCategoryResponse(BaseModel):
    category_id: int
    category_name: str
    total_amount: Decimal
    transaction_count: int
    percentage: Decimal


class BudgetStatusResponse(BaseModel):
    budget_id: int
    category_name: str
    budget_amount: Decimal
    spent_amount: Decimal
    remaining: Decimal
    percentage_used: Decimal
    is_exceeded: bool





