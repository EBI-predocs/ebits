# some operators for R

`%or%` = function(a, b) {
    cmp = function(a,b) if (identical(a, FALSE) || 
                            is.null(a) || 
                            is.na(a) || 
                            is.nan(a) || 
                            length(a) == 0) b else a

    if (is.list(a))
        lapply(1:length(a), function(i) cmp(a[[i]], b[[i]]))
    else if (length(a) > 1)
        mapply(cmp, a, b)
    else
        cmp(a, b)
}

`%OR%` = function(a, b) {
    tryCatch(
        a %or% b,
        error = function(e) b
    )
}

`%catch%` = function(a, b) {
    tryCatch(
        a,
        error = function(e) b
    )
}
