module Exceptions

export @ArgumentError, @APIUsageError, @ArgumentEvaluationError, @FileError, @IncoherentArgumentError, @InsecureRecognitionException, @KeywordArgumentError
export                  APIUsageError,  ArgumentEvaluationError,  FileError,  IncoherentArgumentError,  InsecureRecognitionException,  KeywordArgumentError


macro ArgumentError(msg) esc(:(throw(ArgumentError($msg)))) end
macro APIUsageError(msg) esc(:(throw(APIUsageError($msg)))) end
macro ArgumentEvaluationError(msg) esc(:(throw(ArgumentEvaluationError($msg)))) end
macro FileError(msg) esc(:(throw(APIUsageError($msg)))) end
macro IncoherentArgumentError(msg) esc(:(throw(IncoherentArgumentError($msg)))) end
macro InsecureRecognitionException(msg) esc(:(throw(InsecureRecognitionException($msg)))) end
macro KeywordArgumentError(msg) esc(:(throw(KeywordArgumentError($msg)))) end


struct APIUsageError <: Exception
    msg::String
end
Base.showerror(io::IO, e::APIUsageError) = print(io, "APIUsageError: ", e.msg)

struct ArgumentEvaluationError <: Exception
    msg::String
end
Base.showerror(io::IO, e::ArgumentEvaluationError) = print(io, "ArgumentEvaluationError: ", e.msg)

struct FileError <: Exception
    msg::String
end
Base.showerror(io::IO, e::FileError) = print(io, "FileError: ", e.msg)

struct InsecureRecognitionException <: Exception
    msg::String
end
Base.showerror(io::IO, e::InsecureRecognitionException) = print(io, "InsecureRecognitionException: ", e.msg)

struct IncoherentArgumentError <: Exception
    msg::String
end
Base.showerror(io::IO, e::IncoherentArgumentError) = print(io, "IncoherentArgumentError: ", e.msg)

struct KeywordArgumentError <: Exception
    msg::String
end
Base.showerror(io::IO, e::KeywordArgumentError) = print(io, "KeywordArgumentError: ", e.msg)

end # Module Exceptions
