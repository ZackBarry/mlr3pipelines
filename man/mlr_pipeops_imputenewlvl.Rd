% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/PipeOpImputeNewlvl.R
\name{mlr_pipeops_imputenewlvl}
\alias{mlr_pipeops_imputenewlvl}
\alias{PipeOpImputeNewlvl}
\title{PipeOpImputeNewlvl}
\format{
\code{\link{R6Class}} object inheriting from \code{\link{PipeOpImpute}}/\code{\link{PipeOp}}.
}
\description{
Impute factorial features by adding a new level \code{".MISSING"}.
}
\section{Construction}{
\preformatted{PipeOpImputeNewlvl$new(id = "imputenewlvl", param_vals = list())
}
\itemize{
\item \code{id} :: \code{character(1)}\cr
Identifier of resulting object, default \code{"imputenewlvl"}.
\item \code{param_vals} :: named \code{list}\cr
List of hyperparameter settings, overwriting the hyperparameter settings that would otherwise be set during construction. Default \code{list()}.
}
}

\section{Input and Output Channels}{

Input and output channels are inherited from \code{\link{PipeOpImpute}}.

The output is the input \code{\link[mlr3:Task]{Task}} with all affected factorial features missing values imputed by a new level.
}

\section{State}{

The \verb{$state} is a named \code{list} with the \verb{$state} elements inherited from \code{\link{PipeOpImpute}}.

The \verb{$state$model} contains only \code{NULL} elements.
}

\section{Parameters}{

The parameters are the parameters inherited from \code{\link{PipeOpImpute}}.
}

\section{Internals}{

Adds an explicit new \code{level()} to \code{factor} and \code{ordered} features, but not to \code{character} features.
}

\section{Methods}{

Only methods inherited from \code{\link{PipeOpImpute}}/\code{\link{PipeOp}}.
}

\examples{
library("mlr3")

data = data.table::data.table(x = factor(rep.int(c("y", "n"), times = 5)),
  y = factor(c(NA, letters[2:9], NA)), z = factor(letters[1:10]))
task = TaskClassif$new("task", backend = data, target = "x")
task$missings()

po = po("imputenewlvl")
new_task = po$train(list(task = task))[[1]]
new_task$missings()
new_task$data()
}
\seealso{
Other PipeOps: 
\code{\link{PipeOpEnsemble}},
\code{\link{PipeOpImpute}},
\code{\link{PipeOpProxy}},
\code{\link{PipeOpTargetTrafo}},
\code{\link{PipeOpTaskPreproc}},
\code{\link{PipeOp}},
\code{\link{mlr_pipeops_boxcox}},
\code{\link{mlr_pipeops_branch}},
\code{\link{mlr_pipeops_chunk}},
\code{\link{mlr_pipeops_classbalancing}},
\code{\link{mlr_pipeops_classifavg}},
\code{\link{mlr_pipeops_classweights}},
\code{\link{mlr_pipeops_colapply}},
\code{\link{mlr_pipeops_collapsefactors}},
\code{\link{mlr_pipeops_copy}},
\code{\link{mlr_pipeops_datefeatures}},
\code{\link{mlr_pipeops_encodeimpact}},
\code{\link{mlr_pipeops_encodelmer}},
\code{\link{mlr_pipeops_encode}},
\code{\link{mlr_pipeops_featureunion}},
\code{\link{mlr_pipeops_filter}},
\code{\link{mlr_pipeops_fixfactors}},
\code{\link{mlr_pipeops_histbin}},
\code{\link{mlr_pipeops_ica}},
\code{\link{mlr_pipeops_imputehist}},
\code{\link{mlr_pipeops_imputemean}},
\code{\link{mlr_pipeops_imputemedian}},
\code{\link{mlr_pipeops_imputemode}},
\code{\link{mlr_pipeops_imputesample}},
\code{\link{mlr_pipeops_kernelpca}},
\code{\link{mlr_pipeops_learner}},
\code{\link{mlr_pipeops_missind}},
\code{\link{mlr_pipeops_modelmatrix}},
\code{\link{mlr_pipeops_mutate}},
\code{\link{mlr_pipeops_nop}},
\code{\link{mlr_pipeops_pca}},
\code{\link{mlr_pipeops_quantilebin}},
\code{\link{mlr_pipeops_regravg}},
\code{\link{mlr_pipeops_removeconstants}},
\code{\link{mlr_pipeops_scalemaxabs}},
\code{\link{mlr_pipeops_scalerange}},
\code{\link{mlr_pipeops_scale}},
\code{\link{mlr_pipeops_select}},
\code{\link{mlr_pipeops_smote}},
\code{\link{mlr_pipeops_spatialsign}},
\code{\link{mlr_pipeops_subsample}},
\code{\link{mlr_pipeops_targetinverter}},
\code{\link{mlr_pipeops_targettrafoscalerange}},
\code{\link{mlr_pipeops_targettrafosimple}},
\code{\link{mlr_pipeops_textvectorizer}},
\code{\link{mlr_pipeops_threshold}},
\code{\link{mlr_pipeops_unbranch}},
\code{\link{mlr_pipeops_updatetarget}},
\code{\link{mlr_pipeops_yeojohnson}},
\code{\link{mlr_pipeops}}

Other Imputation PipeOps: 
\code{\link{PipeOpImpute}},
\code{\link{mlr_pipeops_imputehist}},
\code{\link{mlr_pipeops_imputemean}},
\code{\link{mlr_pipeops_imputemedian}},
\code{\link{mlr_pipeops_imputemode}},
\code{\link{mlr_pipeops_imputesample}}
}
\concept{Imputation PipeOps}
\concept{PipeOps}
