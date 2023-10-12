import Pkg
Pkg.activate(dirname(@__DIR__))
Pkg.instantiate()

using CompareScenariosGenerators
# Colocar todas funções que devem ser compiladas
CompareScenariosGenerators.main_evaluation_loop([joinpath(dirname(@__DIR__), "test", "execution_example", "evaluation_config.toml")])
CompareScenariosGenerators.main_report_metrics([joinpath(dirname(@__DIR__), "test", "execution_example", "results_random_forecast", "metrics.json")])
