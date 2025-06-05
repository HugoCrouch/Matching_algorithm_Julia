using Random, Distributions, Statistics
using Plots
using DataFrames, CSV

# DA algorithm with "keep"-idea
# acceptor preference must be a dictionary of tupples of the proposer and its preference order, i.e. [("A", 1), ("B", 2), ...]
# ALERT! This takes longer time (almost x2) than the one-by-one idea's algorithm

function DA_keep(props, accs, prop_prefs, acc_prefs, acc_cap)
    prop_prefs_copy = deepcopy(prop_prefs) # Dictionary for each acceptor
    free_props = Set(props) 
    acc_matches = Dict(a => [] for a in accs)
    prop_matches = Dict(a => [] for a in props)
    acc_matches["outside"] = []
    prop_matches["outside"] = []
    acc_applylist = deepcopy(acc_matches) # Dictionary for each acceptor

    algo_lim = 5000 # limit in case of too long iteration
    count = 1

    while !isempty(free_props) && count < algo_lim # continue until everybody gets matched
        for prop in free_props
            flag = false # to check prop not accepted to applylist
            apply = first(prop_prefs_copy[prop]) # most prefarable one at this time
            for j in acc_prefs[apply[1]]
                if j[1] == prop # check individual rationality
                    push!(acc_applylist[apply[1]], j)
                    flag = true
                end
            end
            prop_prefs_copy[prop] = setdiff(prop_prefs_copy[prop], [apply]) # delete the acceptor from the proposer's preference list(copy)
            if flag == false
                if isempty(prop_prefs_copy[prop])
                    push!(prop_matches["outside"], prop) # matches outside option
                    delete!(free_props, prop)
                end
            end
        end

        # acc_applylist is filled 
        for acc in accs
            if acc_applylist[acc] !== acc_matches[acc] # only if the kept proposers profile is different from the previous 
                sort!(acc_applylist[acc], by = x -> x[2])

                k = min(acc_cap[acc], length(acc_applylist[acc])) # not to exceed the capacity, also technically not to exceed the current matches
                acc_matches[acc] = acc_applylist[acc][1:k] #"keep"

                for kept in acc_matches[acc] # delete proposers from the free propser set
                    delete!(free_props, kept[1])
                end

                for rejected in acc_applylist[acc][k+1:end]
                    if isempty(prop_prefs_copy[rejected[1]])
                        push!(prop_matches["outside"], rejected[1]) # matches outside option
                        delete!(free_props, rejected[1])
                    else
                        push!(free_props, rejected[1]) # add the rejeted proposer to free proposer set
                    end
                end
            end
            acc_applylist[acc] = deepcopy(acc_matches[acc]) # only kept proposers remain
        end

        count += 1
        if count == algo_lim
            print("reached algo_lim")
        end
    end

    for acc in accs
        acc_matches[acc] = [k[1] for k in acc_matches[acc]]
        if acc_matches[acc] == []
            push!(acc_matches["outside"], acc) 
        end
        for i in acc_matches[acc]
            push!(prop_matches[i], acc)
        end
    end
    return prop_matches, acc_matches
end

# DA algorithm process all proposers' proposes one by one
# acceptor preference must be a dictionary of only proposer array, i.e. ["A", "B", ...]

function DA_onebyone(props, accs, prop_prefs, acc_prefs, acc_cap)
    prop_prefs_copy = deepcopy(prop_prefs)
    free_props = Set(props)
    acc_matches = Dict(a => [] for a in accs)
    prop_matches = Dict(a => [] for a in props)
    acc_matches["outside"] = []
    prop_matches["outside"] = []

    algo_lim = 5000
    count = 1

    while !isempty(free_props) && count < algo_lim
        for prop in free_props
            apply = first(prop_prefs_copy[prop])
            if in(prop, acc_prefs[apply]) # check individual rationality
                if length(acc_matches[apply]) < acc_cap[apply] # if the acceptor is not full
                    push!(acc_matches[apply], prop)
                    push!(prop_matches[prop], apply)
                    delete!(free_props, prop)
                else
                    worst_match = 1
                    for current_match in acc_matches[apply] # find the worst prefered match
                        order = findfirst(==(current_match), acc_prefs[apply])
                        if order > worst_match
                            worst_match = order
                        end
                    end
                    if findfirst(==(prop), acc_prefs[apply]) < worst_match # if the new proposer is prefered than the worst one
                        rejected = acc_prefs[apply][worst_match] # rejected proposer
                        filter!(e -> e ≠ rejected, acc_matches[apply]) # remove the rejected proposer
                        push!(acc_matches[apply], prop)
                        push!(prop_matches[prop], apply)
                        delete!(free_props, prop)
                        prop_matches[rejected] = []
                        if isempty(prop_prefs_copy[rejected])
                            push!(prop_matches["outside"], prop)
                        else
                            push!(free_props, rejected)
                        end
                    end
                end
            end
            prop_prefs_copy[prop] = setdiff(prop_prefs_copy[prop], [apply])
            if isempty(prop_prefs_copy[prop]) && isempty(prop_matches[prop])
                push!(prop_matches["outside"], prop)
                delete!(free_props, prop)
            end
        end
        count += 1
        if count == algo_lim
            print("reached algo_lim")
        end
    end
    return prop_matches, acc_matches
end


# use students and universities as an example of matching market
# generate a market

function marketgen_onebyone(n,m,app_min, app_max, acc_min, acc_max, uni_pref_max)
    stu = ["$i" for i in 1:n] # students
    uni = ["$j" for j in 1001:1000+m] # universities
    stu_pref = Dict(s => [] for s in stu) # preference profile of students
    uni_pref = Dict(u => [] for u in uni) # of universities
    uni_cap = Dict(u => rand(acc_min:acc_max) for u in uni) # the capacity of universities following Uniform distribution in [acc_min, acc_max]
    stu_cap = Dict(s => 1 for s in stu)  # the capacity of students is 1

    # generate random preference profiles
    for s in stu
        pref_len = rand(app_min:app_max) # the length of preference list 
        rand_pref = [[rand(Uniform(0,1)) j] for j in uni] # assign a uniformly random number to each university
        sort!(rand_pref, by= x->x[1])
        stu_pref[s] = [rand_pref[k][2] for k in 1:pref_len] # sort and choose
    end

    for u in uni
        pref_len = uni_pref_max # the length of preference list
        rand_pref = [[rand(Uniform(0,1)) j] for j in stu] 
        sort!(rand_pref, by= x->x[1])
        uni_pref[u] = [rand_pref[k][2] for k in 1:pref_len]
    end
    return stu, uni, stu_pref, uni_pref, stu_cap, uni_cap
end

function marketgen_keep(n,m,app_min, app_max, acc_min, acc_max, uni_pref_max)
    stu = ["$i" for i in 1:n] 
    uni = ["$j" for j in 1001:1000+m] 
    stu_pref = Dict(s => [] for s in stu) 
    uni_pref = Dict(u => [] for u in uni)
    uni_cap = Dict(u => rand(acc_min:acc_max) for u in uni) 
    stu_cap = Dict(s => 1 for s in stu) 

    for s in stu
        pref_len = rand(app_min:app_max) 
        rand_pref = [[rand(Uniform(0,1)) j] for j in uni] 
        sort!(rand_pref, by= x->x[1])
        stu_pref[s] = [(rand_pref[k][2], k) for k in 1:pref_len]
    end

    for u in uni
        rand_pref = [[rand(Uniform(0,1)) j] for j in stu] 
        sort!(rand_pref, by= x->x[1])
        uni_pref[u] = [(rand_pref[k][2], k) for k in 1:uni_pref_max] # each element is a tupple of ("student name", preference order)
    end
    return stu, uni, stu_pref, uni_pref, stu_cap, uni_cap
end


# C(n)/n = "the number of participants who can benefit from strategical misrepresentation of preference" / "market size"

function Cn_onebyone(stu, uni, stu_pref, uni_pref, stu_cap, uni_cap)
    # student optimal DA
    matches_so = DA_onebyone(stu, uni, stu_pref, uni_pref, uni_cap)

    # university optimal DA
    matches_uo = DA_onebyone(uni, stu, uni_pref, stu_pref, stu_cap)
    C = 0
    for s in stu
        if !(matches_so[1][s] == matches_uo[2][s]) # if the two result is different, the participant can benefit from misrepresentation
            C += 1
        end
    end
    return C/size(stu, 1) # return the rate
end

function Cn_keep(stu, uni, stu_pref, uni_pref, stu_cap, uni_cap)

    matches_so = DA_keep(stu, uni, stu_pref, uni_pref, uni_cap)
    matches_uo = DA_keep(uni, stu, uni_pref, stu_pref, stu_cap)
    C = 0
    for s in stu
        if !(matches_so[1][s] == matches_uo[2][s]) 
            C += 1
        end
    end
    return C/size(stu, 1)
end



# compute C(n)/n for market size n and the preference length of proposers k

n_max = 500 # the maximum market size, must be < 1000 now
knum_max = 3 # the number of preference length of proposers, from 10 by 5
S = 2 # how many iteration for each (k,n) to average
x = zeros(n_max, knum_max) # the result array for C(n)\n

acc_min = 1 # min of acceptor capacity
acc_max = 1 # max

Random.seed!(34)

# this is faster
# under the assumption that the length of student preference < or = 15
# and the length of university preference < or = 100
@time for k in 1:knum_max
    k_5 = 5 * k + 5
    for n in k_5:n_max
        C_temp = 0
        for j in 1:S
            market = marketgen_onebyone(n, n, min(k_5,15), min(k_5,15), acc_min, acc_max, min(n, 100))
            C_temp += Cn_onebyone(market[1], market[2], market[3], market[4], market[5], market[6])
        end
        x[n, k] = C_temp /S
    end
    print(k_5, " end \n")
end

# ALERT! This takes far longer time (almost x2) than the one-by-one idea's algorithm
@time for k in 1:knum_max
    k_5 = 5 * k + 5
    for n in k_5:n_max
        C_temp = 0
        for j in 1:S
            market = marketgen_keep(n, n, min(k_5,15), min(k_5,15), acc_min, acc_max, min(n, 100))
            C_temp += Cn_keep(market[1], market[2], market[3], market[4], market[5], market[6])
        end
        x[n, k] = C_temp /S
    end
    print(k_5, " end \n")
end

# smoothing with moving average
(n,k)= size(x)
y_1 = copy(x)
for j in 1:k
    k_5 = 5*j+5
    
    for i in k_5+1:n-1
        y_1[i,j] = mean(x[i-1:i+1,j])
    end
end

df = DataFrame(x, [:"k=10",:"k=15",:"k=20"])
CSV.write("1to1_s=2_k=10,15,20.csv",df)

(n,k)= size(x)
y_2 = copy(x)
for j in 1:k
    k_5 = 5*j+5
    for i in k_5+1:n-1
        y_2[i,j] = mean(x[i-1:i+1,j])
    end
end

#ENV["GKS_ENCODING"] = "utf8"
#gr(fontfamily="IPAMincho")
plot([10:n_max], y_1[10:n_max, 1], label = "k=10", title = "C(n)/n for market size: n and \n preference length of students k", xlab = "n", ylab = "C(n)/n", xscale=:log10)
plot!([15:n_max],y_1[15:n_max,2], label = "k=15")
plot!([20:n_max],y_1[20:n_max,3], label = "k=20")
#plot!([20:n_max],y_1[20:n_max,3], label = "k=25")
savefig("matching_sim.png")