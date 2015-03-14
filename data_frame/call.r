#' Call a function passing each row as arguments
#'
#' @param df           A data.frame whose columns represent function args
#' @param fun          The function to call
#' @param ...          Further arguments to pass to `fun`
#' @param result_only  Return only the result column instead of the data.frame
#' @param tidy         Try to convert the result into a data.frame
#' @return             A data frame with the function call results
call = function(df, fun, ..., result_only=FALSE, tidy=TRUE) {
    irow2result = function(i) {
        index_row = df[i,,drop=TRUE] # named list
        re = do.call(fun, c(index_row, args))

        if (tidy)
            re = as.data.frame(re)

        if (result_only)
            re
        else
            cbind(index_row, re)
    }

    args = list(...)
    result = lapply(seq_len(nrow(df)), irow2result)

    if (tidy)
        do.call(rbind, result)
    else
        result
}

#' Use hpc$Q to process data.frame on a cluster
#'
#' ..same args as above..
call_hpc = function() {
}
