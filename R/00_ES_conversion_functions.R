# ----------------------------------------------
#
# functions to convert between different effect size measures relevant to the meta-study
# sources for the conversion formulas are in the paper
#
# ----------------------------------------------




# Cohen's d x
# d / (d^2 + 4)^{0.5}
# valid range -infinity to + infinity
convert_Cohens_d_to_r <- function(d){
  r <- (d / (((d^2) + 4)^0.5) ) * 1.27
  return(r)
}

convert_r_to_cohens_d <- function(r){
  r <- r/1.27
  d <- (sqrt(4) * r / sqrt(1-r^2))
  return(d)
}

# OR x
#(OR^{0.5} - 1) / (OR^{0.5} + 1)
# valid range 0 to +infinity
convert_OR_to_r <- function(OR){
  r <- (((OR^0.5)-1)/((OR^0.5)+1)) * 1.46
  return(r)
}
 

convert_r_to_OR <- function(r){
  r <- r / 1.46
  OR <- (((-1 - r) / (r-1))^2)
  return(OR)
}


# Kendall's tau x
#Sin(0.5 \times \pi \times \tau)
# valid range: -1 to +1
convert_tau_to_r <- function(tau){
  r <- (sin(0.5*pi*tau))*1.01
  return(r)
}

convert_r_to_tau <- function(r){
  r <- r/1.01
  tau <- (asin(r)/(0.5*pi))
  return(tau)
}


# Spearman's rho x
#Sin(\rho \times \pi/6)
# valid range -1 to +1
convert_rho_to_r <- function(rho){
  r <- (2*sin(rho*pi/6))*1.02
  return(r)
}

convert_r_to_rho <- function(r){
  r <- r/1.02
  rho <- ((asin(r/2))/(pi/6))
  return(rho)
}

# eta squared (and partial eta squared and generalized eta squared and unbiased/less-biased variants: omega squared, epsilon squared
# \sqrt{\eta^2}
# valid range 0 to 1 x
convert_eta_squared_to_r <- function(eta_squared){
  r <- sqrt(eta_squared)
  return(r)
}

convert_r_to_eta_squared <- function(r){
  eta_squared <- r^2
  return(eta_squared)
}


#Cramer's V (not phi since we can't be sure that the table is 2x2)
# limit 0 to 1 x
convert_cramers_v_to_r <- function(cramers_v){
  return(cramers_v * 1.44)
}

convert_r_to_Cramers_v <- function(r){
  return(r/1.44)
}


# CLES #Dunlap 1994
# valid range 0 to 1 x
convert_CLES_to_r <- function(cles){
  r <- sin((cles - 0.5) * pi) 
  return(r)
}

convert_r_to_CLES <- function(r){
  cles <- 0.5 + (asin(r)/pi)
  return(cles)
}

# R^2
# valid range 0 to 1 x
convert_Rsquared_to_r <- function(r_squared){
  r <- sqrt(r_squared)
  return(r)
}

convert_r_to_rsquared <- function(r){
  return(r^2)
}

# don't include pseudo-R-squareds

# cohen's f (Cohen 1988) x
# valid range 0 to infinity
convert_f_to_r <- function(f){
  d <- 2*f
  r <- convert_Cohens_d_to_r(d)
  return(r)
}

convert_r_to_f <- function(r){
  d <- convert_r_to_cohens_d(r)
  f <- d/2
  return(f)
}


# Cohen's f^2 (Cohen 1988) x
# f^2 = R^2 / (1-R^2) 
# valid range 0 to + infinity
convert_Cohens_f_squared_to_r <- function(f_squared){
  r <- sqrt((f_squared)/(f_squared + 1))
  return(r)
}

convert_r_to_cohens_f_squared <- function(r){
  f_squared <- (r^2 / (-r^2 + 1))
  return(f_squared)
}

is_valid_es <- function(es_value, es_type){
  if(is.na(es_type) | is.na(es_value)){
    return(NA)
  } else if(es_type == "pearsons_r" | es_type == "spearmans_rho" | 
            es_type == "kendalls_tau" | es_type == "rank_biserial_r" |
            es_type == "eta"){
    if(es_value >=-1 & es_value <= 1){
      return(TRUE)
      }
  } else if (es_type == "cohens_d"){
    return(TRUE)
  } else if (es_type == "odds_ratio" | es_type=="cohens_f" | es_type=="f_squared"){
    if(es_value > 0){
      return(TRUE)
    }
  } else if (es_type == "r_squared" | es_type == "eta_squared" | 
             es_type == "omega_squared" | es_type == "epsilon_square" | 
             es_type == "cramers_v" | es_type == "cles" ) {
    if(es_value >= 0 & es_value <= 1){
      return(TRUE)
    }
  } else{
    warning(paste("es_type", es_type, "is not supported for validity check."))
    return(NA)
  }
  return(FALSE)
}

is_valid_es_vectors<- Vectorize(is_valid_es)


meta_convert_es_to_r <- function(es_value, es_type){
  if(is.na(es_type) | is.na(es_value)){
    return(NA)
  } else if(es_type == "pearsons_r" | es_type == "eta"  | 
            es_type == "rank_biserial_r" | es_type == "omega"){
    return(abs(es_value)) # we need the absolute size not the direction of effects for meta analysis
  } else if (es_type == "cramers_v"){
    return(convert_cramers_v_to_r(es_value))
  } else if( es_type == "spearmans_rho" ){
    return(convert_rho_to_r(abs(es_value)))
  } else if ( es_type == "kendalls_tau" ){
    return(convert_tau_to_r(abs(es_value)))
  } else if (es_type == "cohens_d"){
    return(convert_Cohens_d_to_r(abs(es_value)))
  } else if (es_type == "odds_ratio" ){
    if (es_value < 1){ # get all rs over 1 as a result
      es_value <- 1 / es_value 
    }
    return(convert_OR_to_r(es_value))
  } else if (es_type=="cohens_f" ){
    return(convert_f_to_r(es_value))
  } else if(es_type=="f_squared"){
    return(convert_Cohens_f_squared_to_r(es_value))
  } else if (es_type == "r_squared" ){
    return(convert_Rsquared_to_r(es_value))
  } else if (es_type == "eta_squared" | es_type == "omega_squared" | es_type == "epsilon_square" ) {
    return(convert_eta_squared_to_r(es_value))
  } else if ( es_type == "cles" ) {
    if(es_value < 0.5){# get all rs over 1 as a result
      es_value <- 1 - es_value
    }
    return(convert_CLES_to_r(es_value))
  } else{
    warning(paste("es_type", es_type, "is not supported for conversion."))
    return(NA)
  }
}

meta_convert_es_to_r_vectors <- Vectorize(meta_convert_es_to_r)

meta_convert_r_to_es <- function(es_value, es_type){
  if(is.na(es_type) | is.na(es_value)){
    return(NA)
  } else if(es_type == "pearsons_r" | es_type == "eta"  | 
            es_type == "rank_biserial_r" | es_type == "omega"){
    return(abs(es_value)) # we need the absolute size not the direction of effects for meta analysis
  } else if (es_type == "cramers_v"){
    return(convert_r_to_Cramers_v(es_value))
  } else if( es_type == "spearmans_rho" ){
    return(convert_r_to_rho(abs(es_value)))
  } else if ( es_type == "kendalls_tau" ){
    return(convert_r_to_tau(abs(es_value)))
  } else if (es_type == "cohens_d"){
    return(convert_r_to_cohens_d(abs(es_value)))
  } else if (es_type == "odds_ratio" ){
    return(convert_r_to_OR(es_value))
  } else if (es_type=="cohens_f" ){
    return(convert_r_to_f(es_value))
  } else if(es_type=="f_squared"){
    return(convert_r_to_cohens_f_squared(es_value))
  } else if (es_type == "r_squared" ){
    return(convert_r_to_rsquared(es_value))
  } else if (es_type == "eta_squared" | es_type == "omega_squared" | es_type == "epsilon_square" ) {
    return(convert_r_to_eta_squared(es_value))
  } else if ( es_type == "cles" ) {
    return(convert_r_to_CLES(es_value))
  } else{
    warning(paste("es_type", es_type, "is not supported for conversion."))
    return(NA)
  }
}

meta_convert_r_to_es_vectors <- Vectorize(meta_convert_r_to_es)

