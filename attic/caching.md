# Caching

These docs describe `oportunistic caching`, i.e. caching after a first function call.
If the same function is executed twice in parallel, this does not save any time/cores.
The example currently uses the `R.cache` package by Henrik Bengtsson for caching.
This is just a very simple caching package, that provides a clean, simple API, could
theoretically be replaced by other packages.


## Preliminaries

- Pipelines should be cached at a PipeOp level, as there are rarely situations where 
  caching a full Graph would be required (e.g. tuning a graph requires caching of individual steps).

- PipeOps could either cache `state` and `result` during training or alternatively only `state`
  when `predict` is comparatively cheap and the same transform steps can be done during `train`
  and `predict`. For now we will call the latter pipeops `"predict_like_train"`.
  This should be annotated in each `PipeOp`. Can default to `"predict_like_train"`.

- PipeOps can be **stochastic**, either during `"train"`, `"predict"`, `"both"` or `"deterministic"`.
  Implementation suggestion:
  ```
  stochastic = c("train", "predict", "character(0)") # "character(0)" means not stochastic.
  ```
  This needs to be annotated in each `PipeOp`. Could default to `"deterministic"`.

- Caching can be turned on / off for individual a full `Graph` or individual `PipeOps`.
  API for this could e.g. be: 
  - `Graph` has a `cache` slot, can be set to `TRUE` or `FALSE`, Default `FALSE`?
  - `PipeOp` has a `cache` slot, can be set to `TRUE` or `FALSE`, Default `TRUE`?
    `PipeOp`s that should never be cached (stochastic, meta, ...) are set to `FALSE`.
  - If `Graph$cache && PipeOp$cache`, caching is active.


## Implementation Details

Ideally we would like to do caching on an abstract level, instead of writing a caching mechanism
for each `PipeOp`.

`R.cache::evalWithMemoization` memoizes the provided expression.
The `hash` is computed from its `key` argument.

Possible solution: apply caching in `graph_reduce` (`Graph.R`):

The call to `op[[fun]](input)` calls each `PipeOp's` "train" and "predict" fun.

```
    if (self$cache && op$cache) { # caching can be enabled / disabled
      R.cache::evalWithMemoization(
        {res_out = list(output = op[[fun]](input), state = op$state)},
        key = list(map_chr(input, get_hash), op$hash) # hash of input and hash of pipeop (latter includes param_vals)
      )
      if (is.null(op$state) && fun == "train") op = res_out$state # write cached state
      output = res_out$output
    } else {
      output = list(output = op[[fun]](input), state = op$state)
    }
```   

where `get_hash` is:
```
get_hash = function(x) {
  if (!is.null(x$hash)) return(x$hash)
    digest(x, algo = "xxhash64")
}
```


## Possible problems:

A) Unfortunately `private$.train()` is not a pure function, but
   instead has side-effects:
    - sets a `$state`

If we can ensure that the only side-effect of `$.train` is a modified state, 
we could also memoize the state during `$train` (see above).
If other fields are updated, we need to have a list of fields that are updated or go a different route.

## Further Issues:

F) Should caching be optional? 
   Probably yes!

G) How do we globally enable/disable caching?
    1. global option
    < ugly, might not work with parallelization. >

    2. caching can be turned on in `Graph` | `GraphLearner`
    ```
    Graph = R6Class(
     ...
     caching = TRUE,
     ...
    )
    ```
    `GraphLearner` gets an active binding to turn caching of it's graph on/off.
    Could also be added as an arg to the `GraphLearner`s constructor.

    The caching of individual steps is then done by adjusting calls to `graph_reduce`:
    `graph_reduce(..., caching = self$caching)`

H) Caching for some `PipeOp`s can be manually changed to disable caching for any pipeop.

Open Questions:
  - How do `$train` and `$predict` know whether to do caching or not?
    Add a second argument `caching`?
  - How do caching and `parallelization` interact?
  - Does `R.cache::evalWithMemoization`s `key` arg need anything else?
  - If `state` is obtained from a stochastic function, how do we want this to behave?

From @mb706:

- PipeOps should contain metadata about whether they are deterministic or not, and whether 
  their .train() and .predict() results are the same whenever the input to both is the same (use common vs. separate cache)

  **Possible solution**

  1. Add a new field:
  ```
  cacheable = TRUE  # or deterministic = TRUE
  ```
  only `PipeOp`s where this holds are beeing cached.

  2. For `cacheable = FALSE`, the `.Random.seed` is added to the caching `key`. 
     This would allow to cache reproducible workflows.

- with some operations it may make more sense to save just the $state and not the result.
  Then during $train() the caching mechanism can set the state from cache and call $.predict().

  Question: How do we decide this? We should maybe think about an **API** for this.

### Caching a full graph

- caching in mlrCPO was a wrapper-PipeOp, we could also have that here. 
  Pro: For multiple operations only the last output needs to be saved; makes the configuration of different caching mechanisms easier. 
  Cons: We get the drawbacks of wrapping: the graph structure gets obscured. Also when wrapping multiple operations and just one of them is nondeterministic everything falls apart. We may want a ppl() function that wraps a graph optimally so that linear deterministic segments are cached together and only the output of the last PipeOp is kept. (Also works for arbitrary Graphs).

  Comments:
  - Caching the graph: Yes!
    Caching segments of the graph? 
    This makes things unneccessarily complicated. We could instead either cache the whole graph **or** if any po is nondeterministic, cache only deterministic pipeops.

  - **Possible solution**
    1. Wrap the graph as described above with pro's, con's.

    2. Cache the graph's `$reduce_graph` method in `$train, $predict` (in `Graph.R`)
       similarly to how `PipeOp`s are cached above.
       This is only possible if all po's in a graph are deterministic.


### Caching non-deterministic `PipeOp`s

This could be done if we add `Random.seed` to the `key`. 
Additionally we would have to advance the `Random.seed` properly.
This could be added in future work, but might not be relevant now.

It should be possible to enforce caching for stochastic `PipeOp`s.
Example: I want to evaluate choices (branches) made after or before a stochastic pipeop.
         This would allow me to circumvent stochasticity.


### User Control for caching

This basically could be handled via `R.cache`'s functionality, but should somehow be documented.

### Testthat

How do we disable caching during `unit` tests.