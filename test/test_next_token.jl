using Test
using JustSayIt
using JustSayIt.API
using PyCall
import JustSayIt: DEFAULT_MODEL_NAME, TYPE_MODEL_NAME, MODELDIR_PREFIX, DEFAULT_NOISES
import JustSayIt: recognizer, noises


# Test setup
commands = Dict("help" => Help.help,
                "type" => Keyboard.type)
modeldirs = Dict(DEFAULT_MODEL_NAME => joinpath(MODELDIR_PREFIX, "vosk-model-small-en-us-0.15"),
                 TYPE_MODEL_NAME    => joinpath(MODELDIR_PREFIX, "vosk-model-small-en-us-0.15"))
init_jsi(commands, modeldirs, DEFAULT_NOISES)


@testset "$(basename(@__FILE__))" begin
    @testset "1. dynamic recognizers" begin
        valid_input = ["world", "universe"]
        @test isa(recognizer(valid_input, noises(DEFAULT_MODEL_NAME)), PyObject)
        @test isa(recognizer(valid_input, noises(TYPE_MODEL_NAME); modelname=TYPE_MODEL_NAME), PyObject)
    end;
end;

# Test tear down
finalize_jsi()
