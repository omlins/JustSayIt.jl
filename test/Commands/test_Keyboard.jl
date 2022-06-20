using Test
using JustSayIt
using JustSayIt.API
using PyCall
import JustSayIt: MODELNAME, MODELDIR_PREFIX, DEFAULT_NOISES, COMMAND_RECOGNIZER_ID
import JustSayIt: init_jsi, finalize_jsi, recognizer, noises, reader, start_reading, stop_reading, read_wav, set_default_streamer, reset_all, _are_next


# Test setup
const SAMPLEDIR_TYPE    = joinpath("samples", "type")
const SAMPLEDIR_SILENCE = joinpath("samples", "silence")

commands = Dict("help"      => Help.help,
                "type"      => Keyboard.type)
modeldirs = Dict(MODELNAME.DEFAULT.EN_US => joinpath(MODELDIR_PREFIX, "vosk-model-small-en-us-0.15"),
                 MODELNAME.TYPE.EN_US    => joinpath(MODELDIR_PREFIX, "vosk-model-small-en-us-0.15"))
init_jsi(commands, modeldirs, DEFAULT_NOISES)

and           = read_wav(joinpath(SAMPLEDIR_TYPE, "and.wav"))
a             = read_wav(joinpath(SAMPLEDIR_TYPE, "a.wav"))
colon         = read_wav(joinpath(SAMPLEDIR_TYPE, "colon.wav"))
comma         = read_wav(joinpath(SAMPLEDIR_TYPE, "comma.wav"))
c             = read_wav(joinpath(SAMPLEDIR_TYPE, "c.wav"))
digits        = read_wav(joinpath(SAMPLEDIR_TYPE, "digits.wav"))
dot           = read_wav(joinpath(SAMPLEDIR_TYPE, "dot.wav"))
eight         = read_wav(joinpath(SAMPLEDIR_TYPE, "eight.wav"))
exclamation   = read_wav(joinpath(SAMPLEDIR_TYPE, "exclamation.wav"))
five          = read_wav(joinpath(SAMPLEDIR_TYPE, "five.wav"))
four          = read_wav(joinpath(SAMPLEDIR_TYPE, "four.wav"))
interrogation = read_wav(joinpath(SAMPLEDIR_TYPE, "interrogation.wav"))
i             = read_wav(joinpath(SAMPLEDIR_TYPE, "i.wav"))
julia         = read_wav(joinpath(SAMPLEDIR_TYPE, "julia.wav"))
j             = read_wav(joinpath(SAMPLEDIR_TYPE, "j.wav"))
language      = read_wav(joinpath(SAMPLEDIR_TYPE, "language.wav"))
let_s         = read_wav(joinpath(SAMPLEDIR_TYPE, "let_s.wav"))
letters       = read_wav(joinpath(SAMPLEDIR_TYPE, "letters.wav"))
lowercase     = read_wav(joinpath(SAMPLEDIR_TYPE, "lowercase.wav"))
l             = read_wav(joinpath(SAMPLEDIR_TYPE, "l.wav"))
nine          = read_wav(joinpath(SAMPLEDIR_TYPE, "nine.wav"))
one           = read_wav(joinpath(SAMPLEDIR_TYPE, "one.wav"))
paragraph     = read_wav(joinpath(SAMPLEDIR_TYPE, "paragraph.wav"))
point         = read_wav(joinpath(SAMPLEDIR_TYPE, "point.wav"))
programming   = read_wav(joinpath(SAMPLEDIR_TYPE, "programming.wav"))
redo          = read_wav(joinpath(SAMPLEDIR_TYPE, "redo.wav"))
semicolon     = read_wav(joinpath(SAMPLEDIR_TYPE, "semicolon.wav"))
seven         = read_wav(joinpath(SAMPLEDIR_TYPE, "seven.wav"))
six           = read_wav(joinpath(SAMPLEDIR_TYPE, "six.wav"))
some          = read_wav(joinpath(SAMPLEDIR_TYPE, "some.wav"))
space         = read_wav(joinpath(SAMPLEDIR_TYPE, "space.wav"))
s             = read_wav(joinpath(SAMPLEDIR_TYPE, "s.wav"))
terminus      = read_wav(joinpath(SAMPLEDIR_TYPE, "terminus.wav"))
text          = read_wav(joinpath(SAMPLEDIR_TYPE, "text.wav"))
the           = read_wav(joinpath(SAMPLEDIR_TYPE, "the.wav"))
three         = read_wav(joinpath(SAMPLEDIR_TYPE, "three.wav"))
_try          = read_wav(joinpath(SAMPLEDIR_TYPE, "try.wav"))
two           = read_wav(joinpath(SAMPLEDIR_TYPE, "two.wav"))
type          = read_wav(joinpath(SAMPLEDIR_TYPE, "type.wav"))
undo          = read_wav(joinpath(SAMPLEDIR_TYPE, "undo.wav"))
uppercase     = read_wav(joinpath(SAMPLEDIR_TYPE, "uppercase.wav"))
u             = read_wav(joinpath(SAMPLEDIR_TYPE, "u.wav"))
words         = read_wav(joinpath(SAMPLEDIR_TYPE, "words.wav"))
_zero         = read_wav(joinpath(SAMPLEDIR_TYPE, "zero.wav"))

_05 = read_wav(joinpath(SAMPLEDIR_SILENCE, "silence_501ms.wav"))
_1  = read_wav(joinpath(SAMPLEDIR_SILENCE, "silence_1001ms.wav"))
_2  = read_wav(joinpath(SAMPLEDIR_SILENCE, "silence_2001ms.wav"))
_5  = read_wav(joinpath(SAMPLEDIR_SILENCE, "silence_5001ms.wav"))

tests_words  = Dict("the julia programming language" => [words; _5;   the; julia; programming; language;                                                    _5; terminus; _5],
                    "the julia programming"          => [words; _5;   the; julia; programming; _5; language; _5; undo;                                      _5; terminus; _5],
                    "the julia"                      => [words; _5;   the; julia; _5; undo; _5; undo; _5; redo; _5; redo; _5; redo;                         _5; terminus; _5],
                    "the Julia programming language" => [words; _5;   the; _5; uppercase; _5; julia; _5; uppercase; lowercase; _5; programming; language;   _5; terminus; _5],
                   );

tests_letters = Dict("julia"  => [letters; _5;   j; u; l; i; _05; a;                                              _5; terminus; _5],
                     "cscs"   => [letters; _5;   c; s; c; s;                                                      _5; terminus; _5],
                     "juli a" => [letters; _5;   j; u; l; i; _5; space; _5;  a;                                   _5; terminus; _5],
                     "cs"     => [letters; _5;   c; s; _5; j; u; _5; undo;                                        _5; terminus; _5],
                     "csc"    => [letters; _5;   c; s; _5; c; _5; undo; _5; undo; _5; redo; _5; redo; _5; redo;   _5; terminus; _5],
                    );

tests_digits  = Dict("05261.78 394" => [digits; _5;   _zero; five; two; six; one; _5; dot; _5; seven; eight; _5; space; _5; three; nine; four;   _5; terminus; _5],
                     "05"           => [digits; _5;   _zero; five; _5; six; _5; undo;                                                            _5; terminus; _5],
                     "056"          => [digits; _5;   _zero; five; _5; six; _5; undo; _5; undo; _5; redo; _5; redo; _5; redo;                    _5; terminus; _5],
                    );

tests_text    = Dict("Let's type some words: Julia programming."                             => [text; _5;   let_s; type; some; words;   _5; colon; _5;               uppercase; _5; julia; uppercase; lowercase; _5; programming; _5; point;                _5; terminus; _5],
                     "Let's type some letters: cscs."                                        => [text; _5;   let_s; type; some; letters; _5; colon; _5; letters; _5;  space; c; s; c; s; _5; point;                                                                                  _5; terminus; _5],
                     "Let's type some digits: 07.6."                                         => [text; _5;   let_s; type; some; digits;  _5; colon; _5; digits;  _5;  space; _zero; seven; dot; six; _5; point;                                                               _5; terminus; _5],
                     "Let's try some interrogation exclamation point and paragraph:.,:;!?\n" => [text; _5;   let_s; _try; some; interrogation; exclamation; point; and; paragraph; _5; colon;  point; comma; colon; semicolon; exclamation; interrogation; _5; paragraph;            _5; terminus; _5],
                     "Let's try some interrogation exclamation point and paragraph:.,:;!?"   => [text; _5;   let_s; _try; some; interrogation; exclamation; point; and; paragraph; _5; colon;  point; comma; colon; semicolon; exclamation; interrogation; _5; paragraph; _5; undo;  _5; terminus; _5],
                     "Let's try some interrogation exclamation point and paragraph."         => [text; _5;   let_s; _try; some; interrogation; exclamation; point; and; paragraph; _5;         undo; _5; undo; _5; redo; _5; redo; _5; redo; _5; point;                              _5; terminus; _5],
                    );


@testset "$(basename(@__FILE__))" begin
    @testset "1. type words (\"$test\")" for test in keys(tests_words)
        id = test
        start_reading(tests_words[test]; id=id)
        set_default_streamer(reader, id)
        @test test == Keyboard.type(; do_keystrokes=false)
        stop_reading(id=id)
    end;
    @testset "2. type letters (\"$test\")" for test in keys(tests_letters)
        id = test
        start_reading(tests_letters[test]; id=id)
        set_default_streamer(reader, id)
        @test test == Keyboard.type(; do_keystrokes=false)
        stop_reading(id=id)
    end;
    @testset "3. type digits (\"$test\")" for test in keys(tests_digits)
        id = test
        start_reading(tests_digits[test]; id=id)
        set_default_streamer(reader, id)
        @test test == Keyboard.type(; do_keystrokes=false)
        stop_reading(id=id)
    end;
    @testset "4. type text (\"$test\")" for test in keys(tests_text)
        id = test
        start_reading(tests_text[test]; id=id)
        set_default_streamer(reader, id)
        @test test == Keyboard.type(; do_keystrokes=false)
        stop_reading(id=id)
    end;
end;


# Test tear down
finalize_jsi()
