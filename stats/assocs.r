# linear associations (anova-like)
.b = import('../base', attach_operators=FALSE)
.ar = import('../array')
`%catch%` = .b$`%catch%`

assocs = function(formula, subsets=NULL, group=NULL, min_pts=3, p_adjust="fdr") {
    # get data from parent.env
    formula_vars = all.vars(formula)
    data = sapply(formula_vars, function(x)
        as.matrix(base::get(x, envir=parent.env(environment()))),
        USE.NAMES=TRUE, simplify=FALSE
    )
    matrix_vars = formula_vars[sapply(data, ncol) > 1]

    # check groups
    if (!is.null(group) && !is.character(group))
        stop("group needs to be NULL or a character vector")
    diff = setdiff(group, matrix_vars)
    if (length(diff) > 0)
        stop(paste("Grouped iterations only make sense for matrix vars:", diff))

    if (!is.null(subsets))
        stop("subsets not implemented yet")

    #TODO: add 'subset' to data?
    # p-adjust: group by term, adjust for each
    .assocs_subset(formula, data, group, min_pts)
}

.assocs_subset = function(formula, data, group=NULL, min_pts=3) {
    formula_vars = all.vars(formula)
    matrix_vars = formula_vars[sapply(formula_vars, function(x) ncol(data[[x]]) > 1)]

    # create a data.frame that provides indices for formula data given
    anchor = group[1]
    grouped = group[2:length(group)]
    ungrouped = setdiff(formula_vars, grouped)
    index = do.call(.b$expand_grid, sapply(ungrouped, function(x)
        .b$descriptive_index(data[[x]], along=2),
        USE.NAMES=TRUE, simplify=FALSE)
    )
    for (var in grouped)
        index[[var]] = index[[anchor]]

    # replace data by their subsets, call assocs function with all of them
    irow2result = function(i) {
        index_row = index[i,,drop=TRUE] # named list
        cur_data = data[setdiff(formula_vars, matrix_vars)]
        for (var in matrix_vars)
            cur_data[[var]] = data[[var]][,index_row[[var]]]
        .lm(formula, data=na.omit(as.data.frame(cur_data)), params=index_row)
    }
    do.call(rbind, lapply(1:nrow(index), irow2result))
}

.lm = function(formula, data, params) {
    rownames(params) = NULL
    cbind(params, broom::tidy(lm(formula, data=data)), size=nrow(data)) #%catch% NULL
#TODO: handle num_pts
#TODO: NA better?
}

.cox = function(formula) {
}

# this will be somewhat complicated
.sem = function(formula) {
}
