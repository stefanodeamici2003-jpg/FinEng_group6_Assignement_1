"""
Mathematical Engineering - Financial Engineering, FY 2025-2026
Risk Management - Exercise 0: Discount Factors Bootstrap
"""

import numpy as np
import pandas as pd
import datetime as dt
import QuantLib as ql
from utilities.date_functions import (
    business_date_offset,
    year_frac_act_x,
    year_frac_30e_360
)
from typing import Iterable, Union, List, Union, Tuple

def from_discount_factors_to_zero_rates(
    dates: Union[List[float], pd.DatetimeIndex],
    discount_factors: Iterable[float],
    convention: str = 'act/360'
) -> List[float]: 
    """
    Compute the zero rates from the discount factors.

    Parameters:
        dates (Union[List[float], pd.DatetimeIndex]): List of year fractions or dates.
        discount_factors (Iterable[float]): List of discount factors.
        convention (str): Day count convention, e.g., 'act/360' or '30/360'. Default is 'act/360'.

    Returns:
        List[float]: List of zero rates.
    """

    effDates, effDf = dates, discount_factors
    if isinstance(effDates, pd.DatetimeIndex):   # if the input are dates, convert to year fractions using the custom functions
        reference_date = effDates[0]
        
        effDates = [year_frac_act_x(reference_date, d, 360) if convention == 'act/360' else year_frac_30e_360(reference_date, d) for d in effDates[1:]]
        effDf = discount_factors[1:]
    else:  # already year fractions
        effDates = effDates[1:]
        effDf = discount_factors[1:]

    # Compute zero rates
    zero_rates = [-np.log(df) / yf for df, yf in zip(effDf, effDates)]
    return zero_rates

# def from_discount_factors_to_zero_rates(
#     dates: Union[List[float], pd.DatetimeIndex],
#     discount_factors: Iterable[float],
#     convention: str = 'act/360'
# ) -> List[float]: 
#     """
#     Compute the zero rates from the discount factors.

#     Parameters:
#         dates (Union[List[float], pd.DatetimeIndex]): List of year fractions or dates.
#         discount_factors (Iterable[float]): List of discount factors.
#         convention (str): Day count convention, e.g., 'act/360' or '30/360'. Default is 'act/360'.

#     Returns:
#         List[float]: List of zero rates.
#     """

#     effDates, effDf = dates, discount_factors
#     if isinstance(effDates, pd.DatetimeIndex):   # if the input are dates, convert to year fractions using QuantLib
#         reference_date = effDates[0]
#         ref_ql = ql.Date.from_date(reference_date.to_pydatetime())
        
#         if convention == 'act/360':
#             day_count = ql.Actual360()
#         elif convention == '30/360':
#             day_count = ql.Thirty360(ql.Thirty360.European)
#         else:
#             raise ValueError(f"Unsupported convention: {convention}")
        
#         effDates = [day_count.yearFraction(ref_ql, ql.Date.from_date(d.to_pydatetime())) for d in effDates[1:]]
#         effDf = discount_factors[1:]
#     else:  # already year fractions
#         effDates = effDates[1:]
#         effDf = discount_factors[1:]

#     # Compute zero rates
#     zero_rates = [-np.log(df) / yf for df, yf in zip(effDf, effDates)]
#     return zero_rates



def get_discount_factor_by_zero_rates_linear_interp(
    reference_date: Union[dt.datetime, pd.Timestamp],
    interp_date: Union[dt.datetime, pd.Timestamp],
    dates: Union[List[dt.datetime], pd.DatetimeIndex],
    discount_factors: Iterable[float],
) -> float:
    """
    Given a list of discount factors, return the discount factor at a given date by linear
    interpolation.

    Parameters:
        reference_date (Union[dt.datetime, pd.Timestamp]): Reference date.
        interp_date (Union[dt.datetime, pd.Timestamp]): Date at which the discount factor is
            interpolated.
        dates (Union[List[dt.datetime], pd.DatetimeIndex]): List of dates.
        discount_factors (Iterable[float]): List of discount factors.

    Returns:
        float: Discount factor at the interpolated date.
    """

    
    if len(dates) != len(discount_factors):
        raise ValueError("Dates and discount factors must have the same length.")
    
    
    # compute relevant yearfractions for available set of dates
    T = np.array([year_frac_act_x(reference_date, d, 360) for d in dates])
    T_target = year_frac_act_x(reference_date, interp_date, 360)    
    # convert discounts into zero rates
    zero_rates = np.where(T > 0, -np.log(discount_factors) / T, 0.0)    
    # apply the interpolation on the target day
    interp_rate = np.interp(T_target, T, zero_rates)    
    # convert zero rate into discount
    discount = np.exp(-interp_rate * T_target)
    
    return discount 


def bootstrap(
    reference_date: dt.datetime,
    depo: pd.DataFrame,
    futures: pd.DataFrame,
    swaps: pd.DataFrame,
    shock: float = 0.0,
) -> pd.Series:
    """
    Bootstrap the discount factors from the given bid/ask market data. Deposit rates are used until
    the first future settlement date (included), futures rates are used until the 2y-swap settlement.

    Parameters:
        reference_date (dt.datetime): Reference date.
        depo (pd.DataFrame): Deposit rates.
        futures (pd.DataFrame): Futures rates.
        swaps (pd.DataFrame): Swaps rates.
        shock (Union[float, pd.Series]): Parallel shift to apply to the market rates, default to
            zero.

    Returns:
        pd.Series: Discount factors.
    """

    # initialize the list of dates and discounts
    termDates, discounts = [reference_date], [1.0]

    #### DEPOS
    
    # select the correct depos and their rates
    depoDates = depo.iloc[0:3].index.to_list()    # write the correct condition to filter the dates and depo data needed
    depoRates = depo.loc[depoDates].mean(axis=1).values 

    # needed for the bumped bootstrap: if shock is a float, shift all the mkt data by that number, otherwise for each pillar its value
    depoRates = depoRates +  ( shock if isinstance(shock, float) else shock[depoDates].values )
    # convert rate L(t0,ti) to discount B(t0,ti) and append the results to the current list of dates and discounts
    termDates += depoDates
    # 4. Calcoliamo B(t0, ti) iterando matematicamente su ogni singola scadenza
    for i in range(len(depoDates)):
        # Estraiamo la data e il tasso i-esimo
        t_i = depoDates[i]
        L_i = depoRates[i] 
        # Calcoliamo la frazione d'anno (tau) usando la convenzione Act/360
        tau_i = year_frac_act_x(reference_date, t_i, 360) 
        # Applichiamo la formula di capitalizzazione semplice per ottenere lo Zero-Coupon
        B_i = 1.0 / (1.0 + L_i * tau_i)
        # Aggiungiamo il fattore di sconto appena calcolato alla lista globale
        discounts.append(float(B_i))  


    #print('termDates', termDates)
    #print('discounts', discounts)


    #### FUTURES

    # select the correct futures and their rates
    futures_of_interest = futures.iloc[0:7, :]

    # convert the forward rates L(t0;ti-1, ti) to the forward discount B(t0;ti-1,ti)
    price = (futures_of_interest["ASK"] + futures_of_interest["BID"]) / 2
    L = (100 - price)/100 # price in percentage
    # B(t0;ti-1,ti) = 1/(1+L*0.25) since the forward rate is a 3-month rate
    B = 1 / (1 + L * 0.25)  # write the correct formula to convert the forward rate into a forward discount factor
    # compute the spot discount B(t0, ti) using the compound rule, interpolate if needed
    for i in range(len(B)):
        discounts.append(B.iloc[i] * discounts[-1])  # append the result to the current list of discounts
        
    
    #termDates += futures_of_interest.index.to_list()  # append the futures settlement dates to the current list of dates
    termDates += [(d + pd.DateOffset(months=3) + pd.Timedelta(days=2)) for d in futures_of_interest.index]

    # print('termDates', termDates)
    # print('discounts', discounts)



    #### SWAPS

    # # select the correct swaps and their rates
    # swaps = swaps.iloc[1:, :]

    swapDate = swaps.index[0]
    
    swapYearFrac, swapDisc, df = list(), list(), 0.0

    swapYearFrac.append(year_frac_30e_360(reference_date, swapDate))
    
    swap_old = swapDate
    swapDisc=[df]

    # we don't consider the first swap since we already have futures (more liquid) to cover this date
    swapRates = swaps.iloc[1:, :].mean(axis=1).values + (
        shock if isinstance(shock, float) else shock[swaps.index].values
    )
    # initialize the BPV_1
    # print('reference_date', reference_date )
    # print('swapDate', swapDate)
    # print('')
    BPV_1 = swapYearFrac[0] * get_discount_factor_by_zero_rates_linear_interp(reference_date, swapDate, termDates, discounts) # compute the discount factor at the first swap date by linear interpolation
    # print(swapYearFrac[0], get_discount_factor_by_zero_rates_linear_interp(reference_date, swapDate, termDates, discounts))

    
    # rate, yf = swapRates[0], swapYearFrac[0]
    # df = (1 - rate/100*BPV_1) / (1 + rate/100*yf)
    # BPV_1 += df*yf

    ### il ya un saut entre discount 11 (dernier future) et discount 12 (premier swap)
    ### verifier le calcul du discount pour le premier swap fevrier 2009


    # we don't consider the first swap since we already have futures (more liquid) to cover this date
    for idx, swapDate in enumerate(swaps.iloc[1:, :].index):
            rate, yf = swapRates[idx], year_frac_30e_360(swap_old, swapDate)
            print('rate', rate)
            print('yf', swap_old, swapDate, yf)
            swapYearFrac.append(yf)
            df = (1 - rate/100*BPV_1) / (1 + rate/100*yf)
            termDates.append(swapDate)
            discounts.append(df)
            swap_old = swapDate
            BPV_1 += df*yf

    # print('termDates', termDates)
    # print('discounts', discounts)

    discount_factors = pd.Series(index=termDates, data=discounts)
    #print('discount_factors', discount_factors)
    zero = from_discount_factors_to_zero_rates(discount_factors.index, discount_factors.values)
    zero_rates = pd.Series(index=termDates[1:], data=zero)
    #print('zero', zero)
    #print('zero_rates', zero_rates)
    return discount_factors, zero_rates
