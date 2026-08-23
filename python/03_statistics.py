"""Reproduce the main statistical tests used in the report."""
import sys
from pathlib import Path
import numpy as np
import pandas as pd
from scipy import stats
import statsmodels.formula.api as smf

if len(sys.argv) != 3:
    raise SystemExit("Usage: python 03_statistics.py <cleaned.csv> <output_dir>")
path, out = Path(sys.argv[1]), Path(sys.argv[2]); out.mkdir(parents=True, exist_ok=True)
df=pd.read_csv(path,low_memory=False); comp=df[df['CompletedFlight']==1].copy()
arr=comp['ArrDelay'].dropna(); n=len(arr); mean=arr.mean(); se=arr.std(ddof=1)/np.sqrt(n); ci=stats.t.interval(.95,df=n-1,loc=mean,scale=se)
counts=comp.groupby('Airline').size(); majors=counts[counts>=5000].index.tolist(); groups=[comp.loc[comp['Airline']==a,'ArrDelay'].dropna().values for a in majors]
f,p=stats.f_oneway(*groups); sub=comp[comp['Airline'].isin(majors)]; gm=sub['ArrDelay'].mean(); ssb=sum(len(g)*(np.mean(g)-gm)**2 for g in groups); sst=((sub['ArrDelay']-gm)**2).sum(); eta2=ssb/sst
maj_chi=df.groupby('Airline').size(); maj_chi=maj_chi[maj_chi>=5000].index.tolist(); ct=pd.crosstab(df[df['Airline'].isin(maj_chi)]['Airline'],df[df['Airline'].isin(maj_chi)]['IsCancelled']); chi,pchi,dof,_=stats.chi2_contingency(ct); N=ct.values.sum(); r,k=ct.shape; v=np.sqrt((chi/N)/min(k-1,r-1))
period=comp.dropna(subset=['DeparturePeriod','IsArrivalDelayed15']); ct2=pd.crosstab(period['DeparturePeriod'],period['IsArrivalDelayed15']); chi2,p2,dof2,_=stats.chi2_contingency(ct2); N2=ct2.values.sum(); r2,k2=ct2.shape; v2=np.sqrt((chi2/N2)/min(k2-1,r2-1))
reg=comp[['ArrDelay','DepDelay','Distance','TaxiOut','TaxiIn','ScheduledDepHour','DayOfWeek','Airline']].dropna(); reg=reg.sample(min(120000,len(reg)),random_state=42); model=smf.ols('ArrDelay ~ DepDelay + Distance + TaxiOut + TaxiIn + ScheduledDepHour + C(DayOfWeek) + C(Airline)',data=reg).fit()
summary=pd.DataFrame([
['Mean arrival delay',mean,np.nan,ci[0],ci[1],np.nan],['ANOVA across major airlines',f,p,np.nan,np.nan,eta2],['Chi-square cancellation vs airline',chi,pchi,np.nan,np.nan,v],['Chi-square departure period vs delay15',chi2,p2,np.nan,np.nan,v2],['OLS R-squared',model.rsquared,np.nan,np.nan,np.nan,np.nan]],columns=['analysis','statistic','p_value','ci95_low','ci95_high','effect_size'])
summary.to_csv(out/'statistical_results_summary.csv',index=False)
pd.DataFrame({'term':model.params.index,'coefficient':model.params.values,'std_error':model.bse.values,'t_stat':model.tvalues.values,'p_value':model.pvalues.values}).to_csv(out/'regression_coefficients.csv',index=False)
print(summary.to_string(index=False))
