Presentation on Joint Modelling & Causal Inference Approach to Surrogate Endpoint Evaluation
========================================================
author: Olusoji Oluwafemi Daniel
date: 
autosize: true

Introduction & Background
========================================================


Notations and Model Framework
========================================================
- **$T$** = difference in insulin sensitivity, which is the true endpoint
- **$S_i$** = surrogates (difference in bacteria counts),  $i=1,\ldots,30$. 
- **$X_i$** = Treatment applied. own_feces(control), donor_feces(experimental).

Treatment Effect on Insulin Sensitivity(True Endpoint)
========================================================
- A paired t-test and Wilcoxon test(due to the sample size) is used to test for treatmment effect on T.

  + Results for t-test(treatment effect= difference in means)

    Treatment Effect | 95%CI 
    ---------------- | ------
    12.57            | 6.68, 18.47

  + Results for Wilcoxon(treatment effect= difference in ranks)
  
    Treatment Effect | 95%CI 
    ---------------- | ------
    13.23            | 5.45, 18.96
    
- Both tests showed a treatment effect in favor of the experimental treatment. 

Treatment Effect on Surrogates(log of counts)
========================================================
![Volcano Plot1](t-testvolcano_plot_logcounts.png)

- red = raw p-value is lesser than 0.05

***

![Volcano Plot2](wilcox_volcano_plot_logcounts.png)

- red = raw p-value is lesser than 0.05

Treatment Effect on Surrogates(log of counts)
========================================================
Surrogate|      rawp|        BH|        fc|
---------|---------:|---------:|---------:|
       29| 0.0017313| 0.0519378| -3272.375|
       18| 0.0081190| 0.1217846| -7137.250|
       13| 0.0166647| 0.1666466|  -417.625|
        2| 0.0518900| 0.3891746| -1358.125|
       28| 0.1016089| 0.5728590|   632.375|
       24| 0.1145718| 0.5728590| -1647.000|
        8| 0.1727944| 0.6287726| -1749.125|
       27| 0.1778046| 0.6287726|  6084.875|
       19| 0.1886318| 0.6287726|  3720.625|
        4| 0.2142510| 0.6427529|  -674.750|
        9| 0.2571641| 0.7013566|   186.500|
        7| 0.3240010| 0.7959564|  -328.875|
       
***
Surrogate|      rawp|        BH|        fc|
---------|---------:|---------:|---------:|      
       26| 0.3449144| 0.7959564|  6791.500|"
        1| 0.4037203| 0.8146096|   524.625|"
        3| 0.4454052| 0.8146096|  -788.375|"
       15| 0.4539591| 0.8146096|  -295.000|"
       17| 0.4673569| 0.8146096| -1976.500|"
[20] "|        22| 0.4887658| 0.8146096|    37.625|"
[21] "|        30| 0.5210889| 0.8227720| -4382.625|"
[22] "|         5| 0.6061975| 0.8834452| -2595.750|"
[23] "|        14| 0.6556504| 0.8834452|   943.000|"
[24] "|        23| 0.6649654| 0.8834452|  1754.125|"
[25] "|        11| 0.6773080| 0.8834452|   106.875|"
[26] "|         6| 0.7724000| 0.9227405| -3958.625|"
[27] "|        16| 0.7762738| 0.9227405|   741.875|"
[28] "|        10| 0.8036793| 0.9227405|  2626.625|"
[29] "|        25| 0.8473203| 0.9227405|  3796.000|"
[30] "|        21| 0.8612245| 0.9227405|  3601.375|"
[31] "|        20| 0.9293162| 0.9579962|    38.875|"
[32] "|        12| 0.9579962| 0.9579962|  -346.500|"

Adjusted Association Plots(control=red, experimental=green)
========================================================
![](first_presentation-figure/exploration-1.png)

***

![](first_presentation-figure/exploration-2.png)

Adjusted Association Plots(cont:)
========================================================
![](first_presentation-figure/exploration-3.png)

***

![](first_presentation-figure/exploration-4.png)

Adjusted Association Plots(cont:)
========================================================
![](first_presentation-figure/exploration-5.png)

***

![](first_presentation-figure/exploration-6.png)

Adjusted Association Plots(cont:)
========================================================
![](first_presentation-figure/exploration-7.png)

***

![](first_presentation-figure/exploration-8.png)

Adjusted Association Plots(cont:)
========================================================
![](first_presentation-figure/exploration-9.png)

***

![](first_presentation-figure/exploration-10.png)

Joint Modelling Approach
========================================================
The model framework can be depicted as; 
<center>![Model Framework](modelframework.PNG)

Based on this fraemwork, the following surrogate specific joint model can be formulated;
$$ \left( \begin{array}{c}
S_{ij} \\
T_{i}
\end{array} \right) \sim N\left[ \left( \begin{array}{c}
\mu_{S} + \alpha_jX_i  \\
\mu_{T} + \beta X_i
\end{array}
\right), \Sigma_j \right], \Sigma_j = \left( \begin{array}{cc}
\sigma_{SS} & \sigma_{ST}\\
\sigma_{ST} & \sigma_{TT}
\end{array}\right)$$

Joint Modelling Approach(cont:)
========================================================
- $\alpha_j$ is the effect of treatment on surrogate j 
- $\beta$ is the effect of treatment on the true endpoint
- $\rho_{T,S|X} = \frac{\sigma_{ST}}{\sqrt{\sigma_{SS} \sigma_{TT} }}$. This is the adjusted association (Burzykowski, Molenberghs, and Buyse, 2005, Perualia-Tan, et al, 2016).

Causal Inference Approach
========================================================





