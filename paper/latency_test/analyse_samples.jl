using Statistics
lines = readlines("samples.txt")
samples = parse.(Int64, filter.(isdigit, lines[7:106]))
minimum(samples)
maximum(samples)
median(samples)

