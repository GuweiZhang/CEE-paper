

suppressPackageStartupMessages({library(dlnm); library(splines); library(metafor)})

rain_categories <- c("moderate_rain", "heavy_rain", "storm_rain")
encode_rain <- function(rain, category) {
  if (!category %in% rain_categories) stop("Unknown rain category")
  bounds <- list(moderate_rain=c(10,25), heavy_rain=c(25,50), storm_rain=c(50,Inf))[[category]]
  ifelse(is.na(rain), NA_real_, ifelse(rain < 10, 0,
    ifelse(rain >= bounds[1] & rain < bounds[2], 1, NA_real_)))
}

prepare_data <- function(d) {
  required <- c("region","county","date","d3","mean_temp","rain_mm")
  if (!all(required %in% names(d))) stop("Required columns: ",paste(required,collapse=", "))
  d <- as.data.frame(d)
  d$date <- as.Date(d$date)
  if (anyNA(d[c("region","county","date")])) stop("Missing region/county/date")
  if (any(!d$region %in% c("NE","NC","NW","EC","CC","SC"))) stop("Invalid region")
  if (anyDuplicated(d[c("region","county","date")])) stop("Duplicate site-date records")
  for (v in c("d3","mean_temp","rain_mm")) {
    if (!is.numeric(d[[v]]) || any(!is.finite(d[[v]]) & !is.na(d[[v]]))) stop("Invalid numeric column: ",v)
  }
  if (any(d$d3<0 | d$d3!=floor(d$d3),na.rm=TRUE) || any(d$rain_mm<0,na.rm=TRUE)) stop("Invalid mortality count or rainfall")

  pieces <- split(d, interaction(d$region,d$county,drop=TRUE))
  do.call(rbind,lapply(pieces,function(x) {
    x <- x[order(x$date),]
    z <- merge(data.frame(date=seq(min(x$date),max(x$date),by="day")),x,by="date",all.x=TRUE,sort=TRUE)
    z$region <- x$region[1]; z$county <- x$county[1]
    z$year <- as.integer(format(z$date,"%Y"))
    z$time <- as.numeric(z$date-min(z$date))+1
    z$dow <- as.integer(format(z$date,"%w"))
    for (category in rain_categories) {
      coded <- encode_rain(z$rain_mm,category)
      if (category %in% names(z)) {
        old <- z[[category]]
        if (any(xor(is.na(old),is.na(coded))) || any(old!=coded,na.rm=TRUE))
          stop("Supplied exposure coding disagrees with Methods: ",category)
      }
      z[[category]] <- coded
    }
    z
  }))
}

fit_site <- function(city_data, rain_var) {
  df_time <- 7 * length(unique(city_data$year))
  temp_percentiles <- quantile(city_data$mean_temp,c(.10,.75,.90),na.rm=TRUE)
  if (length(unique(temp_percentiles))!=3) stop("Temperature knots are not distinct")
  temp_cb <- crossbasis(city_data$mean_temp,lag=14,
    argvar=list(fun="bs",degree=2,knots=temp_percentiles),
    arglag=list(fun="ns",knots=logknots(14,3)))
  rain_cb <- crossbasis(city_data[[rain_var]],lag=14,
    argvar=list(fun="strata",breaks=.5),
    arglag=list(fun="ns",knots=logknots(14,4)))
  model <- glm(d3 ~ rain_cb + temp_cb + ns(time,df=df_time) + as.factor(dow),
    data=city_data,family=quasipoisson,na.action=na.exclude)
  if (!isTRUE(model$converged) || model$df.residual<=0) stop("Model did not converge or has no residual df")
  pred <- crosspred(rain_cb,model,cen=0,at=1)
  beta <- as.numeric(log(pred$allRRfit))
  se <- as.numeric((log(pred$allRRhigh)-log(pred$allRRlow))/(2*1.96))
  if (length(beta)!=1 || !is.finite(beta) || !is.finite(se) || se<=0) stop("Non-estimable cumulative effect")
  data.frame(region=city_data$region[1],county=city_data$county[1],rain_level=rain_var,
    coef=beta,se=se,RR=exp(beta),lower95=exp(beta-1.96*se),upper95=exp(beta+1.96*se),
    calendar_days=nrow(city_data),fitted_outcome_days=nobs(model),
    available_target_days=sum(city_data[[rain_var]]==1 & !is.na(city_data$d3),na.rm=TRUE))
}

pool_effects <- function(x) {
  if (nrow(x)==1) return(data.frame(region=x$region[1],rain_level=x$rain_level[1],
    RR=x$RR,lower95=x$lower95,upper95=x$upper95,n_studies=1,I2=NA_real_,tau2=NA_real_,p_heterogeneity=NA_real_))
  m <- rma(yi=x$coef,sei=x$se,method="REML")
  data.frame(region=x$region[1],rain_level=x$rain_level[1],RR=as.numeric(exp(m$b)),
    lower95=exp(m$ci.lb),upper95=exp(m$ci.ub),n_studies=nrow(x),I2=m$I2,tau2=m$tau2,p_heterogeneity=m$QEp)
}

run_analysis <- function(d, output_dir) {
  d <- prepare_data(d)
  dir.create(output_dir,recursive=TRUE,showWarnings=FALSE)
  successes <- list(); audit <- list()
  for (x in split(d,interaction(d$region,d$county,drop=TRUE))) {
    for (category in rain_categories) {
      warns <- character()
      result <- tryCatch(withCallingHandlers(fit_site(x,category),warning=function(w) {
        warns <<- c(warns,conditionMessage(w)); invokeRestart("muffleWarning")
      }),error=function(e)e)
      ok <- !inherits(result,"error")
      audit[[length(audit)+1]] <- data.frame(region=x$region[1],county=x$county[1],rain_level=category,
        status=if(ok) "success" else "failed",reason=if(ok) "" else conditionMessage(result),
        warnings=paste(unique(warns),collapse=" | "))
      if(ok) successes[[length(successes)+1]] <- result
    }
  }
  write.csv(do.call(rbind,audit),file.path(output_dir,"fit_log.csv"),row.names=FALSE,na="")
  if (!length(successes)) stop("No estimable site models; see fit_log.csv")
  stage1 <- do.call(rbind,successes)
  write.csv(stage1,file.path(output_dir,"site_effects.csv"),row.names=FALSE)
  pooled <- do.call(rbind,lapply(split(stage1,interaction(stage1$region,stage1$rain_level,drop=TRUE)),pool_effects))
  write.csv(pooled,file.path(output_dir,"regional_effects.csv"),row.names=FALSE,na="")
  writeLines(capture.output(sessionInfo()),file.path(output_dir,"sessionInfo.txt"))
  invisible(list(stage1=stage1,regional=pooled))
}

if (sys.nframe()==0) {
  args <- commandArgs(trailingOnly=TRUE)
  if (length(args)!=2) stop("Usage: Rscript code/modeling/two_stage_precipitation_mortality_dlm.R INPUT.csv OUTPUT_DIR")
  d <- if(grepl("\\.xlsx$",args[1],ignore.case=TRUE)) as.data.frame(readxl::read_excel(args[1])) else
    read.csv(args[1],stringsAsFactors=FALSE,colClasses=c(county="character",region="character"))
  run_analysis(d,args[2])
}
