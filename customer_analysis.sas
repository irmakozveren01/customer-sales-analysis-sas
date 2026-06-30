/* Customer Sales Analysis and Reporting in SAS */

/* Define project library */
libname data "/home/u64341987/Project";


/* -------------------------------------------------------------------------
   Utility macro: sort datasets by selected key variables
   ------------------------------------------------------------------------- */

%macro sorting(dset=, by=);
    proc sort data=&dset;
        by &by;
    run;
%mend sorting;


/* -------------------------------------------------------------------------
   Step 1: Create an integrated customer-level dataset

   Source datasets:
   - Customer
   - Customer_dim
   - Customer_orders

   The final dataset keeps only customers with purchase records.
   ------------------------------------------------------------------------- */

/* Sort customer tables by Customer_ID before merging */
%sorting(dset=data.customer, by=customer_ID);
%sorting(dset=data.customer_dim, by=customer_ID);

/* Merge customer profile information with customer dimension attributes */
data customers_base;
    merge data.customer
          data.customer_dim(rename=(
              Customer_Country   = Country
              Customer_Gender    = Gender
              Customer_BirthDate = Birth_Date
          ));
    by Customer_ID;
run;


/* Sort the merged customer table and order table by Customer_Name */
%sorting(dset=customers_base, by=customer_name);
%sorting(dset=data.customer_orders, by=customer_name);

/* Merge customer information with order records.
   Only customers with purchases are retained. */
data customers_raw;
    merge customers_base(in=a)
          data.customer_orders(in=b);
    by Customer_Name;

    if a and b;
run;


/* -------------------------------------------------------------------------
   Step 2: Create derived variables

   AGE_CAT:
      0 = missing age or age outside defined categories
      1 = 15 < age <= 30
      2 = age > 30

   FLAG01:
      Y = missing group membership
      N = non-missing group membership

   FLAG02:
      Yes = first or last customer record after ordering by Customer_ID
            and Product_Name
      No  = otherwise

   COST:
      total customer expenditure across all purchases

   BUDGET_CAT:
      <=50 = purchase amount is $50 or below
      >50  = purchase amount is above $50
   ------------------------------------------------------------------------- */

/* Sort detailed purchase records for first/last customer logic */
%sorting(dset=work.customers_raw, by=Customer_ID Product_Name);

data work.Customers_step1;
    set work.customers_raw;
    by Customer_ID Product_Name;

    /* Categorize customers by age */
    if missing(Customer_Age) then AGE_CAT = 0;
    else if 15 < Customer_Age and Customer_Age <= 30 then AGE_CAT = 1;
    else if Customer_Age > 30 then AGE_CAT = 2;
    else AGE_CAT = 0;

    /* Flag missing group membership */
    if missing(Customer_Group) then FLAG01 = "Y";
    else FLAG01 = "N";

    /* Identify first and last records within each customer */
    if first.Customer_ID or last.Customer_ID then FLAG02 = "Yes";
    else FLAG02 = "No";
run;


/* Calculate total expenditure for each customer */
proc means data=work.Customers_step1 nway noprint;
    class Customer_ID;
    var Total_Retail_Price;
    output out=work.Cost_per_Customer(drop=_TYPE_ _FREQ_)
        sum(Total_Retail_Price)=Cost;
run;


/* Merge total customer cost back into the detailed customer-order dataset */
%sorting(dset=work.Customers_step1, by=Customer_ID);
%sorting(dset=work.Cost_per_Customer, by=Customer_ID);

data work.Customers;
    merge work.Customers_step1(in=a)
          work.Cost_per_Customer(in=b);
    by Customer_ID;

    if a;

    /* Categorize expenditure for each individual purchase */
    if Total_Retail_Price <= 50 then BUDGET_CAT = "<=50";
    else BUDGET_CAT = ">50";

    /* Apply currency formatting for reporting */
    format Cost dollar12.2 Total_Retail_Price dollar12.2;
run;


/* -------------------------------------------------------------------------
   Step 3: Generate PDF report
   ------------------------------------------------------------------------- */

ods pdf file="/home/u64341987/Project/final_report.pdf" style=statistical;

title "Customer Sales Analysis Report";


/* -------------------------------------------------------------------------
   Report 1: Summary statistics of Total_Retail_Price by Country

   Statistics reported:
   - Mean
   - Standard deviation
   - Minimum
   - Maximum
   ------------------------------------------------------------------------- */

title "Summary Statistics of Total Retail Price by Country";

proc means data=work.Customers mean std min max;
    class Country;
    var Total_Retail_Price;
run;


/* -------------------------------------------------------------------------
   Report 2: Customer-level purchase aggregation

   Each customer is displayed in one record with:
   - Ordered quantities
   - Total number of orders
   - Total expenditure
   ------------------------------------------------------------------------- */

title "Customer-Level Purchase Summary";

proc means data=work.Customers nway noprint;
    class Customer_ID;
    var Quantity Total_Retail_Price;
    output out=work.Customer_Expenditure(drop=_TYPE_ _FREQ_)
        sum(Quantity)           = Ordered_Quantities
        n(Quantity)             = Total_Num_Orders
        sum(Total_Retail_Price) = Total_Expenditure;
run;

data work.Customer_Expenditure;
    set work.Customer_Expenditure;

    format Total_Expenditure dollar12.2;

    label Ordered_Quantities = "Ordered quantities"
          Total_Num_Orders   = "Total n. of orders"
          Total_Expenditure  = "Total expenditure";
run;

proc print data=work.Customer_Expenditure label noobs;
    var Customer_ID Ordered_Quantities Total_Num_Orders Total_Expenditure;
run;


/* -------------------------------------------------------------------------
   Report 3: Association between Country and Expenditure Range

   Expenditure ranges:
   - Low    = total expenditure below $50
   - Medium = total expenditure between $50 and $100
   - High   = total expenditure above $100

   The association between Country and Expenditure Range is evaluated using
   contingency-table methods.
   ------------------------------------------------------------------------- */

/* Keep one country value per customer */
proc sort data=work.Customers
          out=work.Cust_Country(keep=Customer_ID Country)
          nodupkey;
    by Customer_ID;
run;

/* Combine customer-level total expenditure with country */
%sorting(dset=work.Customer_Expenditure, by=Customer_ID);

data work.Customer_Expend_Country;
    merge work.Customer_Expenditure(in=a)
          work.Cust_Country(in=b);
    by Customer_ID;

    if a;
run;

/* Create total expenditure range */
data work.Customer_Expend_Country;
    set work.Customer_Expend_Country;

    length Exp_Range $6;

    if Total_Expenditure < 50 then Exp_Range = "Low";
    else if 50 <= Total_Expenditure <= 100 then Exp_Range = "Medium";
    else if Total_Expenditure > 100 then Exp_Range = "High";
run;


/* Chi-square test with expected cell frequencies */
title "Association Between Country and Expenditure Range";

proc freq data=work.Customer_Expend_Country;
    tables Country * Exp_Range / chisq expected;
run;


/* Fisher's Exact Test is included as an exact alternative when expected
   frequencies are small. */
title "Exact Test for Country and Expenditure Range";

proc freq data=work.Customer_Expend_Country;
    tables Country * Exp_Range / expected;
    exact fisher;
run;


/* Interpretation:
   When expected cell frequencies are small, Fisher's Exact Test provides a
   more appropriate inferential approach than the Pearson Chi-square test.
   In this analysis, Fisher's Exact Test did not indicate a statistically
   significant association between Country and Expenditure Range
   (p = 0.2651).
*/


/* -------------------------------------------------------------------------
   Report 4: Frequency analysis of Country and Supplier

   Absolute and relative frequencies are computed after excluding records
   with missing Country or Supplier values.
   ------------------------------------------------------------------------- */

title "Frequency Distribution of Country and Supplier";

proc freq data=work.Customers;
    where not missing(Country) and not missing(Supplier);
    tables Country * Supplier;
run;


/* Close PDF output */
ods pdf close;
title;
