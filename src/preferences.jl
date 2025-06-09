"""
    set_preferences!(args...)

Set preferences for JustSayIt. 
    
This function simply calls `Preferences.@set_preferences!`, in order to set the package to set preferences for to JustSayIt. For usage documentation beyond the example below refer to the documentation of `Preferences.@set_preferences!`.

# Example
```julia-repl
julia> using JustSayIt
julia> JustSayIt.set_preferences!("OPENAI_API_KEY"=>"your-api-key")
```
"""
set_preferences!(args...) = Preferences.@set_preferences!(args...)


"""
    load_preference(args...)

Load a preference for JustSayIt.

This function simply calls `Preferences.@load_preference`, in order to load the package to load preferences for to JustSayIt. For usage documentation beyond the example below refer to the documentation of `Preferences.@load_preference`.

# Example
```julia-repl
julia> using JustSayIt
julia> JustSayIt.load_preference("OPENAI_API_KEY")
"your-api-key"
```
"""
load_preference(args...) = Preferences.@load_preference(args...)


"""
    has_preference(args...)

Check if a preference exists for JustSayIt.

This function simply calls `Preferences.@has_preference`, in order to check the package to check preferences for to JustSayIt. For usage documentation beyond the example below refer to the documentation of `Preferences.@has_preference`.

# Example
```julia-repl
julia> using JustSayIt
julia> JustSayIt.has_preference("OPENAI_API_KEY")
true
```

"""
has_preference(args...) = Preferences.@has_preference(args...)


"""
    delete_preferences!(args...)

Delete preferences for JustSayIt.

This function simply calls `Preferences.@delete_preferences!`, in order to delete the package to delete preferences for to JustSayIt. For usage documentation beyond the example below refer to the documentation of `Preferences.@delete_preferences!`.

# Example
```julia-repl
julia> using JustSayIt
julia> JustSayIt.delete_preferences!("OPENAI_API_KEY")
julia> JustSayIt.has_preference("OPENAI_API_KEY")
false
"""
delete_preferences!(args...) = Preferences.@delete_preferences!(args...)



# function set_PT_preferences()
#     if !Preferences.has_preference("PromptingTools", "MODEL_CHAT")
#         Preferences.set_preferences!("PromptingTools", "MODEL_CHAT"=>LLM_DEFAULT_LOCALMODEL)
#     end
# end

# macro set_PT_preferences() set_PT_preferences() end
