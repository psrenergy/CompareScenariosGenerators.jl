import Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()

using CompareScenariosGenerators

CompareScenariosGenerators.main_evaluation_loop(ARGS)
# CompareScenariosGenerators.main_report_metrics(ARGS)
