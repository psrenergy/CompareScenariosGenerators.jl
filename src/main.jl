function finish_path(path::String)
    if isempty(path)
        return path
    end
    if isfile(path)
        return normpath(path)
    end
    if Sys.islinux() && path[end] != '/'
        return normpath(path * "/")
    elseif Sys.iswindows() && path[end] != '\\'
        return normpath(path * "\\")
    else
        return normpath(path)
    end
end
function parse_evaluation_loop_cmdline(args)
    s = ArgParse.ArgParseSettings()

    ArgParse.@add_arg_table! s begin
        "evaluation_config_path"
        help = "path to evaluation_config.toml"
        arg_type = String
    end
    # dump args into dict
    parsed_args = ArgParse.parse_args(args, s)

    # Possibly fix paths and apply the normpath method
    parsed_args["evaluation_config_path"] =
        finish_path(parsed_args["evaluation_config_path"])
    if !isfile(parsed_args["evaluation_config_path"])
        error("The file " * parsed_args["evaluation_config_path"] * " does not exist.")
    end

    return parsed_args
end

function parse_report_metrics_cmdline(args)
    s = ArgParse.ArgParseSettings()

    ArgParse.@add_arg_table! s begin
        "model_execution_jsons"
        help = "path to multiple json files with reported metrics"
        nargs = '*'
        arg_type = String
    end
    # dump args into dict
    parsed_args = ArgParse.parse_args(args, s)

    return parsed_args
end

function main_evaluation_loop(args)
    @info("CompareScenariosGenerators - version: $_VERSION")

    # Funções para validar os argumentos
    parsed_args = parse_evaluation_loop_cmdline(args)

    # If the mode is to evaluate models
    result_dir, elapsed_time = @timed evaluate_model(parsed_args)

    elapsed_time_file = open(joinpath(result_dir,"elapsed_time.txt"), "w")
    write(elapsed_time_file, "Model execution time : $elapsed_time seconds\n")


    return 0
end

function main_report_metrics(args)
    @info("CompareScenariosGenerators - version: $_VERSION")

    # Funções para validar os argumentos
    parsed_args = parse_report_metrics_cmdline(args)

    # If the mode is to evaluate models
    report_metrics(parsed_args)

    return 0
end

function jl_evaluation_loop()::Cint
    return main_evaluation_loop(ARGS)
end

function jl_report_metrics()::Cint
    return main_report_metrics(ARGS)
end