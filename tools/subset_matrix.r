import_package('ompr', attach=TRUE)
import_package('dplyr', attach=TRUE)
.solver = import_package('ROI.plugin.cplex')

#' Subset a big matrix to maximise contained value with rows and columns
#'
#' @param A      The matrix to subset
#' @param nrows  Number of rows to keep in the subset
#' @param ncols  Number of columns to keep in subset
#' @param symmetric  Consider A symmetric (and subset only same indices)
#' @param return_indices  Return indices instead of subsetted matrix
#' @return       A submatrix of mat which maximises its content
subset_matrix = function(A, nrows, ncols=nrows, symmetric=FALSE,
                         return_indices=FALSE) {
    model = MIPModel() %>%
        add_variable(keep_el[i, j], i=1:nrow(A), j=1:ncol(A), type="binary") %>%
        add_variable(keep_row[i], i=1:nrow(A), type="binary") %>%
        add_variable(keep_col[j], j=1:ncol(A), type="binary") %>%

        add_constraint(sum_expr(keep_el[i, j], j=1:ncol(A)) <=
                       keep_row[i] * ncols, i=1:nrow(A)) %>%
        add_constraint(sum_expr(keep_el[i, j], i=1:nrow(A)) <=
                       keep_col[j] * nrows, j=1:ncol(A)) %>%

        add_constraint(sum_expr(keep_row[i], i=1:nrow(A)) == nrows) %>%
        add_constraint(sum_expr(keep_col[j], j=1:ncol(A)) == ncols)

    if (symmetric) {
        if (nrow(A) != ncol(A))
            stop("Matrix needs to be square if symmetric=TRUE")
        model = model %>%
            add_constraint(keep_row[i] == keep_col[i], i=1:nrow(A))
    }

    result = model %>%
        set_objective(sum_expr(keep_el[i, j] * A[i, j], 
                      i=1:nrow(A), j=1:ncol(A)), "max") %>%
        solve_model(ompr.roi::with_ROI("cplex"))

    if (result$status != "optimal")
        warning("Solver status: ", result$status)

    rows = which(result$solution[sprintf("keep_row[%i]", 1:nrow(A))] == 1)
    cols = which(result$solution[sprintf("keep_col[%i]", 1:ncol(A))] == 1)

    if (return_indices && symmetric)
        rows
    else if (return_indices)
        list(rows, cols)
    else
        A[rows, cols]
}

if (is.null(module_name())) {
    A = matrix(rnorm(20), ncol=4, nrow=5)
}
