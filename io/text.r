# I/O helper functions on text files
b = import('base', attach_operators=F)

#' Add \code{ext}ension parameter to \link{\code{base::file.path}}
file_path = function (..., ext = NULL, fsep = .Platform$file.sep) {
    dots = list(...)
    if (! is.null(ext)) {
        ilast = length(dots)
        dots[ilast] = sprintf('%s.%s', dots[ilast], sub('^\\.', '', ext))
    }

    do.call(base::file.path, c(dots, fsep = fsep))
}

#' Augment \code{\link{utils::read.table}} by a mechanism to guess the file format.
#'
#' For the moment, only separators are handled based on the file extension.
#' This might change in the future to be more powerful, think Python’s
#' \code{csv.Sniffer} class.
read_table = function (file, ..., text, stringsAsFactors=F) {
    args = list(...)
    if (missing(file))
        return(do.call(utils::read.table, c(args, text = text)))

    if (! ('sep' %in% names(args))) {
        separators = list('.csv' = ',',
                          '.tsv' = '\t',
                          '.txt' = '\t')
        extension = b$grep('(\\.\\w+)(\\.gz)?$', file)[1]
        args$sep = separators[[extension]]
    }

    args$file = file
    args$stringsAsFactors = stringsAsFactors

    if (extension == ".xlsx")
        do.call(xlsx::read.xlsx, args)
    else
        do.call(utils::read.table, args)
}

read_full_table = function(file, sep="\t", stringsAsFactors=F, ...) {
    index = utils::read.table(file, sep=sep, stringsAsFactors=stringsAsFactors, ...)
    colnames(index) = index[1,]
    rownames(index) = index[,1]
    index[-1,-1]
}
