###
### general utility functions without specific use
###
.op = import_('./operators', attach_operators=FALSE)
.omit = import_('./omit')

#' match() function with extended functionality
#'
#' The function maps the vector `x` with the possible values `from` to their
#' corresponding values `to`.
#'
#' This either input or output of the matching table (`from`, `to`) are
#' factors, they will be converted to characters in order to rule out matching
#' numerical representation of factors.
#'
#' @param x            Vector of identifiers that should be mapped
#' @param from         Vector of identifiers that can be mapped
#' @param to           Matched mapping for all identifiers
#' @param filter_from  Restrict matching to a subset from `from`
#' @param filter_to    Restrict matching to a subset from `to`
#' @param data         List containing the data `from` and `to` reference
#' @param fuzzy_level  0 for exact, 1 punctuation, and 2 closest character
#' @param table        Return a matching table instead of just the matches
#' @param na_rm        Flag to remove items that can not be mapped
match = function(x, from, to, filter_from=NULL, filter_to=NULL, data=parent.frame(),
                 fuzzy_level=0, table=FALSE, na_rm=FALSE, warn=!table && fuzzy_level>0) {

    if (is.character(from) && length(from) == 1)
        from = data[[from]]
    if (is.character(to) && length(to) == 1)
        to = data[[to]]

    if (length(from) != length(to))
        stop("arguments `from` and `to` need to be of the same length")

    # avoid matching its with different level names
    if (is.factor(from))
        from = as.character(from)
    if (is.factor(to))
        to = as.character(to)

    # filter matching table
    if (!is.null(filter_from))
        to[!from %in% filter_from] = NA
    if (!is.null(filter_to))
        to[!to %in% filter_to] = NA

    # remove identical mappings, then map ambivalent to NA
    df = .omit$dups(data.frame(from=from, to=to, stringsAsFactors=FALSE))
    df$to[duplicated(df$from, all=TRUE)] = NA
    df = .omit$dups(df)
    from = df$from
    to = df$to

    # 1st iteration: exact matches
    index = list(level0 = base::match(x, from))

    # 2nd iteration: non-punctuation exact matches
    if (fuzzy_level > 0) {
        FROM = stringr::str_replace_all(toupper(from), "[[:punct:]\\ ]", "")
        x_match = stringr::str_replace_all(toupper(x), "[[:punct:]\\ ]", "")
        index$level1 = base::match(x_match, FROM)
    }

    #TODO: insert iteration here that does closest string matches, but does not
    #  map two different strings to the same fuzzy match

    # 3rd iteration: closest string matches w/o punctuation
    if (fuzzy_level > 1) {
        distances = adist(FROM, x_match)
        mind = apply(distances, 2, min)
        nmin = sapply(1:length(mind), function(i) sum(mind[i]==distances[,i]))
        mind[nmin>1] = NA # no non-unique matches
        index$level2 = sapply(1:length(mind), function(i)
            .op$`%or%`(which(distances[,i]==mind[i]), NA))
    }

    # return best match
    re = Reduce(.op$`%or%`, index)
    from = from[re]
    to = to[re]

    if (warn && any(x != from)) {
        warning("Non-exact matches detected")
        print(na.omit(data.frame(x=x, from=from)[x!=from,]))
    }

    if (table && fuzzy_level == 0)
        .omit$na(data_frame(x=x, to=to), omit=na_rm)
    else if (table && fuzzy_level > 0)
        .omit$na(data_frame(x=x, from=from, to=to), cols=c('x','to'), omit=na_rm)
    else
        .omit$na(setNames(to, x), omit=na_rm)
}
