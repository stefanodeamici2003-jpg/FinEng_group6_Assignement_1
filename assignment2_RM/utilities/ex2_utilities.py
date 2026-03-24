"""
Mathematical Engineering - Financial Engineering, FY 2024-2025
Risk Management - Exercise 2: Corporate Bond Portfolio
"""

from typing import List, Union
import numpy as np
import pandas as pd
import datetime as dt
from utilities.date_functions import (
        year_frac_act_x,
    year_frac_30e_360,
    business_date_offset,
)

from utilities.ex0_utilities import (    
    get_discount_factor_by_zero_rates_linear_interp,
)

# from utilities.ex1_utilities import (
#     _df,
#     )
def _df(
    discount_factors: pd.Series,
    date: Union[dt.date, pd.Timestamp],
) -> float:
    """Thin wrapper around the linear-interpolation discount-factor lookup."""
    return get_discount_factor_by_zero_rates_linear_interp(
        discount_factors.index[0],
        date,
        discount_factors.index,
        discount_factors.values,
    )

def bond_payment_dates(
    issue_date: Union[dt.date, pd.Timestamp], maturity: int, coupon_freq: int
) -> Union[List[dt.date], List[pd.Timestamp]]:
    """
    Calculate the payment dates of a bond.

    Parameters:
        issue_date (Union[dt.date, pd.Timestamp]): Bond's issue date.
        maturity (int): Bond's maturity in years.
        coupon_freq (int): Coupon frequency in payments per years.

    Returns:
        Union[List[dt.date], List[pd.Timestamp]]: List of payment dates.
    """

    payment_dates = []
    counter = 1
    for _ in range(maturity * coupon_freq):
        payment_dt = business_date_offset(
            issue_date, month_offset=(12 // coupon_freq) * counter
        )
        payment_dates.append(pd.Timestamp(payment_dt))
        
        # Complete #

        counter += 1

    return payment_dates




def bond_cash_flows(
    ref_date: Union[dt.date, pd.Timestamp],
    issue_date: Union[dt.date, pd.Timestamp],
    maturity: int,
    coupon_rate: float,
    coupon_freq: int,
    notional: float = 1.0,
) -> pd.Series:
    """
    Calculate the cash flows of a bond.

    Parameters:
    ref_date (Union[dt.date, pd.Timestamp]): Reference date.
    issue_date (Union[dt.date, pd.Timestamp]): Bond's issue date.
    maturity (int): Bond's maturity in years.
    coupon_rate (float): Coupon rate.
    coupon_freq (int): Coupon frequency in payments per years.
    notional (float): Notional amount.

    Returns:
        pd.Series: Bond cash flows.
    """

    # Payment dates
    cash_flows_dates = bond_payment_dates(issue_date, maturity, coupon_freq)
    # Coupon payments
    dates = [ref_date] + cash_flows_dates
    cash_flows = pd.Series(
        data=[
             coupon_rate * year_frac_30e_360(dates[i - 1], dates[i])
            for i in range(1, len(dates))    
              # Complete
        ],
        index=cash_flows_dates,
    )
    # Notional payment
    cash_flows[cash_flows_dates[-1]] += notional

    return cash_flows


def defaultable_bond_dirty_price_from_intensity(
    ref_date: Union[dt.date, pd.Timestamp],
    issue_date: Union[dt.date, pd.Timestamp],
    maturity: int,
    coupon_rate: float,
    coupon_freq: int,
    recovery_rate: float,
    intensity: Union[float, pd.Series],
    discount_factors: pd.Series,
    notional: float = 1.0,
) -> float:
    """
    Calculate the dirty price of a defaultable bond neglecting the recovery of the coupon payments.

    Parameters:
    ref_date (Union[dt.date, pd.Timestamp]): Reference date.
    issue_date (Union[dt.date, pd.Timestamp]): Bond's issue date.
    maturity (int): Bond's maturity in years.
    coupon_rate (float): Coupon rate.
    coupon_freq (int): Coupon frequency in payments a years.
    recovery_rate (float): Recovery rate.
    intensity (Union[float, pd.Series]): Intensity, can be the average intensity (float) or a
        piecewise constant function of time (pd.Series).
    discount_factors (pd.Series): Discount factors.
    notional (float): Notional amount.

    Returns:
        float: Dirty price of the bond.
    """
    ref_date = pd.Timestamp(ref_date)

    # Calculate the cash flows
    cash_flows = bond_cash_flows(
        ref_date, issue_date, maturity, coupon_rate, coupon_freq, notional
    )

    # Discount factors
    discount_factors = _df(discount_factors,cash_flows.index)

    # Calculate the survival probabilities and default probabilities
    if isinstance(intensity, float):                 # if intensity is a float -> constant value
        survival_probs = np.exp(
            [
                -intensity * year_frac_act_x(ref_date, date, 365)
                for date in cash_flows.index
            ]
        )
        survival_probs = pd.Series(data=survival_probs, index=cash_flows.index)
    else:                                            # if instensity is not a float -> pd.Series -> piecewise constant
    
        survival_probs = None

    default_probs = None
    survival_probs_with_start = pd.concat([pd.Series([1.0]), survival_probs])
    default_probs = survival_probs_with_start.diff(-1).dropna()
    default_probs.index = cash_flows.index

    # Calculate the dirty price
    dirty_price = (cash_flows.values * np.array(discount_factors) * survival_probs.values).sum() + (recovery_rate * notional * np.array(discount_factors) * default_probs).sum() 
    return dirty_price

def defaultable_bond_dirty_price_from_z_spread(
    ref_date: Union[dt.date, pd.Timestamp],
    issue_date: Union[dt.date, pd.Timestamp],
    maturity: int,
    coupon_rate: float,
    coupon_freq: int,
    z_spread: float,
    discount_factors: pd.Series,
    notional: float = 1.0,
) -> float:
    """
    Calculate the dirty price of a defaultable bond from the Z-spread.

    Parameters:
    ref_date (Union[dt.date, pd.Timestamp]): Reference date.
    issue_date (Union[dt.date, pd.Timestamp]): Bond's issue date.
    maturity (int): Bond's maturity in years.
    coupon_rate (float): Coupon rate.
    coupon_freq (int): Coupon frequency in payments a years.
    z_spread (float): Z-spread.
    discount_factors (pd.Series): Discount factors.
    notional (float): Notional amount.

    Returns:
        float: Dirty price of the bond.
    """

    ref_date = pd.Timestamp(ref_date)

    # Calculate the cash flows
    cash_flows = bond_cash_flows(
        ref_date, issue_date, maturity, coupon_rate, coupon_freq, notional
    )

    # Discount factors with z-spread

    base_dfs = np.array([_df(discount_factors, d) for d in cash_flows.index])
    year_fracs = np.array([year_frac_act_x(ref_date, d, 365) for d in cash_flows.index])
    discount_factors_z = base_dfs * np.exp(-z_spread * year_fracs)

    # Calculate the dirty price
    dirty_price = (cash_flows.values * discount_factors_z).sum()
    return dirty_price

