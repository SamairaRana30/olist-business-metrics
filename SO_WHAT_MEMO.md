Olist: What the Numbers Mean for the Business

Based on the Olist Brazilian E-commerce dataset (about 99,000 orders between September 2016 and October 2018). All values are in Brazilian reais (R$).

Executive Summary

Olist's growth was driven by attracting more customers and generating more orders, not by getting customers to spend more per purchase. Revenue grew rapidly throughout 2017 but began to level off in 2018.

The biggest challenge is customer retention. Only 3% of customers ever make a second purchase, which means lifetime value is largely limited to a single order. At the same time, delivery performance has a major impact on customer satisfaction. Customers receiving late deliveries give dramatically lower review scores, and late shipments are concentrated in a small number of states and sellers.

If Olist wants sustainable growth, improving delivery reliability and encouraging second purchases appear to be the highest-impact opportunities.

1. Revenue: Strong Growth That Eventually Slowed

Revenue increased from approximately R$112,000 in January 2017 to nearly R$988,000 in November 2017. After that, growth became much slower, with monthly revenue remaining roughly between R$830,000 and R$980,000 through most of 2018.

One major event stands out: Black Friday 2017.

On 24 November 2017, Olist generated around R$150,000 from 1,147 orders in a single day, accounting for roughly 15% of the month's revenue. The day after generated another R$60,000, while a typical day in late November generated between R$30,000 and R$48,000.

Business Meaning

Revenue growth clearly shows strong marketplace adoption during 2017. However, the plateau in 2018 suggests the company was reaching a point where growth became harder to sustain.

The key business question is no longer:

"Can we grow?"

Instead, it becomes:

"How can we restart growth without relying on major promotional events like Black Friday?"

2. Average Order Value (AOV): Customers Didn't Spend More

While order volume grew significantly, Average Order Value remained mostly unchanged, fluctuating between roughly R$126 and R$145.

This means revenue growth came almost entirely from more orders rather than larger purchases.

Business Meaning

Olist succeeded in bringing more people onto the platform, but customers were not spending noticeably more per order.

This is important because there are two ways to grow revenue:

Get more customers.
Increase spending per customer.

Olist was primarily succeeding in the first area.

Product sales were also fairly diversified. No single category dominated revenue, which reduces dependence on any individual product segment.

3. Gross Margin Perspective: Delivery Costs Matter

The dataset does not include actual costs, commissions, or profit information, so true gross margin cannot be calculated.

However, freight costs provide a useful proxy.

Shipping represented approximately 12% to 16% of customer payments, increasing gradually throughout the period while AOV stayed relatively flat.

Business Meaning

Delivery costs are becoming a larger part of the customer bill.

If profitability were declining despite stable revenue, possible explanations might include:

Higher shipping costs
Delivery subsidies
Increased discounting
Product returns
Seller commission changes

Further investigation would require financial and operational data.

4. Customer Acquisition Cost (CAC) and LTV:CAC

The data does not contain marketing spend, so actual CAC cannot be calculated.

Using customer value estimates, average customer lifetime value is approximately R$165.

A commonly accepted benchmark is:

LTV:CAC ≥ 3:1

Using revenue alone, this means Olist could theoretically spend up to R$55 to acquire a customer.

Business Meaning

The challenge is that revenue is not profit.

Once margins are considered, acceptable acquisition costs become much lower.

Because customer lifetime value is already low, Olist has limited room to spend aggressively on customer acquisition unless retention improves.

5. Lifetime Value (LTV): The Real Problem

Among roughly 93,000 customers with delivered orders:

One-time customers generated around R$161
Repeat customers generated around R$309

However:

Only 3% of customers ever return for another purchase.

Business Meaning

This is one of the most important findings in the entire analysis.

Olist's average customer value is low because most customers make only one purchase.

The fastest way to increase LTV is not necessarily finding more customers.

It is getting existing customers to return.

6. Customer Growth: Mostly New Customers

Customer counts depend heavily on how customers are defined.

Using customer_unique_id (actual people), there were roughly 96,000 customers.

Using customer_id (generated per order), there were about 99,000 records, which overstates customer count by roughly 3.5%.

Business Meaning

Most marketplace activity came from first-time customers.

For example, in November 2017:

7,060 customers were new
Only 123 were returning

This means growth was primarily driven by acquiring new customers rather than building customer loyalty.

7. Customer Satisfaction (NPS Proxy)

The dataset does not contain true Net Promoter Score data, so review ratings were used as a proxy.

Results show a striking pattern:

Group	NPS Proxy
Overall	+38
On-time deliveries	+45
Late deliveries	-43

Customers receiving orders on time gave an average review score of 4.29, while late deliveries averaged only 2.57.

Business Meaning

Late delivery appears to be one of the strongest indicators of poor customer experience.

Only about 8% of deliveries were late, but those customers reported dramatically lower satisfaction.

Several northeastern states experienced much higher late-delivery rates than average, including:

Alagoas (AL)
Maranhão (MA)
Piauí (PI)
Ceará (CE)
Sergipe (SE)
Bahia (BA)

Some individual sellers also showed unusually high lateness rates.

While this analysis shows a strong relationship between delays and poor reviews, it does not prove causation. Other factors may contribute as well.

8. Order Funnel: Generally Healthy

The post-purchase funnel looks strong:

Placed       99,441
↓
Approved     99.8%
↓
Shipped      98.2%
↓
Delivered    97.0%


Only around 1.2% of orders were cancelled or unavailable.

Business Meaning

The marketplace is generally effective at moving orders through to completion.

The largest drop occurs between order approval and shipment (about 1.6 percentage points, roughly 1,600 orders; this includes orders cancelled before shipping).

This points towards sellers and fulfilment rather than checkout, although the data cannot say why those orders did not ship.

Because website traffic data is unavailable, pre-purchase conversion rates cannot be analysed.

9. Retention and Churn: The Biggest Long-Term Risk

Retention rates are extremely low.

The percentage of customers who ever purchased again was:

4.9% (2016 cohort)
4.2% (2017 cohort)
2.0% (2018 cohort)

As a result, churn effectively ranges from 95% to 98%.

Monthly cohort analysis also shows very few customers returning in subsequent months.

One caution: the 2018 figure is lower partly because those customers had less time to come back before the data ends. It should not be read on its own as retention getting worse; cohorts need to be compared at the same age.

Business Meaning

This is not a business with strong repeat purchasing behaviour.

Most customers buy once and never return.

That creates constant pressure to acquire new customers simply to maintain growth.

Retention may represent the largest untapped growth opportunity in the marketplace.

Recommendations
1. Improve Delivery Performance

Late deliveries have the strongest observed relationship with low customer satisfaction.

Priority areas should include:

States with the highest late-delivery rates
Sellers consistently missing delivery estimates
Shipping routes with prolonged delivery times

Improving delivery reliability could increase satisfaction and potentially improve retention.

2. Encourage a Second Purchase

Only 3% of customers return, yet repeat customers generate nearly double the value of one-time buyers.

Potential experiments include:

Discount vouchers after delivery
Personalised follow-up emails
Loyalty rewards
Cross-sell recommendations

Even small improvements in repeat purchase rates could significantly increase customer lifetime value.

3. Don't Expect AOV to Drive Growth

Average Order Value remained relatively flat across the dataset.

Future growth is more likely to come from:

Acquiring new customers efficiently
Increasing retention
Improving customer experience

rather than expecting customers to place much larger orders.

Limitations

This dataset cannot answer several important business questions because it does not include:

True gross margin or profitability
Seller commission data
Marketing spend and CAC
Website traffic or advertising performance
Actual Net Promoter Score surveys
Purchases made outside the Olist platform

To deepen the analysis, the next data requested should be marketing spend, commission data, logistics costs, and website analytics.

Final Takeaway

If I were presenting this to a stakeholder, I would summarise it in one sentence:

Olist's growth was powered by acquiring new customers, but long-term growth is limited by low repeat purchases and delivery issues. Improving retention and reducing late deliveries are likely the highest-impact opportunities for the business.