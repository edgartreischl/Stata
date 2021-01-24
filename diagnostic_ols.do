*************************************************************
***********************************************07 May 2017***
*Regression diagnostics: Linear regression ******************
*This is an diagnostic do file example => Please let me know 
*(edgar.treischl@fau.de) if you find any mistakes
*************************************************************
*************************************************************

clear all
set more off, perm

*First, let's use some implemented data to calculate a linear regression
webuse lbw, clear
des

*Here we explain birthweight by different independent variables: Please do not
*regard model as "meaningful" => just for demonstration purposes
regress bwt smoke age lwt ftv




*************************************************************
*************************************************************
*1. Outlier**************************************************
*************************************************************
*************************************************************
*Bivariate we can always (or in single cases) use scatter plts and label ID's
scatter bwt age , mlabel(id)

*in case your data lacks an id variable: use "gen id=_n"


********************
*studentized residuals 
********************
*Let’s examine the studentized residuals as a first mean to identify outliers
*Studentized residuals are a type of standardized residual that can be used to 
*identify outliers...

*Rule of thumb for threshold: abs(rstu) > 2
predict r, rstudent

*Stem-and-leaf plot for r 
stem r 
*Here 6 observations stick out -3.03,-2.99 and so on....

*Lets sort r to see which on it is
sort r
list if r in 1/10

*Even more confortable is the ado Hilo...
*Hilo shows 10 lowest and highest observations on id
*"search hilo"
hilo id r



********************
*Leverage: identify observations that will have potential great influence on 
*regression coefficient estimates.
********************
predict lev, leverage

*Again, stem and leaf plot, or hilo
stem lev
hilo lev id, show(5) high


*Rule of thumb for leverage
*Shall not be greater that (2k+2)/n (k=predictors; n=N)
display (2*4+2)/e(N)
*Here: 0.52

list bwt smoke age lwt ftv if lev >.156

/*
We can make a plot that shows the leverage by the residual squared and look 
for observations that are jointly high on both of these measures.  
We can do this using the lvr2plot command. lvr2plot stands for leverage versus 
residual squared plot. The two reference lines are the means.
*/
lvr2plot, mlabel(id)



********************
/*
Cook’s D and DFITS: general measures of influence  
These measures both combine information on the residual and leverage. Cook’s D 
and DFITS are very similar except that they scale differently but they give us similar answers.
Rule of thumb: the convention cut-off point is > 4/n with [0, infin.]
*/
********************

predict d, cooksd
list bwt smoke age lwt ftv d if d>4/e(N)

*DFITS
*Rule of thumb: > 2*sqrt(k/n), with [-infin, 0, infini] => 0 = no influence
predict dfit, dfits
list bwt smoke age lwt ftv d dfit if abs(dfit)>2*sqrt(4/e(N))


*Make use of general measures of influence to see what happens with your results, eg. 
quietly reg bwt smoke age lwt ftv
estimate store modell_all
quietly reg bwt smoke age lwt ftv if abs(dfit)<2*sqrt(4/e(N))
estimate store modell_outlier

*Compare effect direction, sizes, significance
coefplot (modell_all, label(All data)) (modell_outlier, label(Without outlier)), drop(_cons) xline(0)




********************
*Instead of general measures, your may also look at single coefficients with 
*DFBETA: assess how each coefficient is changed by deleting the observation
*Conventional threshold:  > 2/sqrt(e(N))
********************
quietly regress bwt smoke age lwt ftv
dfbeta

display  2/sqrt(e(N))
*Here: 0.14547859 => adjust yline in scatterplot!
scatter _dfbeta_1 - _dfbeta_4, ylabel(-1(.5)3) yline(.15 -.15) mlabel(id id id)


********************
*AV Plot: partial-regression plot
********************
avplots
*For example, in the avplot for age shown below, the graph shows birthweight by 
*mothersage after both variables have been adjusted (constant) for all other predictors in the model
avplot age, mlabel(id)




*************************************************************
*************************************************************
*2. Checking Normality of Residuals**************************
*************************************************************
*************************************************************
/* Nice to know ;) Normality of residuals is only required for valid hypothesis testing, 
that is, the normality assumption assures that the p-values for the t-tests and
F-test will  be valid. Normality is not required in order to obtain unbiased 
estimates of the regression coefficients. 
Let predict resid!*/

quietly regress bwt smoke age lwt ftv
predict resid, resid

*Below we use the kdensity command to produce a kernel density plot 
*with the normal option requesting that a normal density be overlaid on the plot
kdensity resid, normal

/* The pnorm command graphs a standardized normal probability (P-P) plot while 
qnorm plots the quantiles of a variable against the quantiles of a normal distribution.
pnorm is sensitive to non-normality in the middle range of data and qnorm is sensitive 
to non-normality near the tails. 

As you see below, the results from pnorm show alsmost no indications of non-normality, 
while the qnorm command shows a slight deviation  from normal at the upper tail, 
as can be seen in the kdensity as well. Nevertheless, this seems to be a minor 
and trivial deviation from normality. We can accept that the residuals are close 
to a normal distribution. */

pnorm resid
qnorm resid

*Last and least: test it statistically For example with!
swilk resid
*Shapiro-Wilk W test for normality. The p-value is based on the assumption 
*that the distribution is normal. In our example, prob is > 0.05, 
*indicating that we cannot reject that r is normally distributed.



*************************************************************
*************************************************************
*3. Homoscedasticity of Residuals****************************
*************************************************************
*************************************************************
/*
If the model is well-fitted, there should be no pattern to the residuals plotted 
against the fitted values. If the variance of the residuals is non-constant then 
the residual variance is said to be “heteroscedastic.” There are graphical and 
non-graphical methods for detecting heteroscedasticity. A commonly used graphical 
method is to plot the Residuals Versus Fitted (predicted) values. 
*/
quietly regress bwt smoke age lwt ftv
rvfplot, yline(0)

*At the first glance, it looks like we have homoscedastic variance!
*Again, lets use a test and pretend that the picture was not that clear!
estat imtest
estat hettest

*Both test the null hypothesis that the variance of the residuals is homogenous. 
*Therefore, if the p-value is very small, we would have to reject the hypothesis 
*and accept the alternative hypothesis that the variance is not homogenous
*Here: p > 0.05 => reject alternative hypothesis => variance is homogenous!
*By the way, use robust regression if no other solutions (e.g. transformation) are 
*available to adjust for homoscedasticity: reg X Y, vce (robust)





*************************************************************
*************************************************************
*4. Checking for Multicollinearity***************************
*************************************************************
*************************************************************
/* When there is a perfect linear relationship among the predictors, the estimates 
for a regression model cannot be uniquely computed. The term collinearity implies 
that two variables are near perfect linear combinations of one another. Consequence:
standard errors for the coefficients can get wildly inflated.

Lets checks VIF values: vif stands for variance inflation factor. As a rule 
of thumb,  a variable whose VIF values are greater than 10 may merit further 
investigation.  Tolerance, defined as 1/VIF, is used by many researchers to check 
on the degree of collinearity. A tolerance value lower than 0.1 is comparable 
to a VIF of 10. It means that the variable could be considered as a linear 
combination of other independent variables. */

quietly regress bwt smoke age lwt ftv
estat vif

*Here we're fine. In general, if you have several variables in a model that
*measure somethings very similiar or different aspects of one construct you have
*calcuate a index or use factor analysis to determine what you want to include



*************************************************************
*************************************************************
*5. Checking Linearity***************************************
*************************************************************
*************************************************************
*Basic assumption: we assume a relationship between the response variable and
*the predictors to be linear :)
*If this assumption is violated, we! will try to fit a straight 
*line to data that does not follow a straight line.

*In case of of one independet variable it is straight forward, scatter plot it!
twoway (scatter bwt age) (lfit bwt age) (lowess bwt age)

*Or look at several corr plots in one graph
graph matrix bwt smoke age lwt ftv, half


*No longer straightforward, in the case of multiple predictors
*The most straightforward thing to do is to plot the standardized 
*residuals against each of the predictor variables
quietly regress bwt age lwt

*a reminder: drop always prediction (resid) and use the one of your final estimation

predict resid, resid

scatter resid age
scatter resid lwt

*you can also use partial residual plots: CPR-Plot (Component-Plus-Residual)
cprplot age, lowess 


*Aprplot graphs an augmented component-plus-residual 
*plot, a.k.a. augmented partial residual plot. *Adds a quadratic term

acprplot age, lowess lsopts(bwidth(1))

*If you see a non-linear relationsship, look again at your different covariates,
*how's their distribution? Skewd? => Transformation e.g. log
kdensity lwt, normal


*************************************************************
*************************************************************
*6. Model Specification: Omitted Variables, irrelevant var, etc*
*************************************************************
*************************************************************
/* you can test if your single model may lack model specification with
link test: linktest is based on the idea that if a regression is 
properly specified, one should not be able to find any additional 
independent variables that are significant except by chance. 
linktest creates two new variables, the variable of prediction, _hat, 
and the variable of squared prediction, _hatsq. The model is then refit 
using these two variables as predictors. _hat should be significant since 
it is the predicted value. On the other hand, _hatsq shouldn’t, because 
if our model is specified correctly, the squared predictions should not 
have much explanatory power. That is we wouldn’t  expect  _hatsq to be a 
significant predictor if our model is specified correctly
*/
quietly regress bwt smoke age lwt ftv

linktest

* Here it seems like our model doesn't explain our outcome well (okay,
*we only use it for demonstration purposes; at least _hatsq is ns => 
*no misspecification 

*OV Test: Ramsey-RESET-Test
*the idea behind ovtest is very similar to linktest. It also creates new variables 
*based on the predictors and refits the model using those new variables to see if 
*any of them would be significant (also: A formal test for linearity)
ovtest

*So we see what we expect from the likt test => ov test clearly indicates at we have 
*a omitted variables/misspecification=> reconsider model





*************************************************************
*************************************************************
*7. Independence of error terms******************************
*************************************************************
*************************************************************
/*assumption that the errors associated with one observation are not correlated 
with the errors of any other observation cover several different situations. 
Consider the case of collecting data from students in eight different elementary 
schools. It is likely that the students within each school will tend to be more 
like one another than students from different schools, that is, their errors are 
not independent. 

Another way in which the assumption of independence can be broken is when data 
are collected on the same variables over time.  => autocorrelation (EK t1, t2...)
When you have data that can be considered to be time-series you should use the 
dwstat command that performs a Durbin-Watson test for correlated residuals.*/


*For demonstration purposes only: use dwstat after your time-series commands

help estat dwatson

*The Durbin-Watson statistic has a range from 0 to 4 with a midpoint of 2














