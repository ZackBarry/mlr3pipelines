# Caching

These docs describe `oportunistic caching`, i.e. caching after a first function call.
If the same function is executed twice in parallel, this does not save any time/cores.
The example currently uses the `R.cache` package by Henrik Bengtsson for caching.
This is just a very simple caching package, that provides a clean, simple API, could
theoretically be replaced by other packages.

Caching can / should be done on two levels:
  - caching of individual pipeops
  - caching of full graphs

## Implementation Details

Ideally we would like to do caching on an abstract level,
perhaps within the PipeOp base-classes `$train` function.
A very nice point would be to wrap the call to `private$.train`.
This would make complexity very manageable.

`R.cache::evalWithMemoization` memoizes the provided expression.
The `hash` is computed from its `key` argument.

~~Possible solution: adjust `PipeOp` in `PipeOp.R`
```
train = function(input) {
      ...
      t = check_types(self, input, "input", "train")
      # caching
      R.cache::evalWithMemoization({
        result = list(private$.train(input), self$state) #(see A below)
        }, key = list(map_chr(input, get_hash), self$hash)
      )
      if (is.null(self$state)) state = result$state #(see A below)
      output = check_types(self, result$output, "output", "train")
      output
    },
    predict = function(input) {
      ...
      input = check_types(self, input, "input", "predict")
      R.cache::evalWithMemoization({
        output = private$.predict(input)
        },
         key = list(map_chr(input, get_hash), self$hash)
      )
      output = check_types(self, output, "output", "predict")
      output
    }
  ),
```
~~

or alternatively in `graph_reduce`:

The call to `op[[fun]](input)` calls the `PipeOp's` "train" and "predict" fun.

```
    R.cache::evalWithMemoization(
      {res_out = list(output = op[[fun]](input), state = op$state)},
      key = list(map_chr(input, get_hash), op$hash)
    )
    if (is.null(op$state) && fun == "train") op = res_out$state # write cached state
    output = res_out$output
```   

where `get_hash` is:
```
get_hash = function(x) {
  if (!is.null(x$hash)) return(x$hash)
    digest(x, algo = "xxhash64")
}
```

**Alternative:**

Caching could also be done in `reduce_graph`. This would also simplify caching
whole graph vs. single pipeops.

## Possible problems:

A) Unfortunately `private$.train()` is not a pure function, but
   instead has side-effects:
    - sets a `$state`
    - ... (others?)

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

H) Should caching be disabled for some `PipeOp`s?
   Yes, possible solution: New field in each `PipeOp`: `cached`.
   Caching for a pipeop only happens if `cached = TRUE`.
   Can also be manually changed to disable caching for any pipeop.

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

