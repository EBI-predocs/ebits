###
### general utility functions without specific use
###
.omit = import('./omit')

#' match() function with extended functionality
#'
#' @param x            Vector of identifiers that should be mapped
#' @param from         Vector of identifiers that can be mapped
#' @param to           Matched mapping for all identifiers
#' @param filter_from  Restrict matching to a subset from `from`
#' @param filter_to    Restrict matching to a subset from `to`
#' @param fuzzy_level  0 for exact, 1 punctuation, and 2 closest character
#' @param table        Return a matching table instead of just the matches
#' @param na_rm        Flag to remove items that can not be mapped
match = function(x, from, to, filter_from=NULL, filter_to=NULL,
                 fuzzy_level=0, table=FALSE, na_rm=FALSE) {
    # filter matching table
    if (!is.null(filter_from))
        to[!from %in% filter_from] = NA
    if (!is.null(filter_to))
        to[!to %in% filter_to] = NA

    # 1st iteration: exact matches
    index = list(level0 = base::match(x, from))

    # 2nd iteration: non-punctuation exact matches
    if (fuzzy_level > 0) {
        FROM = stringr::str_replace_all(toupper(from), "[[:punct:]]", "")
        x = stringr::str_replace_all(x, "[[:punct:]]", "")
        index$level1 = base::match(x, FROM)
    }

    # 3rd iteration: closest string matches w/o punctuation
    if (fuzzy_level > 1) {
        distances = adist(FROM, x)
        mind = apply(distances, 2, min)
        nmin = sapply(1:length(mind), function(i) sum(mind[i]==distances[,i]))
        mind[nmin>1] = NA # no non-unique matches
        index$level2 = sapply(1:length(mind), function(i)
            which(distances[,i]==mind[i]) %or% NA)
    }

    # return best match
    from = from[index[[1]]]
    index = lapply(index, function(i) to[i])
    b = import('./operators', attach_operators=FALSE)
    re = Reduce(b$`%or%`, index)

    if (table && fuzzy_level == 0)
        .omit$na(cbind(x=x, to=re), omit=na_rm)
    else if (table && fuzzy_level > 0)
        .omit$na(cbind(x=x, from=from, to=re, as.data.frame(index)),
                 cols=c('x','to'), omit=na_rm)
    else
        .omit$na(setNames(re, from), omit=na_rm)
}

#' duplicated() function with extended functionality
#'
#' @param ...     Arguments to be passed to R's `duplicated()`
#' @param all     Return all instances of duplicated entries
#' @param random  Randomly select with entry is marked as duplicate
duplicated = function(x, ..., all=F, random=F) {
    if (all && random)
        stop("Can not return all and randomly selected duplicates")

    if (all)
        base::duplicated(x, ...) | base::duplicated(x, ..., fromLast=TRUE)
    else if (random) { # stat.ethz.ch/pipermail/r-help/2010-June/241244.html
        if ( is.vector(x) ) {
            permutation = sample(length(x))
            x.perm      = x[permutation]
            result.perm = duplicated(x.perm, ...)
            result      = result.perm[order(permutation)]
            return(result)
        }
        else if ( is.matrix(x) ) {
            permutation = sample(nrow(x))
            x.perm      = x[permutation,]
            result.perm = duplicated(x.perm, ...)
            result      = result.perm[order(permutation)]
            return(result)
        }
        else {
            stop(paste("duplicated.random() only supports vectors",
            "matrices for now."))
        }
    }
    else
        base::duplicated(x, ...)
}

#' intersect() function that takes an arbitrary number of elements
#'
#' @param ...  Arbitrary elements that `base::intersect` should be called on
intersect = function(...) {
    Reduce(base::intersect, list(...))
}

