using Base.Threads
using TaskScheduling
using Base.Test

# Simple test
flag = false
submit() do
    global flag = true
end
runtasks()
@test flag == true

# Run many trivial tasks
counter = Atomic{Int}(0)
for i in 1:100
    submit() do
        global counter
        atomic_add!(counter, 1)
    end
end
runtasks()
@test counter[] == 100

# Run a long sequence of tasks
counter = Atomic{Int}(0)
function run1(i::Integer)
    global counter
    i==0 && return
    atomic_add!(counter, 1)
    submit() do
        run1(i-1)
    end
end
submit() do
    run1(100)
end
runtasks()
@test counter[] == 100

# Run a tree of tasks
counter = Atomic{Int}(0)
function run2(i::Integer)
    global counter
    i==0 && return
    atomic_add!(counter, 1)
    j = i-1
    j1 = div(j,2)
    j2 = j - j1
    submit() do
        run2(j1)
    end
    submit() do
        run2(j2)
    end
end
submit() do
    run2(100)
end
runtasks()
@test counter[] == 100

# A real-world example
mats = Matrix{Float64}[]
for i in 1:100
    sz = rand(10:100)
    A = rand(sz,sz)
    push!(mats, A)
end
svds = Vector{Any}(100)
for i in 1:100
    submit() do
        svds[i] = svd(mats[i])
    end
end
runtasks()
for i in 1:100
    @test isa(svds[i][2], Vector{Float64})
end
