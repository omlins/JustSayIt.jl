using Test
using JustSayIt
using JustSayIt.API
using PyCall
import JustSayIt: DEFAULT_MODEL_NAME, TYPE_MODEL_NAME, MODELDIR_PREFIX, DEFAULT_NOISES
import JustSayIt: init_jsi, finalize_jsi

commands = Dict("help"      => Help.help,
                "type"      => Keyboard.type)
modeldirs = Dict(DEFAULT_MODEL_NAME => joinpath(MODELDIR_PREFIX, "vosk-model-small-en-us-0.15"),
                 TYPE_MODEL_NAME    => joinpath(MODELDIR_PREFIX, "vosk-model-small-en-us-0.15"))

init_jsi(commands, modeldirs, DEFAULT_NOISES)


@testset "$(basename(@__FILE__))" begin
    @testset "1. finalizing" begin
        finalize_jsi()
        @test true # meaning reached that point.
    end;
end;
