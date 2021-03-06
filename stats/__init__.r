export_submodule('./nmf')
export_submodule('./util')
export_submodule('./roc')
batch = import('./batch')
cor = import('./correlation')
discretize = import('./discretize')
fishers_exact_test = import('./fishers_exact_test')$fishers_exact_test
hypergeometric_test = import('./hypergeometric_test')$hypergeometric_test
signed_ks_test = import('./signed-ks-test')$ks.test.2

.wrap = import('../data_frame/wrap_formula_indexing')
for (fname in list.files(module_file('export_indexed'), "\\.r$", recursive=TRUE)) {
    .mod = import(paste0("./export_indexed/", sub("\\.r$", "", fname)))
    .FUN = ls(.mod)
    assign(.FUN, .wrap$wrap_formula_indexing(.mod[[.FUN]]))
}
