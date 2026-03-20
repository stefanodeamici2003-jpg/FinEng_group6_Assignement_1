"""
Mathematical Engineering - Financial Engineering, FY 2025-2026
Risk Management - Exercise 1: Hedging a Swaption Portfolio
"""

from enum import Enum
import numpy as np
import pandas as pd
import datetime as dt
from utilities.date_functions import (
    year_frac_act_x,
    date_series,
    year_frac_30e_360,
    schedule_year_fraction,
)
from utilities.ex0_utilities import (
    get_discount_factor_by_zero_rates_linear_interp,
)

from scipy.stats import norm

from typing import Union, List, Tuple


class SwapType(Enum):
    """
    Types of swaptions.
    """

    RECEIVER = "receiver"
    PAYER = "payer"


def swaption_price_calculator(
    S0: float,
    strike: float,
    ref_date: Union[dt.date, pd.Timestamp],
    expiry: Union[dt.date, pd.Timestamp],
    underlying_expiry: Union[dt.date, pd.Timestamp],
    sigma_black: float,
    freq: int,
    discount_factors: pd.Series,
    swaption_type: SwapType = SwapType.RECEIVER,
    compute_delta: bool = False,
) -> Union[float, Tuple[float, float]]:
    """
    Return the swaption price defined by the input parameters.

    Parameters:
        S0 (float): Forward swap rate.
        strike (float): Swaption strike price.
        ref_date (Union[dt.date, pd.Timestamp]): Value date.
        expiry (Union[dt.date, pd.Timestamp]): Swaption expiry date.
        underlying_expiry (Union[dt.date, pd.Timestamp]): Underlying forward starting swap expiry.
        sigma_black (float): Swaption implied volatility.
        freq (int): Number of times a year the fixed leg pays the coupon.
        discount_factors (pd.Series): Discount factors.
        swaption_type (SwapType): Swaption type, default to receiver.

    Returns:
        Union[float, Tuple[float, float]]: Swaption price (and possibly delta).
    """

    ttm = year_frac_act_x(ref_date, expiry, 365)
    d1 = (np.log(S0 / strike) + 0.5 * sigma_black**2 * ttm) / (sigma_black * np.sqrt(ttm))
    d2 = (np.log(S0 / strike) - 0.5 * sigma_black**2 * ttm) / (sigma_black * np.sqrt(ttm))
    fixed_leg_payment_dates = date_series(expiry, underlying_expiry, freq)
    bpv = basis_point_value(fixed_leg_payment_dates[1:], discount_factors, expiry)
    discount_factor_tn = get_discount_factor_by_zero_rates_linear_interp(
            discount_factors.index[0],
            expiry,
            discount_factors.index,
            discount_factors.values) # discount factor at swaption expiry, used to discount the swaption payoff back to the value date

    # the PAYER and RECEIVER swaption price formulas were inverted
    if swaption_type == SwapType.RECEIVER:
        price = discount_factor_tn * bpv * (strike * norm.cdf(-d2) - S0 * norm.cdf(-d1))
        delta = discount_factor_tn * bpv * (norm.cdf(d1) - 1)
    elif swaption_type == SwapType.PAYER:
        price = discount_factor_tn * bpv * (S0 * norm.cdf(d1) - strike * norm.cdf(d2))
        delta = discount_factor_tn * bpv * norm.cdf(d1)

    else:
        raise ValueError("Invalid swaption type.")

    if compute_delta:
        return price, delta
    else:
        return price


def irs_proxy_duration(
    ref_date: dt.date,
    swap_rate: float,
    fixed_leg_payment_dates: List[dt.date],
    discount_factors: pd.Series,
) -> float:
    """
    Given the specifics of an interest rate swap (IRS), return its rate sensitivity calculated as
    the duration of a fixed coupon bond.

    Parameters:
        ref_date (dt.date): Reference date.
        swap_rate (float): Swap rate.
        fixed_leg_payment_dates (List[dt.date]): Fixed leg payment dates.
        discount_factors (pd.Series): Discount factors.

    Returns:
        (float): Swap duration.
    """
    numerator = 0
    denominator = 0

    for i, payment_date in enumerate(fixed_leg_payment_dates):
        t = year_frac_30e_360(ref_date, payment_date)
        df = get_discount_factor_by_zero_rates_linear_interp(
            discount_factors.index[0],
            payment_date,
            discount_factors.index,
            discount_factors.values,
        )
        
        if i == len(fixed_leg_payment_dates) - 1:
            cashflow = swap_rate + 1
        else:
            cashflow = swap_rate
        
        numerator += t * cashflow * df
        denominator += cashflow * df

    duration = numerator / denominator

    return duration



def basis_point_value(
    fixed_leg_schedule: List[dt.datetime],
    discount_factors: pd.Series,
    settlement_date: dt.datetime | None = None,
) -> float:
    """
    Given a swap fixed leg payment dates and the discount factors, return the basis point value.

    Parameters:
        fixed_leg_schedule (List[dt.datetime]): Fixed leg payment dates.
        discount_factors (pd.Series): Discount factors.
        settlement_date (dt.datetime | None): Settlement date, default to None, i.e. to today.
            Needed in case of forward starting swaps.

    Returns:
        float: Basis point value.
    """

    # !!! COMPLETE AS APPROPRIATE !!!
    if settlement_date is not None:
        discount_factor_tn = get_discount_factor_by_zero_rates_linear_interp(
            discount_factors.index[0],
            settlement_date,
            discount_factors.index,
            discount_factors.values,
        )
        bpv = year_frac_30e_360(settlement_date, fixed_leg_schedule[0]) * get_discount_factor_by_zero_rates_linear_interp(
            discount_factors.index[0],  fixed_leg_schedule[0], discount_factors.index, discount_factors.values) / discount_factor_tn
    
        bpv +=sum( year_frac_30e_360(fixed_leg_schedule[i], fixed_leg_schedule[i+1]) 
            * get_discount_factor_by_zero_rates_linear_interp(discount_factors.index[0],fixed_leg_schedule[i+1],discount_factors.index,discount_factors.values)for i in range(len(fixed_leg_schedule)-1)
        ) / discount_factor_tn

    else:
        settlement_date = dt.date(2008,2,15) # hard code maybe we can change it later

        bpv = year_frac_30e_360(settlement_date, fixed_leg_schedule[0]) * get_discount_factor_by_zero_rates_linear_interp(
            discount_factors.index[0],  fixed_leg_schedule[0], discount_factors.index, discount_factors.values)
        
        bpv += sum( year_frac_30e_360(fixed_leg_schedule[i], fixed_leg_schedule[i+1]) 
            * get_discount_factor_by_zero_rates_linear_interp(discount_factors.index[0],fixed_leg_schedule[i+1],discount_factors.index,discount_factors.values)for i in range(len(fixed_leg_schedule)-1)
        )   
    return bpv




def swap_par_rate(
    fixed_leg_schedule: List[dt.datetime],
    discount_factors: pd.Series,
    fwd_start_date: dt.datetime | None = None,
) -> float:
    """
    Given a fixed leg payment schedule and the discount factors, return the swap par rate. If a
    forward start date is provided, a forward swap rate is returned.

    Parameters:
        fixed_leg_schedule (List[dt.datetime]): Fixed leg payment dates.
        discount_factors (pd.Series): Discount factors.
        fwd_start_date (dt.datetime | None): Forward start date, default to None.

    Returns:
        float: Swap par rate.
    """

    # !!! MODIFY AS APPROPRIATE !!!
    discount_factor_tN = get_discount_factor_by_zero_rates_linear_interp(
        discount_factors.index[0],
        fixed_leg_schedule[-1],
        discount_factors.index,
        discount_factors.values,
        )

    if fwd_start_date is not None:
        discount_factor_tn = get_discount_factor_by_zero_rates_linear_interp(
            discount_factors.index[0],
            fwd_start_date,
            discount_factors.index,
            discount_factors.values,
        )   

        bpv = basis_point_value(fixed_leg_schedule, discount_factors, fwd_start_date) 

        float_leg = 1.0 - (discount_factor_tN/discount_factor_tn)

    else:

        bpv = basis_point_value(fixed_leg_schedule, discount_factors)

        float_leg = 1.0 - discount_factor_tN

    return float_leg / bpv


def swap_mtm(
    swap_rate: float,
    payments_schedule: List[dt.datetime],
    discount_factors: pd.Series,
    swap_type: SwapType = SwapType.PAYER,
) -> float:
    """
    Given a swap rate, a fixed leg payment schedule and the discount factors, return the swap
    mark-to-market.

    Parameters:
        swap_rate (float): Swap rate.
        fixed_leg_schedule (List[dt.datetime]): Fixed leg payment dates.
        discount_factors (pd.Series): Discount factors.
        swap_type (SwapType): Swap type, either 'payer' or 'receiver', default to 'payer'.

    Returns:
        float: Swap mark-to-market.
    """

    # Single curve framework, returns price and basis point value

    bpv = basis_point_value(payments_schedule, discount_factors) # We skip the settlement date

    P_term = get_discount_factor_by_zero_rates_linear_interp(
        discount_factors.index[0],
        payments_schedule[-1],
        discount_factors.index,
        discount_factors.values,
    )
    float_leg = 1.0 - P_term
    fixed_leg = swap_rate * bpv

    if swap_type == SwapType.RECEIVER: # Originally twisted values
        multiplier = -1
    elif swap_type == SwapType.PAYER:
        multiplier = 1
    else:
        raise ValueError("Unknown swap type.")

    return multiplier * (float_leg - fixed_leg)
